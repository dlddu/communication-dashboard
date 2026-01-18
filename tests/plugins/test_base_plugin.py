"""Tests for BasePlugin abstract class and related data structures.

This test module follows TDD Red Phase - tests are written before implementation.
All tests should fail initially until the implementation code is written.
"""

from datetime import datetime
from typing import Any

import pytest
from pydantic import ValidationError


def test_base_plugin_cannot_be_instantiated() -> None:
    """Test that BasePlugin is abstract and cannot be instantiated directly."""
    from communication_dashboard.plugins.base import BasePlugin

    with pytest.raises(TypeError, match="Can't instantiate abstract class"):
        BasePlugin()  # type: ignore[abstract]


def test_plugin_must_implement_fetch() -> None:
    """Test that a plugin must implement the fetch method."""
    from communication_dashboard.plugins.base import BasePlugin

    # Create a plugin that doesn't implement fetch
    with pytest.raises(TypeError, match="Can't instantiate abstract class"):

        class IncompletePlugin(BasePlugin):
            """Plugin without fetch implementation."""

            def validate_config(self, _config: Any) -> Any:
                return {"valid": True, "errors": []}

        IncompletePlugin()  # type: ignore[abstract]


def test_plugin_must_implement_validate_config() -> None:
    """Test that a plugin must implement the validate_config method."""
    from communication_dashboard.plugins.base import BasePlugin

    # Create a plugin that doesn't implement validate_config
    with pytest.raises(TypeError, match="Can't instantiate abstract class"):

        class IncompletePlugin(BasePlugin):
            """Plugin without validate_config implementation."""

            def fetch(self) -> Any:
                return []

        IncompletePlugin()  # type: ignore[abstract]


def test_plugin_fetch_returns_plugin_data_list() -> None:
    """Test that fetch method returns a list of PluginData objects."""
    from communication_dashboard.plugins.base import BasePlugin, PluginData, ValidationResult

    class ConcretePlugin(BasePlugin):
        """Complete plugin implementation for testing."""

        def fetch(self) -> list[PluginData]:
            return [
                PluginData(
                    id="test-1",
                    source="test-plugin",
                    title="Test Message",
                    content="Test content",
                    timestamp=datetime(2024, 1, 1, 12, 0, 0),
                    metadata={"key": "value"},
                )
            ]

        def validate_config(self, _config: Any) -> ValidationResult:
            return {"valid": True, "errors": []}

    plugin = ConcretePlugin()
    result = plugin.fetch()

    assert isinstance(result, list)
    assert len(result) == 1
    assert isinstance(result[0], PluginData)
    assert result[0].id == "test-1"
    assert result[0].source == "test-plugin"
    assert result[0].title == "Test Message"
    assert result[0].content == "Test content"
    assert result[0].timestamp == datetime(2024, 1, 1, 12, 0, 0)
    assert result[0].metadata == {"key": "value"}
    assert result[0].read is False  # default value


def test_plugin_data_creation() -> None:
    """Test PluginData dataclass creation with all fields."""
    from communication_dashboard.plugins.base import PluginData

    timestamp = datetime(2024, 1, 18, 10, 30, 0)
    metadata = {"author": "test", "priority": "high"}

    data = PluginData(
        id="msg-123",
        source="email",
        title="Test Email",
        content="Email body content",
        timestamp=timestamp,
        metadata=metadata,
        read=True,
    )

    assert data.id == "msg-123"
    assert data.source == "email"
    assert data.title == "Test Email"
    assert data.content == "Email body content"
    assert data.timestamp == timestamp
    assert data.metadata == metadata
    assert data.read is True


def test_plugin_data_default_read_value() -> None:
    """Test that PluginData.read defaults to False."""
    from communication_dashboard.plugins.base import PluginData

    data = PluginData(
        id="msg-456",
        source="slack",
        title="Slack Message",
        content="Message content",
        timestamp=datetime.now(),
        metadata={},
    )

    assert data.read is False


def test_plugin_config_validation() -> None:
    """Test that invalid PluginConfig raises ValidationError."""
    from communication_dashboard.plugins.base import PluginConfig

    # Valid config
    valid_config = PluginConfig(
        name="test-plugin",
        enabled=True,
        interval_minutes=60,
        credentials={"api_key": "secret"},
        options={"option1": "value1"},
    )

    assert valid_config.name == "test-plugin"
    assert valid_config.enabled is True
    assert valid_config.interval_minutes == 60
    assert valid_config.credentials == {"api_key": "secret"}
    assert valid_config.options == {"option1": "value1"}

    # Invalid config - missing required fields
    with pytest.raises(ValidationError) as exc_info:
        PluginConfig(name="test")  # type: ignore[call-arg]

    errors = exc_info.value.errors()
    error_fields = {error["loc"][0] for error in errors}
    assert "enabled" in error_fields
    assert "interval_minutes" in error_fields


