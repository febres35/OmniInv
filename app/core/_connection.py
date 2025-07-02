# coding: utf-8
import os
import contextlib

from typing import AsyncIterator

from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
    AsyncEngine,
)

db_user = os.getenv("DB_USER")
db_password = os.getenv("DB_PASSWORD")
db_host = os.getenv("DB_HOST")
db_port = os.getenv("DB_PORT")
db_name = os.getenv("DB_NAME")


class ConnectionManager:

    def __init__(self):
        self.engines: dict[str, AsyncEngine] = {}
        self._sessionmaker = async_sessionmaker(autoflush=False)

    async def _create_engine(self) -> AsyncEngine:

        # pylint: disable=consider-using-f-string
        connection_string = "postgresql+asyncpg://{}:{}@{}:{}/{}".format(
            db_user, db_password, db_host, db_port, db_name
        )

        return create_async_engine(
            connection_string,
            pool_recycle=10,
            pool_size=60,
            max_overflow=10,
            pool_use_lifo=True,
            pool_reset_on_return=True,
        )

    async def _get_connection(self):
        connection = await self._create_engine()

        if connection is None:
            # pylint: disable=broad-exception-raised
            raise Exception("Can not get connectiong wiht Database")

        return connection

    @contextlib.asynccontextmanager
    async def get_context_session(self) -> AsyncIterator[AsyncSession]:

        if self._sessionmaker is None:
            # pylint: disable=broad-exception-raised
            raise Exception("DatabaseSessionManager is not initialized")

        connection = await self._create_engine()
        session = self._sessionmaker(bind=connection, autocommit=False)

        try:
            yield session
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()

    async def get_session(self) -> AsyncSession:

        if self._sessionmaker is None:
            # pylint: disable=broad-exception-raised
            raise Exception("DatabaseSessionManager is not initialized")

        connection = await self._get_connection()
        session = self._sessionmaker(bind=connection, autocommit=False)

        return session


connection_manager = ConnectionManager()


async def get_session() -> AsyncSession:
    return await connection_manager.get_session()


async def get_context_session():
    async with connection_manager.get_context_session() as session:
        yield session
