from fastapi import FastAPI, Query, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from contextlib import asynccontextmanager
from typing import Optional
import logging
import asyncpg

from database import get_pool, close_pool
from models import (
    Component,
    ComponentSearchResult,
    CircuitRequest,
    CircuitResponse,
    CircuitComponent,
    CircuitConnection,
    CategoryDetail,
    CategoryInfo,
)
from gemini_service import generate_circuit

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

limiter = Limiter(key_func=get_remote_address)

CATEGORY_TABLES = {
    "ana": "g-ana",
    "art": "g-art",
    "asy": "g-asy",
    "cap": "g-cap",
    "con": "g-con",
    "cpd": "g-cpd",
    "dio": "g-dio",
    "fan": "g-fan",
    "ics": "g-ics",
    "ind": "g-ind",
    "mcu": "g-mcu",
    "mpu": "g-mpu",
    "opt": "g-opt",
    "osc": "g-osc",
    "pwr": "g-pwr",
    "reg": "g-reg",
    "res": "g-res",
    "rfm": "g-rfm",
    "swi": "g-swi",
    "xtr": "g-xtr",
}

CATEGORY_DISPLAY_NAMES = {
    "ana": "Analog",
    "art": "Artwork",
    "asy": "Assembly",
    "cap": "Capacitors",
    "con": "Connectors",
    "cpd": "Capacitive Devices",
    "dio": "Diodes",
    "fan": "Fans",
    "ics": "ICs",
    "ind": "Inductors",
    "mcu": "MCUs",
    "mpu": "MPUs",
    "opt": "Optoelectronics",
    "osc": "Oscillators",
    "pwr": "Power",
    "reg": "Regulators",
    "res": "Resistors",
    "rfm": "RF Modules",
    "swi": "Switches",
    "xtr": "Transistors",
}


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting up...")
    await get_pool()
    yield
    logger.info("Shutting down...")
    await close_pool()


