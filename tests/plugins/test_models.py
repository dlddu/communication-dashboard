"""Tests for plugin data models and validation."""

from datetime import UTC, datetime

import pytest
from pydantic import ValidationError

from src.plugins.models import PluginConfig, PluginData, ValidationResult


class TestPluginData:
    """Test suite for PluginData dataclass."""

    def test_plugin_data_creation_with_valid_data(self) -> None:
        """Test creating PluginData with all valid fields."""
        timestamp = datetime.now(UTC)
        metadata = {"key": "value", "count": 42}

        data = PluginData(
            id="item-123",
            source="test-source",
            title="Test Title",
            content="Test content here",
            timestamp=timestamp,
            metadata=metadata,
            read=False,
        )

        assert data.id == "item-123"
        assert data.source == "test-source"
        assert data.title == "Test Title"
        assert data.content == "Test content here"
        assert data.timestamp == timestamp
        assert data.metadata == metadata
        assert data.read is False

    def test_plugin_data_read_defaults_to_false(self) -> None:
        """Test that read field defaults to False if not specified."""
        data = PluginData(
            id="item-123",
            source="test-source",
            title="Test Title",
            content="Test content",
            timestamp=datetime.now(UTC),
            metadata={},
        )

        assert data.read is False

    def test_plugin_data_metadata_defaults_to_empty_dict(self) -> None:
        """Test that metadata defaults to empty dict if not specified."""
        data = PluginData(
            id="item-123",
            source="test-source",
            title="Test Title",
            content="Test content",
            timestamp=datetime.now(UTC),
            read=False,
        )

        assert data.metadata == {}

    def test_plugin_data_requires_all_mandatory_fields(self) -> None:
        """Test that PluginData requires id, source, title, content, and timestamp."""
        with pytest.raises(ValidationError) as exc_info:
            PluginData()  # type: ignore[call-arg]

        errors = exc_info.value.errors()
        required_fields = {"id", "source", "title", "content", "timestamp"}
        error_fields = {error["loc"][0] for error in errors}
        assert required_fields.issubset(error_fields)

    def test_plugin_data_with_empty_metadata(self) -> None:
        """Test PluginData with explicitly empty metadata."""
        data = PluginData(
            id="item-123",
            source="test-source",
            title="Test Title",
            content="Content",
            timestamp=datetime.now(UTC),
            metadata={},
            read=True,
        )

        assert data.metadata == {}
        assert data.read is True


class TestPluginConfig:
    """Test suite for PluginConfig Pydantic model."""

    def test_plugin_config_with_valid_data(self) -> None:
        """Test creating PluginConfig with all valid fields."""
        config = PluginConfig(
            name="test-plugin",
            enabled=True,
            interval_minutes=60,
            credentials={"api_key": "secret123"},
            options={"timeout": 30, "retry": 3},
        )

        assert config.name == "test-plugin"
        assert config.enabled is True
        assert config.interval_minutes == 60
        assert config.credentials == {"api_key": "secret123"}
        assert config.options == {"timeout": 30, "retry": 3}

    def test_plugin_config_validation(self) -> None:
        """Test that invalid config raises ValidationError.

        Empty name should fail validation.
        """
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(
                name="",  # Empty name should fail
                enabled=True,
                interval_minutes=60,
                credentials={},
                options={},
            )

        errors = exc_info.value.errors()
        assert len(errors) > 0
        # Check that the error is related to the name field
        assert any(error["loc"][0] == "name" for error in errors)

    def test_interval_minutes_boundary_minimum(self) -> None:
        """Test that interval_minutes must be at least 1.

        Value of 0 should raise ValidationError.
        """
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(
                name="test-plugin",
                enabled=True,
                interval_minutes=0,  # Below minimum
                credentials={},
                options={},
            )

        errors = exc_info.value.errors()
        assert any(error["loc"][0] == "interval_minutes" for error in errors)

    def test_interval_minutes_boundary_maximum(self) -> None:
        """Test that interval_minutes must be at most 1440 (24 hours).

        Value of 1441 should raise ValidationError.
        """
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(
                name="test-plugin",
                enabled=True,
                interval_minutes=1441,  # Above maximum
                credentials={},
                options={},
            )

        errors = exc_info.value.errors()
        assert any(error["loc"][0] == "interval_minutes" for error in errors)

    def test_interval_minutes_valid_boundaries(self) -> None:
        """Test that interval_minutes accepts valid boundary values 1 and 1440."""
        # Test minimum boundary (1)
        config_min = PluginConfig(
            name="test-plugin",
            enabled=True,
            interval_minutes=1,
            credentials={},
            options={},
        )
        assert config_min.interval_minutes == 1

        # Test maximum boundary (1440)
        config_max = PluginConfig(
            name="test-plugin",
            enabled=True,
            interval_minutes=1440,
            credentials={},
            options={},
        )
        assert config_max.interval_minutes == 1440

    def test_plugin_config_enabled_defaults_to_true(self) -> None:
        """Test that enabled defaults to True."""
        config = PluginConfig(
            name="test-plugin",
            interval_minutes=60,
            credentials={},
            options={},
        )

        assert config.enabled is True

    def test_plugin_config_credentials_defaults_to_empty_dict(self) -> None:
        """Test that credentials defaults to empty dict."""
        config = PluginConfig(
            name="test-plugin",
            enabled=True,
            interval_minutes=60,
            options={},
        )

        assert config.credentials == {}

    def test_plugin_config_options_defaults_to_empty_dict(self) -> None:
        """Test that options defaults to empty dict."""
        config = PluginConfig(
            name="test-plugin",
            enabled=True,
            interval_minutes=60,
            credentials={},
        )

        assert config.options == {}

    def test_plugin_config_name_cannot_be_whitespace_only(self) -> None:
        """Test that name cannot be only whitespace."""
        with pytest.raises(ValidationError):
            PluginConfig(
                name="   ",  # Whitespace only
                enabled=True,
                interval_minutes=60,
                credentials={},
                options={},
            )


class TestValidationResult:
    """Test suite for ValidationResult type."""

    def test_validation_result_success_type(self) -> None:
        """Test that ValidationResult can represent a success state."""
        result: ValidationResult = {"valid": True, "errors": []}

        assert result["valid"] is True
        assert result["errors"] == []

    def test_validation_result_failure_type(self) -> None:
        """Test that ValidationResult can represent a failure state with errors."""
        result: ValidationResult = {
            "valid": False,
            "errors": ["Invalid name", "Invalid interval"],
        }

        assert result["valid"] is False
        assert len(result["errors"]) == 2
        assert "Invalid name" in result["errors"]
        assert "Invalid interval" in result["errors"]

    def test_validation_result_partial_failure(self) -> None:
        """Test ValidationResult with single error."""
        result: ValidationResult = {"valid": False, "errors": ["Missing required field"]}

        assert result["valid"] is False
        assert len(result["errors"]) == 1
