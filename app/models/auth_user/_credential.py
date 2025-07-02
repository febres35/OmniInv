# coding: utf-8
from __future__ import absolute_import
from sqlalchemy import Column, Integer, String, ForeignKey, Boolean, DateTime
from sqlalchemy.orm import relationship
from ..base import Base


class Credential(Base):
    __tablename__ = "credential"

    id = Column(Integer, primary_key=True, autoincrement=True)
    auth_user_id = Column(Integer, ForeignKey("auth_user.id"), nullable=False)
    password = Column(String(50), nullable=False)
    created_at = Column(DateTime, nullable=False)
    update_at = Column(DateTime, nullable=False)
    failed_attempts = Column(Integer, nullable=False, default=0)
    is_active = Column(Boolean, nullable=False, default=True)

    user = relationship("AuthUser", back_populates="credentials")

    def __repr__(self):
        return f"{self.password}"
