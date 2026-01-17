"""Database connection management."""

import sqlite3
import threading
from collections.abc import Generator
from contextlib import contextmanager
from pathlib import Path

# Thread-local storage for database connections (FastAPI compatibility)
_thread_local = threading.local()

# Default database path
DEFAULT_DB_PATH = Path("data/dashboard.db")


def _get_connection(db_path: Path | str = DEFAULT_DB_PATH) -> sqlite3.Connection:
    """Get or create a thread-local database connection.

    Args:
        db_path: Path to SQLite database file

    Returns:
        sqlite3.Connection: Database connection
    """
    if not hasattr(_thread_local, "connection") or _thread_local.connection is None:
        db_path_obj = Path(db_path) if isinstance(db_path, str) else db_path
        db_path_obj.parent.mkdir(parents=True, exist_ok=True)

        conn: sqlite3.Connection = sqlite3.connect(str(db_path_obj), check_same_thread=False)
        conn.row_factory = sqlite3.Row
        _thread_local.connection = conn

    result: sqlite3.Connection = _thread_local.connection
    return result


@contextmanager
def get_db_connection(
    db_path: Path | str = DEFAULT_DB_PATH
) -> Generator[sqlite3.Connection, None, None]:
    """Context manager for database connections.

    Provides thread-safe database connection management for FastAPI.

    Args:
        db_path: Path to SQLite database file

    Yields:
        sqlite3.Connection: Database connection

    Example:
        >>> with get_db_connection() as conn:
        ...     cursor = conn.execute("SELECT * FROM plugin_data")
    """
    conn = _get_connection(db_path)
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise


def close_connection() -> None:
    """Close the thread-local database connection."""
    if hasattr(_thread_local, "connection") and _thread_local.connection is not None:
        _thread_local.connection.close()
        _thread_local.connection = None
