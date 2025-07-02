from typing import Annotated, Optional, Generic, Self, TypeVar
from pydantic import BaseModel, Field, field_validator, model_validator
from typing_extensions import TypeAliasType

M = TypeVar("M")
D = TypeVar("D")


class PaginatedPerPageResponse(BaseModel, Generic[M]):
    total: int | None = Field(description="Number of total items")
    page: list[M] = Field(description="List of items returned in a paginated response")
    nextPage: Optional[int] = Field(
        None, description="The number of the next page if it exists"
    )
    prevPage: Optional[int] = Field(
        None, description="Ther number of the previous page if it exists"
    )


QueryArray = Annotated[Optional[str], Field()]
query_array = TypeAliasType('query_array', QueryArray)


class PaginatedPerPageRequest(BaseModel):
    page: int = Field(1, ge=1)
    per_page: int = Field(100, gt=0)
    sorting: str | None = None

    @model_validator(mode='after')
    def get_key(self) -> Self:
        for key, value in self.model_fields.items():
            if str(value.annotation) == query_array.__name__:
                query_srr_attr = getattr(self, key)
                if query_srr_attr is None:
                    continue
                setattr(self, key, query_srr_attr.split(','))

        return self


class ExportConfigRequest(BaseModel, Generic[M, D]):
    columns: dict[D, str]
    file_name: str
    sheet_name: str = "Sheet1"
    filters: M

    class Config:
        arbitrary_types_allowed = True

    @field_validator("columns")
    @classmethod
    def check_keys_length(cls, v: dict[D, str]) -> dict[D, str]:
        if len(v.keys()) < 1:
            raise ValueError("Almost one column is required")
        return v


class CustomHeadersSchema(BaseModel):
    timezone: Optional[str] = None
    x_betsol_cached_count: int | None = None
