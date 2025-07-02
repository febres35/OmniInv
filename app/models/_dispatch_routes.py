from sqlalchemy import Column, Integer, String, Text
from .base import Base


class DispatchRoute(Base):
    __tablename__ = "dispatch_routes"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(255), nullable=False)
    description = Column(Text)
