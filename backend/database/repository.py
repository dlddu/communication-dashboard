"""
Repository for PluginData CRUD operations.

This module provides the PluginDataRepository class that handles all database
operations for PluginData objects.
"""

import json
from datetime import datetime, timedelta
from typing import Any, Optional

from backend.database.connection import DatabaseConnection
from backend.plugins.schemas import PluginData


class PluginDataRepository:
    """
    Repository for PluginData CRUD operations.

    This class provides:
    - Save and update operations
    - Query operations with filtering
    - Read status management
    - Automatic cleanup of old records
    - Thread-safe database access

    Args:
        db: DatabaseConnection instance

    Example:
        >>> db = DatabaseConnection(":memory:")
        >>> repo = PluginDataRepository(db)
        >>> data = PluginData(id="1", source="email", title="Test", ...)
        >>> repo.save(data)
    """

    def __init__(self, db: DatabaseConnection) -> None:
        """
        Initialize repository with database connection.

        Args:
            db: DatabaseConnection instance
        """
        self.db = db

    def save(self, data: PluginData) -> None:
        """
        Save or update PluginData in database.

        Uses INSERT OR REPLACE to handle duplicate IDs automatically.

        Args:
            data: PluginData instance to save

        Example:
            >>> repo.save(PluginData(id="1", source="email", ...))
        """
        with self.db.get_connection() as conn:
            cursor = conn.cursor()

            # Serialize metadata to JSON
            metadata_json = json.dumps(data.metadata) if data.metadata else None

            # Convert timestamp to ISO format string
            timestamp_str = data.timestamp.isoformat()

            # Convert boolean to integer for SQLite
            read_int = 1 if data.read else 0

            cursor.execute(
                """
                INSERT OR REPLACE INTO plugin_data
                (id, source, title, content, timestamp, metadata, read)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    data.id,
                    data.source,
                    data.title,
                    data.content,
                    timestamp_str,
                    metadata_json,
                    read_int,
                ),
            )

            conn.commit()

    def get_by_id(self, id: str) -> Optional[PluginData]:
        """
        Retrieve a single PluginData record by ID.

        Args:
            id: Unique identifier of the record

        Returns:
            PluginData instance if found, None otherwise

        Example:
            >>> data = repo.get_by_id("test-001")
            >>> if data:
            ...     print(data.title)
        """
        with self.db.get_connection() as conn:
            cursor = conn.cursor()

            cursor.execute(
                """
                SELECT id, source, title, content, timestamp, metadata, read
                FROM plugin_data
                WHERE id = ?
                """,
                (id,),
            )

            row = cursor.fetchone()

            if row is None:
                return None

            return self._row_to_plugin_data(row)

    def get_latest_by_plugin(self, source: str, limit: int = 10) -> list[PluginData]:
        """
        Get latest records for a specific plugin source.

        Args:
            source: Plugin source name
            limit: Maximum number of records to return (default: 10)

        Returns:
            List of PluginData sorted by timestamp (newest first)

        Example:
            >>> latest = repo.get_latest_by_plugin("email", limit=5)
            >>> for data in latest:
            ...     print(data.title)
        """
        with self.db.get_connection() as conn:
            cursor = conn.cursor()

            cursor.execute(
                """
                SELECT id, source, title, content, timestamp, metadata, read
                FROM plugin_data
                WHERE source = ?
                ORDER BY timestamp DESC
                LIMIT ?
                """,
                (source, limit),
            )

            rows = cursor.fetchall()

            return [self._row_to_plugin_data(row) for row in rows]

    def cleanup_old_records(self, days: int = 7) -> int:
        """
        Delete records older than specified number of days.

        Args:
            days: Number of days to keep (default: 7)

        Returns:
            Number of records deleted

        Example:
            >>> deleted = repo.cleanup_old_records(days=7)
            >>> print(f"Deleted {deleted} old records")
        """
        with self.db.get_connection() as conn:
            cursor = conn.cursor()

            # Calculate cutoff timestamp
            cutoff_time = datetime.now() - timedelta(days=days)
            cutoff_str = cutoff_time.isoformat()

            cursor.execute(
                """
                DELETE FROM plugin_data
                WHERE timestamp < ?
                """,
                (cutoff_str,),
            )

            deleted_count = cursor.rowcount
            conn.commit()

            return deleted_count

    def mark_as_read(self, id: str) -> bool:
        """
        Mark a record as read.

        Args:
            id: Unique identifier of the record

        Returns:
            True if record was updated, False if record not found

        Example:
            >>> success = repo.mark_as_read("test-001")
            >>> if success:
            ...     print("Marked as read")
        """
        with self.db.get_connection() as conn:
            cursor = conn.cursor()

            cursor.execute(
                """
                UPDATE plugin_data
                SET read = 1
                WHERE id = ?
                """,
                (id,),
            )

            updated = cursor.rowcount > 0
            conn.commit()

            return updated

    def get_all_unread(self) -> list[PluginData]:
        """
        Get all unread records.

        Returns:
            List of unread PluginData sorted by timestamp (newest first)

        Example:
            >>> unread = repo.get_all_unread()
            >>> print(f"You have {len(unread)} unread items")
        """
        with self.db.get_connection() as conn:
            cursor = conn.cursor()

            cursor.execute(
                """
                SELECT id, source, title, content, timestamp, metadata, read
                FROM plugin_data
                WHERE read = 0
                ORDER BY timestamp DESC
                """
            )

            rows = cursor.fetchall()

            return [self._row_to_plugin_data(row) for row in rows]

    def count_by_plugin(self, source: str) -> int:
        """
        Count records for a specific plugin source.

        Args:
            source: Plugin source name

        Returns:
            Number of records for the specified source

        Example:
            >>> count = repo.count_by_plugin("email")
            >>> print(f"Email plugin has {count} records")
        """
        with self.db.get_connection() as conn:
            cursor = conn.cursor()

            cursor.execute(
                """
                SELECT COUNT(*)
                FROM plugin_data
                WHERE source = ?
                """,
                (source,),
            )

            result = cursor.fetchone()

            return result[0] if result else 0

    def delete_by_id(self, id: str) -> bool:
        """
        Delete a specific record by ID.

        Args:
            id: Unique identifier of the record

        Returns:
            True if record was deleted, False if record not found

        Example:
            >>> success = repo.delete_by_id("test-001")
            >>> if success:
            ...     print("Record deleted")
        """
        with self.db.get_connection() as conn:
            cursor = conn.cursor()

            cursor.execute(
                """
                DELETE FROM plugin_data
                WHERE id = ?
                """,
                (id,),
            )

            deleted = cursor.rowcount > 0
            conn.commit()

            return deleted

    def _row_to_plugin_data(self, row: tuple[Any, ...]) -> PluginData:
        """
        Convert database row to PluginData instance.

        Args:
            row: Database row tuple

        Returns:
            PluginData instance

        Note:
            This is an internal helper method for deserialization.
        """
        id_val, source, title, content, timestamp_str, metadata_json, read_int = row

        # Parse timestamp from ISO format string
        timestamp = datetime.fromisoformat(timestamp_str)

        # Deserialize metadata from JSON
        metadata: dict[str, Any] = json.loads(metadata_json) if metadata_json else {}

        # Convert integer to boolean
        read = bool(read_int)

        return PluginData(
            id=id_val,
            source=source,
            title=title,
            content=content,
            timestamp=timestamp,
            metadata=metadata,
            read=read,
        )
