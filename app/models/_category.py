# -*- coding: utf-8 -*-
from __future__ import absolute_import
from sqlalchemy import Column, ForeignKey, Integer, String

from .base import Base


class Category(Base):
    __tablename__ = "category"
    id = Column(Integer, primary_key=True)
    code = Column(String(4), nullable=False)
    name = Column(String(64), unique=True, nullable=False)
    status_id = Column(Integer, ForeignKey("status.id"), default=1)
