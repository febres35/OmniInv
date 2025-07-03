from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import status, HTTPException

from app.jwt import (
    TokenData,
    RefreshTokenData,
    create_access_token,
    create_refresh_token,
    decode_refresh_token,
    verify_password,
)
from app.models import Profile
from app.models import User, AuthUser, Credential
from app.models._partner import Partner
from app.core import session
from app.constans import const_status


class UserSchemaBase(BaseModel):
    id: str | None = None
    name: str | None = None
    username: str | None = None


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    username: str | None = None


class Session(BaseModel):
    full_name: str
    partner_name: str | None
    partner_id: int | None
    profile: str


class UserLogin(BaseModel):
    full_name: str
    username: str
    password: str
    status_id: int
    profile_id: int
    partner_id: int | None
    auth_user_id: int
    user_id: int


class AuthService:

    def __init__(self, sess: AsyncSession | None = None):
        self.sess = sess

    async def autenticate(self, password, username) -> TokenResponse:
        """Login user"""
        try:
            user = await get_user_or_none(username)
        except Exception as ex:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Unable to process the provided username format",
                headers={"WWW-Authenticate": "Bearer"},
            ) from ex

        if user is None or not verify_password(password, user.password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect username or password",
                headers={"WWW-Authenticate": "Bearer"},
            )

        if user.status_id != const_status.HABILITADO.value:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User is inactive, please contact support",
                headers={"WWW-Authenticate": "Bearer"},
            )

        access_token, refresh_token = set_crendentials(user)

        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            username=user.full_name,
        )

    async def refresh_token(self, refresh_token: str) -> TokenResponse:
        """Get a new access token using a valid refresh token"""
        decoded_token: RefreshTokenData | None = await decode_refresh_token(
            refresh_token
        )
        if not decoded_token:
            raise HTTPException(status_code=401, detail="Invalid refresh token")

        user = await get_user_by_id(decoded_token.sub)

        if not user:
            raise HTTPException(status_code=401, detail="User does not exist")

        subject = TokenData(
            sub=str(user.login_id),
            profile=user.profile_id,
            user_id=user.user_id,
            group_id=user.group_id,
        )

        access_token = create_access_token(subject.model_dump())

        return TokenResponse(
            access_token=access_token,
            refresh_token="",
            token_type="bearer",
        )

    async def get_session(self, current_user_id: str):
        """Get session"""
        assert self.sess is not None

        get_user_stmt = (
            select(
                (User.firstname + " " + User.lastname).label("full_name"),
                Profile.name.label("profile"),
                Partner.name.label("partner_name"),
                Partner.id.label("partner_id"),
            )
            .select_from(User)
            .join(AuthUser, AuthUser.user_id == User.id)
            .join(Partner, Partner.id == AuthUser.partner_id)
            .join(Profile, Profile.id == AuthUser.profile_id)
            .where(
                AuthUser.id == int(current_user_id),
                AuthUser.status_id == const_status.HABILITADO.value,
            )
        )

        try:
            user = (await self.sess.execute(get_user_stmt)).one()
            if user is None:
                raise HTTPException(status_code=401, detail="Invalid refresh token")

            return user

        except HTTPException as ex:
            return {"message": str(ex), "error": " Unauthorized"}, 401

    async def logout(self, refresh_token: str):
        """
        Invalidate the refresh token (logout).
        This is a placeholder as JWTs are stateless; implement token blacklisting if needed.
        """
        # If using a token blacklist, add the refresh_token to the blacklist here.
        # For now, just return a success message.
        return {"message": "Successfully logged out"}


async def get_user_or_none(username) -> UserLogin | None:
    sess = await session()

    if sess is None:
        raise Exception("paso un error")  # pylint: disable=broad-exception-raised

    get_user_stmt = (
        select(
            AuthUser.profile_id,
            AuthUser.status_id,
            (User.firstname + " " + User.lastname).label("full_name"),
            Credential.password,
            AuthUser.username,
            AuthUser.id.label("auth_user_id"),
            User.id.label("user_id"),
        )
        .join(User, User.id == AuthUser.user_id)
        .where(AuthUser.username == username)
    )
    result = (await sess.execute(get_user_stmt)).one_or_none()
    await sess.close()
    return result


async def get_user_by_id(id: str) -> UserLogin | None:

    sess = await session()

    if sess is None:
        raise Exception("paso un error")  # pylint: disable=broad-exception-raised

    get_user_stmt = (
        select(
            AuthUser.partner_id,
            AuthUser.profile_id,
            AuthUser.status_id,
            (User.firstname + " " + User.lastname).label("full_name"),
            Credential.password,
            AuthUser.username,
            AuthUser.id.label("login_id"),
            User.id.label("user_id"),
        )
        .join(User, User.id == AuthUser.user_id)
        .where(AuthUser.id == int(id), AuthUser.status_id == 1)
    )

    result = (await sess.execute(get_user_stmt)).one_or_none()
    await sess.close()
    return result


def set_crendentials(user: UserLogin):

    subject = TokenData(
        sub=str(user.login_id),
        profile=user.profile_id,
        partner_id=user.partner_id,
        user_id=user.user_id,
    )

    refresh_subject = RefreshTokenData(sub=str(user.login_id))

    access_token = create_access_token(subject.model_dump())
    refresh_token = create_refresh_token(refresh_subject.model_dump())

    return access_token, refresh_token
