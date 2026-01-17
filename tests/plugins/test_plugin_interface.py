"""Tests for plugin interface - TDD Red Phase.

These tests define the expected behavior of the plugin system:
- BasePlugin ABC with required fetch() method
- PluginData dataclass for plugin output
- PluginConfig Pydantic model with validation
- ValidationResult type for config validation
"""

from datetime import datetime

import pytest
from pydantic import ValidationError

from communication_dashboard.plugins.base import BasePlugin
from communication_dashboard.plugins.schema import (
    PluginConfig,
    PluginData,
    ValidationResult,
)


class TestPluginInterface:
    """Test cases for BasePlugin abstract interface."""

    def test_plugin_must_implement_fetch(self) -> None:
        """fetch 메서드 미구현 시 TypeError 발생.

        BasePlugin is an ABC that requires fetch() to be implemented.
        Attempting to instantiate a subclass without implementing fetch()
        should raise TypeError.
        """

        class IncompletePlugin(BasePlugin):
            """Plugin that does not implement fetch()."""

            def validate_config(self) -> ValidationResult:
                return ValidationResult(valid=True)

        with pytest.raises(TypeError, match="fetch"):
            IncompletePlugin()  # type: ignore[abstract]

    def test_plugin_fetch_returns_plugin_data_list(self) -> None:
        """fetch는 PluginData 리스트 반환.

        A properly implemented plugin's fetch() method should return
        a list of PluginData instances.
        """

        class CompletePlugin(BasePlugin):
            """Plugin that properly implements all required methods."""

            def fetch(self) -> list[PluginData]:
                return [
                    PluginData(
                        id="test-1",
                        source="test-plugin",
                        title="Test Item",
                        content="Test content",
                        timestamp=datetime.now(),
                        metadata={},
                        read=False,
                    )
                ]

            def validate_config(self) -> ValidationResult:
                return ValidationResult(valid=True)

        plugin = CompletePlugin()
        result = plugin.fetch()

        assert isinstance(result, list)
        assert len(result) == 1
        assert isinstance(result[0], PluginData)
        assert result[0].id == "test-1"
        assert result[0].source == "test-plugin"
        assert result[0].read is False


class TestPluginConfig:
    """Test cases for PluginConfig Pydantic model."""

    def test_plugin_config_validation(self) -> None:
        """잘못된 config는 ValidationError 발생.

        PluginConfig should validate that required fields are present
        and have correct types.
        """
        # Valid config should work
        valid_config = PluginConfig(
            name="test-plugin",
            enabled=True,
            interval_minutes=60,
            credentials={},
            options={},
        )
        assert valid_config.name == "test-plugin"
        assert valid_config.enabled is True
        assert valid_config.interval_minutes == 60

        # Missing required field should raise ValidationError
        with pytest.raises(ValidationError):
            PluginConfig(
                enabled=True,
                interval_minutes=60,
            )  # type: ignore[call-arg]

        # Wrong type should raise ValidationError
        with pytest.raises(ValidationError):
            PluginConfig(
                name="test",
                enabled="not-a-bool",  # type: ignore[arg-type]
                interval_minutes=60,
                credentials={},
                options={},
            )

    def test_interval_minutes_boundary(self) -> None:
        """interval은 1-1440 범위만 허용.

        interval_minutes must be between 1 and 1440 (inclusive).
        Values outside this range should raise ValidationError.
        """
        # Boundary: 0 should fail (below minimum)
        with pytest.raises(ValidationError, match="interval_minutes"):
            PluginConfig(
                name="test",
                enabled=True,
                interval_minutes=0,
                credentials={},
                options={},
            )

        # Boundary: 1 should pass (minimum valid value)
        config_min = PluginConfig(
            name="test",
            enabled=True,
            interval_minutes=1,
            credentials={},
            options={},
        )
        assert config_min.interval_minutes == 1

        # Boundary: 1440 should pass (maximum valid value)
        config_max = PluginConfig(
            name="test",
            enabled=True,
            interval_minutes=1440,
            credentials={},
            options={},
        )
        assert config_max.interval_minutes == 1440

        # Boundary: 1441 should fail (above maximum)
        with pytest.raises(ValidationError, match="interval_minutes"):
            PluginConfig(
                name="test",
                enabled=True,
                interval_minutes=1441,
                credentials={},
                options={},
            )


class TestPluginData:
    """Test cases for PluginData dataclass."""

    def test_plugin_data_creation(self) -> None:
        """PluginData should be creatable with all required fields."""
        now = datetime.now()
        data = PluginData(
            id="item-1",
            source="slack",
            title="New message",
            content="Hello world",
            timestamp=now,
            metadata={"channel": "general"},
            read=False,
        )

        assert data.id == "item-1"
        assert data.source == "slack"
        assert data.title == "New message"
        assert data.content == "Hello world"
        assert data.timestamp == now
        assert data.metadata == {"channel": "general"}
        assert data.read is False

    def test_plugin_data_immutable_fields(self) -> None:
        """PluginData fields should have correct types."""
        data = PluginData(
            id="test",
            source="test",
            title="Test",
            content="Content",
            timestamp=datetime.now(),
            metadata={},
            read=True,
        )

        # Verify field types
        assert isinstance(data.id, str)
        assert isinstance(data.source, str)
        assert isinstance(data.title, str)
        assert isinstance(data.content, str)
        assert isinstance(data.timestamp, datetime)
        assert isinstance(data.metadata, dict)
        assert isinstance(data.read, bool)


class TestValidationResult:
    """Test cases for ValidationResult type."""

    def test_validation_result_valid(self) -> None:
        """ValidationResult should indicate valid configuration."""
        result = ValidationResult(valid=True)
        assert result.valid is True
        assert result.errors is None or result.errors == []

    def test_validation_result_invalid(self) -> None:
        """ValidationResult should contain error messages when invalid."""
        result = ValidationResult(valid=False, errors=["Missing API key"])
        assert result.valid is False
        assert result.errors is not None
        assert "Missing API key" in result.errors
