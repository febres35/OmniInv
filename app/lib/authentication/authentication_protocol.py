from typing import Protocol, Any


class AuthenticationPrototype(Protocol):
    def login(self, username: str, password: str) -> Any:
        """Authenticate a user with username and password."""
        pass

    def logout(self) -> None:
        """Log out the current user."""
        pass

    def register(self, user_data: dict[str, Any]) -> Any:
        """Register a new user with the provided data."""
        pass
