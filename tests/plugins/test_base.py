"""Tests for BasePlugin abstract base class.

This module tests the BasePlugin ABC which defines the interface
that all communication plugins must implement.
"""

from datetime import UTC, datetime

import pytest

from communication_dashboard.plugins.base import BasePlugin
from communication_dashboard.plugins.models import PluginConfig, PluginData


class TestBasePlugin:
    """Tests for BasePlugin abstract base class."""

    def test_plugin_must_implement_fetch(self) -> None:
        """BasePlugin subclass must implement fetch method."""
        # Arrange
        class IncompletePlugin(BasePlugin):
            """Plugin without fetch implementation."""

            pass

        # Act & Assert
        # Cannot instantiate ABC without implementing abstract method
        with pytest.raises(TypeError) as exc_info:
            IncompletePlugin()

        # Verify error message mentions fetch method
        assert "fetch" in str(exc_info.value).lower()

    def test_plugin_fetch_returns_plugin_data_list(self) -> None:
        """fetch method should return list of PluginData."""
        # Arrange
        class TestPlugin(BasePlugin):
            """Concrete plugin implementation for testing."""

            def fetch(self) -> list[PluginData]:
                """Fetch test data."""
                return [
                    PluginData(
                        id="test-1",
                        source="test",
                        title="Test Item 1",
                        content="Content 1",
                        timestamp=datetime.now(UTC),
                        metadata={},
                    ),
                    PluginData(
                        id="test-2",
                        source="test",
                        title="Test Item 2",
                        content="Content 2",
                        timestamp=datetime.now(UTC),
                        metadata={},
                    ),
                ]

        # Act
        plugin = TestPlugin()
        result = plugin.fetch()

        # Assert
        assert isinstance(result, list)
        assert len(result) == 2
        assert all(isinstance(item, PluginData) for item in result)
        assert result[0].id == "test-1"
        assert result[1].id == "test-2"

    def test_plugin_fetch_can_return_empty_list(self) -> None:
        """fetch method should be able to return empty list."""
        # Arrange
        class EmptyPlugin(BasePlugin):
            """Plugin that returns no data."""

            def fetch(self) -> list[PluginData]:
                """Return empty list."""
                return []

        # Act
        plugin = EmptyPlugin()
        result = plugin.fetch()

        # Assert
        assert isinstance(result, list)
        assert len(result) == 0

    def test_plugin_instantiation_with_config(self) -> None:
        """BasePlugin subclass can be instantiated (tests it's abstract)."""
        # Arrange
        class ConfigurablePlugin(BasePlugin):
            """Plugin with configuration."""

            def __init__(self, config: PluginConfig) -> None:
                """Initialize with config."""
                self.config = config

            def fetch(self) -> list[PluginData]:
                """Fetch data based on config."""
                if not self.config.enabled:
                    return []
                return [
                    PluginData(
                        id=f"{self.config.name}-1",
                        source=self.config.name,
                        title="Test",
                        content="Content",
                        timestamp=datetime.now(UTC),
                        metadata=self.config.options,
                    )
                ]

        config = PluginConfig(
            name="test_plugin",
            enabled=True,
            interval_minutes=30,
            credentials={},
            options={"test_option": "value"},
        )

        # Act
        plugin = ConfigurablePlugin(config)
        result = plugin.fetch()

        # Assert
        assert plugin.config == config
        assert len(result) == 1
        assert result[0].source == "test_plugin"
        assert result[0].metadata == {"test_option": "value"}

    def test_plugin_with_disabled_config_returns_empty(self) -> None:
        """Plugin with disabled config should handle gracefully."""
        # Arrange
        class ConditionalPlugin(BasePlugin):
            """Plugin that checks enabled status."""

            def __init__(self, config: PluginConfig) -> None:
                """Initialize with config."""
                self.config = config

            def fetch(self) -> list[PluginData]:
                """Return empty if disabled."""
                if not self.config.enabled:
                    return []
                return [
                    PluginData(
                        id="item-1",
                        source="test",
                        title="Item",
                        content="Content",
                        timestamp=datetime.now(UTC),
                        metadata={},
                    )
                ]

        disabled_config = PluginConfig(
            name="disabled",
            enabled=False,
            interval_minutes=60,
            credentials={},
            options={},
        )

        # Act
        plugin = ConditionalPlugin(disabled_config)
        result = plugin.fetch()

        # Assert
        assert result == []
