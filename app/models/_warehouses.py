from sqlalchemy import Column, Integer, String, Text, TIMESTAMP, text
from .base import Base


class Warehouse(Base):
    __tablename__ = "warehouses"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(255), nullable=False)
    code = Column(String(50), unique=True)
    address = Column(Text)
    create_at = Column(TIMESTAMP, server_default=text("CURRENT_TIMESTAMP"))
