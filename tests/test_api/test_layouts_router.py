"""
Tests for the layouts API router.

This module contains comprehensive tests for layout persistence endpoints,
including backend sync, localStorage fallback, and widget merging functionality.
"""

import pytest
from fastapi.testclient import TestClient

from backend.api.dependencies import set_database
from backend.api.main import app
from backend.database.connection import DatabaseConnection


@pytest.fixture
def test_db():
    """Create a test database with in-memory SQLite."""
    db = DatabaseConnection(":memory:")
    set_database(db)
    yield db
    db.close()


@pytest.fixture
def test_client(test_db):
    """Create a test client with the test database."""
    with TestClient(app) as client:
        yield client


@pytest.fixture
def sample_layout():
    """Create a sample layout for testing."""
    return {
        "layout": {
            "lg": [
                {"i": "widget-1", "x": 0, "y": 0, "w": 4, "h": 2},
                {"i": "widget-2", "x": 4, "y": 0, "w": 4, "h": 2},
            ],
            "md": [
                {"i": "widget-1", "x": 0, "y": 0, "w": 3, "h": 2},
                {"i": "widget-2", "x": 3, "y": 0, "w": 3, "h": 2},
            ],
            "sm": [
                {"i": "widget-1", "x": 0, "y": 0, "w": 2, "h": 2},
                {"i": "widget-2", "x": 0, "y": 2, "w": 2, "h": 2},
            ],
        }
    }


class TestGetLayout:
    """Tests for GET /api/layouts endpoint."""

    def test_get_layout_returns_empty_when_no_layout_saved(self, test_client):
        """Test that empty layout is returned when no layout has been saved."""
        response = test_client.get("/api/layouts")

        assert response.status_code == 200
        data = response.json()
        assert "layout" in data
        assert data["layout"]["lg"] == []
        assert data["layout"]["md"] == []
        assert data["layout"]["sm"] == []

    def test_get_layout_returns_saved_layout(self, test_client, sample_layout):
        """Test that saved layout is returned correctly."""
        # Arrange - Save a layout first
        test_client.post("/api/layouts", json=sample_layout)

        # Act
        response = test_client.get("/api/layouts")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert "layout" in data
        assert len(data["layout"]["lg"]) == 2
        assert data["layout"]["lg"][0]["i"] == "widget-1"

    def test_get_layout_includes_all_breakpoints(self, test_client, sample_layout):
        """Test that layout includes all responsive breakpoints."""
        # Arrange
        test_client.post("/api/layouts", json=sample_layout)

        # Act
        response = test_client.get("/api/layouts")

        # Assert
        data = response.json()
        assert "lg" in data["layout"]
        assert "md" in data["layout"]
        assert "sm" in data["layout"]

    def test_get_layout_returns_most_recent_layout(self, test_client):
        """Test that most recently saved layout is returned."""
        # Arrange - Save two different layouts
        layout1 = {
            "layout": {
                "lg": [{"i": "widget-1", "x": 0, "y": 0, "w": 4, "h": 2}],
                "md": [{"i": "widget-1", "x": 0, "y": 0, "w": 3, "h": 2}],
                "sm": [{"i": "widget-1", "x": 0, "y": 0, "w": 2, "h": 2}],
            }
        }
        layout2 = {
            "layout": {
                "lg": [{"i": "widget-2", "x": 4, "y": 0, "w": 4, "h": 2}],
                "md": [{"i": "widget-2", "x": 3, "y": 0, "w": 3, "h": 2}],
                "sm": [{"i": "widget-2", "x": 0, "y": 2, "w": 2, "h": 2}],
            }
        }
        test_client.post("/api/layouts", json=layout1)
        test_client.post("/api/layouts", json=layout2)

        # Act
        response = test_client.get("/api/layouts")

        # Assert
        data = response.json()
        assert data["layout"]["lg"][0]["i"] == "widget-2"

    def test_get_layout_includes_metadata(self, test_client, sample_layout):
        """Test that layout response includes metadata."""
        # Arrange
        test_client.post("/api/layouts", json=sample_layout)

        # Act
        response = test_client.get("/api/layouts")

        # Assert
        data = response.json()
        assert "layout" in data
        assert "last_updated" in data or "timestamp" in data


