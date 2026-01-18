"""Tests for BasePlugin abstract base class."""

from abc import ABC
from datetime import UTC, datetime

import pytest

from communication_dashboard.plugins.base import BasePlugin
from communication_dashboard.plugins.schemas import PluginConfig, PluginData


class TestBasePlugin:
    """Test cases for BasePlugin ABC."""

    def test_plugin_must_implement_fetch(self):
        """Plugin without fetch implementation should raise TypeError."""
        # Arrange
        class IncompletePlugin(BasePlugin):
            """Plugin that doesn't implement fetch method."""
            pass

        # Act & Assert
        with pytest.raises(TypeError) as exc_info:
            IncompletePlugin()

        # Verify error message mentions abstract method
        error_msg = str(exc_info.value)
        assert "abstract" in error_msg.lower()
        assert "fetch" in error_msg.lower()

    def test_plugin_fetch_returns_plugin_data_list(self):
        """Plugin fetch method should return list of PluginData."""
        # Arrange
        class ValidPlugin(BasePlugin):
            """Valid plugin implementation."""

            def fetch(self) -> list[PluginData]:
                """Fetch plugin data."""
                return [
                    PluginData(
                        id="test-001",
                        source="test",
                        title="Test message",
                        content="Test content",
                        timestamp=datetime.now(UTC),
                        metadata={},
                        read=False,
                    )
                ]

        # Act
        plugin = ValidPlugin()
        result = plugin.fetch()

        # Assert
        assert isinstance(result, list)
        assert len(result) == 1
        assert isinstance(result[0], PluginData)
        assert result[0].id == "test-001"
        assert result[0].source == "test"

    def test_plugin_is_abc_subclass(self):
        """BasePlugin should be an ABC subclass."""
        # Assert
        assert issubclass(BasePlugin, ABC)

    def test_plugin_fetch_can_return_empty_list(self):
        """Plugin fetch method should be able to return empty list."""
        # Arrange
        class EmptyPlugin(BasePlugin):
            """Plugin that returns no data."""

            def fetch(self) -> list[PluginData]:
                """Fetch plugin data."""
                return []

        # Act
        plugin = EmptyPlugin()
        result = plugin.fetch()

        # Assert
        assert isinstance(result, list)
        assert len(result) == 0

    def test_plugin_fetch_returns_multiple_items(self):
        """Plugin fetch method should support multiple PluginData items."""
        # Arrange
        class MultiItemPlugin(BasePlugin):
            """Plugin that returns multiple items."""

            def fetch(self) -> list[PluginData]:
                """Fetch plugin data."""
                timestamp = datetime.now(UTC)
                return [
                    PluginData(
                        id=f"test-{i:03d}",
                        source="test",
                        title=f"Message {i}",
                        content=f"Content {i}",
                        timestamp=timestamp,
                        metadata={"index": i},
                        read=False,
                    )
                    for i in range(5)
                ]

        # Act
        plugin = MultiItemPlugin()
        result = plugin.fetch()

        # Assert
        assert len(result) == 5
        assert all(isinstance(item, PluginData) for item in result)
        assert result[0].id == "test-000"
        assert result[4].id == "test-004"
        assert result[2].metadata == {"index": 2}

    def test_plugin_with_config_initialization(self):
        """Plugin should support initialization with config."""
        # Arrange
        class ConfigurablePlugin(BasePlugin):
            """Plugin that accepts configuration."""

            def __init__(self, config: PluginConfig):
                super().__init__(config)

            def fetch(self) -> list[PluginData]:
                """Fetch plugin data."""
                return []

        config = PluginConfig(
            name="test-plugin",
            enabled=True,
            interval_minutes=30,
            credentials={"api_key": "test-key"},
            options={"option1": "value1"},
        )

        # Act
        plugin = ConfigurablePlugin(config)

        # Assert
        assert plugin.config == config
        assert plugin.config.name == "test-plugin"
        assert plugin.config.interval_minutes == 30

    def test_plugin_fetch_with_metadata(self):
        """Plugin fetch should correctly handle metadata."""
        # Arrange
        class MetadataPlugin(BasePlugin):
            """Plugin that returns data with rich metadata."""

            def fetch(self) -> list[PluginData]:
                """Fetch plugin data."""
                return [
                    PluginData(
                        id="meta-001",
                        source="slack",
                        title="Slack message",
                        content="Message content",
                        timestamp=datetime.now(UTC),
                        metadata={
                            "channel": "#general",
                            "user": "john.doe",
                            "reactions": ["👍", "🎉"],
                            "thread_count": 5,
                        },
                        read=False,
                    )
                ]

        # Act
        plugin = MetadataPlugin()
        result = plugin.fetch()

        # Assert
        assert len(result) == 1
        metadata = result[0].metadata
        assert metadata["channel"] == "#general"
        assert metadata["user"] == "john.doe"
        assert metadata["reactions"] == ["👍", "🎉"]
        assert metadata["thread_count"] == 5

    def test_plugin_fetch_with_read_status(self):
        """Plugin fetch should support read/unread status."""
        # Arrange
        class ReadStatusPlugin(BasePlugin):
            """Plugin that returns mixed read status data."""

            def fetch(self) -> list[PluginData]:
                """Fetch plugin data."""
                timestamp = datetime.now(UTC)
                return [
                    PluginData(
                        id="read-001",
                        source="email",
                        title="Read email",
                        content="Already read",
                        timestamp=timestamp,
                        metadata={},
                        read=True,
                    ),
                    PluginData(
                        id="unread-001",
                        source="email",
                        title="Unread email",
                        content="Not yet read",
                        timestamp=timestamp,
                        metadata={},
                        read=False,
                    ),
                ]

        # Act
        plugin = ReadStatusPlugin()
        result = plugin.fetch()

        # Assert
        assert len(result) == 2
        assert result[0].read is True
        assert result[1].read is False
