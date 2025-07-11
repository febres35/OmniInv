# coding: utf-8
from __future__ import absolute_import
from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, text
from sqlalchemy.orm import relationship
from app.models.base import Base


class UserGroup(Base):
    __tablename__ = "user_groups"

    id = Column(Integer, primary_key=True, autoincrement=True)
    version = Column(Integer, default=0, nullable=False)
    name = Column(String(255), nullable=False)
    description = Column(String(255), nullable=True)
    group_id = Column(Integer, ForeignKey("user_groups.id"), nullable=True)
    created_at = Column(
        DateTime, nullable=False, server_default=text("CURRENT_TIMESTAMP")
    )
    updated_at = Column(
        DateTime, nullable=False, server_default=text("CURRENT_TIMESTAMP")
    )
    created_by = Column(Integer, ForeignKey("auth_user.id"), nullable=False)
    updated_by = Column(Integer, ForeignKey("auth_user.id"), nullable=False)

    def __repr__(self):
        return f"{self.name}"
