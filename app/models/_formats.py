# -*- coding: utf-8 -*-
from __future__ import absolute_import
from sqlalchemy import Column, Integer, String, ForeignKey
from .base import Base


class Format(Base):
    __tablename__ = "formats"
    __table_args__ = {"schema": "public"}

    id = Column(Integer, primary_key=True, autoincrement=True)
    dimensions = Column(String(20), nullable=True)
    description = Column(String(100), nullable=True)
    unit_measure_id = Column(
        Integer, ForeignKey("public.unit_measure.id"), nullable=True
    )
