from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy import Column, Integer, String, text, ForeignKey, DateTime, Text

from app.models.base import Base


class UserReports(Base):
    __tablename__ = "user_reports"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(ForeignKey("user.id"), nullable=True)
    title = Column(Text, nullable=False)
    error_description = Column(ForeignKey("state_flow.id"), default=1, nullable=False)
    server_message = Column(
        Text, server_default=text("CURRENT_TIMESTAMP"), nullable=False
    )
    created_at = Column(DateTime(timezone=True))
    status_flow_id = Column(Integer, default=1, nullable=False)
    images = Column(ARRAY(String(255)))
