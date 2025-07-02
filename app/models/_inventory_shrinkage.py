from sqlalchemy import (
    Column,
    Integer,
    Text,
    Numeric,
    TIMESTAMP,
    ForeignKey,
    text,
)
from .base import Base


class InventoryShrinkage(Base):
    __tablename__ = "inventory_shrinkage"

    id = Column(Integer, primary_key=True, autoincrement=True)
    inventory_movement_id = Column(
        Integer, ForeignKey("inventory_movements.id"), nullable=False
    )
    shrinkage_reason_id = Column(
        Integer, ForeignKey("shrinkage_reasons.id"), nullable=False
    )
    quantity_lost = Column(Integer, nullable=False)
    price = Column(Numeric(18, 2))
    loss_date = Column(TIMESTAMP, server_default=text("CURRENT_TIMESTAMP"))
    rate_id = Column(Integer, ForeignKey("rate.id"), nullable=False)
    notes = Column(Text)
