"""Tests for database connection management."""

from pathlib import Path

from communication_dashboard.db.connection import close_connection, get_db_connection


def test_get_db_connection_with_path(tmp_path: Path) -> None:
    """Test creating database connection with custom path.

    Args:
        tmp_path: Pytest temporary directory
    """
    db_path = tmp_path / "test_simple.db"

    with get_db_connection(db_path) as conn:
        cursor = conn.execute("SELECT 1")
        result = cursor.fetchone()
        assert result is not None
        assert result[0] == 1

    assert db_path.exists()
    close_connection()


def test_get_db_connection_creates_parent_dirs(tmp_path: Path) -> None:
    """Test that parent directories are created if they don't exist.

    Args:
        tmp_path: Pytest temporary directory
    """
    db_path = tmp_path / "nested" / "dir" / "test_nested.db"

    with get_db_connection(db_path) as conn:
        assert conn is not None
        # Execute a query to ensure connection works
        cursor = conn.execute("SELECT 1")
        assert cursor.fetchone() is not None

    # Check parent directory was created
    assert db_path.parent.exists()
    close_connection()


def test_connection_context_manager_commit(tmp_path: Path) -> None:
    """Test that context manager commits changes.

    Args:
        tmp_path: Pytest temporary directory
    """
    db_path = tmp_path / "test_commit.db"

    # Create table and insert data
    with get_db_connection(db_path) as conn:
        conn.execute("CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT)")
        conn.execute("INSERT INTO test (name) VALUES (?)", ("test_name",))

    close_connection()

    # Verify data was committed
    with get_db_connection(db_path) as conn:
        cursor = conn.execute("SELECT name FROM test WHERE id = 1")
        row = cursor.fetchone()
        assert row is not None
        assert row[0] == "test_name"

    close_connection()


def test_connection_context_manager_rollback_on_exception(tmp_path: Path) -> None:
    """Test that context manager rolls back on exception.

    Args:
        tmp_path: Pytest temporary directory
    """
    db_path = tmp_path / "test_rollback.db"

    # Create table
    with get_db_connection(db_path) as conn:
        conn.execute("CREATE TABLE test (id INTEGER PRIMARY KEY)")

    close_connection()

    # Try to insert with exception
    try:
        with get_db_connection(db_path) as conn:
            conn.execute("INSERT INTO test (id) VALUES (?)", (1,))
            raise ValueError("Test exception")  # noqa: TRY301
    except ValueError:
        pass

    close_connection()

    # Verify data was rolled back
    with get_db_connection(db_path) as conn:
        cursor = conn.execute("SELECT COUNT(*) FROM test")
        row = cursor.fetchone()
        assert row[0] == 0

    close_connection()


def test_close_connection(tmp_path: Path) -> None:
    """Test closing connection.

    Args:
        tmp_path: Pytest temporary directory
    """
    db_path = tmp_path / "test_close.db"

    # Create connection
    with get_db_connection(db_path) as conn:
        assert conn is not None

    # Close connection
    close_connection()

    # New connection should be created
    with get_db_connection(db_path) as conn:
        assert conn is not None

    close_connection()
