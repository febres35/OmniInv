from sqlalchemy import Column, Integer, Numeric, ForeignKey
from .base import Base


class PurchaseOrderDetail(Base):
    __tablename__ = "purchase_order_details"

    id = Column(Integer, primary_key=True, autoincrement=True)
    purchase_order_id = Column(
        Integer, ForeignKey("purchase_orders.id"), nullable=False
    )
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    quantity = Column(Numeric(10, 2), nullable=False)
    unit_price = Column(Numeric(10, 2), nullable=False)
    subtotal = Column(Numeric(12, 2), nullable=False)
