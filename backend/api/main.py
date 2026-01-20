"""
FastAPI application initialization and configuration.

This module creates and configures the FastAPI application instance
with middleware, CORS, routers, and database initialization.
"""

from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager
from typing import Optional

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from backend.api.dependencies import set_database
from backend.api.routers import plugins
from backend.database.connection import DatabaseConnection


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """
    Application lifespan manager.

    Handles startup and shutdown events for the application,
    including database initialization and cleanup.

    Args:
        app: FastAPI application instance.

    Yields:
        None during application runtime.
    """
    # Startup: Initialize database only if not already set (e.g., by tests)
    from backend.api.dependencies import _db_instance

    db_created_here = False
    db: Optional[DatabaseConnection] = None
    if _db_instance is None:
        db = DatabaseConnection(":memory:")
        set_database(db)
        db_created_here = True

    yield

    # Shutdown: Close database only if we created it here
    if db_created_here and db is not None:
        db.close()


# Create FastAPI app
app = FastAPI(
    title="Communication Dashboard API",
    description="API for managing communication plugins and their data",
    version="0.1.0",
    lifespan=lifespan,
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(plugins.router)


@app.get("/", tags=["health"])
def root() -> dict[str, str]:
    """
    Root endpoint for health check.

    Returns:
        Simple status message.
    """
    return {"status": "ok", "message": "Communication Dashboard API"}
