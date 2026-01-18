"""
Database connection management for SQLite.

This module provides the DatabaseConnection class that manages SQLite connections
with automatic table creation and context manager support.
"""

import sqlite3
from collections.abc import Generator
from contextlib import contextmanager


class DatabaseConnection:
    """
    Manages SQLite database connections with automatic table initialization.

    This class provides:
    - Automatic creation of plugin_data table with proper schema
    - Context manager support for connection lifecycle
    - Thread-safe connection handling
    - Proper indexing for performance

    Args:
        db_path: Path to SQLite database file or ":memory:" for in-memory database

    Example:
        >>> db = DatabaseConnection(":memory:")
        >>> with db.get_connection() as conn:
        ...     cursor = conn.cursor()
        ...     cursor.execute("SELECT * FROM plugin_data")
    """

    def __init__(self, db_path: str) -> None:
        """
        Initialize database connection and create tables.

        Args:
            db_path: Path to SQLite database file or ":memory:" for in-memory database
        """
        self.db_path = db_path
        self._initialize_database()

    def _initialize_database(self) -> None:
        """
        Create necessary tables and indices if they don't exist.

        Creates:
        - plugin_data table with proper schema
        - Indices on source and timestamp columns for performance
        """
        # Use direct connection instead of get_connection() to avoid circular issues
        conn = sqlite3.connect(self.db_path, check_same_thread=False)
        try:
            cursor = conn.cursor()

            # Create plugin_data table
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS plugin_data (
                    id TEXT PRIMARY KEY,
                    source TEXT NOT NULL,
                    title TEXT NOT NULL,
                    content TEXT NOT NULL,
                    timestamp TEXT NOT NULL,
                    metadata TEXT,
                    read INTEGER DEFAULT 0
                )
                """
            )

            # Create indices for performance
            cursor.execute(
                """
                CREATE INDEX IF NOT EXISTS idx_plugin_data_source
                ON plugin_data(source)
                """
            )

            cursor.execute(
                """
                CREATE INDEX IF NOT EXISTS idx_plugin_data_timestamp
                ON plugin_data(timestamp)
                """
            )

            conn.commit()
        finally:
            conn.close()

    @contextmanager
    def get_connection(self) -> Generator[sqlite3.Connection, None, None]:
        """
        Get a database connection as a context manager.

        Yields:
            sqlite3.Connection: Database connection object

        Example:
            >>> db = DatabaseConnection(":memory:")
            >>> with db.get_connection() as conn:
            ...     cursor = conn.cursor()
            ...     cursor.execute("SELECT 1")
        """
        conn = sqlite3.connect(self.db_path, check_same_thread=False)
        try:
            yield conn
        finally:
            conn.close()

    def __enter__(self) -> sqlite3.Connection:
        """
        Enter context manager and return connection.

        Returns:
            sqlite3.Connection: Database connection object
        """
        self._context_conn = sqlite3.connect(self.db_path, check_same_thread=False)
        return self._context_conn

    def __exit__(self, exc_type: object, exc_val: object, exc_tb: object) -> None:
        """
        Exit context manager and close connection.

        Args:
            exc_type: Exception type if an exception occurred
            exc_val: Exception value if an exception occurred
            exc_tb: Exception traceback if an exception occurred
        """
        if hasattr(self, "_context_conn"):
            self._context_conn.close()
