"""Pytest configuration and fixtures."""

import sqlite3
from collections.abc import Generator
from contextlib import closing
from pathlib import Path

import pytest


@pytest.fixture
def in_memory_db() -> Generator[sqlite3.Connection, None, None]:
    """Create an in-memory SQLite database for testing.

    Yields:
        sqlite3.Connection: Connection to in-memory database
    """
    conn = sqlite3.connect(":memory:")
    conn.row_factory = sqlite3.Row

    # Initialize database schema
    with closing(conn.cursor()) as cursor:
        cursor.execute("""
            CREATE TABLE plugin_data (
                id TEXT PRIMARY KEY,
                plugin_name TEXT NOT NULL,
                data TEXT NOT NULL,
                fetched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        cursor.execute(
            "CREATE INDEX idx_plugin_name ON plugin_data(plugin_name)"
        )
        cursor.execute(
            "CREATE INDEX idx_fetched_at ON plugin_data(fetched_at)"
        )
        conn.commit()

    yield conn
    conn.close()


@pytest.fixture
def db_path(tmp_path: Path) -> Path:
    """Create a temporary database file path.

    Args:
        tmp_path: Pytest temporary directory

    Returns:
        Path: Path to temporary database file
    """
    return tmp_path / "test.db"
