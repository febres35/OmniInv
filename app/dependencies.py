from typing import Annotated
from fastapi import Depends, Header
import redis.asyncio as redis
from sqlalchemy.ext.asyncio import AsyncSession
from app.jwt import TokenData, get_current_user
from app.schemas import CustomHeadersSchema
from app.db._connection import (
    get_context_session,
)
from app.services._redis import get_redis_context_client, get_redis_client

DBSessionDep = Annotated[AsyncSession, Depends(get_context_session)]
RedisClient = Annotated[redis.Redis, Depends(get_redis_context_client)]
RedisClientNoContext = Annotated[redis.Redis, Depends(get_redis_client)]
CurrentUser = Annotated[TokenData, Depends(get_current_user)]
CustomHeaders = Annotated[CustomHeadersSchema, Header()]
