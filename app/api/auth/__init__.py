from fastapi import APIRouter
from .auth_router import authentication_router


auth_router = APIRouter()
auth_router.include_router(authentication_router)

__all__ = [
    "auth_router",
]
