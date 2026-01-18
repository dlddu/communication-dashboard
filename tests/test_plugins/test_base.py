"""
Tests for base plugin functionality.

This test suite verifies the core plugin system including:
- BasePlugin abstract class behavior
- PluginData dataclass structure
- PluginConfig validation with Pydantic v2
- ValidationResult type

These tests are written in TDD style (Red Phase) and will fail until implementation is complete.
"""

from datetime import datetime

import pytest
from pydantic import ValidationError


class TestBasePlugin:
    """Test cases for BasePlugin abstract class."""

    def test_plugin_must_implement_fetch(self) -> None:
        """
        Test that a plugin class must implement the abstract fetch() method.

        Expected behavior:
        - Attempting to instantiate a plugin that doesn't implement fetch() raises TypeError
        - The error message should indicate that fetch is abstract
        """
        # This will be imported once implemented
        from backend.plugins.base import BasePlugin

        # Arrange: Create a plugin class without implementing fetch
        class IncompletePlugin(BasePlugin):
            pass

        # Act & Assert: Attempting to instantiate should raise TypeError
        with pytest.raises(TypeError) as exc_info:
            IncompletePlugin()

        # Verify the error message mentions the abstract method
        assert "fetch" in str(exc_info.value).lower()

    def test_plugin_fetch_returns_plugin_data_list(self) -> None:
        """
        Test that a properly implemented plugin returns list[PluginData] from fetch().

        Expected behavior:
        - fetch() should return a list
        - All items in the list should be PluginData instances
        """
        from backend.plugins.base import BasePlugin
        from backend.plugins.schemas import PluginConfig, PluginData

        # Arrange: Create a complete plugin implementation
        class TestPlugin(BasePlugin):
            def fetch(self) -> list[PluginData]:
                return [
                    PluginData(
                        id="test-1",
                        source="test-plugin",
                        title="Test Message",
                        content="Test content",
                        timestamp=datetime.now(),
                        metadata={},
                        read=False,
                    )
                ]

        # Act
        config = PluginConfig(name="test-plugin", enabled=True, interval_minutes=60)
        plugin = TestPlugin(config)
        result = plugin.fetch()

        # Assert
        assert isinstance(result, list)
        assert len(result) == 1
        assert isinstance(result[0], PluginData)
        assert result[0].id == "test-1"
        assert result[0].source == "test-plugin"
        assert result[0].read is False


class TestPluginData:
    """Test cases for PluginData dataclass."""

    def test_plugin_data_creation(self) -> None:
        """
        Test that PluginData can be created with all required fields.

        Expected behavior:
        - All fields should be accessible
        - dataclass should work with standard Python dataclass features
        """
        from backend.plugins.schemas import PluginData

        # Arrange & Act
        timestamp = datetime.now()
        data = PluginData(
            id="msg-123",
            source="email",
            title="Important Email",
            content="Email content here",
            timestamp=timestamp,
            metadata={"from": "user@example.com"},
            read=True,
        )

        # Assert
        assert data.id == "msg-123"
        assert data.source == "email"
        assert data.title == "Important Email"
        assert data.content == "Email content here"
        assert data.timestamp == timestamp
        assert data.metadata == {"from": "user@example.com"}
        assert data.read is True

    def test_plugin_data_with_empty_metadata(self) -> None:
        """
        Test that PluginData works with empty metadata.

        Expected behavior:
        - metadata can be an empty dict
        """
        from backend.plugins.schemas import PluginData

        # Arrange & Act
        data = PluginData(
            id="msg-456",
            source="slack",
            title="Slack Message",
            content="Content",
            timestamp=datetime.now(),
            metadata={},
            read=False,
        )

        # Assert
        assert data.metadata == {}


