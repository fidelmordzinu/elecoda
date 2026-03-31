import asyncpg
import os
import logging
import asyncio
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger(__name__)

_pool = None
_pool_lock = asyncio.Lock()


async def get_pool():
    global _pool
    if _pool is None:
        async with _pool_lock:
            if _pool is None:
                _pool = await _create_pool()
    else:
        if not _pool.is_alive():
            logger.warning("Pool is not alive, recreating...")
            async with _pool_lock:
                if _pool is not None and not _pool.is_alive():
                    try:
                        await _pool.close()
                    except Exception:
                        pass
                    _pool = await _create_pool()
    return _pool


async def _create_pool(retries: int = 3, delay: float = 2.0):
    database_url = os.getenv("DATABASE_URL")
    if not database_url:
        raise ValueError("DATABASE_URL not set in environment")

    for attempt in range(retries):
        try:
            pool = await asyncpg.create_pool(
                dsn=database_url,
                min_size=2,
                max_size=10,
                command_timeout=60,
            )
            logger.info("Database connection pool created")
            return pool
        except Exception as e:
            logger.warning(
                f"Failed to create pool (attempt {attempt + 1}/{retries}): {e}"
            )
            if attempt < retries - 1:
                await asyncio.sleep(delay * (2**attempt))
            else:
                raise


async def close_pool():
    global _pool
    if _pool:
        await _pool.close()
        _pool = None
        logger.info("Database connection pool closed")
