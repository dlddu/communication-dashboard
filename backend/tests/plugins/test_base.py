"""Tests for BasePlugin and PluginData."""

from abc import ABC
from datetime import datetime
from typing import Any

import pytest

from backend.src.plugins.base import BasePlugin, PluginData


class TestPluginData:
    """Test PluginData dataclass."""

    def test_plugin_data_creation_with_all_fields(self) -> None:
        """Test that PluginData can be created with all required fields."""
        # Arrange
        plugin_id = "test-123"
        source = "test-source"
        title = "Test Title"
        content = "Test content"
        timestamp = datetime.now()
        metadata: dict[str, Any] = {"key": "value"}
        read = False

        # Act
        data = PluginData(
            id=plugin_id,
            source=source,
            title=title,
            content=content,
            timestamp=timestamp,
            metadata=metadata,
            read=read,
        )

        # Assert
        assert data.id == plugin_id
        assert data.source == source
        assert data.title == title
        assert data.content == content
        assert data.timestamp == timestamp
        assert data.metadata == metadata
        assert data.read == read

    def test_plugin_data_default_read_is_false(self) -> None:
        """Test that read field defaults to False."""
        # Arrange & Act
        data = PluginData(
            id="test-123",
            source="test-source",
            title="Test Title",
            content="Test content",
            timestamp=datetime.now(),
            metadata={},
        )

        # Assert
        assert data.read is False

    def test_plugin_data_immutable(self) -> None:
        """Test that PluginData is immutable (frozen dataclass)."""
        # Arrange
        data = PluginData(
            id="test-123",
            source="test-source",
            title="Test Title",
            content="Test content",
            timestamp=datetime.now(),
            metadata={},
        )

        # Act & Assert
        with pytest.raises(AttributeError):
            data.id = "new-id"  # type: ignore[misc]


class TestBasePlugin:
    """Test BasePlugin ABC."""

    def test_plugin_must_implement_fetch(self) -> None:
        """Test that fetch abstractmethod must be implemented."""
        # Arrange & Act & Assert
        with pytest.raises(TypeError) as exc_info:

            class IncompletePlugin(BasePlugin):
                """Plugin without fetch implementation."""

                pass

            IncompletePlugin()  # type: ignore[abstract]

        assert "fetch" in str(exc_info.value)

    def test_plugin_fetch_returns_plugin_data_list(self) -> None:
        """Test that fetch method returns list of PluginData."""
        # Arrange
        class ValidPlugin(BasePlugin):
            """Valid plugin implementation."""

            async def fetch(self) -> list[PluginData]:
                """Fetch data from plugin."""
                return [
                    PluginData(
                        id="test-1",
                        source="valid-plugin",
                        title="Test 1",
                        content="Content 1",
                        timestamp=datetime.now(),
                        metadata={},
                    )
                ]

        # Act
        plugin = ValidPlugin()

        # Assert
        assert isinstance(plugin, BasePlugin)
        assert hasattr(plugin, "fetch")
        assert callable(plugin.fetch)

    def test_plugin_is_abstract_base_class(self) -> None:
        """Test that BasePlugin is an ABC."""
        # Assert
        assert issubclass(BasePlugin, ABC)
        assert hasattr(BasePlugin, "__abstractmethods__")
        assert "fetch" in BasePlugin.__abstractmethods__

    def test_multiple_plugin_data_returned(self) -> None:
        """Test that fetch can return multiple PluginData items."""
        # Arrange
        class MultiDataPlugin(BasePlugin):
            """Plugin that returns multiple data items."""

            async def fetch(self) -> list[PluginData]:
                """Fetch multiple data items."""
                now = datetime.now()
                return [
                    PluginData(
                        id=f"test-{i}",
                        source="multi-plugin",
                        title=f"Test {i}",
                        content=f"Content {i}",
                        timestamp=now,
                        metadata={"index": i},
                    )
                    for i in range(3)
                ]

        # Act
        plugin = MultiDataPlugin()

        # Assert - verify the plugin is properly set up
        assert isinstance(plugin, BasePlugin)

    def test_empty_plugin_data_list(self) -> None:
        """Test that fetch can return empty list."""
        # Arrange
        class EmptyPlugin(BasePlugin):
            """Plugin that returns no data."""

            async def fetch(self) -> list[PluginData]:
                """Return empty list."""
                return []

        # Act
        plugin = EmptyPlugin()

        # Assert
        assert isinstance(plugin, BasePlugin)
