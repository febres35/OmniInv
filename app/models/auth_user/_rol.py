# -*- coding: utf-8 -*-
from __future__ import absolute_import
from sqlalchemy import Column, Integer, String, ForeignKey
from app.models.base import Base


class Rol(Base):
    __tablename__ = "roles"

    id = Column(Integer, primary_key=True, autoincrement=True)
    version = Column(Integer, default=0, nullable=False)
    name = Column(String(255), nullable=False)
    description = Column(String(255))
    is_active = Column(Integer, default=1, nullable=False)
    path_name = Column(String(255), nullable=True, default="#")
    icon = Column(String(255), nullable=True)
    label = Column(String(255), nullable=True)
    rol_parent = Column(Integer, ForeignKey("roles.id"), nullable=True)