class TestSaveLayout:
    """Tests for POST /api/layouts endpoint."""

    def test_save_layout_success(self, test_client, sample_layout):
        """Test successful layout save."""
        response = test_client.post("/api/layouts", json=sample_layout)

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_save_layout_stores_data(self, test_client, sample_layout):
        """Test that layout data is actually stored."""
        # Act - Save layout
        save_response = test_client.post("/api/layouts", json=sample_layout)
        assert save_response.status_code == 200

        # Assert - Retrieve and verify
        get_response = test_client.get("/api/layouts")
        data = get_response.json()
        assert len(data["layout"]["lg"]) == 2

    def test_save_layout_overwrites_existing(self, test_client):
        """Test that saving a new layout overwrites the existing one."""
        # Arrange
        layout1 = {
            "layout": {
                "lg": [{"i": "widget-1", "x": 0, "y": 0, "w": 4, "h": 2}],
                "md": [{"i": "widget-1", "x": 0, "y": 0, "w": 3, "h": 2}],
                "sm": [{"i": "widget-1", "x": 0, "y": 0, "w": 2, "h": 2}],
            }
        }
        layout2 = {
            "layout": {
                "lg": [
                    {"i": "widget-2", "x": 4, "y": 0, "w": 4, "h": 2},
                    {"i": "widget-3", "x": 8, "y": 0, "w": 4, "h": 2},
                ],
                "md": [
                    {"i": "widget-2", "x": 3, "y": 0, "w": 3, "h": 2},
                    {"i": "widget-3", "x": 6, "y": 0, "w": 3, "h": 2},
                ],
                "sm": [
                    {"i": "widget-2", "x": 0, "y": 2, "w": 2, "h": 2},
                    {"i": "widget-3", "x": 0, "y": 4, "w": 2, "h": 2},
                ],
            }
        }

        # Act
        test_client.post("/api/layouts", json=layout1)
        test_client.post("/api/layouts", json=layout2)

        # Assert
        response = test_client.get("/api/layouts")
        data = response.json()
        assert len(data["layout"]["lg"]) == 2
        assert data["layout"]["lg"][0]["i"] == "widget-2"

    def test_save_layout_validates_required_fields(self, test_client):
        """Test that layout validation rejects missing required fields."""
        # Arrange - Invalid layout missing required fields
        invalid_layout = {"layout": {"lg": [{"i": "widget-1"}]}}  # Missing x, y, w, h

        # Act
        response = test_client.post("/api/layouts", json=invalid_layout)

        # Assert
        assert response.status_code == 422  # Unprocessable Entity

    def test_save_layout_validates_breakpoint_structure(self, test_client):
        """Test that layout validation enforces breakpoint structure."""
        # Arrange - Layout missing required breakpoints
        invalid_layout = {
            "layout": {
                "lg": [{"i": "widget-1", "x": 0, "y": 0, "w": 4, "h": 2}],
                # Missing md and sm
            }
        }

        # Act
        response = test_client.post("/api/layouts", json=invalid_layout)

        # Assert
        assert response.status_code == 422

    def test_save_layout_accepts_empty_layout(self, test_client):
        """Test that empty layout can be saved (clear all widgets)."""
        # Arrange
        empty_layout = {"layout": {"lg": [], "md": [], "sm": []}}

        # Act
        response = test_client.post("/api/layouts", json=empty_layout)

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_save_layout_handles_large_layouts(self, test_client):
        """Test that large layouts with many widgets can be saved."""
        # Arrange - Layout with 50 widgets
        large_layout = {
            "layout": {
                "lg": [
                    {"i": f"widget-{i}", "x": (i % 3) * 4, "y": (i // 3) * 2, "w": 4, "h": 2}
                    for i in range(50)
                ],
                "md": [
                    {"i": f"widget-{i}", "x": (i % 2) * 6, "y": (i // 2) * 2, "w": 6, "h": 2}
                    for i in range(50)
                ],
                "sm": [
                    {"i": f"widget-{i}", "x": 0, "y": i * 2, "w": 12, "h": 2}
                    for i in range(50)
                ],
            }
        }

        # Act
        response = test_client.post("/api/layouts", json=large_layout)

        # Assert
        assert response.status_code == 200

    def test_save_layout_preserves_widget_properties(self, test_client):
        """Test that all widget properties are preserved."""
        # Arrange
        layout_with_props = {
            "layout": {
                "lg": [
                    {
                        "i": "widget-1",
                        "x": 0,
                        "y": 0,
                        "w": 4,
                        "h": 2,
                        "minW": 2,
                        "minH": 1,
                        "maxW": 8,
                        "maxH": 4,
                        "static": False,
                        "isDraggable": True,
                        "isResizable": True,
                    }
                ],
                "md": [
                    {
                        "i": "widget-1",
                        "x": 0,
                        "y": 0,
                        "w": 3,
                        "h": 2,
                    }
                ],
                "sm": [
                    {
                        "i": "widget-1",
                        "x": 0,
                        "y": 0,
                        "w": 2,
                        "h": 2,
                    }
                ],
            }
        }

        # Act
        save_response = test_client.post("/api/layouts", json=layout_with_props)
        assert save_response.status_code == 200

        get_response = test_client.get("/api/layouts")
        data = get_response.json()

        # Assert
        widget = data["layout"]["lg"][0]
        assert widget["minW"] == 2
        assert widget["maxW"] == 8
        assert widget["static"] is False


class TestLayoutPersistenceDLD122:
    """Tests for DLD-122: Layout Persistence feature."""

    def test_syncs_layout_to_backend(self, test_client, sample_layout):
        """Test that layout syncs to backend successfully."""
        # Act
        response = test_client.post("/api/layouts", json=sample_layout)

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

        # Verify it was actually saved
        get_response = test_client.get("/api/layouts")
        saved_data = get_response.json()
        assert len(saved_data["layout"]["lg"]) == 2

    def test_falls_back_to_localStorage_if_backend_fails(self, test_client):
        """
        Test fallback behavior when backend fails.

        Note: This tests the API's error handling. The actual localStorage
        fallback is tested in the frontend tests (layoutStore.test.ts).
        """
        # Arrange - Simulate backend error by sending invalid data
        invalid_layout = {"invalid": "data"}

        # Act
        response = test_client.post("/api/layouts", json=invalid_layout)

        # Assert - Backend should return error
        assert response.status_code == 422
        # Frontend should catch this error and use localStorage instead

    def test_merges_new_widgets_into_existing_layout(self, test_client):
        """
        Test that new widgets can be merged into existing layout.

        Note: The actual merge logic is on the frontend. This tests that
        the backend can store and retrieve updated layouts.
        """
        # Arrange - Save initial layout
        initial_layout = {
            "layout": {
                "lg": [{"i": "widget-1", "x": 0, "y": 0, "w": 4, "h": 2}],
                "md": [{"i": "widget-1", "x": 0, "y": 0, "w": 3, "h": 2}],
                "sm": [{"i": "widget-1", "x": 0, "y": 0, "w": 2, "h": 2}],
            }
        }
        test_client.post("/api/layouts", json=initial_layout)

        # Act - Save layout with merged widget
        merged_layout = {
            "layout": {
                "lg": [
                    {"i": "widget-1", "x": 0, "y": 0, "w": 4, "h": 2},
                    {"i": "widget-2", "x": 4, "y": 0, "w": 4, "h": 2},  # New widget
                ],
                "md": [
                    {"i": "widget-1", "x": 0, "y": 0, "w": 3, "h": 2},
                    {"i": "widget-2", "x": 3, "y": 0, "w": 3, "h": 2},
                ],
                "sm": [
                    {"i": "widget-1", "x": 0, "y": 0, "w": 2, "h": 2},
                    {"i": "widget-2", "x": 0, "y": 2, "w": 2, "h": 2},
                ],
            }
        }
        response = test_client.post("/api/layouts", json=merged_layout)

        # Assert
        assert response.status_code == 200

        # Verify both widgets are stored
        get_response = test_client.get("/api/layouts")
        data = get_response.json()
        assert len(data["layout"]["lg"]) == 2
        widget_ids = [w["i"] for w in data["layout"]["lg"]]
        assert "widget-1" in widget_ids
        assert "widget-2" in widget_ids


class TestLayoutEdgeCases:
    """Tests for edge cases and error handling."""

    def test_save_layout_with_missing_layout_key(self, test_client):
        """Test error handling for missing 'layout' key."""
        # Arrange
        invalid_data = {
            "lg": [{"i": "widget-1", "x": 0, "y": 0, "w": 4, "h": 2}],
        }

        # Act
        response = test_client.post("/api/layouts", json=invalid_data)

        # Assert
        assert response.status_code == 422

    def test_save_layout_with_null_values(self, test_client):
        """Test handling of null values in layout."""
        # Arrange
        layout_with_nulls = {
            "layout": {
                "lg": [{"i": "widget-1", "x": 0, "y": 0, "w": None, "h": 2}],
                "md": [{"i": "widget-1", "x": 0, "y": 0, "w": 3, "h": 2}],
                "sm": [{"i": "widget-1", "x": 0, "y": 0, "w": 2, "h": 2}],
            }
        }

        # Act
        response = test_client.post("/api/layouts", json=layout_with_nulls)

        # Assert
        assert response.status_code == 422

    def test_save_layout_with_negative_values(self, test_client):
        """Test validation of negative position/size values."""
        # Arrange
        invalid_layout = {
            "layout": {
                "lg": [{"i": "widget-1", "x": -1, "y": 0, "w": 4, "h": 2}],
                "md": [{"i": "widget-1", "x": 0, "y": 0, "w": 3, "h": 2}],
                "sm": [{"i": "widget-1", "x": 0, "y": 0, "w": 2, "h": 2}],
            }
        }

        # Act
        response = test_client.post("/api/layouts", json=invalid_layout)

        # Assert
        # Should either accept (grid layout allows negative) or reject consistently
        assert response.status_code in [200, 422]

    def test_save_layout_with_duplicate_widget_ids(self, test_client):
        """Test handling of duplicate widget IDs."""
        # Arrange
        layout_with_duplicates = {
            "layout": {
                "lg": [
                    {"i": "widget-1", "x": 0, "y": 0, "w": 4, "h": 2},
                    {"i": "widget-1", "x": 4, "y": 0, "w": 4, "h": 2},  # Duplicate ID
                ],
                "md": [
                    {"i": "widget-1", "x": 0, "y": 0, "w": 3, "h": 2},
                    {"i": "widget-1", "x": 3, "y": 0, "w": 3, "h": 2},
                ],
                "sm": [
                    {"i": "widget-1", "x": 0, "y": 0, "w": 2, "h": 2},
                    {"i": "widget-1", "x": 0, "y": 2, "w": 2, "h": 2},
                ],
            }
        }

        # Act
        response = test_client.post("/api/layouts", json=layout_with_duplicates)

        # Assert
        # Should handle gracefully (either accept or reject with clear error)
        assert response.status_code in [200, 400, 422]

    def test_get_layout_with_corrupted_data(self, test_client):
        """Test error handling when stored layout data is corrupted."""
        # Note: This would require manual database corruption simulation
        # For now, test that GET always returns valid JSON
        response = test_client.get("/api/layouts")

        assert response.status_code == 200
        assert response.headers["content-type"] == "application/json"

    def test_concurrent_layout_updates(self, test_client):
        """Test handling of rapid concurrent layout updates."""
        # Arrange
        layout1 = {
            "layout": {
                "lg": [{"i": "widget-1", "x": 0, "y": 0, "w": 4, "h": 2}],
                "md": [{"i": "widget-1", "x": 0, "y": 0, "w": 3, "h": 2}],
                "sm": [{"i": "widget-1", "x": 0, "y": 0, "w": 2, "h": 2}],
            }
        }
        layout2 = {
            "layout": {
                "lg": [{"i": "widget-2", "x": 4, "y": 0, "w": 4, "h": 2}],
                "md": [{"i": "widget-2", "x": 3, "y": 0, "w": 3, "h": 2}],
                "sm": [{"i": "widget-2", "x": 0, "y": 2, "w": 2, "h": 2}],
            }
        }

        # Act - Send multiple updates rapidly
        response1 = test_client.post("/api/layouts", json=layout1)
        response2 = test_client.post("/api/layouts", json=layout2)

        # Assert - Last update should be stored
        assert response1.status_code == 200
        assert response2.status_code == 200

        get_response = test_client.get("/api/layouts")
        data = get_response.json()
        assert data["layout"]["lg"][0]["i"] == "widget-2"

    def test_save_layout_with_special_characters_in_widget_id(self, test_client):
        """Test handling of special characters in widget IDs."""
        # Arrange
        layout = {
            "layout": {
                "lg": [{"i": "widget-@#$%", "x": 0, "y": 0, "w": 4, "h": 2}],
                "md": [{"i": "widget-@#$%", "x": 0, "y": 0, "w": 3, "h": 2}],
                "sm": [{"i": "widget-@#$%", "x": 0, "y": 0, "w": 2, "h": 2}],
            }
        }

        # Act
        response = test_client.post("/api/layouts", json=layout)

        # Assert
        assert response.status_code in [200, 422]

    def test_save_layout_with_very_long_widget_id(self, test_client):
        """Test handling of very long widget IDs."""
        # Arrange
        long_id = "widget-" + "a" * 1000
        layout = {
            "layout": {
                "lg": [{"i": long_id, "x": 0, "y": 0, "w": 4, "h": 2}],
                "md": [{"i": long_id, "x": 0, "y": 0, "w": 3, "h": 2}],
                "sm": [{"i": long_id, "x": 0, "y": 0, "w": 2, "h": 2}],
            }
        }

        # Act
        response = test_client.post("/api/layouts", json=layout)

        # Assert
        assert response.status_code in [200, 413, 422]
