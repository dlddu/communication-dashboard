"""Tests for database operations."""

import json
import sqlite3
from datetime import datetime, timedelta
from uuid import uuid4

from communication_dashboard.db import (
    cleanup_old_records,
    get_latest_data_by_plugin,
    save_plugin_data,
)


def test_save_plugin_data(in_memory_db: sqlite3.Connection) -> None:
    """Test saving plugin data to database.

    Args:
        in_memory_db: In-memory SQLite connection fixture
    """
    plugin_name = "test_plugin"
    test_data = {"key": "value", "count": 42}

    # Save data
    result = save_plugin_data(in_memory_db, plugin_name, test_data)

    # Verify save was successful
    assert result is True

    # Verify data was saved correctly
    cursor = in_memory_db.execute(
        "SELECT plugin_name, data FROM plugin_data WHERE plugin_name = ?",
        (plugin_name,)
    )
    row = cursor.fetchone()
    assert row is not None
    assert row["plugin_name"] == plugin_name

    saved_data = json.loads(row["data"])
    assert saved_data == test_data


def test_get_latest_data_by_plugin(in_memory_db: sqlite3.Connection) -> None:
    """Test retrieving latest data for a specific plugin.

    Args:
        in_memory_db: In-memory SQLite connection fixture
    """
    plugin_name = "test_plugin"

    # Insert multiple records with different timestamps
    older_data = {"version": "1.0"}
    newer_data = {"version": "2.0"}

    # Insert older record
    in_memory_db.execute(
        """
        INSERT INTO plugin_data (id, plugin_name, data, fetched_at)
        VALUES (?, ?, ?, ?)
        """,
        (
            str(uuid4()),
            plugin_name,
            json.dumps(older_data),
            (datetime.now() - timedelta(hours=2)).isoformat()
        )
    )

    # Insert newer record
    in_memory_db.execute(
        """
        INSERT INTO plugin_data (id, plugin_name, data, fetched_at)
        VALUES (?, ?, ?, ?)
        """,
        (
            str(uuid4()),
            plugin_name,
            json.dumps(newer_data),
            datetime.now().isoformat()
        )
    )
    in_memory_db.commit()

    # Retrieve latest data
    latest_data = get_latest_data_by_plugin(in_memory_db, plugin_name)

    # Verify we got the newest record
    assert latest_data is not None
    assert latest_data == newer_data


def test_get_latest_data_by_plugin_no_data(in_memory_db: sqlite3.Connection) -> None:
    """Test retrieving data when plugin has no records.

    Args:
        in_memory_db: In-memory SQLite connection fixture
    """
    result = get_latest_data_by_plugin(in_memory_db, "nonexistent_plugin")
    assert result is None


def test_data_cleanup_old_records(in_memory_db: sqlite3.Connection) -> None:
    """Test automatic cleanup of records older than 7 days.

    Args:
        in_memory_db: In-memory SQLite connection fixture
    """
    plugin_name = "test_plugin"

    # Insert old record (10 days ago)
    old_date = datetime.now() - timedelta(days=10)
    in_memory_db.execute(
        """
        INSERT INTO plugin_data (id, plugin_name, data, fetched_at)
        VALUES (?, ?, ?, ?)
        """,
        (
            str(uuid4()),
            plugin_name,
            json.dumps({"old": True}),
            old_date.isoformat()
        )
    )

    # Insert recent record (2 days ago)
    recent_date = datetime.now() - timedelta(days=2)
    in_memory_db.execute(
        """
        INSERT INTO plugin_data (id, plugin_name, data, fetched_at)
        VALUES (?, ?, ?, ?)
        """,
        (
            str(uuid4()),
            plugin_name,
            json.dumps({"recent": True}),
            recent_date.isoformat()
        )
    )
    in_memory_db.commit()

    # Run cleanup
    deleted_count = cleanup_old_records(in_memory_db, days=7)

    # Verify one record was deleted
    assert deleted_count == 1

    # Verify only recent record remains
    cursor = in_memory_db.execute(
        "SELECT COUNT(*) as count FROM plugin_data WHERE plugin_name = ?",
        (plugin_name,)
    )
    row = cursor.fetchone()
    assert row["count"] == 1

    # Verify the remaining record is the recent one
    latest_data = get_latest_data_by_plugin(in_memory_db, plugin_name)
    assert latest_data is not None
    assert latest_data.get("recent") is True
    assert latest_data.get("old") is None
