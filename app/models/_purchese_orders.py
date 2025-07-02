from sqlalchemy import (
    Column,
    Integer,
    String,
    Date,
    Text,
    TIMESTAMP,
    Numeric,
    ForeignKey,
    text,
)
from .base import Base


class PurchaseOrder(Base):
    __tablename__ = "purchase_orders"

    id = Column(Integer, primary_key=True, autoincrement=True)
    order_number = Column(String(50), unique=True, nullable=False)
    partner_id = Column(Integer, ForeignKey("partners.id"), nullable=False)
    order_date = Column(TIMESTAMP, server_default=text("CURRENT_TIMESTAMP"))
    delivery_date = Column(Date)
    created_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    state_flow = Column(
        Integer, ForeignKey("state_flow.id"), nullable=False, server_default=text("3")
    )
    rate_id = Column(Integer, ForeignKey("rate.id"))
    total_amount = Column(Numeric(18, 2))
    notes = Column(Text)
