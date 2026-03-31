from pydantic import BaseModel
from typing import Optional, List, Any


class Component(BaseModel):
    id: int
    mpn: str
    description: Optional[str] = None
    datasheet_url: Optional[str] = None
    specs: Optional[Any] = None
    category: Optional[str] = None


class ComponentSearchResult(BaseModel):
    id: int
    mpn: str
    description: Optional[str] = None
    category: Optional[str] = None


class CircuitComponent(BaseModel):
    ref: str
    type: str
    value: str
    mpn: Optional[str] = None
    in_inventory: bool = False


class CircuitConnection(BaseModel):
    fr: str
    to: str


class CircuitRequest(BaseModel):
    query: str
    inventory: Optional[List[str]] = []


class CircuitResponse(BaseModel):
    components: List[CircuitComponent]
    connections: List[CircuitConnection]
