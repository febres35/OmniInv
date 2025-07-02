import uuid
from sqlalchemy import (
    Column,
    Integer,
    String,
    Sequence,
)

from sqlalchemy.dialects.postgresql import UUID
from .base import Base


class Image(Base):
    __tablename__ = "image"
    id = Column(Integer, Sequence("image_id_seq"), autoincrement=True, primary_key=True)
    uuid = Column(UUID(as_uuid=True), default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    url = Column(String(255), nullable=False)
