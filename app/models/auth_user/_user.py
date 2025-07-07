# --
from datetime import datetime

from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey

from app.models.base import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, autoincrement=True, primary_key=True)
    firstname = Column(String(64), nullable=False)
    lastname = Column(String(64))
    type = Column(String(64), nullable=False)
    idem = Column(String(25), nullable=False, unique=True)
    phone = Column(String(100))
    email = Column(String(255))
    create_at = Column(DateTime, default=datetime.now)
    version = Column(Integer, nullable=False, default=0)

    def __repr__(self) -> str:
        return f"<User {self.firstname} {self.lastname}\
             {self.type}-{self.idem} {self.phone}>"
