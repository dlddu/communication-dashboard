"""Pytest configuration and fixtures."""
from datetime import datetime
from typing import Any

import pytest

from backend.models.plugin import PluginConfig, PluginData


@pytest.fixture
def valid_plugin_config() -> PluginConfig:
    """Create a valid plugin configuration for testing."""
    return PluginConfig(
        name="test_plugin",
        enabled=True,
        interval_minutes=60,
        credentials={"api_key": "test_key"},
        options={"timeout": 30}
    )


@pytest.fixture
def sample_plugin_data() -> PluginData:
    """Create sample plugin data for testing."""
    return PluginData(
        id="test-123",
        source="test_source",
        title="Test Title",
        content="Test content",
        timestamp=datetime(2026, 1, 18, 12, 0, 0),
        metadata={"author": "Test Author"},
        read=False
    )


@pytest.fixture
def invalid_config_data() -> dict[str, Any]:
    """Create invalid configuration data for testing."""
    return {
        "name": "test_plugin",
        "enabled": True,
        "interval_minutes": 2000,  # Invalid: exceeds 1440
        "credentials": None,
        "options": {}
    }
