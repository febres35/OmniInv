# coding: utf-8
from __future__ import absolute_import

from sqlalchemy import Column, ForeignKey, Integer, String, text, DateTime
from sqlalchemy.orm import relationship

from app.models.base import Base


class AuthUser(Base):

    __tablename__ = "auth_user"

    id = Column(Integer, primary_key=True, autoincrement=True)
    version = Column(Integer, nullable=False, default=0)
    user_id = Column(Integer, ForeignKey("public.users.id"), nullable=False)
    username = Column(String(32), nullable=False, unique=True)
    profile_id = Column(Integer, ForeignKey("profile.id"), nullable=False)
    group_id = Column(Integer, ForeignKey("group.id"), nullable=True)
    status_id = Column(Integer, ForeignKey("status.id"), nullable=False, default=2)
    updated_at = Column(
        DateTime, nullable=False, server_default=text("CURRENT_TIMESTAMP")
    )

    status = relationship("Status")
