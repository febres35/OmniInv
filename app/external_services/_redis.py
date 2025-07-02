import os
import json
import contextlib
from typing import AsyncIterator
import redis.asyncio as redis

from app.logger import logger

redis_host = os.getenv("REDIS_HOST")


class RedisConnection():

    def __init__(self):
        self.pool = redis.ConnectionPool.from_url(
            f'redis://:{os.getenv("REDIS_PASSWORD")}@{redis_host}:{os.getenv("REDIS_PORT")}/1',
            encoding="utf8", decode_responses=True
        )

    @contextlib.asynccontextmanager
    async def get_context_session(self) -> AsyncIterator[redis.Redis]:
        redis_client = redis.Redis.from_pool(self.pool)

        try:
            yield redis_client
        except Exception as ex:
            logger.error(ex)
            raise
        finally:
            pass
            # await redis_client.aclose()

    async def get_session(self) -> redis.Redis:
        redis_client = redis.Redis.from_pool(self.pool)

        return redis_client


redis_connection = RedisConnection()


async def get_redis_context_client():
    async with redis_connection.get_context_session() as client:
        yield client


async def get_redis_client():
    return await redis_connection.get_session()


class RedisService:

    def __init__(self):
        self.redis = redis_connection
        self.client = None

    async def _ensure_client(self):
        if self.client is None:
            async with self.redis.get_context_session() as client:
                pong = await client.ping()
                if pong:
                    self.client = client
                else:
                    logger.error("Redis is not connected")
                    raise ConnectionError("Redis is not connected")

    async def get_client(self):
        await self._ensure_client()
        pong = await self.client.ping()

        if pong:
            return self.client

        logger.error("Redis is not connected")
        return None

    async def get_(self, key):
        await self._ensure_client()
        pong = await self.client.ping()
        if not pong:
            logger.error("Redis is not connected")
            return None

        result = await self.client.get(key)
        if result is None:
            return None

        return json.loads(result)

    async def set_(self, key, value, time=360):
        await self._ensure_client()
        pong = await self.client.ping()

        if not pong:
            logger.error("Redis is not connected")
            return None

        return await self.client.set(key, json.dumps(value), ex=int(time))

    async def exist_conn(self):
        await self._ensure_client()
        return await self.client.ping()

    async def delete_pattern(self, pattern: str):
        await self._ensure_client()
        keys = await self.client.keys(pattern)

        if keys:
            await self.client.delete(*keys)
