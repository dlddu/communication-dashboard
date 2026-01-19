"""
Tests for database CRUD operations.

This test suite verifies:
- Saving PluginData to database
- Retrieving data by plugin source
- Updating read status
- Deleting old records
- Query operations and filtering

These tests are written in TDD style (Red Phase) and will fail until implementation is complete.
"""

from datetime import datetime, timedelta


class TestPluginDataCRUD:
    """Test cases for PluginData CRUD operations."""

    def test_save_plugin_data(self) -> None:
        """
        Test that PluginData can be saved to SQLite database.

        Expected behavior:
        - PluginData should be saved successfully
        - All fields should be persisted correctly
        - Returns saved data or confirmation

        Requirement: test_save_plugin_data (데이터 저장 성공)
        """
        from backend.database.connection import DatabaseConnection
        from backend.database.repository import PluginDataRepository
        from backend.plugins.schemas import PluginData

        # Arrange
        db = DatabaseConnection(":memory:")
        repo = PluginDataRepository(db)

        plugin_data = PluginData(
            id="test-001",
            source="email",
            title="Test Email",
            content="This is a test email content",
            timestamp=datetime.now(),
            metadata={"from": "user@example.com", "priority": "high"},
            read=False,
        )

        # Act
        result = repo.save(plugin_data)

        # Assert
        assert result is not None
        # Verify data was saved by retrieving it
        retrieved = repo.get_by_id("test-001")
        assert retrieved is not None
        assert retrieved.id == "test-001"
        assert retrieved.source == "email"
        assert retrieved.title == "Test Email"
        assert retrieved.content == "This is a test email content"
        assert retrieved.metadata == {"from": "user@example.com", "priority": "high"}
        assert retrieved.read is False

    def test_save_plugin_data_with_empty_metadata(self) -> None:
        """
        Test saving PluginData with empty metadata.

        Expected behavior:
        - Empty metadata should be saved as empty dict or null
        - Should not raise errors
        """
        from backend.database.connection import DatabaseConnection
        from backend.database.repository import PluginDataRepository
        from backend.plugins.schemas import PluginData

        # Arrange
        db = DatabaseConnection(":memory:")
        repo = PluginDataRepository(db)

        plugin_data = PluginData(
            id="test-002",
            source="slack",
            title="Slack Message",
            content="Message content",
            timestamp=datetime.now(),
            metadata={},
            read=False,
        )

        # Act
        repo.save(plugin_data)

        # Assert
        retrieved = repo.get_by_id("test-002")
        assert retrieved is not None
        assert retrieved.metadata == {}

    def test_get_latest_data_by_plugin(self) -> None:
        """
        Test retrieving latest data by plugin source.

        Expected behavior:
        - Should return only data from specified plugin
        - Should be sorted by timestamp (newest first)
        - Should not include data from other plugins

        Requirement: test_get_latest_data_by_plugin (플러그인별 최신 데이터 조회)
        """
        from backend.database.connection import DatabaseConnection
        from backend.database.repository import PluginDataRepository
        from backend.plugins.schemas import PluginData

        # Arrange
        db = DatabaseConnection(":memory:")
        repo = PluginDataRepository(db)

        # Create test data for multiple plugins
        now = datetime.now()
        email_data = [
            PluginData(
                id="email-001",
                source="email",
                title="Email 1",
                content="Content 1",
                timestamp=now - timedelta(hours=2),
                metadata={},
                read=False,
            ),
            PluginData(
                id="email-002",
                source="email",
                title="Email 2",
                content="Content 2",
                timestamp=now - timedelta(hours=1),
                metadata={},
                read=False,
            ),
            PluginData(
                id="email-003",
                source="email",
                title="Email 3",
                content="Content 3",
                timestamp=now,
                metadata={},
                read=False,
            ),
        ]

        slack_data = [
            PluginData(
                id="slack-001",
                source="slack",
                title="Slack 1",
                content="Slack content",
                timestamp=now - timedelta(hours=1),
                metadata={},
                read=False,
            ),
        ]

        # Save all data
        for data in email_data + slack_data:
            repo.save(data)

        # Act: Get latest email data
        email_results = repo.get_latest_by_plugin("email", limit=10)

        # Assert
        assert len(email_results) == 3
        # Should be sorted by timestamp (newest first)
        assert email_results[0].id == "email-003"
        assert email_results[1].id == "email-002"
        assert email_results[2].id == "email-001"
        # Should only contain email data
        for result in email_results:
            assert result.source == "email"

    def test_get_latest_data_by_plugin_with_limit(self) -> None:
        """
        Test retrieving latest data with result limit.

        Expected behavior:
        - Should respect the limit parameter
        - Should return only the newest N records
        """
        from backend.database.connection import DatabaseConnection
        from backend.database.repository import PluginDataRepository
        from backend.plugins.schemas import PluginData

        # Arrange
        db = DatabaseConnection(":memory:")
        repo = PluginDataRepository(db)

        now = datetime.now()
        for i in range(10):
            repo.save(
                PluginData(
                    id=f"test-{i:03d}",
                    source="test-plugin",
                    title=f"Test {i}",
                    content=f"Content {i}",
                    timestamp=now - timedelta(hours=10 - i),
                    metadata={},
                    read=False,
                )
            )

        # Act: Get only 3 latest
        results = repo.get_latest_by_plugin("test-plugin", limit=3)

        # Assert
        assert len(results) == 3
        assert results[0].id == "test-009"
        assert results[1].id == "test-008"
        assert results[2].id == "test-007"

    def test_data_cleanup_old_records(self) -> None:
        """
        Test cleanup of records older than 7 days.

        Expected behavior:
        - Records older than 7 days should be deleted
        - Records within 7 days should be kept
        - Returns count of deleted records

        Requirement: test_data_cleanup_old_records (7일 이상 오래된 데이터 정리)
        """
        from backend.database.connection import DatabaseConnection
        from backend.database.repository import PluginDataRepository
        from backend.plugins.schemas import PluginData

        # Arrange
        db = DatabaseConnection(":memory:")
        repo = PluginDataRepository(db)

        now = datetime.now()

        # Old data (should be deleted)
        old_data = [
            PluginData(
                id="old-001",
                source="email",
                title="Old Email 1",
                content="Content",
                timestamp=now - timedelta(days=8),
                metadata={},
                read=False,
            ),
            PluginData(
                id="old-002",
                source="slack",
                title="Old Slack",
                content="Content",
                timestamp=now - timedelta(days=10),
                metadata={},
                read=False,
            ),
            PluginData(
                id="old-003",
                source="email",
                title="Old Email 2",
                content="Content",
                timestamp=now - timedelta(days=30),
                metadata={},
                read=True,
            ),
        ]

        # Recent data (should be kept)
        recent_data = [
            PluginData(
                id="recent-001",
                source="email",
                title="Recent Email",
                content="Content",
                timestamp=now - timedelta(days=6),
                metadata={},
                read=False,
            ),
            PluginData(
                id="recent-002",
                source="slack",
                title="Recent Slack",
                content="Content",
                timestamp=now - timedelta(days=1),
                metadata={},
                read=False,
            ),
            PluginData(
                id="recent-003",
                source="email",
                title="Very Recent",
                content="Content",
                timestamp=now,
                metadata={},
                read=False,
            ),
        ]

        # Save all data
        for data in old_data + recent_data:
            repo.save(data)

        # Act: Cleanup old records (older than 7 days)
        deleted_count = repo.cleanup_old_records(days=7)

        # Assert
        assert deleted_count == 3  # Should delete 3 old records

        # Verify old records are gone
        assert repo.get_by_id("old-001") is None
        assert repo.get_by_id("old-002") is None
        assert repo.get_by_id("old-003") is None

        # Verify recent records are still there
        assert repo.get_by_id("recent-001") is not None
        assert repo.get_by_id("recent-002") is not None
        assert repo.get_by_id("recent-003") is not None

    def test_get_by_id(self) -> None:
        """
        Test retrieving a single record by ID.

        Expected behavior:
        - Should return PluginData when ID exists
        - Should return None when ID doesn't exist
        """
        from backend.database.connection import DatabaseConnection
        from backend.database.repository import PluginDataRepository
        from backend.plugins.schemas import PluginData

        # Arrange
        db = DatabaseConnection(":memory:")
        repo = PluginDataRepository(db)

        plugin_data = PluginData(
            id="unique-id-123",
            source="email",
            title="Test Email",
            content="Content",
            timestamp=datetime.now(),
            metadata={},
            read=False,
        )
        repo.save(plugin_data)

        # Act & Assert: Existing ID
        result = repo.get_by_id("unique-id-123")
        assert result is not None
        assert result.id == "unique-id-123"
        assert result.title == "Test Email"

        # Act & Assert: Non-existing ID
        result = repo.get_by_id("non-existent-id")
        assert result is None

    def test_mark_as_read(self) -> None:
        """
        Test updating the read status of a PluginData record.

        Expected behavior:
        - Should update read field from False to True
        - Should persist the change in database
        - Should return success confirmation
        """
        from backend.database.connection import DatabaseConnection
        from backend.database.repository import PluginDataRepository
        from backend.plugins.schemas import PluginData

        # Arrange
        db = DatabaseConnection(":memory:")
        repo = PluginDataRepository(db)

        plugin_data = PluginData(
            id="unread-001",
            source="email",
            title="Unread Email",
            content="Content",
            timestamp=datetime.now(),
            metadata={},
            read=False,
        )
        repo.save(plugin_data)

        # Verify initial state
        initial = repo.get_by_id("unread-001")
        assert initial is not None
        assert initial.read is False

        # Act
        success = repo.mark_as_read("unread-001")

        # Assert
        assert success is True

        # Verify updated state
        updated = repo.get_by_id("unread-001")
        assert updated is not None
        assert updated.read is True

    def test_mark_as_read_nonexistent_id(self) -> None:
        """
        Test marking non-existent record as read.

        Expected behavior:
        - Should return False or raise appropriate exception
        - Should not cause database errors
        """
        from backend.database.connection import DatabaseConnection
        from backend.database.repository import PluginDataRepository

        # Arrange
        db = DatabaseConnection(":memory:")
        repo = PluginDataRepository(db)

        # Act
        result = repo.mark_as_read("non-existent-id")

        # Assert
        assert result is False

    def test_get_all_unread(self) -> None:
        """
        Test retrieving all unread records.

        Expected behavior:
        - Should return only records with read=False
        - Should be sorted by timestamp (newest first)
        - Should not include read records
        """
        from backend.database.connection import DatabaseConnection
        from backend.database.repository import PluginDataRepository
        from backend.plugins.schemas import PluginData

        # Arrange
        db = DatabaseConnection(":memory:")
        repo = PluginDataRepository(db)

        now = datetime.now()
        test_data = [
            PluginData(
                id="unread-1",
                source="email",
                title="Unread 1",
                content="Content",
                timestamp=now - timedelta(hours=2),
                metadata={},
                read=False,
            ),
            PluginData(
                id="read-1",
                source="email",
                title="Read 1",
                content="Content",
                timestamp=now - timedelta(hours=1),
                metadata={},
                read=True,
            ),
            PluginData(
                id="unread-2",
                source="slack",
                title="Unread 2",
                content="Content",
                timestamp=now,
                metadata={},
                read=False,
            ),
        ]

        for data in test_data:
            repo.save(data)

        # Act
        unread = repo.get_all_unread()

        # Assert
        assert len(unread) == 2
        assert all(item.read is False for item in unread)
        # Should be sorted by timestamp (newest first)
        assert unread[0].id == "unread-2"
        assert unread[1].id == "unread-1"

    def test_count_by_plugin(self) -> None:
        """
        Test counting records by plugin source.

        Expected behavior:
        - Should return correct count for each plugin
        - Should handle plugins with no data
        """
        from backend.database.connection import DatabaseConnection
        from backend.database.repository import PluginDataRepository
        from backend.plugins.schemas import PluginData

        # Arrange
        db = DatabaseConnection(":memory:")
        repo = PluginDataRepository(db)

        now = datetime.now()
        for i in range(5):
            repo.save(
                PluginData(
                    id=f"email-{i}",
                    source="email",
                    title=f"Email {i}",
                    content="Content",
                    timestamp=now,
                    metadata={},
                    read=False,
                )
            )

        for i in range(3):
            repo.save(
                PluginData(
                    id=f"slack-{i}",
                    source="slack",
                    title=f"Slack {i}",
                    content="Content",
                    timestamp=now,
                    metadata={},
                    read=False,
                )
            )

        # Act
        email_count = repo.count_by_plugin("email")
        slack_count = repo.count_by_plugin("slack")
        nonexistent_count = repo.count_by_plugin("nonexistent")

        # Assert
        assert email_count == 5
        assert slack_count == 3
        assert nonexistent_count == 0

    def test_delete_by_id(self) -> None:
        """
        Test deleting a specific record by ID.

        Expected behavior:
        - Should delete the record with matching ID
        - Should return success confirmation
        - Record should no longer be retrievable
        """
        from backend.database.connection import DatabaseConnection
        from backend.database.repository import PluginDataRepository
        from backend.plugins.schemas import PluginData

        # Arrange
        db = DatabaseConnection(":memory:")
        repo = PluginDataRepository(db)

        plugin_data = PluginData(
            id="to-delete",
            source="email",
            title="To Delete",
            content="Content",
            timestamp=datetime.now(),
            metadata={},
            read=False,
        )
        repo.save(plugin_data)

        # Verify it exists
        assert repo.get_by_id("to-delete") is not None

        # Act
        success = repo.delete_by_id("to-delete")

        # Assert
        assert success is True
        assert repo.get_by_id("to-delete") is None

    def test_save_duplicate_id_updates_record(self) -> None:
        """
        Test that saving with duplicate ID updates the existing record.

        Expected behavior:
        - Second save with same ID should update, not create duplicate
        - Updated fields should be persisted
        - Should not increase total record count
        """
        from backend.database.connection import DatabaseConnection
        from backend.database.repository import PluginDataRepository
        from backend.plugins.schemas import PluginData

        # Arrange
        db = DatabaseConnection(":memory:")
        repo = PluginDataRepository(db)

        now = datetime.now()
        original = PluginData(
            id="duplicate-id",
            source="email",
            title="Original Title",
            content="Original Content",
            timestamp=now,
            metadata={},
            read=False,
        )
        repo.save(original)

        # Act: Save again with same ID but different data
        updated = PluginData(
            id="duplicate-id",
            source="email",
            title="Updated Title",
            content="Updated Content",
            timestamp=now,
            metadata={"updated": True},
            read=True,
        )
        repo.save(updated)

        # Assert
        result = repo.get_by_id("duplicate-id")
        assert result is not None
        assert result.title == "Updated Title"
        assert result.content == "Updated Content"
        assert result.metadata == {"updated": True}
        assert result.read is True

        # Verify only one record exists
        all_data = repo.get_latest_by_plugin("email", limit=100)
        count = sum(1 for item in all_data if item.id == "duplicate-id")
        assert count == 1
