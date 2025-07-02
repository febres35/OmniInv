import hashlib
from typing import Any, Callable, Dict, Optional, Tuple
from fastapi import Request, Response


def key_builder(  # pylint: disable=too-many-arguments
    func: Callable[..., Any],
    namespace: str = "",
    *,
    request: Optional[Request] = None,  # pylint: disable=unused-argument
    response: Optional[Response] = None,   # pylint: disable=unused-argument
    args: Tuple[Any, ...],
    kwargs: Dict[str, Any],
) -> str:
    if kwargs.get('sess'):
        del kwargs["sess"]

    cache_key = hashlib.md5(  # noqa: S324
        f"{func.__module__}:{func.__name__}:{args}:{kwargs}".encode()
    ).hexdigest()

    return f"{namespace}:{cache_key}"
