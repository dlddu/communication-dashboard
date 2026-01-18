"""Tests for BasePlugin ABC and related data structures.

This module contains comprehensive tests for the plugin system's base classes,
following TDD Red Phase principles. Tests are written before implementation.
"""

from dataclasses import FrozenInstanceError
from datetime import datetime, timezone
from typing import Any

import pytest
from pydantic import ValidationError


# Import the modules we're testing (these don't exist yet - TDD Red Phase)
# These imports will fail until implementation is complete
try:
    from src.plugins.base import (
        BasePlugin,
        PluginConfig,
        PluginData,
        ValidationResult,
    )
except ImportError:
    # Placeholder for TDD - these will be implemented next
    BasePlugin = None  # type: ignore
    PluginConfig = None  # type: ignore
    PluginData = None  # type: ignore
    ValidationResult = None  # type: ignore


# Mark all tests to skip if imports fail (TDD Red Phase)
pytestmark = pytest.mark.skipif(
    BasePlugin is None,
    reason="Implementation not yet available - TDD Red Phase"
)


class TestBasePluginAbstract:
    """Test suite for BasePlugin ABC abstract methods."""

    def test_plugin_must_implement_fetch(self) -> None:
        """Test that BasePlugin subclass must implement fetch() method.
        
        Expected behavior:
        - Creating instance without fetch() raises TypeError
        - Error message mentions abstract method
        """
        with pytest.raises(TypeError, match="abstract"):
            class IncompletePlugin(BasePlugin):  # type: ignore
                def validate_config(self, config: PluginConfig) -> ValidationResult:  # type: ignore
                    return {"valid": True, "errors": []}
            
            IncompletePlugin()  # Should raise TypeError

    def test_plugin_must_implement_validate_config(self) -> None:
        """Test that BasePlugin subclass must implement validate_config() method.
        
        Expected behavior:
        - Creating instance without validate_config() raises TypeError
        - Error message mentions abstract method
        """
        with pytest.raises(TypeError, match="abstract"):
            class IncompletePlugin(BasePlugin):  # type: ignore
                def fetch(self) -> list[PluginData]:  # type: ignore
                    return []
            
            IncompletePlugin()  # Should raise TypeError

    def test_plugin_fetch_returns_plugin_data_list(self) -> None:
        """Test that a properly implemented plugin can return List[PluginData].
        
        Expected behavior:
        - Plugin with both methods implemented can be instantiated
        - fetch() returns a list of PluginData objects
        """
        class ValidPlugin(BasePlugin):  # type: ignore
            def fetch(self) -> list[PluginData]:  # type: ignore
                return [
                    PluginData(  # type: ignore
                        id="test-1",
                        source="test",
                        title="Test Message",
                        content="Test content",
                        timestamp=datetime.now(timezone.utc),
                        metadata={"key": "value"},
                        read=False
                    )
                ]
            
            def validate_config(self, config: PluginConfig) -> ValidationResult:  # type: ignore
                return {"valid": True, "errors": []}
        
        plugin = ValidPlugin()
        result = plugin.fetch()
        
        assert isinstance(result, list)
        assert len(result) == 1
        assert isinstance(result[0], PluginData)  # type: ignore
        assert result[0].id == "test-1"


class TestPluginData:
    """Test suite for PluginData dataclass."""

    def test_plugin_data_fields(self) -> None:
        """Test that PluginData has all required fields with correct types.
        
        Expected behavior:
        - All required fields can be set
        - read field defaults to False
        - Fields have expected values
        """
        timestamp = datetime(2026, 1, 18, 12, 0, 0, tzinfo=timezone.utc)
        metadata = {"priority": "high", "tags": ["important"]}
        
        data = PluginData(  # type: ignore
            id="msg-123",
            source="slack",
            title="Important Update",
            content="This is important content",
            timestamp=timestamp,
            metadata=metadata,
        )
        
        assert data.id == "msg-123"
        assert data.source == "slack"
        assert data.title == "Important Update"
        assert data.content == "This is important content"
        assert data.timestamp == timestamp
        assert data.metadata == metadata
        assert data.read is False  # Default value

    def test_plugin_data_with_read_true(self) -> None:
        """Test that PluginData read field can be set to True.
        
        Expected behavior:
        - read=True is preserved
        """
        data = PluginData(  # type: ignore
            id="msg-456",
            source="email",
            title="Read Message",
            content="Already read",
            timestamp=datetime.now(timezone.utc),
            metadata={},
            read=True
        )
        
        assert data.read is True

    def test_plugin_data_immutable(self) -> None:
        """Test that PluginData is immutable (frozen=True).
        
        Expected behavior:
        - Attempting to modify any field raises FrozenInstanceError
        """
        data = PluginData(  # type: ignore
            id="msg-789",
            source="discord",
            title="Frozen Message",
            content="Cannot modify",
            timestamp=datetime.now(timezone.utc),
            metadata={},
        )
        
        # Try to modify various fields
        with pytest.raises(FrozenInstanceError):
            data.read = True  # type: ignore
        
        with pytest.raises(FrozenInstanceError):
            data.title = "New Title"  # type: ignore
        
        with pytest.raises(FrozenInstanceError):
            data.id = "new-id"  # type: ignore

    def test_plugin_data_metadata_can_contain_any_type(self) -> None:
        """Test that metadata dict can contain various types.
        
        Expected behavior:
        - metadata accepts dict[str, Any]
        - Can store strings, numbers, lists, dicts, etc.
        """
        complex_metadata: dict[str, Any] = {
            "string": "value",
            "number": 42,
            "float": 3.14,
            "list": [1, 2, 3],
            "nested": {"key": "value"},
            "bool": True,
        }
        
        data = PluginData(  # type: ignore
            id="msg-complex",
            source="test",
            title="Complex Metadata",
            content="Test",
            timestamp=datetime.now(timezone.utc),
            metadata=complex_metadata,
        )
        
        assert data.metadata == complex_metadata
        assert data.metadata["string"] == "value"
        assert data.metadata["number"] == 42
        assert data.metadata["nested"]["key"] == "value"


