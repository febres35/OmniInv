# coding: utf-8
from __future__ import absolute_import
from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from app.models.base import Base


class ProfileRol(Base):
    __tablename__ = "profile_rol"

    id = Column(Integer, primary_key=True, autoincrement=True)
    version = Column(Integer, default=0, nullable=False)
    name = Column(String(255), nullable=False)
    profile_id = Column(Integer, ForeignKey("profile.id"), nullable=False)
    rol_id = Column(Integer, ForeignKey("rol.id"), nullable=False)
    permissing_level = Column(Integer, nullable=False, default=0)

    def __repr__(self):
        return f"{self.name}"
