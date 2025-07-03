# coding: utf-8
from __future__ import absolute_import

from sqlalchemy import Column, Integer, String

from app.models.base import Base


class Profile(Base):
    __tablename__ = "profile"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(255), nullable=False)