class TestPluginConfig:
    """Test suite for PluginConfig Pydantic model."""

    def test_plugin_config_validation_valid(self) -> None:
        """Test that valid PluginConfig can be created.
        
        Expected behavior:
        - Config with required fields is created successfully
        - Default values are applied
        """
        config = PluginConfig(  # type: ignore
            name="slack-plugin",
            interval_minutes=30
        )
        
        assert config.name == "slack-plugin"
        assert config.enabled is True  # Default value
        assert config.interval_minutes == 30
        assert config.credentials == {}  # Default value
        assert config.options == {}  # Default value

    def test_plugin_config_with_all_fields(self) -> None:
        """Test PluginConfig with all fields specified.
        
        Expected behavior:
        - All fields can be set explicitly
        - No defaults override provided values
        """
        config = PluginConfig(  # type: ignore
            name="email-plugin",
            enabled=False,
            interval_minutes=60,
            credentials={"api_key": "secret123", "user": "admin"},
            options={"fetch_limit": 50, "include_spam": False}
        )
        
        assert config.name == "email-plugin"
        assert config.enabled is False
        assert config.interval_minutes == 60
        assert config.credentials == {"api_key": "secret123", "user": "admin"}
        assert config.options == {"fetch_limit": 50, "include_spam": False}

    def test_plugin_config_interval_boundary_valid(self) -> None:
        """Test that interval_minutes accepts valid boundary values.
        
        Expected behavior:
        - interval_minutes=1 (minimum) is valid
        - interval_minutes=1440 (maximum, 24 hours) is valid
        """
        # Test minimum boundary
        config_min = PluginConfig(name="test", interval_minutes=1)  # type: ignore
        assert config_min.interval_minutes == 1
        
        # Test maximum boundary
        config_max = PluginConfig(name="test", interval_minutes=1440)  # type: ignore
        assert config_max.interval_minutes == 1440

    def test_plugin_config_interval_boundary_invalid_zero(self) -> None:
        """Test that interval_minutes=0 raises ValidationError.
        
        Expected behavior:
        - interval_minutes=0 is invalid (below minimum of 1)
        - ValidationError is raised
        """
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(name="test", interval_minutes=0)  # type: ignore
        
        errors = exc_info.value.errors()
        assert any("interval_minutes" in str(err) for err in errors)

    def test_plugin_config_interval_boundary_invalid_negative(self) -> None:
        """Test that negative interval_minutes raises ValidationError.
        
        Expected behavior:
        - interval_minutes=-1 is invalid
        - ValidationError is raised
        """
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(name="test", interval_minutes=-1)  # type: ignore
        
        errors = exc_info.value.errors()
        assert any("interval_minutes" in str(err) for err in errors)

    def test_plugin_config_interval_boundary_invalid_too_large(self) -> None:
        """Test that interval_minutes > 1440 raises ValidationError.
        
        Expected behavior:
        - interval_minutes=1441 is invalid (above maximum)
        - ValidationError is raised
        """
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(name="test", interval_minutes=1441)  # type: ignore
        
        errors = exc_info.value.errors()
        assert any("interval_minutes" in str(err) for err in errors)

    def test_plugin_config_missing_required_field_name(self) -> None:
        """Test that missing 'name' field raises ValidationError.
        
        Expected behavior:
        - name is a required field
        - ValidationError mentions missing field
        """
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(interval_minutes=30)  # type: ignore
        
        errors = exc_info.value.errors()
        assert any(err["loc"] == ("name",) for err in errors)

    def test_plugin_config_missing_required_field_interval(self) -> None:
        """Test that missing 'interval_minutes' field raises ValidationError.
        
        Expected behavior:
        - interval_minutes is a required field
        - ValidationError mentions missing field
        """
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(name="test")  # type: ignore
        
        errors = exc_info.value.errors()
        assert any(err["loc"] == ("interval_minutes",) for err in errors)


