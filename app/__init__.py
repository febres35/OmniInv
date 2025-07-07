import os
from jwt import decode
from typing import AsyncIterator
from contextlib import asynccontextmanager

from redis import asyncio as aioredis
from fastapi import FastAPI, APIRouter, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi_cache import FastAPICache
from fastapi_cache.backends.redis import RedisBackend
from sqlalchemy.exc import SQLAlchemyError


from app import logger
from app.jwt import ALGORITHM, SECRET_KEY
from app.utils.save_error_log import save_sql_error_log

from .utils.key_builder import key_builder
from .api import main_router
from .middlewares import middleware

DEPLOY_ENV = os.getenv("DEPLOY_ENV")
REDIS_PASSWORD = os.getenv("REDIS_PASSWORD")
REDIS_HOST = os.getenv("REDIS_HOST")
REDIS_PORT = os.getenv("REDIS_PORT")


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    pool = aioredis.ConnectionPool.from_url(
        f"redis://:{REDIS_PASSWORD}@{REDIS_HOST}:{REDIS_PORT}/1"
    )
    redis = aioredis.Redis(connection_pool=pool)
    FastAPICache.init(
        RedisBackend(redis), prefix="fastapi-cache", key_builder=key_builder
    )

    yield


app = FastAPI(
    lifespan=lifespan,
    middleware=middleware,
    swagger_ui_parameters={
        "docExpansion": "none",
    },
)


@app.exception_handler(SQLAlchemyError)
async def db_api_error(request: Request, exc: SQLAlchemyError):
    try:
        assert SECRET_KEY is not None
        assert ALGORITHM is not None
        assert DEPLOY_ENV is not None

        content = "Something got wrong" if DEPLOY_ENV == "production" else str(exc)
        token = request.headers["authorization"]

        prefix = "Bearer "
        token = token[len(prefix) :]
        payload = decode(token, SECRET_KEY, algorithms=[ALGORITHM])

        tick = await save_sql_error_log(request, payload["DB"], exc)
        content = {"tick": tick, "content": content}

    except Exception as ex:  # pylint: disable=broad-exception-caught,
        logger.logger.error(ex)

    logger.logger.error(exc)
    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,
        content=content,
    )


top_router = APIRouter(prefix="/api")
sub_router = APIRouter(prefix="/v1")


origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


top_router.include_router(sub_router)

app.include_router(top_router)
app.include_router(main_router)
