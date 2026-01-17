"""Tests for database migration."""

import sqlite3
from pathlib import Path

from communication_dashboard.db.connection import close_connection
from communication_dashboard.db.migration import init_db


def test_init_db_creates_table(tmp_path: Path) -> None:
    """Test that init_db creates plugin_data table.

    Args:
        tmp_path: Pytest temporary directory
    """
    db_path = tmp_path / "test_create.db"
    init_db(db_path)
    close_connection()

    conn = sqlite3.connect(str(db_path))
    cursor = conn.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='plugin_data'"
    )
    result = cursor.fetchone()
    assert result is not None
    assert result[0] == "plugin_data"
    conn.close()


def test_init_db_creates_indexes(tmp_path: Path) -> None:
    """Test that init_db creates required indexes.

    Args:
        tmp_path: Pytest temporary directory
    """
    db_path = tmp_path / "test_indexes.db"
    init_db(db_path)
    close_connection()

    conn = sqlite3.connect(str(db_path))

    # Check plugin_name index
    cursor = conn.execute(
        "SELECT name FROM sqlite_master WHERE type='index' AND name='idx_plugin_name'"
    )
    result = cursor.fetchone()
    assert result is not None

    # Check fetched_at index
    cursor = conn.execute(
        "SELECT name FROM sqlite_master WHERE type='index' AND name='idx_fetched_at'"
    )
    result = cursor.fetchone()
    assert result is not None

    conn.close()


def test_init_db_idempotent(tmp_path: Path) -> None:
    """Test that init_db can be called multiple times safely.

    Args:
        tmp_path: Pytest temporary directory
    """
    db_path = tmp_path / "test_idempotent.db"

    # Initialize database twice
    init_db(db_path)
    close_connection()

    init_db(db_path)  # Should not raise exception
    close_connection()

    conn = sqlite3.connect(str(db_path))
    cursor = conn.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='plugin_data'"
    )
    result = cursor.fetchone()
    assert result is not None
    conn.close()


def test_init_db_table_schema(tmp_path: Path) -> None:
    """Test that plugin_data table has correct schema.

    Args:
        tmp_path: Pytest temporary directory
    """
    db_path = tmp_path / "test_schema.db"
    init_db(db_path)
    close_connection()

    conn = sqlite3.connect(str(db_path))
    cursor = conn.execute("PRAGMA table_info(plugin_data)")
    columns = {row[1]: row[2] for row in cursor.fetchall()}

    assert "id" in columns
    assert "plugin_name" in columns
    assert "data" in columns
    assert "fetched_at" in columns

    assert columns["id"] == "TEXT"
    assert columns["plugin_name"] == "TEXT"
    assert columns["data"] == "TEXT"
    assert columns["fetched_at"] == "TIMESTAMP"

    conn.close()
