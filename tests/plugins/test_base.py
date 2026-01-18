"""Tests for base plugin interface.

TDD Red Phase - These tests are expected to fail until implementation is complete.
"""

from datetime import datetime, timezone

import pytest
from pydantic import ValidationError


def test_plugin_must_implement_fetch():
    """BasePlugin ABC cannot be instantiated without implementing fetch method.

    This test verifies that BasePlugin is a proper abstract base class
    that requires subclasses to implement the fetch method.
    """
    from communication_dashboard.plugins.base import BasePlugin

    # Arrange & Act & Assert
    # Attempting to instantiate BasePlugin directly should raise TypeError
    with pytest.raises(TypeError, match="Can't instantiate abstract class"):
        BasePlugin()  # type: ignore[abstract]


def test_plugin_fetch_returns_plugin_data_list():
    """fetch method must return a list of PluginData objects.

    This test verifies that a concrete implementation of BasePlugin
    returns the correct type from the fetch method.
    """
    from communication_dashboard.plugins.base import BasePlugin, PluginData

    # Arrange - Create a concrete implementation
    class TestPlugin(BasePlugin):
        def fetch(self) -> list[PluginData]:
            return [
                PluginData(
                    id="test-1",
                    source="test-plugin",
                    title="Test Message",
                    content="This is a test message",
                    timestamp=datetime.now(timezone.utc),
                    metadata={"priority": "high"},
                    read=False,
                )
            ]

    plugin = TestPlugin()

    # Act
    result = plugin.fetch()

    # Assert
    assert isinstance(result, list)
    assert len(result) == 1
    assert isinstance(result[0], PluginData)
    assert result[0].id == "test-1"
    assert result[0].source == "test-plugin"
    assert result[0].title == "Test Message"
    assert result[0].content == "This is a test message"
    assert isinstance(result[0].timestamp, datetime)
    assert result[0].metadata == {"priority": "high"}
    assert result[0].read is False


def test_plugin_config_validation():
    """PluginConfig must validate required fields and types.

    This test verifies that PluginConfig enforces proper validation
    using Pydantic v2.
    """
    from communication_dashboard.plugins.base import PluginConfig

    # Arrange & Act & Assert - Valid configuration
    valid_config = PluginConfig(
        name="test-plugin",
        enabled=True,
        interval_minutes=60,
        credentials={"api_key": "test123"},
        options={"timeout": 30},
    )
    assert valid_config.name == "test-plugin"
    assert valid_config.enabled is True
    assert valid_config.interval_minutes == 60
    assert valid_config.credentials == {"api_key": "test123"}
    assert valid_config.options == {"timeout": 30}

    # Test default values
    minimal_config = PluginConfig(name="minimal", interval_minutes=30)
    assert minimal_config.enabled is True
    assert minimal_config.credentials == {}
    assert minimal_config.options == {}

    # Test missing required field 'name'
    with pytest.raises(ValidationError) as exc_info:
        PluginConfig(interval_minutes=60)  # type: ignore[call-arg]

    errors = exc_info.value.errors()
    assert any(error["loc"] == ("name",) and error["type"] == "missing" for error in errors)

    # Test missing required field 'interval_minutes'
    with pytest.raises(ValidationError) as exc_info:
        PluginConfig(name="test")  # type: ignore[call-arg]

    errors = exc_info.value.errors()
    assert any(
        error["loc"] == ("interval_minutes",) and error["type"] == "missing" for error in errors
    )

    # Test wrong type for 'name'
    with pytest.raises(ValidationError) as exc_info:
        PluginConfig(name=123, interval_minutes=60)  # type: ignore[arg-type]

    errors = exc_info.value.errors()
    assert any(error["loc"] == ("name",) for error in errors)

    # Test wrong type for 'enabled'
    with pytest.raises(ValidationError) as exc_info:
        PluginConfig(name="test", interval_minutes=60, enabled="yes")  # type: ignore[arg-type]

    errors = exc_info.value.errors()
    assert any(error["loc"] == ("enabled",) for error in errors)


def test_interval_minutes_boundary():
    """interval_minutes must be within 1-1440 range (1 minute to 24 hours).

    This test verifies that PluginConfig validates the interval_minutes field
    to ensure it falls within acceptable boundaries.
    """
    from communication_dashboard.plugins.base import PluginConfig

    # Arrange & Act & Assert - Valid boundary values
    # Lower boundary
    config_min = PluginConfig(name="test", interval_minutes=1)
    assert config_min.interval_minutes == 1

    # Middle value
    config_mid = PluginConfig(name="test", interval_minutes=60)
    assert config_mid.interval_minutes == 60

    # Upper boundary
    config_max = PluginConfig(name="test", interval_minutes=1440)
    assert config_max.interval_minutes == 1440

    # Invalid - Below minimum
    with pytest.raises(ValidationError) as exc_info:
        PluginConfig(name="test", interval_minutes=0)

    errors = exc_info.value.errors()
    assert any(
        error["loc"] == ("interval_minutes",) and error["type"] in ("greater_than_equal", "int_ge")
        for error in errors
    )

    # Invalid - Negative value
    with pytest.raises(ValidationError) as exc_info:
        PluginConfig(name="test", interval_minutes=-1)

    errors = exc_info.value.errors()
    assert any(error["loc"] == ("interval_minutes",) for error in errors)

    # Invalid - Above maximum
    with pytest.raises(ValidationError) as exc_info:
        PluginConfig(name="test", interval_minutes=1441)

    errors = exc_info.value.errors()
    assert any(
        error["loc"] == ("interval_minutes",) and error["type"] in ("less_than_equal", "int_le")
        for error in errors
    )

    # Invalid - Far above maximum
    with pytest.raises(ValidationError) as exc_info:
        PluginConfig(name="test", interval_minutes=10000)

    errors = exc_info.value.errors()
    assert any(error["loc"] == ("interval_minutes",) for error in errors)
