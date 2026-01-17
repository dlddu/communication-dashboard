"""Database migration and initialization."""

from pathlib import Path

from communication_dashboard.db.connection import DEFAULT_DB_PATH, get_db_connection


def init_db(db_path: Path | str = DEFAULT_DB_PATH) -> None:
    """Initialize database schema.

    Creates the plugin_data table with appropriate indexes if it doesn't exist.

    Args:
        db_path: Path to SQLite database file

    Example:
        >>> init_db()  # Uses default path
        >>> init_db("custom.db")  # Custom path
    """
    with get_db_connection(db_path) as conn:
        cursor = conn.cursor()

        # Create plugin_data table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS plugin_data (
                id TEXT PRIMARY KEY,
                plugin_name TEXT NOT NULL,
                data TEXT NOT NULL,
                fetched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # Create index on plugin_name for faster queries
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_plugin_name
            ON plugin_data(plugin_name)
        """)

        # Create index on fetched_at for cleanup operations
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_fetched_at
            ON plugin_data(fetched_at)
        """)

        conn.commit()
