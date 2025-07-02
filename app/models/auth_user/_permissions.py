# coding: utf-8
from __future__ import absolute_import
from sqlalchemy import Column, Integer, String
from app.models.base import Base


class Permissions(Base):
    __tablename__ = "permissions"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(255), nullable=False)

    def __repr__(self):
        return f"{self.name}"
