# -*- coding: utf-8 -*-
from __future__ import absolute_import
from sqlalchemy import Column, Integer, text, ForeignKey, Numeric, Date

from .base import Base


class Rate(Base):
    __tablename__ = "rate"

    id = Column(Integer, primary_key=True, autoincrement=True)
    currency_id = Column(ForeignKey("moneda.id"), nullable=True)
    _value = Column(Numeric(18, 3, asdecimal=False), nullable=False, default=0)
    rate_date = Column(Date, nullable=False)
    rate_value = Column(Numeric(10, 2, asdecimal=False), nullable=False, default=0)
