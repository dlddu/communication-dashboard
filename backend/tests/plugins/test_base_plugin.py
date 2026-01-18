"""Tests for BasePlugin abstract class.

This test file implements TDD Red Phase - tests are written before implementation.
All tests should fail initially until the implementation is complete.
"""
from datetime import datetime
from typing import Any

import pytest
from pydantic import ValidationError

from backend.models.plugin import PluginConfig, PluginData
from backend.plugins.base import BasePlugin


class ConcretePlugin(BasePlugin):
    """Concrete implementation of BasePlugin for testing."""
    
    def fetch(self) -> list[PluginData]:
        """Implement fetch method for testing."""
        return [
            PluginData(
                id="1",
                source="concrete_plugin",
                title="Test",
                content="Content",
                timestamp=datetime.now(),
                metadata={},
                read=False
            )
        ]


class IncompletePlugin(BasePlugin):
    """Incomplete plugin that doesn't implement fetch - should raise TypeError."""
    pass


class TestBasePlugin:
    """Test suite for BasePlugin abstract class."""

    def test_plugin_must_implement_fetch(
        self, 
        valid_plugin_config: PluginConfig
    ) -> None:
        """Test that plugin without fetch implementation raises TypeError.
        
        TDD Test Case 1: fetch 메서드 미구현 시 TypeError 발생
        
        Args:
            valid_plugin_config: Valid plugin configuration fixture
        """
        # Act & Assert
        with pytest.raises(TypeError) as exc_info:
            IncompletePlugin(valid_plugin_config)  # type: ignore[abstract]
        
        # Verify error message mentions abstract method
        assert "abstract" in str(exc_info.value).lower() or \
               "fetch" in str(exc_info.value).lower(), \
               "Error should mention abstract method or fetch"

    def test_plugin_fetch_returns_plugin_data_list(
        self,
        valid_plugin_config: PluginConfig
    ) -> None:
        """Test that fetch returns List[PluginData].
        
        TDD Test Case 2: fetch는 List[PluginData] 타입 반환
        
        Args:
            valid_plugin_config: Valid plugin configuration fixture
        """
        # Arrange
        plugin = ConcretePlugin(valid_plugin_config)
        
        # Act
        result = plugin.fetch()
        
        # Assert
        assert isinstance(result, list), "fetch() must return a list"
        assert len(result) > 0, "Result should contain at least one item"
        
        for item in result:
            assert isinstance(item, PluginData), \
                f"Each item must be PluginData, got {type(item)}"
            assert isinstance(item.id, str), "id must be string"
            assert isinstance(item.source, str), "source must be string"
            assert isinstance(item.title, str), "title must be string"
            assert isinstance(item.content, str), "content must be string"
            assert isinstance(item.timestamp, datetime), \
                "timestamp must be datetime"
            assert isinstance(item.metadata, dict), "metadata must be dict"
            assert isinstance(item.read, bool), "read must be bool"

    def test_plugin_config_validation(
        self,
        invalid_config_data: dict[str, Any]
    ) -> None:
        """Test that invalid config raises ValidationError.
        
        TDD Test Case 3: 잘못된 config는 ValidationError 발생
        
        Args:
            invalid_config_data: Invalid configuration data fixture
        """
        # Act & Assert
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(**invalid_config_data)
        
        # Verify error relates to interval_minutes
        errors = exc_info.value.errors()
        assert len(errors) > 0, "Should have validation errors"
        
        # Check that interval_minutes validation failed
        interval_error = any(
            'interval_minutes' in str(error.get('loc', ''))
            for error in errors
        )
        assert interval_error, "Should have interval_minutes validation error"

    def test_interval_minutes_boundary(self) -> None:
        """Test that interval_minutes only accepts 1-1440 range.
        
        TDD Test Case 4: interval은 1-1440 범위만 허용
        """
        # Test valid boundaries
        valid_configs: list[dict[str, Any]] = [
            {"name": "test", "enabled": True, "interval_minutes": 1},
            {"name": "test", "enabled": True, "interval_minutes": 60},
            {"name": "test", "enabled": True, "interval_minutes": 720},
            {"name": "test", "enabled": True, "interval_minutes": 1440},
        ]
        
        for config_data in valid_configs:
            config = PluginConfig(**config_data)
            assert config.interval_minutes == config_data["interval_minutes"], \
                f"Valid interval {config_data['interval_minutes']} should be accepted"
        
        # Test invalid boundaries
        invalid_configs: list[dict[str, Any]] = [
            {"name": "test", "enabled": True, "interval_minutes": 0},
            {"name": "test", "enabled": True, "interval_minutes": -1},
            {"name": "test", "enabled": True, "interval_minutes": 1441},
            {"name": "test", "enabled": True, "interval_minutes": 9999},
        ]
        
        for config_data in invalid_configs:
            with pytest.raises(ValidationError) as exc_info:
                PluginConfig(**config_data)
            
            errors = exc_info.value.errors()
            assert len(errors) > 0, \
                f"interval_minutes={config_data['interval_minutes']} should fail"
            
            # Verify error is about interval_minutes constraint
            interval_error = any(
                'interval_minutes' in str(error.get('loc', ''))
                for error in errors
            )
            assert interval_error, \
                f"Should have interval_minutes error for {config_data['interval_minutes']}"


