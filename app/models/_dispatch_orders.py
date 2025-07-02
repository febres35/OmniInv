from sqlalchemy import Column, Integer, String, Text, TIMESTAMP, ForeignKey, text
from .base import Base


class DispatchOrder(Base):
    __tablename__ = "dispatch_orders"

    id = Column(Integer, primary_key=True, autoincrement=True)
    order_number = Column(String(50), unique=True, nullable=False)
    dispatch_date = Column(TIMESTAMP, server_default=text("CURRENT_TIMESTAMP"))
    created_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    status_id = Column(
        Integer, ForeignKey("status.id"), nullable=False, server_default=text("3")
    )
    notes = Column(Text)
