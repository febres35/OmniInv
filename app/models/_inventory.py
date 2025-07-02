from sqlalchemy import (
    Column,
    Integer,
    Numeric,
    TIMESTAMP,
    ForeignKey,
    UniqueConstraint,
    text,
)
from .base import Base


class Inventory(Base):
    __tablename__ = "inventory"
    __table_args__ = (
        UniqueConstraint(
            "warehouse_id", "product_id", name="uq_inventory_warehouse_product"
        ),
    )

    id = Column(Integer, primary_key=True, autoincrement=True)
    warehouse_id = Column(Integer, ForeignKey("warehouses.id"), nullable=False)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    stock_quantity = Column(Numeric(10, 2), nullable=False, server_default=text("0"))
    last_update = Column(TIMESTAMP, server_default=text("CURRENT_TIMESTAMP"))
