# -*- coding: utf-8 -*-
from __future__ import absolute_import

from sqlalchemy import Column, Integer, ForeignKey, String, Numeric, Date, Boolean

from .base import Base


class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, autoincrement=True)
    code = Column(String(20), nullable=False, unique=True)
    category_id = Column(Integer, ForeignKey("category.id"), nullable=False)
    quality_id = Column(Integer, ForeignKey("quality.id"), nullable=False)
    numeric_seq = Column(Integer, nullable=True)
    format_id = Column(Integer, ForeignKey("format.id"), nullable=True)
    model_id = Column(Integer, ForeignKey("model.id"), nullable=True)
    make_id = Column(Integer, ForeignKey("make.id"))  # marca
    name = Column(String(200), nullable=False)
    unit_measure_id = Column(String(50), nullable=False)
    batching = Column(Boolean, default=False)
    serial_processing = Column(Boolean, default=False)
    amount_of_content = Column(Numeric(10, 2), nullable=False)
    pallet_load_weight = Column(Numeric(10, 2), nullable=True)
    box_weight = Column(Numeric(10, 2), nullable=True)
    mt2_pallet = Column(Numeric(10, 2), nullable=True)
    mt2_box = Column(Numeric(10, 2), nullable=True)
    currency_id = Column(Integer, ForeignKey("currency.id"), nullable=True)
    created_at = Column(Date, default="CURRENT_DATE")
    replacement_cost = Column(Numeric(10, 2), nullable=True)
