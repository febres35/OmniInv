# coding: utf-8
from sqlalchemy import CHAR, Column, Integer, String, text

from .base import Base


class PartnerType(Base):
    __tablename__ = "partner_type"

    id = Column(
        Integer,
        primary_key=True,
        autoincrement=True,
    )
    version = Column(Integer, nullable=False, default=1)
    name = Column(String(64), nullable=False)
    code = Column(CHAR(1))
