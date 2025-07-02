from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from app.dependencies import DBSessionDep
from app.jwt import TokenData, get_current_user, oauth2_scheme
from app.routes.auth.auth_service import AuthService, Session

authentication_router = APIRouter(prefix="/auth", tags=["Authentication"])


async def check_cookie(token: str = Depends(oauth2_scheme)):
    if not token:
        return None
    return token


@authentication_router.post("/login")
async def login(
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()],
):
    service = AuthService()
    response = await service.autenticate(
        username=form_data.username, password=form_data.password
    )

    return response


@authentication_router.post("/refresh")
async def refresh(
    refresh_token: str = Depends(check_cookie),
):
    """
    Create a refresh token route
    """

    service = AuthService()
    if not refresh_token:
        raise HTTPException(status_code=401, detail="No refresh token")
    print(refresh_token)
    return await service.refresh_token(
        refresh_token=refresh_token,
    )


@authentication_router.post("/session", response_model=Session)
async def session(
    current_user: Annotated[TokenData, Depends(get_current_user)],
    sess: DBSessionDep,
):
    """
    Create session of a user
    """

    service = AuthService(sess)
    return await service.get_session(
        current_user_id=current_user.sub,
    )
