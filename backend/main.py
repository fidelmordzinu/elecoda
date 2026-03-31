from fastapi import FastAPI, Query, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
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
)
from gemini_service import generate_circuit

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


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
    version="2.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    return {"message": "Elecoda API", "docs": "/docs"}


@app.get("/health")
async def health():
    return {"status": "healthy"}


@app.get("/search", response_model=list[ComponentSearchResult])
async def search_components(
    q: str = Query(..., description="Search query"),
    limit: int = Query(20, ge=1, le=100, description="Maximum results"),
):
    if not q or not q.strip():
        raise HTTPException(status_code=400, detail="Query cannot be empty")

    try:
        pool = await get_pool()
        async with pool.acquire() as conn:
            rows = await conn.fetch(
                """
                SELECT id, mpn, description, category
                FROM components
                WHERE to_tsvector('english', COALESCE(mpn, '') || ' ' || COALESCE(description, '') || ' ' || COALESCE(category, ''))
                      @@ plainto_tsquery('english', $1)
                ORDER BY ts_rank(
                    to_tsvector('english', COALESCE(mpn, '') || ' ' || COALESCE(description, '') || ' ' || COALESCE(category, '')),
                    plainto_tsquery('english', $1)
                ) DESC
                LIMIT $2
                """,
                q,
                limit,
            )

        results = [
            ComponentSearchResult(
                id=row["id"],
                mpn=row["mpn"],
                description=row["description"],
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


@app.get("/component/{component_id}", response_model=Component)
async def get_component(component_id: int):
    try:
        pool = await get_pool()
        async with pool.acquire() as conn:
            row = await conn.fetchrow(
                "SELECT id, mpn, description, datasheet_url, specs, category FROM components WHERE id = $1",
                component_id,
            )

        if not row:
            raise HTTPException(status_code=404, detail="Component not found")

        logger.info(f"Fetched component {component_id}")
        return Component(
            id=row["id"],
            mpn=row["mpn"],
            description=row["description"],
            datasheet_url=row["datasheet_url"],
            specs=row["specs"],
            category=row["category"],
        )
    except HTTPException:
        raise
    except asyncpg.PostgresError as e:
        logger.error(f"Database error fetching component {component_id}: {e}")
        raise HTTPException(status_code=500, detail="Database error")
    except Exception as e:
        logger.error(f"Unexpected error fetching component {component_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")


@app.post("/generate_circuit", response_model=CircuitResponse)
async def generate_circuit_endpoint(request: CircuitRequest):
    if not request.query or not request.query.strip():
        raise HTTPException(status_code=400, detail="Query cannot be empty")

    try:
        result = generate_circuit(
            query=request.query,
            inventory=request.inventory or [],
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
            CircuitConnection(fr=c.get("from", ""), to=c.get("to", ""))
            for c in result.get("connections", [])
        ]

        logger.info(
            f"Generated circuit for query '{request.query}' with {len(components)} components"
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
