from fastapi import APIRouter
from .auth import auth_router

main_router = APIRouter(prefix="/api/v1")

main_router.include_router(auth_router)


__all__ = [
    "main_router",
]
