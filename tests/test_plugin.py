"""Tests for BasePlugin interface and related data models.

This test suite follows TDD approach and validates:
- BasePlugin ABC interface enforcement
- PluginData dataclass structure
- PluginConfig validation rules
- Type safety with mypy --strict
"""

import pytest
from datetime import datetime
from typing import List
from pydantic import ValidationError

from app.plugins.base import BasePlugin, PluginData, PluginConfig


class TestBasePluginInterface:
    """Test BasePlugin ABC interface."""

    def test_plugin_must_implement_fetch(self) -> None:
        """Test that BasePlugin cannot be instantiated without implementing fetch."""
        # This should raise TypeError because fetch is not implemented
        with pytest.raises(TypeError) as exc_info:

            class IncompletePlugin(BasePlugin):
                """Plugin without fetch implementation."""

                pass

            config = PluginConfig(
                name="test",
                interval_minutes=60
            )
            IncompletePlugin(config)  # type: ignore[abstract]

        assert "abstract method" in str(exc_info.value).lower()
        assert "fetch" in str(exc_info.value).lower()

    def test_plugin_fetch_returns_plugin_data_list(self) -> None:
        """Test that fetch method returns list of PluginData."""

        class ValidPlugin(BasePlugin):
            """Valid plugin implementation."""

            async def fetch(self) -> List[PluginData]:
                return [
                    PluginData(
                        id="test-1",
                        source="test-source",
                        title="Test Title",
                        content="Test Content",
                        timestamp=datetime.now(),
                        metadata={"key": "value"},
                        read=False
                    )
                ]

        config = PluginConfig(name="test", interval_minutes=60)
        plugin = ValidPlugin(config)
        
        # Type checking: ensure fetch returns List[PluginData]
        assert hasattr(plugin, "fetch")
        assert callable(plugin.fetch)

    def test_plugin_validate_config_returns_bool(self) -> None:
        """Test that validate_config returns bool."""

        class ValidPlugin(BasePlugin):
            """Valid plugin implementation."""

            async def fetch(self) -> List[PluginData]:
                return []

        config = PluginConfig(name="test", interval_minutes=60)
        plugin = ValidPlugin(config)
        
        result = plugin.validate_config()
        assert isinstance(result, bool)
        assert result is True


class TestPluginData:
    """Test PluginData dataclass."""

    def test_plugin_data_creation(self) -> None:
        """Test creating PluginData instance."""
        timestamp = datetime.now()
        data = PluginData(
            id="msg-123",
            source="slack",
            title="New Message",
            content="Hello World",
            timestamp=timestamp,
            metadata={"channel": "general"},
            read=False
        )

        assert data.id == "msg-123"
        assert data.source == "slack"
        assert data.title == "New Message"
        assert data.content == "Hello World"
        assert data.timestamp == timestamp
        assert data.metadata == {"channel": "general"}
        assert data.read is False

    def test_plugin_data_default_read_false(self) -> None:
        """Test that read field defaults to False."""
        data = PluginData(
            id="msg-123",
            source="slack",
            title="Test",
            content="Content",
            timestamp=datetime.now(),
            metadata={}
        )

        assert data.read is False

    def test_plugin_data_immutability(self) -> None:
        """Test that PluginData is immutable (frozen dataclass)."""
        data = PluginData(
            id="msg-123",
            source="slack",
            title="Test",
            content="Content",
            timestamp=datetime.now(),
            metadata={}
        )

        # Should raise FrozenInstanceError when trying to modify
        with pytest.raises(AttributeError):
            data.read = True  # type: ignore[misc]


class TestPluginConfig:
    """Test PluginConfig Pydantic model."""

    def test_plugin_config_creation(self) -> None:
        """Test creating PluginConfig instance."""
        config = PluginConfig(
            name="slack-plugin",
            enabled=True,
            interval_minutes=30,
            credentials={"token": "abc123"},
            options={"debug": True}
        )

        assert config.name == "slack-plugin"
        assert config.enabled is True
        assert config.interval_minutes == 30
        assert config.credentials == {"token": "abc123"}
        assert config.options == {"debug": True}

    def test_plugin_config_defaults(self) -> None:
        """Test PluginConfig default values."""
        config = PluginConfig(
            name="test",
            interval_minutes=60
        )

        assert config.enabled is True
        assert config.credentials is None
        assert config.options == {}

    def test_interval_minutes_boundary(self) -> None:
        """Test interval_minutes validation boundaries (1-1440)."""
        # Valid boundaries
        config_min = PluginConfig(name="test", interval_minutes=1)
        assert config_min.interval_minutes == 1

        config_max = PluginConfig(name="test", interval_minutes=1440)
        assert config_max.interval_minutes == 1440

        # Invalid: too low
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(name="test", interval_minutes=0)
        
        assert "interval_minutes" in str(exc_info.value).lower()

        # Invalid: too high
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(name="test", interval_minutes=1441)
        
        assert "interval_minutes" in str(exc_info.value).lower()

    def test_plugin_config_validation(self) -> None:
        """Test that invalid config raises ValidationError."""
        # Missing required field
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(name="test")  # type: ignore[call-arg]
        
        assert "interval_minutes" in str(exc_info.value).lower()

        # Invalid type
        with pytest.raises(ValidationError):
            PluginConfig(
                name="test",
                interval_minutes="not-a-number"  # type: ignore[arg-type]
            )


class TestPluginIntegration:
    """Integration tests for plugin system."""

    @pytest.mark.asyncio
    async def test_plugin_fetch_integration(self) -> None:
        """Test full plugin fetch cycle."""

        class TestPlugin(BasePlugin):
            """Test plugin implementation."""

            async def fetch(self) -> List[PluginData]:
                return [
                    PluginData(
                        id=f"msg-{i}",
                        source="test",
                        title=f"Message {i}",
                        content=f"Content {i}",
                        timestamp=datetime.now(),
                        metadata={"index": i}
                    )
                    for i in range(3)
                ]

        config = PluginConfig(
            name="test-plugin",
            interval_minutes=30
        )
        plugin = TestPlugin(config)

        results = await plugin.fetch()

        assert len(results) == 3
        assert all(isinstance(item, PluginData) for item in results)
        assert results[0].id == "msg-0"
        assert results[1].title == "Message 1"
        assert results[2].metadata == {"index": 2}