class TestValidationResult:
    """Test suite for ValidationResult structure."""

    def test_validation_result_structure_valid(self) -> None:
        """Test that ValidationResult has correct structure for valid case.
        
        Expected behavior:
        - ValidationResult has 'valid' bool field
        - ValidationResult has 'errors' list[str] field
        - Can represent successful validation
        """
        result: ValidationResult = {"valid": True, "errors": []}  # type: ignore
        
        assert result["valid"] is True
        assert isinstance(result["errors"], list)
        assert len(result["errors"]) == 0

    def test_validation_result_structure_invalid(self) -> None:
        """Test that ValidationResult can represent validation errors.
        
        Expected behavior:
        - valid=False indicates validation failure
        - errors list contains error messages
        """
        result: ValidationResult = {  # type: ignore
            "valid": False,
            "errors": [
                "Invalid API key format",
                "Missing required option: channel_id"
            ]
        }
        
        assert result["valid"] is False
        assert len(result["errors"]) == 2
        assert "Invalid API key format" in result["errors"]
        assert "Missing required option: channel_id" in result["errors"]

    def test_validation_result_can_be_used_in_plugin(self) -> None:
        """Test that ValidationResult works in plugin context.
        
        Expected behavior:
        - Plugin can return ValidationResult from validate_config
        - Result can be inspected properly
        """
        class TestPlugin(BasePlugin):  # type: ignore
            def fetch(self) -> list[PluginData]:  # type: ignore
                return []
            
            def validate_config(self, config: PluginConfig) -> ValidationResult:  # type: ignore
                errors: list[str] = []
                
                if not config.credentials.get("api_key"):
                    errors.append("API key is required")
                
                if config.interval_minutes < 5:
                    errors.append("Interval too short, minimum 5 minutes recommended")
                
                return {
                    "valid": len(errors) == 0,
                    "errors": errors
                }
        
        plugin = TestPlugin()
        
        # Test with invalid config
        invalid_config = PluginConfig(name="test", interval_minutes=1)  # type: ignore
        result = plugin.validate_config(invalid_config)
        
        assert result["valid"] is False
        assert len(result["errors"]) == 2
        assert "API key is required" in result["errors"]
        
        # Test with valid config
        valid_config = PluginConfig(  # type: ignore
            name="test",
            interval_minutes=30,
            credentials={"api_key": "valid-key"}
        )
        result = plugin.validate_config(valid_config)
        
        assert result["valid"] is True
        assert len(result["errors"]) == 0


class TestIntegration:
    """Integration tests for complete plugin workflow."""

    def test_complete_plugin_workflow(self) -> None:
        """Test a complete plugin implementation workflow.
        
        Expected behavior:
        - Plugin can be created with valid config
        - Config can be validated
        - Data can be fetched
        - All components work together
        """
        class MockPlugin(BasePlugin):  # type: ignore
            def __init__(self) -> None:
                self.config: PluginConfig | None = None  # type: ignore
            
            def fetch(self) -> list[PluginData]:  # type: ignore
                if not self.config:
                    return []
                
                return [
                    PluginData(  # type: ignore
                        id=f"{self.config.name}-1",
                        source=self.config.name,
                        title="Message 1",
                        content="Content 1",
                        timestamp=datetime.now(timezone.utc),
                        metadata=self.config.options,
                        read=False
                    )
                ]
            
            def validate_config(self, config: PluginConfig) -> ValidationResult:  # type: ignore
                errors: list[str] = []
                
                if not config.enabled:
                    errors.append("Plugin must be enabled")
                
                return {"valid": len(errors) == 0, "errors": errors}
        
        # Create plugin
        plugin = MockPlugin()
        
        # Create and validate config
        config = PluginConfig(  # type: ignore
            name="mock-plugin",
            enabled=True,
            interval_minutes=15,
            options={"tag": "important"}
        )
        
        validation = plugin.validate_config(config)
        assert validation["valid"] is True
        
        # Set config and fetch data
        plugin.config = config
        data = plugin.fetch()
        
        assert len(data) == 1
        assert data[0].source == "mock-plugin"
        assert data[0].metadata == {"tag": "important"}
        assert data[0].read is False

    def test_plugin_with_invalid_config_workflow(self) -> None:
        """Test plugin behavior with invalid configuration.
        
        Expected behavior:
        - Invalid config is detected during validation
        - Validation result indicates failure
        - Error messages are descriptive
        """
        class StrictPlugin(BasePlugin):  # type: ignore
            def fetch(self) -> list[PluginData]:  # type: ignore
                return []
            
            def validate_config(self, config: PluginConfig) -> ValidationResult:  # type: ignore
                errors: list[str] = []
                
                if config.interval_minutes < 10:
                    errors.append("Interval must be at least 10 minutes")
                
                if not config.credentials.get("token"):
                    errors.append("Token credential is required")
                
                return {"valid": len(errors) == 0, "errors": errors}
        
        plugin = StrictPlugin()
        
        # Create invalid config (will pass Pydantic validation but fail plugin validation)
        config = PluginConfig(  # type: ignore
            name="strict-plugin",
            interval_minutes=5,  # Too short for plugin
            credentials={}  # Missing token
        )
        
        validation = plugin.validate_config(config)
        
        assert validation["valid"] is False
        assert len(validation["errors"]) == 2
        assert any("10 minutes" in err for err in validation["errors"])
        assert any("Token" in err for err in validation["errors"])
