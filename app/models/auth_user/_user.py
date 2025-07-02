# --
from datetime import datetime
from xmlrpc.client import Boolean

from sqlalchemy import (
    Column,
    Integer,
    String,
    DateTime,
)

from app.models.base import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, autoincrement=True, primary_key=True)
    version = Column(Integer, nullable=False, default=1)
    firstname = Column(String(64))
    lastname = Column(String(64))
    type = Column(String(1), nullable=False)
    identity = Column(String(32), nullable=False)
    phone_number = Column(String(64))
    email = Column(String(128))
    create_at = Column(DateTime, default=datetime.now())
    update_at = Column(DateTime, default=datetime.now())
    is_deleted = Column(Boolean, default=False)

    def __repr__(self) -> str:
        return f"<Usurious {self.firstname} {self.lastname}\
             {self.type}-{self.identity} {self.phone_number}>"
