# coding: utf-8
from sqlalchemy import Column, ForeignKey, Integer, String, Sequence
from .base import Base


class ProductImage(Base):
    __tablename__ = "product_image"

    id = Column(Integer, Sequence("product_image_id_seq"), primary_key=True)
    product_id = Column(Integer, ForeignKey("product.id"), nullable=False)
    img_url = Column(String, nullable=False)
