"""
Dependency injection for FastAPI routes.

This module provides dependency functions that can be injected into
FastAPI route handlers to provide database connections and repositories.
"""

from collections.abc import Generator
from typing import Annotated, Optional

from fastapi import Depends

from backend.database.connection import DatabaseConnection
from backend.database.repository import PluginDataRepository

# Global database instance (initialized in main.py)
_db_instance: Optional[DatabaseConnection] = None


def set_database(db: DatabaseConnection) -> None:
    """
    Set the global database instance.

    This should be called during application startup.

    Args:
        db: DatabaseConnection instance to use globally.
    """
    global _db_instance
    _db_instance = db


def get_db() -> Generator[DatabaseConnection, None, None]:
    """
    Get database connection dependency.

    Yields:
        The global database instance.

    Raises:
        RuntimeError: If database has not been initialized.
    """
    if _db_instance is None:
        raise RuntimeError("Database not initialized. Call set_database() during startup.")
    yield _db_instance


def get_repository(
    db: Annotated[DatabaseConnection, Depends(get_db)],
) -> PluginDataRepository:
    """
    Get plugin data repository dependency.

    Args:
        db: DatabaseConnection injected by FastAPI.

    Returns:
        Repository instance for database operations.
    """
    return PluginDataRepository(db)
