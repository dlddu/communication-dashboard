"""Tests for PluginConfig and ValidationResult."""

from typing import Any

import pytest
from pydantic import ValidationError

from backend.src.plugins.config import PluginConfig, ValidationResult


class TestPluginConfig:
    """Test PluginConfig Pydantic model."""

    def test_plugin_config_creation_with_valid_data(self) -> None:
        """Test that PluginConfig can be created with valid data."""
        # Arrange
        name = "test-plugin"
        enabled = True
        interval_minutes = 30
        credentials: dict[str, str] = {"api_key": "test-key"}
        options: dict[str, Any] = {"option1": "value1"}

        # Act
        config = PluginConfig(
            name=name,
            enabled=enabled,
            interval_minutes=interval_minutes,
            credentials=credentials,
            options=options,
        )

        # Assert
        assert config.name == name
        assert config.enabled == enabled
        assert config.interval_minutes == interval_minutes
        assert config.credentials == credentials
        assert config.options == options

    def test_plugin_config_validation(self) -> None:
        """Test that invalid config raises ValidationError."""
        # Arrange & Act & Assert - Missing required fields
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig()  # type: ignore[call-arg]

        errors = exc_info.value.errors()
        missing_fields = {error["loc"][0] for error in errors}
        assert "name" in missing_fields
        assert "enabled" in missing_fields
        assert "interval_minutes" in missing_fields

    def test_interval_minutes_boundary_minimum(self) -> None:
        """Test that interval_minutes must be at least 1."""
        # Arrange & Act & Assert - Below minimum
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(
                name="test",
                enabled=True,
                interval_minutes=0,
                credentials={},
                options={},
            )

        errors = exc_info.value.errors()
        assert any(
            error["loc"][0] == "interval_minutes" and "greater than or equal to 1" in str(error)
            for error in errors
        )

    def test_interval_minutes_boundary_maximum(self) -> None:
        """Test that interval_minutes must be at most 1440."""
        # Arrange & Act & Assert - Above maximum
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(
                name="test",
                enabled=True,
                interval_minutes=1441,
                credentials={},
                options={},
            )

        errors = exc_info.value.errors()
        assert any(
            error["loc"][0] == "interval_minutes" and "less than or equal to 1440" in str(error)
            for error in errors
        )

    def test_interval_minutes_valid_boundaries(self) -> None:
        """Test that interval_minutes accepts valid boundary values."""
        # Act - Minimum boundary
        config_min = PluginConfig(
            name="test",
            enabled=True,
            interval_minutes=1,
            credentials={},
            options={},
        )

        # Assert
        assert config_min.interval_minutes == 1

        # Act - Maximum boundary
        config_max = PluginConfig(
            name="test",
            enabled=True,
            interval_minutes=1440,
            credentials={},
            options={},
        )

        # Assert
        assert config_max.interval_minutes == 1440

    def test_plugin_config_default_credentials_and_options(self) -> None:
        """Test that credentials and options have sensible defaults."""
        # Arrange & Act
        config = PluginConfig(
            name="test",
            enabled=True,
            interval_minutes=60,
        )

        # Assert
        assert config.credentials == {} or config.credentials is None
        assert config.options == {} or config.options is None

    def test_plugin_config_name_validation(self) -> None:
        """Test that plugin name cannot be empty."""
        # Arrange & Act & Assert
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(
                name="",
                enabled=True,
                interval_minutes=60,
                credentials={},
                options={},
            )

        errors = exc_info.value.errors()
        assert any(error["loc"][0] == "name" for error in errors)

    def test_plugin_config_enabled_must_be_boolean(self) -> None:
        """Test that enabled field must be boolean."""
        # Arrange & Act & Assert
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(
                name="test",
                enabled="yes",  # type: ignore[arg-type]
                interval_minutes=60,
                credentials={},
                options={},
            )

        errors = exc_info.value.errors()
        assert any(
            error["loc"][0] == "enabled" and error["type"] == "bool_type" for error in errors
        )

    def test_plugin_config_interval_must_be_integer(self) -> None:
        """Test that interval_minutes must be an integer."""
        # Arrange & Act & Assert
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(
                name="test",
                enabled=True,
                interval_minutes=30.5,  # type: ignore[arg-type]
                credentials={},
                options={},
            )

        errors = exc_info.value.errors()
        assert any(error["loc"][0] == "interval_minutes" for error in errors)


class TestValidationResult:
    """Test ValidationResult type definition."""

    def test_validation_result_success(self) -> None:
        """Test ValidationResult structure for successful validation."""
        # Arrange
        result: ValidationResult = {
            "valid": True,
            "errors": [],
        }

        # Assert
        assert result["valid"] is True
        assert result["errors"] == []
        assert isinstance(result["errors"], list)

    def test_validation_result_failure(self) -> None:
        """Test ValidationResult structure for failed validation."""
        # Arrange
        result: ValidationResult = {
            "valid": False,
            "errors": ["Error 1", "Error 2"],
        }

        # Assert
        assert result["valid"] is False
        assert len(result["errors"]) == 2
        assert "Error 1" in result["errors"]
        assert "Error 2" in result["errors"]

    def test_validation_result_has_required_keys(self) -> None:
        """Test that ValidationResult has required keys."""
        # Arrange
        result: ValidationResult = {
            "valid": True,
            "errors": [],
        }

        # Assert
        assert "valid" in result
        assert "errors" in result
        assert isinstance(result["valid"], bool)
        assert isinstance(result["errors"], list)
