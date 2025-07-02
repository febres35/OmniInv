# coding: utf-8
from sqlalchemy import (
    Column,
    ForeignKey,
    Integer,
    CHAR,
    String,
    text,
)

from .base import Base


class Partner(Base):
    __tablename__ = "partners"

    id = Column(
        Integer,
        primary_key=True,
        autoincrement=True,
    )
    version = Column(Integer, nullable=False, default=0)
    name = Column(String(255), nullable=False)
    type = Column(CHAR(1), nullable=False)
    ident = Column(String(25))
    email = Column(String(255))
    phone = Column(String(100))
    address = Column(String(255))
    partner_type = Column(Integer, ForeignKey("partner_type.id"), nullable=False)
    status_id = Column(Integer, ForeignKey("status.id"), nullable=False, default=2)
