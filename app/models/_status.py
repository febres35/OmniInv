# coding: utf-8
from __future__ import absolute_import

from sqlalchemy import Column, Integer, String

from .base import Base


class Status(Base):
    __tablename__ = "status"

    id = Column(Integer, primary_key=True, autoincrement=True)
    version = Column(Integer, nullable=False)
    name = Column(String(24), nullable=False)
