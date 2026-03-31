from pydantic import BaseModel, Field
from typing import Optional, List, Any, Annotated
from pydantic import StringConstraints


class Component(BaseModel):
    id: int
    part_number: str
    manufacturer: str
    category: Optional[str] = None
    attributes: Optional[Any] = None


class ComponentSearchResult(BaseModel):
    id: int
    part_number: str
    manufacturer: str
    category: Optional[str] = None


class CategoryDetail(BaseModel):
    ipn: Optional[str] = None
    mpn: Optional[str] = None
    manufacturer: Optional[str] = None
    description: Optional[str] = None
    symbol: Optional[str] = None
    footprint: Optional[str] = None
    datasheet: Optional[str] = None
    extra: Optional[dict] = None


class CircuitComponent(BaseModel):
    ref: str
    type: str
    value: str
    mpn: Optional[str] = None
    in_inventory: bool = False


class CircuitConnection(BaseModel):
    from_: str = Field(alias="from")
    to: str

    model_config = {"populate_by_name": True}


class CircuitRequest(BaseModel):
    query: Annotated[str, StringConstraints(min_length=1, max_length=2000, strip_whitespace=True)]
    inventory: Optional[List[Annotated[str, StringConstraints(max_length=500)]]] = []


class CircuitResponse(BaseModel):
    components: List[CircuitComponent]
    connections: List[CircuitConnection]


class CategoryInfo(BaseModel):
    name: str
    display_name: str
    count: int
    description: Optional[str] = None
