# coding: utf-8
from __future__ import absolute_import

from sqlalchemy import Column, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.models.base import Base
from ._rol import ProfileType


class Profile(Base):
    __tablename__ = "profile"

    id = Column(Integer, primary_key=True, autoincrement=True)
    version = Column(Integer, nullable=False)
    name = Column(String(255), nullable=False)
    profile_type_id = Column(ForeignKey("profile_type.id"), nullable=False)

    tipo_perfil = relationship(ProfileType)
