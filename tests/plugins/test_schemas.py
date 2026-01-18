"""Tests for plugin data schemas and validation."""

from datetime import UTC, datetime

import pytest
from pydantic import ValidationError

from communication_dashboard.plugins.schemas import (
    PluginConfig,
    PluginData,
    ValidationResult,
)


class TestPluginData:
    """Test cases for PluginData dataclass."""

    def test_plugin_data_creation_with_valid_fields(self):
        """PluginData should be created with all required fields."""
        # Arrange
        timestamp = datetime.now(UTC)

        # Act
        data = PluginData(
            id="msg-001",
            source="slack",
            title="New message",
            content="Hello world",
            timestamp=timestamp,
            metadata={"channel": "#general"},
            read=False,
        )

        # Assert
        assert data.id == "msg-001"
        assert data.source == "slack"
        assert data.title == "New message"
        assert data.content == "Hello world"
        assert data.timestamp == timestamp
        assert data.metadata == {"channel": "#general"}
        assert data.read is False

    def test_plugin_data_defaults(self):
        """PluginData should have sensible defaults for optional fields."""
        # Arrange
        timestamp = datetime.now(UTC)

        # Act
        data = PluginData(
            id="msg-002",
            source="email",
            title="Email subject",
            content="Email body",
            timestamp=timestamp,
        )

        # Assert
        assert data.metadata == {}
        assert data.read is False

    def test_plugin_data_immutability(self):
        """PluginData should be immutable (frozen dataclass)."""
        # Arrange
        data = PluginData(
            id="msg-003",
            source="discord",
            title="Discord message",
            content="Content",
            timestamp=datetime.now(UTC),
        )

        # Act & Assert
        with pytest.raises(AttributeError):
            data.id = "new-id"

    def test_plugin_data_equality(self):
        """Two PluginData instances with same values should be equal."""
        # Arrange
        timestamp = datetime.now(UTC)
        metadata = {"key": "value"}

        # Act
        data1 = PluginData(
            id="msg-004",
            source="teams",
            title="Teams message",
            content="Content",
            timestamp=timestamp,
            metadata=metadata,
            read=True,
        )
        data2 = PluginData(
            id="msg-004",
            source="teams",
            title="Teams message",
            content="Content",
            timestamp=timestamp,
            metadata=metadata,
            read=True,
        )

        # Assert
        assert data1 == data2


class TestPluginConfig:
    """Test cases for PluginConfig Pydantic model."""

    def test_plugin_config_creation_with_valid_fields(self):
        """PluginConfig should be created with all valid fields."""
        # Arrange & Act
        config = PluginConfig(
            name="slack-plugin",
            enabled=True,
            interval_minutes=15,
            credentials={"api_token": "xoxb-secret"},
            options={"channels": ["#general", "#dev"]},
        )

        # Assert
        assert config.name == "slack-plugin"
        assert config.enabled is True
        assert config.interval_minutes == 15
        assert config.credentials == {"api_token": "xoxb-secret"}
        assert config.options == {"channels": ["#general", "#dev"]}

    def test_plugin_config_validation(self):
        """Invalid config should raise ValidationError."""
        # Act & Assert
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(
                name="",  # Empty name should be invalid
                enabled=True,
                interval_minutes=15,
                credentials={},
                options={},
            )

        # Verify error message mentions name field
        assert "name" in str(exc_info.value)

    def test_interval_minutes_boundary(self):
        """Interval should only allow 1-1440 range."""
        # Test valid boundaries
        config_min = PluginConfig(
            name="test-plugin",
            enabled=True,
            interval_minutes=1,
            credentials={},
            options={},
        )
        assert config_min.interval_minutes == 1

        config_max = PluginConfig(
            name="test-plugin",
            enabled=True,
            interval_minutes=1440,
            credentials={},
            options={},
        )
        assert config_max.interval_minutes == 1440

        # Test below minimum
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(
                name="test-plugin",
                enabled=True,
                interval_minutes=0,
                credentials={},
                options={},
            )
        assert "interval_minutes" in str(exc_info.value)

        # Test above maximum
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(
                name="test-plugin",
                enabled=True,
                interval_minutes=1441,
                credentials={},
                options={},
            )
        assert "interval_minutes" in str(exc_info.value)

    def test_plugin_config_defaults(self):
        """PluginConfig should have sensible defaults."""
        # Arrange & Act
        config = PluginConfig(
            name="minimal-plugin",
        )

        # Assert
        assert config.enabled is True
        assert config.interval_minutes == 60
        assert config.credentials == {}
        assert config.options == {}

    def test_plugin_config_disabled_plugin(self):
        """PluginConfig should support disabled state."""
        # Arrange & Act
        config = PluginConfig(
            name="disabled-plugin",
            enabled=False,
        )

        # Assert
        assert config.enabled is False

    def test_plugin_config_type_validation(self):
        """PluginConfig should validate field types."""
        # Test invalid enabled type (a value that cannot be coerced to bool meaningfully)
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(
                name="test-plugin",
                enabled=[1, 2, 3],  # List cannot be coerced to bool
                interval_minutes=60,
                credentials={},
                options={},
            )
        assert "enabled" in str(exc_info.value)

        # Test invalid interval type (a value that cannot be coerced to int)
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(
                name="test-plugin",
                enabled=True,
                interval_minutes="not-a-number",  # Cannot be coerced to int
                credentials={},
                options={},
            )
        assert "interval_minutes" in str(exc_info.value)

    def test_plugin_config_credentials_dict_validation(self):
        """PluginConfig credentials should be a dict."""
        # Test invalid credentials type
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(
                name="test-plugin",
                enabled=True,
                interval_minutes=60,
                credentials="not-a-dict",  # Should be dict
                options={},
            )
        assert "credentials" in str(exc_info.value)

    def test_plugin_config_options_dict_validation(self):
        """PluginConfig options should be a dict."""
        # Test invalid options type
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(
                name="test-plugin",
                enabled=True,
                interval_minutes=60,
                credentials={},
                options="not-a-dict",  # Should be dict
            )
        assert "options" in str(exc_info.value)


class TestValidationResult:
    """Test cases for ValidationResult type."""

    def test_validation_result_success(self):
        """ValidationResult should support success case."""
        # Arrange & Act
        result: ValidationResult = {
            "valid": True,
            "errors": [],
        }

        # Assert
        assert result["valid"] is True
        assert result["errors"] == []

    def test_validation_result_failure(self):
        """ValidationResult should support failure case with errors."""
        # Arrange & Act
        result: ValidationResult = {
            "valid": False,
            "errors": ["Invalid API token", "Missing channel configuration"],
        }

        # Assert
        assert result["valid"] is False
        assert len(result["errors"]) == 2
        assert "Invalid API token" in result["errors"]

    def test_validation_result_with_warnings(self):
        """ValidationResult should support optional warnings."""
        # Arrange & Act
        result: ValidationResult = {
            "valid": True,
            "errors": [],
            "warnings": ["Deprecated option used"],
        }

        # Assert
        assert result["valid"] is True
        assert "warnings" in result
        assert result["warnings"] == ["Deprecated option used"]
