"""Tests for plugin data models.

This module tests the data models used in the plugin system:
- PluginData: Dataclass for storing communication data
- PluginConfig: Pydantic model for plugin configuration with validation
- ValidationResult: Type for validation results
"""

from datetime import UTC, datetime

import pytest
from pydantic import ValidationError

from communication_dashboard.plugins.models import PluginConfig, PluginData


class TestPluginData:
    """Tests for PluginData dataclass."""

    def test_plugin_data_creation_with_all_fields(self) -> None:
        """PluginData should be created with all required fields."""
        # Arrange
        now = datetime.now(UTC)
        metadata = {"author": "test@example.com", "category": "email"}

        # Act
        data = PluginData(
            id="msg-123",
            source="email",
            title="Test Message",
            content="This is a test message",
            timestamp=now,
            metadata=metadata,
            read=False,
        )

        # Assert
        assert data.id == "msg-123"
        assert data.source == "email"
        assert data.title == "Test Message"
        assert data.content == "This is a test message"
        assert data.timestamp == now
        assert data.metadata == metadata
        assert data.read is False

    def test_plugin_data_default_read_is_false(self) -> None:
        """PluginData.read should default to False."""
        # Arrange & Act
        data = PluginData(
            id="msg-456",
            source="slack",
            title="Slack Message",
            content="Test content",
            timestamp=datetime.now(UTC),
            metadata={},
        )

        # Assert
        assert data.read is False

    def test_plugin_data_metadata_can_be_empty(self) -> None:
        """PluginData.metadata should accept empty dict."""
        # Arrange & Act
        data = PluginData(
            id="msg-789",
            source="teams",
            title="Teams Message",
            content="Content",
            timestamp=datetime.now(UTC),
            metadata={},
        )

        # Assert
        assert data.metadata == {}


class TestPluginConfig:
    """Tests for PluginConfig Pydantic model."""

    def test_plugin_config_valid_configuration(self) -> None:
        """PluginConfig should accept valid configuration."""
        # Arrange & Act
        config = PluginConfig(
            name="email_plugin",
            enabled=True,
            interval_minutes=30,
            credentials={"api_key": "secret123"},
            options={"folder": "inbox"},
        )

        # Assert
        assert config.name == "email_plugin"
        assert config.enabled is True
        assert config.interval_minutes == 30
        assert config.credentials == {"api_key": "secret123"}
        assert config.options == {"folder": "inbox"}

    def test_plugin_config_interval_minimum_boundary(self) -> None:
        """PluginConfig should accept interval_minutes = 1 (minimum)."""
        # Arrange & Act
        config = PluginConfig(
            name="test_plugin",
            enabled=True,
            interval_minutes=1,
            credentials={},
            options={},
        )

        # Assert
        assert config.interval_minutes == 1

    def test_plugin_config_interval_maximum_boundary(self) -> None:
        """PluginConfig should accept interval_minutes = 1440 (maximum)."""
        # Arrange & Act
        config = PluginConfig(
            name="test_plugin",
            enabled=True,
            interval_minutes=1440,
            credentials={},
            options={},
        )

        # Assert
        assert config.interval_minutes == 1440

    def test_plugin_config_interval_below_minimum_raises_error(self) -> None:
        """PluginConfig should raise ValidationError when interval < 1."""
        # Arrange & Act & Assert
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(
                name="test_plugin",
                enabled=True,
                interval_minutes=0,
                credentials={},
                options={},
            )

        # Verify error contains interval validation message
        errors = exc_info.value.errors()
        assert any("interval_minutes" in str(error) for error in errors)

    def test_plugin_config_interval_above_maximum_raises_error(self) -> None:
        """PluginConfig should raise ValidationError when interval > 1440."""
        # Arrange & Act & Assert
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(
                name="test_plugin",
                enabled=True,
                interval_minutes=1441,
                credentials={},
                options={},
            )

        # Verify error contains interval validation message
        errors = exc_info.value.errors()
        assert any("interval_minutes" in str(error) for error in errors)

    def test_plugin_config_missing_required_fields_raises_error(self) -> None:
        """PluginConfig should raise ValidationError when required fields missing."""
        # Arrange & Act & Assert
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig()  # type: ignore[call-arg]

        # Verify required fields are mentioned in error
        errors = exc_info.value.errors()
        error_fields = {error["loc"][0] for error in errors}
        assert "name" in error_fields
        assert "enabled" in error_fields
        assert "interval_minutes" in error_fields

    def test_plugin_config_empty_credentials_and_options(self) -> None:
        """PluginConfig should accept empty dicts for credentials and options."""
        # Arrange & Act
        config = PluginConfig(
            name="minimal_plugin",
            enabled=False,
            interval_minutes=60,
            credentials={},
            options={},
        )

        # Assert
        assert config.credentials == {}
        assert config.options == {}

    def test_plugin_config_disabled_plugin(self) -> None:
        """PluginConfig should support enabled=False."""
        # Arrange & Act
        config = PluginConfig(
            name="disabled_plugin",
            enabled=False,
            interval_minutes=120,
            credentials={},
            options={},
        )

        # Assert
        assert config.enabled is False
