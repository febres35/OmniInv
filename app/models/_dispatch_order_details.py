from sqlalchemy import Column, Integer, Numeric, ForeignKey
from .base import Base


class DispatchOrderDetail(Base):
    __tablename__ = "dispatch_order_details"

    id = Column(Integer, primary_key=True, autoincrement=True)
    dispatch_order_id = Column(
        Integer, ForeignKey("dispatch_orders.id"), nullable=False
    )
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    quantity = Column(Numeric(10, 2), nullable=False)
