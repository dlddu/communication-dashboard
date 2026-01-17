"""CRUD operations for plugin data."""

import json
import sqlite3
from datetime import datetime, timedelta
from typing import Any, cast
from uuid import uuid4


def save_plugin_data(
    conn: sqlite3.Connection,
    plugin_name: str,
    data: dict[str, Any]
) -> bool:
    """Save plugin data to database.

    Args:
        conn: SQLite database connection
        plugin_name: Name of the plugin
        data: Data to save (must be JSON-serializable)

    Returns:
        bool: True if save was successful

    Example:
        >>> with get_db_connection() as conn:
        ...     save_plugin_data(conn, "slack", {"messages": 42})
    """
    try:
        record_id = str(uuid4())
        data_json = json.dumps(data)

        conn.execute(
            """
            INSERT INTO plugin_data (id, plugin_name, data, fetched_at)
            VALUES (?, ?, ?, ?)
            """,
            (record_id, plugin_name, data_json, datetime.now().isoformat())
        )
        conn.commit()
        return True
    except Exception:
        conn.rollback()
        raise


def get_latest_data_by_plugin(
    conn: sqlite3.Connection,
    plugin_name: str
) -> dict[str, Any] | None:
    """Get the latest data for a specific plugin.

    Args:
        conn: SQLite database connection
        plugin_name: Name of the plugin

    Returns:
        dict | None: Latest plugin data, or None if not found

    Example:
        >>> with get_db_connection() as conn:
        ...     data = get_latest_data_by_plugin(conn, "slack")
        ...     print(data)
    """
    cursor = conn.execute(
        """
        SELECT data
        FROM plugin_data
        WHERE plugin_name = ?
        ORDER BY fetched_at DESC
        LIMIT 1
        """,
        (plugin_name,)
    )

    row = cursor.fetchone()
    if row is None:
        return None

    data_str: str = row["data"]
    result: dict[str, Any] = cast(dict[str, Any], json.loads(data_str))
    return result


def cleanup_old_records(conn: sqlite3.Connection, days: int = 7) -> int:
    """Delete records older than specified number of days.

    Args:
        conn: SQLite database connection
        days: Number of days to keep (default: 7)

    Returns:
        int: Number of deleted records

    Example:
        >>> with get_db_connection() as conn:
        ...     deleted = cleanup_old_records(conn, days=7)
        ...     print(f"Deleted {deleted} old records")
    """
    cutoff_date = datetime.now() - timedelta(days=days)

    cursor = conn.execute(
        "DELETE FROM plugin_data WHERE fetched_at < ?",
        (cutoff_date.isoformat(),)
    )
    conn.commit()

    return cursor.rowcount
