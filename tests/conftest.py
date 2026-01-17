"""
Pytest configuration and fixtures for communication-dashboard tests.
"""

from datetime import datetime
from typing import Any

import pytest


@pytest.fixture
def sample_plugin_config_data() -> dict[str, Any]:
    """Fixture providing sample plugin configuration data."""
    return {
        "name": "test-plugin",
        "enabled": True,
        "interval_minutes": 60,
        "credentials": {"api_key": "test-key-123"},
        "options": {"feature_x": True, "timeout": 30},
    }


@pytest.fixture
def sample_plugin_data_dict() -> dict[str, Any]:
    """Fixture providing sample plugin data dictionary."""
    return {
        "id": "msg-001",
        "source": "test-source",
        "title": "Test Message",
        "content": "This is test content",
        "timestamp": datetime(2026, 1, 17, 12, 0, 0),
        "metadata": {"priority": "high", "tags": ["test", "sample"]},
        "read": False,
    }
