# -*- coding: utf-8 -*-
from __future__ import absolute_import
from sqlalchemy import Column, Integer, String
from .base import Base


class Currency(Base):
    __tablename__ = "currency"

    id = Column(Integer, primary_key=True, autoincrement=True)
    code = Column(String(3), nullable=True)
    name = Column(String(50), nullable=True)