app = FastAPI(
    title="Elecoda API",
    description="API for electronic component search and AI-generated circuits",
    version="3.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)


@app.exception_handler(RateLimitExceeded)
async def rate_limit_handler(request: Request, exc: RateLimitExceeded):
    raise HTTPException(status_code=429, detail="Too many requests. Please try again later.")


@app.get("/")
async def root():
    return {"message": "Elecoda API", "docs": "/docs"}


@app.get("/health")
async def health():
    status = {"status": "healthy", "database": "unknown"}

    try:
        pool = await get_pool()
        async with pool.acquire() as conn:
            await conn.fetchval("SELECT 1")
        status["database"] = "connected"
    except Exception as e:
        status["database"] = f"error: {str(e)}"
        status["status"] = "degraded"

    return status


@app.get("/categories", response_model=list[CategoryInfo])
async def list_categories():
    try:
        pool = await get_pool()
        async with pool.acquire() as conn:
            rows = await conn.fetch(
                """
                SELECT category, COUNT(*) as count
                FROM all_components
                WHERE category IS NOT NULL
                GROUP BY category
                ORDER BY count DESC
                """
            )

        result = []
        for row in rows:
            cat = row["category"] or ""
            result.append(CategoryInfo(
                name=cat,
                display_name=CATEGORY_DISPLAY_NAMES.get(cat, cat.title()),
                count=row["count"],
            ))
        return result
    except Exception as e:
        logger.error(f"Error listing categories: {e}")
        return []


@app.get("/search", response_model=list[ComponentSearchResult])
async def search_components(
    q: str = Query(..., description="Search query"),
    category: Optional[str] = Query(None, description="Filter by category"),
    limit: int = Query(20, ge=1, le=100, description="Maximum results"),
    offset: int = Query(0, ge=0, description="Number of results to skip"),
):
    if not q or not q.strip():
        raise HTTPException(status_code=400, detail="Query cannot be empty")

    try:
        pool = await get_pool()
        async with pool.acquire() as conn:
            if category:
                rows = await conn.fetch(
                    """
                    SELECT id, part_number, manufacturer, category
                    FROM all_components
                    WHERE LOWER(category) = LOWER($1)
                      AND (
                          part_number ILIKE $4
                          OR manufacturer ILIKE $4
                      )
                    ORDER BY part_number
                    LIMIT $2 OFFSET $3
                    """,
                    category,
                    limit,
                    offset,
                    f"%{q}%",
                )
            else:
                rows = await conn.fetch(
                    """
                    SELECT id, part_number, manufacturer, category
                    FROM all_components
                    WHERE part_number ILIKE $3
                       OR manufacturer ILIKE $3
                       OR category ILIKE $3
                    ORDER BY part_number
                    LIMIT $1 OFFSET $2
                    """,
                    limit,
                    offset,
                    f"%{q}%",
                )

        results = [
            ComponentSearchResult(
                id=row["id"],
                part_number=row["part_number"],
                manufacturer=row["manufacturer"],
                category=row["category"],
            )
            for row in rows
        ]
        logger.info(f"Search for '{q}' returned {len(results)} results")
        return results
    except asyncpg.PostgresError as e:
        logger.error(f"Database error during search: {e}")
        raise HTTPException(status_code=500, detail="Database error")
    except Exception as e:
        logger.error(f"Unexpected error during search: {e}")
        raise HTTPException(status_code=500, detail=f"Search error: {str(e)}")


@app.get("/suggestions")
async def suggestions(
    q: str = Query(..., description="Partial search query"),
    limit: int = Query(5, ge=1, le=20, description="Maximum suggestions"),
):
    if not q or not q.strip():
        return []

    try:
        pool = await get_pool()
        async with pool.acquire() as conn:
            rows = await conn.fetch(
                """
                SELECT DISTINCT part_number, manufacturer, category
                FROM all_components
                WHERE part_number ILIKE $1
                   OR manufacturer ILIKE $1
                ORDER BY part_number
                LIMIT $2
                """,
                f"%{q}%",
                limit,
            )

        return [
            {
                "part_number": row["part_number"],
                "manufacturer": row["manufacturer"],
                "category": row["category"],
            }
            for row in rows
        ]
    except Exception:
        return []


@app.get("/component/{component_id}", response_model=Component)
async def get_component(component_id: int):
    try:
        pool = await get_pool()
        async with pool.acquire() as conn:
            row = await conn.fetchrow(
                "SELECT id, part_number, manufacturer, category, attributes FROM all_components WHERE id = $1",
                component_id,
            )

        if not row:
            raise HTTPException(status_code=404, detail="Component not found")

        return Component(
            id=row["id"],
            part_number=row["part_number"],
            manufacturer=row["manufacturer"],
            category=row["category"],
            attributes=row["attributes"],
        )
    except HTTPException:
        raise
    except asyncpg.PostgresError as e:
        logger.error(f"Database error fetching component {component_id}: {e}")
        raise HTTPException(status_code=500, detail="Database error")
    except Exception as e:
        logger.error(f"Unexpected error fetching component {component_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")


@app.get("/component/{component_id}/details")
async def get_component_details(component_id: int):
    try:
        pool = await get_pool()
        async with pool.acquire() as conn:
            row = await conn.fetchrow(
                "SELECT id, part_number, manufacturer, category, attributes FROM all_components WHERE id = $1",
                component_id,
            )

        if not row:
            raise HTTPException(status_code=404, detail="Component not found")

        category = row["category"]
        table_name = CATEGORY_TABLES.get(category)

        details = CategoryDetail(
            ipn=None,
            mpn=row["part_number"],
            manufacturer=row["manufacturer"],
            description=None,
            symbol=None,
            footprint=None,
            datasheet=None,
        )

        if table_name:
            detail_row = await conn.fetchrow(
                f'SELECT * FROM "{table_name}" WHERE mpn = $1',
                row["part_number"],
            )
            if detail_row:
                extra = {}
                skip = {"ipn", "mpn", "manufacturer", "description", "symbol", "footprint", "datasheet"}
                for key, value in dict(detail_row).items():
                    if key in skip:
                        setattr(details, key, value)
                    elif value is not None:
                        extra[key] = value
                details.extra = extra if extra else None

        if row["attributes"]:
            if details.extra:
                details.extra.update(row["attributes"])
            else:
                details.extra = row["attributes"]

        return details
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching details for component {component_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")


@app.post("/generate_circuit", response_model=CircuitResponse)
@limiter.limit("5/minute")
async def generate_circuit_endpoint(request: Request, body: CircuitRequest):
    if not body.query or not body.query.strip():
        raise HTTPException(status_code=400, detail="Query cannot be empty")

    try:
        result = await generate_circuit(
            query=body.query,
            inventory=body.inventory or [],
        )

        components = [
            CircuitComponent(
                ref=c.get("ref", ""),
                type=c.get("type", ""),
                value=c.get("value", ""),
                mpn=c.get("mpn"),
                in_inventory=c.get("in_inventory", False),
            )
            for c in result.get("components", [])
        ]

        connections = [
            CircuitConnection(**{"from": c.get("from", ""), "to": c.get("to", "")})
            for c in result.get("connections", [])
        ]

        logger.info(
            f"Generated circuit for query '{body.query}' with {len(components)} components"
        )
        return CircuitResponse(components=components, connections=connections)
    except ValueError as e:
        logger.error(f"Invalid Gemini response: {e}")
        raise HTTPException(status_code=502, detail="AI service returned invalid response")
    except Exception as e:
        logger.error(f"Circuit generation error: {e}")
        raise HTTPException(status_code=500, detail=f"Circuit generation error: {str(e)}")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
