from fastapi import Request
from sqlalchemy import insert
from sqlalchemy.exc import SQLAlchemyError
from app.models._error_logs import ErrorLogs
from app.core import session


async def save_sql_error_log(request: Request, port: str, exc: SQLAlchemyError) -> str:

    sess = await session()

    async with sess:
        error_log_stmt = (
            insert(ErrorLogs)
            .values(
                code=exc.code if exc.code else "SQLALCHEMY",
                message=str(exc),
                request=str(request.url),
                db=port,
            )
            .returning(ErrorLogs.id)
        )

        tick = (await sess.execute(error_log_stmt)).scalar_one()
        await sess.commit()
    return tick