class TestPluginDataModel:
    """Test suite for PluginData dataclass."""

    def test_plugin_data_creation(
        self,
        sample_plugin_data: PluginData
    ) -> None:
        """Test PluginData can be created with required fields.
        
        Args:
            sample_plugin_data: Sample plugin data fixture
        """
        # Assert
        assert sample_plugin_data.id == "test-123"
        assert sample_plugin_data.source == "test_source"
        assert sample_plugin_data.title == "Test Title"
        assert sample_plugin_data.content == "Test content"
        assert sample_plugin_data.timestamp.year == 2026
        assert sample_plugin_data.metadata == {"author": "Test Author"}
        assert sample_plugin_data.read is False

    def test_plugin_data_default_read_false(self) -> None:
        """Test that PluginData.read defaults to False."""
        # Arrange & Act
        data = PluginData(
            id="test",
            source="source",
            title="Title",
            content="Content",
            timestamp=datetime.now(),
            metadata={}
        )
        
        # Assert
        assert data.read is False, "read should default to False"


class TestPluginConfigModel:
    """Test suite for PluginConfig Pydantic model."""

    def test_plugin_config_creation(
        self,
        valid_plugin_config: PluginConfig
    ) -> None:
        """Test PluginConfig can be created with valid data.
        
        Args:
            valid_plugin_config: Valid plugin config fixture
        """
        # Assert
        assert valid_plugin_config.name == "test_plugin"
        assert valid_plugin_config.enabled is True
        assert valid_plugin_config.interval_minutes == 60
        assert valid_plugin_config.credentials == {"api_key": "test_key"}
        assert valid_plugin_config.options == {"timeout": 30}

    def test_plugin_config_optional_fields(self) -> None:
        """Test that credentials and options are optional."""
        # Arrange & Act
        config = PluginConfig(
            name="minimal",
            enabled=False,
            interval_minutes=30
        )
        
        # Assert
        assert config.credentials is None
        assert config.options == {}

    def test_plugin_config_options_default_empty_dict(self) -> None:
        """Test that options defaults to empty dict."""
        # Arrange & Act
        config = PluginConfig(
            name="test",
            enabled=True,
            interval_minutes=60,
            credentials=None
        )
        
        # Assert
        assert config.options == {}
        assert isinstance(config.options, dict)


class TestValidateConfig:
    """Test suite for BasePlugin.validate_config method."""

    def test_validate_config_valid(
        self,
        valid_plugin_config: PluginConfig
    ) -> None:
        """Test validate_config returns valid result for valid config.
        
        Args:
            valid_plugin_config: Valid plugin config fixture
        """
        # Arrange
        plugin = ConcretePlugin(valid_plugin_config)
        
        # Act
        result = plugin.validate_config()
        
        # Assert
        assert result["is_valid"] is True
        assert len(result["errors"]) == 0

    def test_validate_config_empty_name(self) -> None:
        """Test validate_config detects empty name."""
        # Arrange
        config = PluginConfig(
            name="",
            enabled=True,
            interval_minutes=60
        )
        plugin = ConcretePlugin(config)
        
        # Act
        result = plugin.validate_config()
        
        # Assert
        assert result["is_valid"] is False
        assert len(result["errors"]) > 0
        assert any("name" in error.lower() for error in result["errors"])

    def test_validate_config_invalid_interval(self) -> None:
        """Test validate_config detects invalid interval through config."""
        # Note: This tests the validate_config method logic
        # Pydantic validation happens before this in real usage
        
        # We test with valid Pydantic config but check validation logic
        config = PluginConfig(
            name="test",
            enabled=True,
            interval_minutes=60
        )
        plugin = ConcretePlugin(config)
        
        # Manually set invalid value to test validation logic
        # (In real code, Pydantic would prevent this)
        object.__setattr__(plugin.config, 'interval_minutes', 2000)
        
        # Act
        result = plugin.validate_config()
        
        # Assert
        assert result["is_valid"] is False
        assert any("interval" in error.lower() for error in result["errors"])
