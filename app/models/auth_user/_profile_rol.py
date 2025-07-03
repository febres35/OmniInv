# coding: utf-8
from __future__ import absolute_import
from sqlalchemy import Column, Integer, ForeignKey
from app.models.base import Base


class ProfileRol(Base):
    __tablename__ = "profile_rol"

    id = Column(Integer, primary_key=True, autoincrement=True)
    profile_id = Column(Integer, ForeignKey("profile.id"), nullable=False)
    rol_id = Column(Integer, ForeignKey("rol.id"), nullable=False)
    permissing_level = Column(Integer, nullable=False, default=0)

    def __repr__(self):
        return f"ProfileRol(id={self.id}, profile_id={self.profile_id}, rol_id={self.rol_id}, permissing_level={self.permissing_level})"