def test_plugin_config_optional_credentials() -> None:
    """Test that PluginConfig.credentials is optional."""
    from communication_dashboard.plugins.base import PluginConfig

    config = PluginConfig(
        name="test-plugin",
        enabled=True,
        interval_minutes=30,
        options={},
    )

    assert config.credentials is None


def test_interval_minutes_boundary() -> None:
    """Test that interval_minutes only accepts values in range 1-1440."""
    from communication_dashboard.plugins.base import PluginConfig

    # Valid boundaries
    config_min = PluginConfig(
        name="test", enabled=True, interval_minutes=1, options={}
    )
    assert config_min.interval_minutes == 1

    config_max = PluginConfig(
        name="test", enabled=True, interval_minutes=1440, options={}
    )
    assert config_max.interval_minutes == 1440

    config_middle = PluginConfig(
        name="test", enabled=True, interval_minutes=60, options={}
    )
    assert config_middle.interval_minutes == 60

    # Invalid - below minimum
    with pytest.raises(ValidationError) as exc_info:
        PluginConfig(name="test", enabled=True, interval_minutes=0, options={})

    assert any(
        "greater than or equal to 1" in str(error["msg"]).lower()
        for error in exc_info.value.errors()
    )

    # Invalid - above maximum
    with pytest.raises(ValidationError) as exc_info:
        PluginConfig(name="test", enabled=True, interval_minutes=1441, options={})

    assert any(
        "less than or equal to 1440" in str(error["msg"]).lower()
        for error in exc_info.value.errors()
    )

    # Invalid - negative value
    with pytest.raises(ValidationError) as exc_info:
        PluginConfig(name="test", enabled=True, interval_minutes=-10, options={})

    assert any(
        "greater than or equal to 1" in str(error["msg"]).lower()
        for error in exc_info.value.errors()
    )


def test_validation_result_structure() -> None:
    """Test ValidationResult TypedDict structure."""
    from communication_dashboard.plugins.base import ValidationResult

    # Valid result
    valid: ValidationResult = {"valid": True, "errors": []}
    assert valid["valid"] is True
    assert valid["errors"] == []

    # Invalid result with errors
    invalid: ValidationResult = {
        "valid": False,
        "errors": ["Missing API key", "Invalid interval"],
    }
    assert invalid["valid"] is False
    assert len(invalid["errors"]) == 2
    assert "Missing API key" in invalid["errors"]


def test_plugin_config_with_empty_options() -> None:
    """Test that PluginConfig.options can be an empty dict."""
    from communication_dashboard.plugins.base import PluginConfig

    config = PluginConfig(
        name="minimal-plugin",
        enabled=False,
        interval_minutes=15,
        options={},
    )

    assert config.options == {}
    assert isinstance(config.options, dict)


def test_plugin_config_with_complex_options() -> None:
    """Test that PluginConfig.options can contain complex nested structures."""
    from communication_dashboard.plugins.base import PluginConfig

    complex_options: dict[str, Any] = {
        "filters": {"priority": ["high", "critical"], "labels": ["bug", "urgent"]},
        "formatting": {"html": True, "markdown": False},
        "limits": {"max_items": 100, "timeout_seconds": 30},
    }

    config = PluginConfig(
        name="complex-plugin",
        enabled=True,
        interval_minutes=120,
        options=complex_options,
    )

    assert config.options == complex_options
    assert config.options["filters"]["priority"] == ["high", "critical"]
    assert config.options["formatting"]["html"] is True
    assert config.options["limits"]["max_items"] == 100


def test_plugin_data_with_empty_metadata() -> None:
    """Test that PluginData.metadata can be an empty dict."""
    from communication_dashboard.plugins.base import PluginData

    data = PluginData(
        id="test-id",
        source="test-source",
        title="Test",
        content="Content",
        timestamp=datetime.now(),
        metadata={},
    )

    assert data.metadata == {}
    assert isinstance(data.metadata, dict)


def test_validation_result_with_multiple_errors() -> None:
    """Test ValidationResult with multiple validation errors."""
    from communication_dashboard.plugins.base import ValidationResult

    result: ValidationResult = {
        "valid": False,
        "errors": [
            "Invalid credentials format",
            "Interval out of range",
            "Missing required option: api_url",
        ],
    }

    assert result["valid"] is False
    assert len(result["errors"]) == 3
    assert all(isinstance(error, str) for error in result["errors"])
