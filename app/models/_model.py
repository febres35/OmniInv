# -*- coding: utf-8 -*-
from __future__ import absolute_import
from sqlalchemy import Column, Integer, String
from .base import Base


class Model(Base):
    __tablename__ = "model"

    id = Column(Integer, primary_key=True, autoincrement=True)
    code = Column(String(20), nullable=True)
    name = Column(String(100), nullable=True)
