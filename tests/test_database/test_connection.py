"""
Tests for database connection management.

This test suite verifies:
- SQLite connection lifecycle
- Table creation and schema management
- Connection context manager behavior
- Error handling for database operations

These tests are written in TDD style (Red Phase) and will fail until implementation is complete.
"""

import sqlite3
from pathlib import Path

import pytest


class TestDatabaseConnection:
    """Test cases for database connection management."""

    def test_create_database_connection(self) -> None:
        """
        Test that a database connection can be created.

        Expected behavior:
        - Should create an in-memory SQLite database
        - Connection should be usable
        - Should return a valid connection object
        """
        from backend.database.connection import DatabaseConnection

        # Act
        db = DatabaseConnection(":memory:")

        # Assert
        assert db is not None
        assert hasattr(db, "get_connection")

    def test_database_connection_context_manager(self) -> None:
        """
        Test that DatabaseConnection works as a context manager.

        Expected behavior:
        - Should support 'with' statement
        - Connection should be active within context
        - Connection should be closed after context
        """
        from backend.database.connection import DatabaseConnection

        # Act & Assert
        with DatabaseConnection(":memory:") as conn:
            assert conn is not None
            # Connection should be usable
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            result = cursor.fetchone()
            assert result == (1,)

    def test_create_tables_on_initialization(self) -> None:
        """
        Test that database tables are created on initialization.

        Expected behavior:
        - Tables should be created automatically
        - plugin_data table should exist with correct schema
        """
        from backend.database.connection import DatabaseConnection

        # Arrange & Act
        db = DatabaseConnection(":memory:")

        # Assert: Verify table exists
        with db.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                "SELECT name FROM sqlite_master WHERE type='table' AND name='plugin_data'"
            )
            result = cursor.fetchone()
            assert result is not None
            assert result[0] == "plugin_data"

    def test_plugin_data_table_schema(self) -> None:
        """
        Test that plugin_data table has the correct schema.

        Expected behavior:
        - Table should have columns: id, source, title, content, timestamp, metadata, read
        - id should be primary key
        - timestamp should be indexed for performance
        """
        from backend.database.connection import DatabaseConnection

        # Arrange & Act
        db = DatabaseConnection(":memory:")

        # Assert: Verify schema
        with db.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("PRAGMA table_info(plugin_data)")
            columns = {row[1]: row[2] for row in cursor.fetchall()}

            # Check required columns exist
            assert "id" in columns
            assert "source" in columns
            assert "title" in columns
            assert "content" in columns
            assert "timestamp" in columns
            assert "metadata" in columns
            assert "read" in columns

            # Verify column types
            assert columns["id"] == "TEXT"
            assert columns["source"] == "TEXT"
            assert columns["timestamp"] in ("TEXT", "DATETIME")
            assert columns["read"] in ("INTEGER", "BOOLEAN")

    def test_database_file_creation(self) -> None:
        """
        Test that database file is created when path is provided.

        Expected behavior:
        - When a file path is provided, database file should be created
        - File should be accessible
        """
        import tempfile

        from backend.database.connection import DatabaseConnection

        # Arrange
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "test.db"

            # Act
            DatabaseConnection(str(db_path))

            # Assert
            assert db_path.exists()
            assert db_path.is_file()

            # Verify it's a valid SQLite database
            conn = sqlite3.connect(str(db_path))
            cursor = conn.cursor()
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
            tables = cursor.fetchall()
            conn.close()

            assert len(tables) > 0

    def test_multiple_connections_to_same_database(self) -> None:
        """
        Test that multiple connections to the same database work correctly.

        Expected behavior:
        - Multiple DatabaseConnection instances should be able to access the same database
        - Data written by one connection should be readable by another
        """
        import tempfile

        from backend.database.connection import DatabaseConnection

        # Arrange
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "shared.db"

            # Act: Create and write with first connection
            db1 = DatabaseConnection(str(db_path))
            with db1.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    """
                    CREATE TABLE IF NOT EXISTS test_table (id INTEGER PRIMARY KEY, value TEXT)
                    """
                )
                cursor.execute("INSERT INTO test_table (value) VALUES (?)", ("test_data",))
                conn.commit()

            # Act: Read with second connection
            db2 = DatabaseConnection(str(db_path))
            with db2.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("SELECT value FROM test_table WHERE id = 1")
                result = cursor.fetchone()

            # Assert
            assert result is not None
            assert result[0] == "test_data"

    def test_connection_error_handling(self) -> None:
        """
        Test error handling for invalid database paths.

        Expected behavior:
        - Invalid paths should raise appropriate exceptions
        - Error messages should be informative
        """
        from backend.database.connection import DatabaseConnection

        # Arrange: Use an invalid path (directory without write permissions)
        invalid_path = "/root/readonly/test.db"

        # Act & Assert
        with pytest.raises((PermissionError, OSError, sqlite3.OperationalError)):
            db = DatabaseConnection(invalid_path)
            with db.get_connection() as conn:
                conn.cursor()
