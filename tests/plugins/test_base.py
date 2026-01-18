"""Tests for BasePlugin abstract base class."""

from abc import ABC
from datetime import UTC, datetime
from typing import get_type_hints

import pytest

from src.plugins.base import BasePlugin
from src.plugins.models import PluginData


class TestBasePlugin:
    """Test suite for BasePlugin abstract class."""

    def test_plugin_is_abstract_base_class(self) -> None:
        """Test that BasePlugin is an abstract base class."""
        assert issubclass(BasePlugin, ABC)
        assert hasattr(BasePlugin, "__abstractmethods__")
        assert "fetch" in BasePlugin.__abstractmethods__

    def test_plugin_must_implement_fetch(self) -> None:
        """Test that a plugin without fetch method cannot be instantiated.

        This is a key requirement: any plugin that doesn't implement the fetch
        method should raise TypeError when trying to instantiate it.
        """

        class IncompletePlugin(BasePlugin):
            """Plugin without fetch method implementation."""

        with pytest.raises(
            TypeError,
            match=r"Can't instantiate abstract class IncompletePlugin.*abstract method.*fetch",
        ):
            IncompletePlugin()

    def test_plugin_fetch_returns_plugin_data_list(self) -> None:
        """Test that fetch method returns a list of PluginData.

        This validates that a properly implemented plugin returns the correct
        type from the fetch method.
        """

        class ValidPlugin(BasePlugin):
            """Minimal valid plugin implementation."""

            def fetch(self) -> list[PluginData]:
                """Return sample plugin data."""
                return [
                    PluginData(
                        id="test-1",
                        source="test-plugin",
                        title="Test Item",
                        content="Test content",
                        timestamp=datetime.now(UTC),
                        metadata={},
                        read=False,
                    )
                ]

        plugin = ValidPlugin()
        result = plugin.fetch()

        assert isinstance(result, list)
        assert len(result) == 1
        assert isinstance(result[0], PluginData)
        assert result[0].id == "test-1"
        assert result[0].source == "test-plugin"
        assert result[0].title == "Test Item"
        assert result[0].read is False

    def test_plugin_can_return_empty_list(self) -> None:
        """Test that fetch can return an empty list when no data is available."""

        class EmptyPlugin(BasePlugin):
            """Plugin that returns no data."""

            def fetch(self) -> list[PluginData]:
                """Return empty list."""
                return []

        plugin = EmptyPlugin()
        result = plugin.fetch()

        assert isinstance(result, list)
        assert len(result) == 0

    def test_plugin_fetch_return_type_is_enforced(self) -> None:
        """Test that type hints are properly defined on fetch method."""
        # This test validates the type signature exists
        # Get type hints from the abstract method
        hints = get_type_hints(BasePlugin.fetch)
        assert "return" in hints
        # The return type should be list[PluginData]
        assert hasattr(hints["return"], "__origin__")
