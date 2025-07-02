from sqlalchemy import (
    Column,
    Integer,
    String,
    Text,
)
from .base import Base


class ShrinkageReason(Base):
    __tablename__ = "shrinkage_reasons"

    id = Column(Integer, primary_key=True, autoincrement=True)
    reason_name = Column(String(255), nullable=False, unique=True)
    description = Column(Text)
