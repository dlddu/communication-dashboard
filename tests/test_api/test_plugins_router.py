"""
Tests for the plugins API router.

This module contains comprehensive tests for all plugin-related API endpoints.
"""

from datetime import datetime

import pytest
from fastapi.testclient import TestClient

from backend.api.dependencies import set_database
from backend.api.main import app
from backend.database.connection import DatabaseConnection
from backend.database.repository import PluginDataRepository
from backend.plugins.schemas import PluginData


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
def sample_plugin_data(test_db):
    """Create sample plugin data for testing."""
    repo = PluginDataRepository(test_db)

    data1 = PluginData(
        id="test-001",
        source="email",
        title="Test Email 1",
        content="Email content 1",
        timestamp=datetime(2026, 1, 20, 10, 0, 0),
        metadata={"sender": "test@example.com"},
        read=False,
    )
    data2 = PluginData(
        id="test-002",
        source="email",
        title="Test Email 2",
        content="Email content 2",
        timestamp=datetime(2026, 1, 20, 11, 0, 0),
        metadata={"sender": "test2@example.com"},
        read=True,
    )
    data3 = PluginData(
        id="test-003",
        source="slack",
        title="Test Slack Message",
        content="Slack content",
        timestamp=datetime(2026, 1, 20, 12, 0, 0),
        metadata={"channel": "#general"},
        read=False,
    )

    repo.save(data1)
    repo.save(data2)
    repo.save(data3)

    return [data1, data2, data3]


class TestGetPluginsList:
    """Tests for GET /api/plugins endpoint."""

    def test_get_plugins_list_empty(self, test_client):
        """Test that empty list is returned when no plugins have data."""
        response = test_client.get("/api/plugins")

        assert response.status_code == 200
        assert response.json() == []

    def test_get_plugins_list_with_data(self, test_client, sample_plugin_data):
        """Test that plugin list includes metadata."""
        response = test_client.get("/api/plugins")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2  # email and slack

        # Check email plugin
        email_plugin = next((p for p in data if p["name"] == "email"), None)
        assert email_plugin is not None
        assert email_plugin["count"] == 2
        assert email_plugin["last_updated"] is not None

        # Check slack plugin
        slack_plugin = next((p for p in data if p["name"] == "slack"), None)
        assert slack_plugin is not None
        assert slack_plugin["count"] == 1


class TestGetPluginData:
    """Tests for GET /api/plugins/{name}/data endpoint."""

    def test_get_plugin_data_success(self, test_client, sample_plugin_data):
        """Test successful retrieval of plugin data."""
        response = test_client.get("/api/plugins/email/data")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        assert data[0]["source"] == "email"

    def test_get_plugin_data_with_limit(self, test_client, sample_plugin_data):
        """Test limit parameter restricts results."""
        response = test_client.get("/api/plugins/email/data?limit=1")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1

    def test_get_plugin_data_not_found(self, test_client, test_db):
        """Test 404 for non-existent plugin."""
        response = test_client.get("/api/plugins/nonexistent/data")

        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    def test_get_plugin_data_limit_default_value(self, test_client, sample_plugin_data):
        """Test default limit value is applied."""
        response = test_client.get("/api/plugins/email/data")

        assert response.status_code == 200
        # Default limit is 10, but we only have 2 email items
        data = response.json()
        assert len(data) <= 10


class TestRefreshPlugin:
    """Tests for POST /api/plugins/{name}/refresh endpoint."""

    def test_refresh_plugin_success(self, test_client, sample_plugin_data):
        """Test successful plugin refresh."""
        response = test_client.post("/api/plugins/email/refresh")

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "email" in data["message"]
        assert data["data_count"] is not None

    def test_refresh_plugin_not_found(self, test_client, test_db):
        """Test 404 for non-existent plugin."""
        response = test_client.post("/api/plugins/nonexistent/refresh")

        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()


class TestOpenAPIDocs:
    """Tests for OpenAPI documentation endpoints."""

    def test_openapi_docs_accessible(self, test_client, test_db):
        """Test that /docs endpoint is accessible."""
        response = test_client.get("/docs")

        assert response.status_code == 200

    def test_openapi_json_schema(self, test_client, test_db):
        """Test that OpenAPI JSON schema is valid."""
        response = test_client.get("/openapi.json")

        assert response.status_code == 200
        data = response.json()
        assert "openapi" in data
        assert "paths" in data
        assert "/api/plugins" in data["paths"]
        assert "/api/plugins/{name}/data" in data["paths"]
        assert "/api/plugins/{name}/refresh" in data["paths"]
