# coding: utf-8
from __future__ import absolute_import
from sqlalchemy import Column, Integer, ForeignKey, DateTime, text
from sqlalchemy.orm import relationship
from app.models.base import Base
from ._rol import Rol
from ._permissions import (
    Permissions,
)


class PermissionsLevel(Base):
    __tablename__ = "permissions_level"

    id = Column(Integer, primary_key=True, autoincrement=True)
    rol_id = Column(ForeignKey("roles.id"), nullable=False)
    permissions_id = Column(ForeignKey("permissions.id"), nullable=False)
    created_at = Column(
        DateTime, nullable=False, server_default=text("CURRENT_TIMESTAMP")
    )

    rol = relationship(Rol)
    permissions = relationship(Permissions)

    def __repr__(self):
        return f"{self.rol.name} - {self.permissions.name}"