class TestPluginConfig:
    """Test cases for PluginConfig Pydantic model."""

    def test_plugin_config_valid_creation(self) -> None:
        """
        Test that PluginConfig can be created with valid data.

        Expected behavior:
        - All fields should be properly validated and accessible
        - Uses Pydantic v2 features
        """
        from backend.plugins.schemas import PluginConfig

        # Arrange & Act
        config = PluginConfig(
            name="email-plugin",
            enabled=True,
            interval_minutes=30,
            credentials={"api_key": "secret"},
            options={"fetch_unread_only": True},
        )

        # Assert
        assert config.name == "email-plugin"
        assert config.enabled is True
        assert config.interval_minutes == 30
        assert config.credentials == {"api_key": "secret"}
        assert config.options == {"fetch_unread_only": True}

    def test_plugin_config_validation(self) -> None:
        """
        Test that PluginConfig validates data correctly.

        Expected behavior:
        - Invalid data types should raise ValidationError
        - Pydantic v2 ValidationError should be raised
        """
        from backend.plugins.schemas import PluginConfig

        # Act & Assert: Invalid interval_minutes type
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(
                name="test",
                enabled=True,
                interval_minutes="invalid",  # type: ignore
                credentials={},
                options={},
            )

        # Verify it's a Pydantic v2 ValidationError
        assert exc_info.value.error_count() > 0

    def test_interval_minutes_boundary_minimum(self) -> None:
        """
        Test that interval_minutes must be >= 1.

        Expected behavior:
        - interval_minutes < 1 should raise ValidationError
        """
        from backend.plugins.schemas import PluginConfig

        # Act & Assert: Test 0
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(
                name="test",
                enabled=True,
                interval_minutes=0,
                credentials={},
                options={},
            )

        errors = exc_info.value.errors()
        assert any("interval_minutes" in str(e) for e in errors)

        # Act & Assert: Test negative value
        with pytest.raises(ValidationError):
            PluginConfig(
                name="test",
                enabled=True,
                interval_minutes=-5,
                credentials={},
                options={},
            )

    def test_interval_minutes_boundary_maximum(self) -> None:
        """
        Test that interval_minutes must be <= 1440 (24 hours).

        Expected behavior:
        - interval_minutes > 1440 should raise ValidationError
        """
        from backend.plugins.schemas import PluginConfig

        # Act & Assert: Test 1441
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(
                name="test",
                enabled=True,
                interval_minutes=1441,
                credentials={},
                options={},
            )

        errors = exc_info.value.errors()
        assert any("interval_minutes" in str(e) for e in errors)

        # Act & Assert: Test large value
        with pytest.raises(ValidationError):
            PluginConfig(
                name="test",
                enabled=True,
                interval_minutes=10000,
                credentials={},
                options={},
            )

    def test_interval_minutes_valid_boundaries(self) -> None:
        """
        Test that interval_minutes accepts valid boundary values.

        Expected behavior:
        - interval_minutes = 1 should be valid
        - interval_minutes = 1440 should be valid
        """
        from backend.plugins.schemas import PluginConfig

        # Act: Test minimum valid value
        config_min = PluginConfig(
            name="test",
            enabled=True,
            interval_minutes=1,
            credentials={},
            options={},
        )
        assert config_min.interval_minutes == 1

        # Act: Test maximum valid value
        config_max = PluginConfig(
            name="test",
            enabled=True,
            interval_minutes=1440,
            credentials={},
            options={},
        )
        assert config_max.interval_minutes == 1440

    def test_plugin_config_optional_fields(self) -> None:
        """
        Test PluginConfig behavior with optional fields.

        Expected behavior:
        - credentials and options can be empty dicts
        - enabled defaults or requires explicit value
        """
        from backend.plugins.schemas import PluginConfig

        # Arrange & Act
        config = PluginConfig(
            name="minimal-plugin",
            enabled=False,
            interval_minutes=60,
            credentials={},
            options={},
        )

        # Assert
        assert config.credentials == {}
        assert config.options == {}

    def test_plugin_config_uses_pydantic_v2(self) -> None:
        """
        Test that PluginConfig uses Pydantic v2 features.

        Expected behavior:
        - Should use model_config = ConfigDict() approach
        - Should have model_dump() method (v2) not dict() (v1)
        """
        from backend.plugins.schemas import PluginConfig

        # Arrange
        config = PluginConfig(
            name="test",
            enabled=True,
            interval_minutes=30,
            credentials={},
            options={},
        )

        # Act & Assert: v2 should have model_dump()
        assert hasattr(config, "model_dump")
        data = config.model_dump()
        assert isinstance(data, dict)
        assert data["name"] == "test"


class TestValidationResult:
    """Test cases for ValidationResult type."""

    def test_validation_result_type_exists(self) -> None:
        """
        Test that ValidationResult type is defined and can be used.

        Expected behavior:
        - ValidationResult should be importable
        - Should be usable for type hints
        """
        from backend.plugins.schemas import ValidationResult

        # Act & Assert: Just verify it's importable
        # The actual structure will be defined in implementation
        assert ValidationResult is not None


class TestPluginIntegration:
    """Integration tests for plugin system components."""

    def test_plugin_with_config(self) -> None:
        """
        Test that a plugin can work with PluginConfig.

        Expected behavior:
        - Plugin and PluginConfig should work together
        - Demonstrates typical usage pattern
        """
        from backend.plugins.base import BasePlugin
        from backend.plugins.schemas import PluginConfig, PluginData

        # Arrange: Create a configurable plugin
        class ConfigurablePlugin(BasePlugin):
            def __init__(self, config: PluginConfig) -> None:
                self.config = config

            def fetch(self) -> list[PluginData]:
                if not self.config.enabled:
                    return []

                return [
                    PluginData(
                        id=f"{self.config.name}-1",
                        source=self.config.name,
                        title="Test",
                        content="Content",
                        timestamp=datetime.now(),
                        metadata=self.config.options,
                        read=False,
                    )
                ]

        config = PluginConfig(
            name="integration-test",
            enabled=True,
            interval_minutes=15,
            credentials={},
            options={"test": "value"},
        )

        # Act
        plugin = ConfigurablePlugin(config)
        result = plugin.fetch()

        # Assert
        assert len(result) == 1
        assert result[0].source == "integration-test"
        assert result[0].metadata == {"test": "value"}

    def test_disabled_plugin_returns_empty(self) -> None:
        """
        Test plugin behavior when disabled.

        Expected behavior:
        - Disabled plugin should return empty list
        """
        from backend.plugins.base import BasePlugin
        from backend.plugins.schemas import PluginConfig, PluginData

        # Arrange
        class ConfigurablePlugin(BasePlugin):
            def __init__(self, config: PluginConfig) -> None:
                self.config = config

            def fetch(self) -> list[PluginData]:
                if not self.config.enabled:
                    return []
                return [
                    PluginData(
                        id="1",
                        source="test",
                        title="Test",
                        content="Content",
                        timestamp=datetime.now(),
                        metadata={},
                        read=False,
                    )
                ]

        config = PluginConfig(
            name="disabled-plugin",
            enabled=False,
            interval_minutes=30,
            credentials={},
            options={},
        )

        # Act
        plugin = ConfigurablePlugin(config)
        result = plugin.fetch()

        # Assert
        assert result == []
