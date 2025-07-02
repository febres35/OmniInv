from sqlalchemy import (
    Column,
    Integer,
    String,
    Numeric,
    TIMESTAMP,
    ForeignKey,
    CheckConstraint,
    text,
)
from .base import Base


class InventoryMovement(Base):
    __tablename__ = "inventory_movements"

    id = Column(Integer, primary_key=True, autoincrement=True)
    warehouse_id = Column(Integer, ForeignKey("warehouses.id"), nullable=False)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    movement_type = Column(String(50), nullable=False)
    quantity = Column(Numeric(10, 2), nullable=False)
    movement_date = Column(TIMESTAMP, server_default=text("CURRENT_TIMESTAMP"))
    source_document = Column(
        String(255)
    )  # Ejemplo: Número de Orden de Compra, Número de Despacho
    notes = Column(String)
    unit_measure_id = Column(Integer, ForeignKey("unit_measure.id"), nullable=False)

    __table_args__ = (
        CheckConstraint(
            "movement_type IN ('ENTRADA', 'SALIDA')", name="chk_movement_type"
        ),
    )
