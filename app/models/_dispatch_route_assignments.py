from sqlalchemy import Column, Integer, TIMESTAMP, ForeignKey, text
from .base import Base


class DispatchRouteAssignment(Base):
    __tablename__ = "dispatch_route_assignments"

    id = Column(Integer, primary_key=True, autoincrement=True)
    dispatch_order_id = Column(
        Integer, ForeignKey("dispatch_orders.id"), nullable=False
    )
    route_id = Column(Integer, ForeignKey("dispatch_routes.id"), nullable=True)
    assigned_at = Column(TIMESTAMP, server_default=text("CURRENT_TIMESTAMP"))
