from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import (Column, DateTime, String, text)


Base = declarative_base()


class ErrorLogs(Base):
    __tablename__ = 'error_logs'

    id = Column(String, primary_key=True)
    created_at = Column(DateTime, server_default=text("CURRENT_TIMESTAMP"))
    code = Column(String, nullable=False)
    message = Column(String, nullable=False)
    request = Column(String, nullable=False)
    db = Column(String)
