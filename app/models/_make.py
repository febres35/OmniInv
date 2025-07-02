# -*- coding: utf-8 -*-
from __future__ import absolute_import
from sqlalchemy import Column, Integer, String
from .base import Base


class Make(Base):
    __tablename__ = "make"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(100), nullable=True)
