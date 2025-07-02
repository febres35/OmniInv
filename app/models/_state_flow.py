# coding: utf-8
from __future__ import absolute_import

from sqlalchemy import Column, Integer, String, text

from .base import Base


class StateFlow(Base):
    __tablename__ = "state_flow"

    id = Column(
        Integer,
        primary_key=True,
        autoincrement=True,
    )
    version = Column(Integer, nullable=False)
    name = Column(String(24), nullable=False)
