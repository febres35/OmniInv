# -*- coding: utf-8 -*-
from __future__ import absolute_import
from sqlalchemy import Column, Integer, String
from .base import Base


class UnitMeasure(Base):
    __tablename__ = "unit_measure"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(32), nullable=False)
    code = Column(String(8), nullable=False)
