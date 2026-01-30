"""
Tests for the layout repository.

This module contains comprehensive tests for layout persistence operations.
"""

import pytest

from backend.database.connection import DatabaseConnection


@pytest.fixture
def test_db():
    """Create a test database with in-memory SQLite."""
    db = DatabaseConnection(":memory:")
    yield db
    db.close()


class TestLayoutRepository:
    """Tests for LayoutRepository CRUD operations."""

    def test_save_layout_for_new_user(self, test_db):
        """Test saving layout for a new user."""
        # This test will fail until LayoutRepository is implemented
        from backend.database.repository import LayoutRepository

        repo = LayoutRepository(test_db)
        user_id = "test-user-1"
        layouts = {
            "lg": [{"i": "widget-1", "x": 0, "y": 0, "w": 6, "h": 4}],
            "md": [{"i": "widget-1", "x": 0, "y": 0, "w": 5, "h": 4}],
        }
        timestamp = 1706600000000

        result = repo.save_layout(user_id, layouts, timestamp)

        assert result is not None
        assert result.user_id == user_id
        assert result.layouts == layouts
        assert result.timestamp == timestamp

    def test_save_layout_updates_existing_user(self, test_db):
        """Test that saving layout for existing user updates the record."""
        from backend.database.repository import LayoutRepository

        repo = LayoutRepository(test_db)
        user_id = "test-user-1"

        # Save initial layout
        initial_layouts = {
            "lg": [{"i": "widget-1", "x": 0, "y": 0, "w": 6, "h": 4}],
        }
        initial_timestamp = 1706600000000
        repo.save_layout(user_id, initial_layouts, initial_timestamp)

        # Update layout
        updated_layouts = {
            "lg": [
                {"i": "widget-1", "x": 0, "y": 0, "w": 6, "h": 4},
                {"i": "widget-2", "x": 6, "y": 0, "w": 6, "h": 4},
            ],
        }
        updated_timestamp = 1706600100000
        result = repo.save_layout(user_id, updated_layouts, updated_timestamp)

        assert result.layouts == updated_layouts
        assert result.timestamp == updated_timestamp

    def test_get_layout_by_user_id_success(self, test_db):
        """Test successful retrieval of layout by user ID."""
        from backend.database.repository import LayoutRepository

        repo = LayoutRepository(test_db)
        user_id = "test-user-1"
        layouts = {
            "lg": [{"i": "widget-1", "x": 0, "y": 0, "w": 6, "h": 4}],
        }
        timestamp = 1706600000000

        # Save layout
        repo.save_layout(user_id, layouts, timestamp)

        # Retrieve layout
        result = repo.get_layout(user_id)

        assert result is not None
        assert result.user_id == user_id
        assert result.layouts == layouts
        assert result.timestamp == timestamp

    def test_get_layout_returns_none_for_nonexistent_user(self, test_db):
        """Test that get_layout returns None for user without saved layout."""
        from backend.database.repository import LayoutRepository

        repo = LayoutRepository(test_db)

        result = repo.get_layout("nonexistent-user")

        assert result is None

    def test_save_layout_with_complex_nested_structure(self, test_db):
        """Test saving layout with complex nested widget configurations."""
        from backend.database.repository import LayoutRepository

        repo = LayoutRepository(test_db)
        user_id = "test-user-1"
        layouts = {
            "lg": [
                {
                    "i": "widget-1",
                    "x": 0,
                    "y": 0,
                    "w": 6,
                    "h": 4,
                    "minW": 3,
                    "minH": 2,
                },
                {
                    "i": "widget-2",
                    "x": 6,
                    "y": 0,
                    "w": 6,
                    "h": 4,
                    "static": True,
                },
            ],
            "md": [
                {"i": "widget-1", "x": 0, "y": 0, "w": 5, "h": 4},
                {"i": "widget-2", "x": 5, "y": 0, "w": 5, "h": 4},
            ],
            "sm": [
                {"i": "widget-1", "x": 0, "y": 0, "w": 12, "h": 4},
                {"i": "widget-2", "x": 0, "y": 4, "w": 12, "h": 4},
            ],
        }
        timestamp = 1706600000000

        result = repo.save_layout(user_id, layouts, timestamp)

        assert result is not None
        assert result.layouts == layouts
        # Verify nested structure is preserved
        assert result.layouts["lg"][0]["minW"] == 3
        assert result.layouts["lg"][1]["static"] is True

    def test_save_layout_with_empty_layouts(self, test_db):
        """Test saving layout with empty layouts object."""
        from backend.database.repository import LayoutRepository

        repo = LayoutRepository(test_db)
        user_id = "test-user-1"
        layouts = {}
        timestamp = 1706600000000

        result = repo.save_layout(user_id, layouts, timestamp)

        assert result is not None
        assert result.layouts == {}

    def test_multiple_users_have_separate_layouts(self, test_db):
        """Test that multiple users can have different layouts."""
        from backend.database.repository import LayoutRepository

        repo = LayoutRepository(test_db)

        # Save layout for user 1
        user1_id = "user-1"
        user1_layouts = {"lg": [{"i": "widget-1", "x": 0, "y": 0, "w": 6, "h": 4}]}
        repo.save_layout(user1_id, user1_layouts, 1706600000000)

        # Save layout for user 2
        user2_id = "user-2"
        user2_layouts = {"lg": [{"i": "widget-2", "x": 0, "y": 0, "w": 12, "h": 8}]}
        repo.save_layout(user2_id, user2_layouts, 1706600100000)

        # Retrieve and verify both layouts
        result1 = repo.get_layout(user1_id)
        result2 = repo.get_layout(user2_id)

        assert result1 is not None
        assert result2 is not None
        assert result1.layouts != result2.layouts
        assert result1.layouts["lg"][0]["i"] == "widget-1"
        assert result2.layouts["lg"][0]["i"] == "widget-2"

    def test_save_layout_preserves_timestamp(self, test_db):
        """Test that timestamp is correctly preserved during save."""
        from backend.database.repository import LayoutRepository

        repo = LayoutRepository(test_db)
        user_id = "test-user-1"
        layouts = {"lg": [{"i": "widget-1", "x": 0, "y": 0, "w": 6, "h": 4}]}
        timestamp = 1706612345678  # Specific timestamp with milliseconds

        repo.save_layout(user_id, layouts, timestamp)
        result = repo.get_layout(user_id)

        assert result is not None
        assert result.timestamp == timestamp
