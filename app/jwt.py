import os
from datetime import datetime, timedelta, timezone
from jwt import PyJWTError, encode, decode
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from passlib.context import CryptContext
from pydantic import BaseModel

SECRET_KEY = os.getenv("SECRET_KEY")
REFRESH_TOKEN_SECRET_KEY = os.getenv("REFRESH_TOKEN_SECRET_KEY")
ALGORITHM = os.getenv("ALGORITHM")
ACCESS_TOKEN_EXPIRE_MINUTES = os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES")
REFRESH_TOKEN_EXPIRE_MINUTES = os.getenv("REFRESH_TOKEN_EXPIRE_MINUTES")


oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl="/api/v1/auth/login", scheme_name="JWT", auto_error=False
)


class Token(BaseModel):
    access_token: str
    token_type: str


class TokenData(BaseModel):
    sub: str
    profile: int
    group_id: int
    user_id: int


class RefreshTokenData(BaseModel):
    sub: str


class User(BaseModel):
    username: str
    email: str | None = None
    full_name: str | None = None
    disabled: bool | None = None


class UserInDB(User):
    hashed_password: str


pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def verify_password(plain_password, hashed_password) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def hash_password(password) -> str:
    return pwd_context.hash(password)


def create_access_token(data: dict, expires_delta: timedelta | None = None):
    assert ACCESS_TOKEN_EXPIRE_MINUTES is not None
    assert SECRET_KEY is not None

    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(
            minutes=int(ACCESS_TOKEN_EXPIRE_MINUTES)
        )
    to_encode.update({"exp": expire})
    encoded_jwt = encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def create_refresh_token(data: dict, expires_delta: timedelta | None = None):
    assert REFRESH_TOKEN_EXPIRE_MINUTES is not None
    assert REFRESH_TOKEN_SECRET_KEY is not None

    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(
            minutes=int(REFRESH_TOKEN_EXPIRE_MINUTES)
        )

    to_encode.update({"exp": expire})
    encoded_jwt = encode(to_encode, REFRESH_TOKEN_SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


async def decode_access_token(token: str) -> TokenData | None:
    assert SECRET_KEY is not None
    assert ALGORITHM is not None

    try:
        payload = decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return TokenData(
            sub=payload.get("sub"),
            profile=payload.get("profile"),
            user_id=payload.get("user_id"),
            partner_id=payload.get("partner_id"),
        )

    except PyJWTError as e:
        print(e)
        return None


async def decode_refresh_token(token: str) -> RefreshTokenData | None:
    assert REFRESH_TOKEN_SECRET_KEY is not None
    assert ALGORITHM is not None

    try:
        payload = decode(token, REFRESH_TOKEN_SECRET_KEY, algorithms=[ALGORITHM])
        return RefreshTokenData(sub=payload.get("sub"))

    except PyJWTError as e:
        print(e)
        return None


async def get_current_user(token: str = Depends(oauth2_scheme)) -> TokenData:
    assert SECRET_KEY is not None
    assert ALGORITHM is not None

    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
    )

    try:

        payload = decode(token, SECRET_KEY, algorithms=[ALGORITHM])

        return TokenData(
            sub=payload.get("sub"),
            profile=payload.get("profile"),
            user_id=payload.get("user_id"),
            partner_id=payload.get("partner_id"),
        )

    except Exception as ex:
        raise credentials_exception from ex


class GetCurrentUser:
    def __init__(self, attr: list[str] | str):
        self.attr = attr

    def __call__(self, token: str = Depends(oauth2_scheme)):
        assert SECRET_KEY is not None
        assert ALGORITHM is not None

        credentials_exception = HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
        )

        try:
            payload = decode(token, SECRET_KEY, algorithms=[ALGORITHM])

        except Exception as ex:
            raise credentials_exception from ex

        if isinstance(self.attr, str):
            return payload.get(self.attr)

        if len(self.attr) == 1:
            return payload.get(self.attr[0])

        attrs = {}
        for key in self.attr:
            if key in payload:
                attrs[key] = payload.get(key, None)

        return attrs
