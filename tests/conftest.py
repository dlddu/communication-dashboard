"""Pytest configuration and shared fixtures."""

from datetime import datetime
from typing import Any

import pytest

from communication_dashboard.plugins.base import BasePlugin
from communication_dashboard.plugins.config import ValidationResult
from communication_dashboard.plugins.models import PluginData


class MockValidPlugin(BasePlugin):
    """Mock plugin that properly implements the interface."""

    def fetch(self) -> list[PluginData]:
        """Implement fetch method."""
        return [
            PluginData(
                id="test-1",
                source="mock",
                title="Test Item",
                content="Test content",
                timestamp=datetime.now(),
                metadata={},
                read=False,
            )
        ]

    def validate_config(self) -> ValidationResult:
        """Implement validate_config method."""
        return ValidationResult(success=True, message="Valid", errors=None)


class MockInvalidPlugin(BasePlugin):
    """Mock plugin that doesn't implement required methods (for testing)."""
    pass


@pytest.fixture
def valid_plugin_data() -> PluginData:
    """Provide a valid PluginData instance."""
    return PluginData(
        id="test-id-123",
        source="test-source",
        title="Test Title",
        content="Test content for plugin data",
        timestamp=datetime(2026, 1, 18, 10, 30, 0),
        metadata={"author": "test", "tags": ["test", "example"]},
        read=False,
    )


@pytest.fixture
def valid_plugin_config_data() -> dict[str, Any]:
    """Provide valid configuration data."""
    return {
        "name": "test-plugin",
        "enabled": True,
        "interval_minutes": 60,
        "credentials": {"api_key": "test-key"},
        "options": {"timeout": 30},
    }


@pytest.fixture
def minimal_plugin_config_data() -> dict[str, Any]:
    """Provide minimal valid configuration data."""
    return {
        "name": "minimal-plugin",
    }
