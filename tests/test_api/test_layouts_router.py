"""
Tests for the layouts API router.

This module contains comprehensive tests for all layout-related API endpoints.
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
def sample_layout_data(test_db):
    """Create sample layout data for testing."""
    from backend.database.repository import LayoutRepository

    repo = LayoutRepository(test_db)

    layouts = {
        "lg": [
            {"i": "widget-1", "x": 0, "y": 0, "w": 6, "h": 4},
            {"i": "widget-2", "x": 6, "y": 0, "w": 6, "h": 4},
        ],
        "md": [
            {"i": "widget-1", "x": 0, "y": 0, "w": 5, "h": 4},
            {"i": "widget-2", "x": 5, "y": 0, "w": 5, "h": 4},
        ],
    }

    repo.save_layout("test-user-1", layouts, 1706600000000)

    return {"user_id": "test-user-1", "layouts": layouts, "timestamp": 1706600000000}


class TestGetLayout:
    """Tests for GET /api/layouts endpoint."""

    def test_get_layout_success(self, test_client, sample_layout_data):
        """Test successful retrieval of user layout."""
        user_id = sample_layout_data["user_id"]
        expected_layouts = sample_layout_data["layouts"]

        response = test_client.get(f"/api/layouts?user_id={user_id}")

        assert response.status_code == 200
        data = response.json()
        assert data == expected_layouts

    def test_get_layout_returns_empty_for_new_user(self, test_client, test_db):
        """Test that empty layout is returned for user without saved layout."""
        response = test_client.get("/api/layouts?user_id=new-user")

        assert response.status_code == 200
        data = response.json()
        assert data == {}

    def test_get_layout_requires_user_id_parameter(self, test_client, test_db):
        """Test that user_id query parameter is required."""
        response = test_client.get("/api/layouts")

        assert response.status_code == 422  # Validation error

    def test_get_layout_with_complex_nested_structure(self, test_client, test_db):
        """Test retrieval of layout with complex nested widget configurations."""
        from backend.database.repository import LayoutRepository

        repo = LayoutRepository(test_db)
        user_id = "test-user-complex"
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
                    "static": False,
                },
            ],
        }
        repo.save_layout(user_id, layouts, 1706600000000)

        response = test_client.get(f"/api/layouts?user_id={user_id}")

        assert response.status_code == 200
        data = response.json()
        assert data == layouts
        assert data["lg"][0]["minW"] == 3
        assert data["lg"][0]["static"] is False


class TestSaveLayout:
    """Tests for POST /api/layouts endpoint."""

    def test_save_layout_for_new_user_success(self, test_client, test_db):
        """Test successful saving of layout for new user."""
        payload = {
            "user_id": "new-user",
            "layouts": {
                "lg": [{"i": "widget-1", "x": 0, "y": 0, "w": 6, "h": 4}],
            },
            "timestamp": 1706600000000,
        }

        response = test_client.post("/api/layouts", json=payload)

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

        # Verify layout was saved by retrieving it
        get_response = test_client.get(f"/api/layouts?user_id={payload['user_id']}")
        assert get_response.status_code == 200
        assert get_response.json() == payload["layouts"]

    def test_save_layout_updates_existing_user(self, test_client, sample_layout_data):
        """Test that saving layout for existing user updates the record."""
        user_id = sample_layout_data["user_id"]
        updated_layouts = {
            "lg": [
                {"i": "widget-1", "x": 0, "y": 0, "w": 6, "h": 4},
                {"i": "widget-2", "x": 6, "y": 0, "w": 6, "h": 4},
                {"i": "widget-3", "x": 0, "y": 4, "w": 12, "h": 4},
            ],
        }
        payload = {
            "user_id": user_id,
            "layouts": updated_layouts,
            "timestamp": 1706600100000,
        }

        response = test_client.post("/api/layouts", json=payload)

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

        # Verify layout was updated
        get_response = test_client.get(f"/api/layouts?user_id={user_id}")
        assert get_response.status_code == 200
        assert get_response.json() == updated_layouts

    def test_save_layout_with_empty_layouts(self, test_client, test_db):
        """Test saving layout with empty layouts object."""
        payload = {
            "user_id": "empty-layout-user",
            "layouts": {},
            "timestamp": 1706600000000,
        }

        response = test_client.post("/api/layouts", json=payload)

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_save_layout_requires_user_id(self, test_client, test_db):
        """Test that user_id is required in request body."""
        payload = {
            "layouts": {"lg": [{"i": "widget-1", "x": 0, "y": 0, "w": 6, "h": 4}]},
            "timestamp": 1706600000000,
        }

        response = test_client.post("/api/layouts", json=payload)

        assert response.status_code == 422  # Validation error

    def test_save_layout_requires_layouts(self, test_client, test_db):
        """Test that layouts is required in request body."""
        payload = {
            "user_id": "test-user",
            "timestamp": 1706600000000,
        }

        response = test_client.post("/api/layouts", json=payload)

        assert response.status_code == 422  # Validation error

    def test_save_layout_requires_timestamp(self, test_client, test_db):
        """Test that timestamp is required in request body."""
        payload = {
            "user_id": "test-user",
            "layouts": {"lg": [{"i": "widget-1", "x": 0, "y": 0, "w": 6, "h": 4}]},
        }

        response = test_client.post("/api/layouts", json=payload)

        assert response.status_code == 422  # Validation error

    def test_save_layout_with_multiple_breakpoints(self, test_client, test_db):
        """Test saving layout with all breakpoint sizes."""
        payload = {
            "user_id": "multi-breakpoint-user",
            "layouts": {
                "lg": [{"i": "widget-1", "x": 0, "y": 0, "w": 6, "h": 4}],
                "md": [{"i": "widget-1", "x": 0, "y": 0, "w": 5, "h": 4}],
                "sm": [{"i": "widget-1", "x": 0, "y": 0, "w": 12, "h": 4}],
                "xs": [{"i": "widget-1", "x": 0, "y": 0, "w": 12, "h": 4}],
                "xxs": [{"i": "widget-1", "x": 0, "y": 0, "w": 12, "h": 4}],
            },
            "timestamp": 1706600000000,
        }

        response = test_client.post("/api/layouts", json=payload)

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

        # Verify all breakpoints were saved
        get_response = test_client.get(f"/api/layouts?user_id={payload['user_id']}")
        assert get_response.status_code == 200
        retrieved = get_response.json()
        assert "lg" in retrieved
        assert "md" in retrieved
        assert "sm" in retrieved
        assert "xs" in retrieved
        assert "xxs" in retrieved

    def test_save_layout_preserves_widget_properties(self, test_client, test_db):
        """Test that all widget properties are preserved during save."""
        payload = {
            "user_id": "properties-test-user",
            "layouts": {
                "lg": [
                    {
                        "i": "widget-1",
                        "x": 0,
                        "y": 0,
                        "w": 6,
                        "h": 4,
                        "minW": 3,
                        "minH": 2,
                        "maxW": 12,
                        "maxH": 8,
                        "static": False,
                        "isDraggable": True,
                        "isResizable": True,
                    },
                ],
            },
            "timestamp": 1706600000000,
        }

        response = test_client.post("/api/layouts", json=payload)

        assert response.status_code == 200

        # Verify all properties were preserved
        get_response = test_client.get(f"/api/layouts?user_id={payload['user_id']}")
        assert get_response.status_code == 200
        retrieved = get_response.json()
        widget = retrieved["lg"][0]
        assert widget["minW"] == 3
        assert widget["minH"] == 2
        assert widget["maxW"] == 12
        assert widget["maxH"] == 8
        assert widget["static"] is False
        assert widget["isDraggable"] is True
        assert widget["isResizable"] is True


class TestLayoutPersistenceIntegration:
    """Integration tests for layout persistence workflow."""

    def test_save_and_retrieve_workflow(self, test_client, test_db):
        """Test complete workflow of saving and retrieving layout."""
        user_id = "workflow-test-user"

        # Step 1: Save initial layout
        initial_payload = {
            "user_id": user_id,
            "layouts": {
                "lg": [{"i": "widget-1", "x": 0, "y": 0, "w": 6, "h": 4}],
            },
            "timestamp": 1706600000000,
        }
        save_response = test_client.post("/api/layouts", json=initial_payload)
        assert save_response.status_code == 200

        # Step 2: Retrieve layout
        get_response = test_client.get(f"/api/layouts?user_id={user_id}")
        assert get_response.status_code == 200
        assert get_response.json() == initial_payload["layouts"]

        # Step 3: Update layout
        updated_payload = {
            "user_id": user_id,
            "layouts": {
                "lg": [
                    {"i": "widget-1", "x": 0, "y": 0, "w": 6, "h": 4},
                    {"i": "widget-2", "x": 6, "y": 0, "w": 6, "h": 4},
                ],
            },
            "timestamp": 1706600100000,
        }
        update_response = test_client.post("/api/layouts", json=updated_payload)
        assert update_response.status_code == 200

        # Step 4: Verify updated layout
        final_get_response = test_client.get(f"/api/layouts?user_id={user_id}")
        assert final_get_response.status_code == 200
        assert final_get_response.json() == updated_payload["layouts"]

    def test_multiple_users_isolated_layouts(self, test_client, test_db):
        """Test that multiple users have isolated layout storage."""
        # Save layout for user 1
        user1_payload = {
            "user_id": "user-1",
            "layouts": {"lg": [{"i": "widget-a", "x": 0, "y": 0, "w": 6, "h": 4}]},
            "timestamp": 1706600000000,
        }
        test_client.post("/api/layouts", json=user1_payload)

        # Save layout for user 2
        user2_payload = {
            "user_id": "user-2",
            "layouts": {"lg": [{"i": "widget-b", "x": 0, "y": 0, "w": 12, "h": 8}]},
            "timestamp": 1706600000000,
        }
        test_client.post("/api/layouts", json=user2_payload)

        # Verify both users have their own layouts
        user1_response = test_client.get("/api/layouts?user_id=user-1")
        user2_response = test_client.get("/api/layouts?user_id=user-2")

        assert user1_response.status_code == 200
        assert user2_response.status_code == 200
        assert user1_response.json() != user2_response.json()
        assert user1_response.json()["lg"][0]["i"] == "widget-a"
        assert user2_response.json()["lg"][0]["i"] == "widget-b"


class TestOpenAPIDocsForLayouts:
    """Tests for OpenAPI documentation of layout endpoints."""

    def test_openapi_json_includes_layout_endpoints(self, test_client, test_db):
        """Test that OpenAPI JSON schema includes layout endpoints."""
        response = test_client.get("/openapi.json")

        assert response.status_code == 200
        data = response.json()
        assert "paths" in data
        assert "/api/layouts" in data["paths"]
        assert "get" in data["paths"]["/api/layouts"]
        assert "post" in data["paths"]["/api/layouts"]
