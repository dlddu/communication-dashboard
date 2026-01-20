"""
Mock plugin for testing purposes.

This module provides a MockPlugin implementation that generates dummy data
for testing the plugin system. It supports error simulation and respects
the enabled flag.
"""

from datetime import datetime, timezone

from .base import BasePlugin
from .schemas import PluginData


class MockPlugin(BasePlugin):
    """
    Mock plugin that generates dummy data for testing.

    This plugin creates test data and supports:
    - Enabled/disabled state via config.enabled
    - Error simulation via config.options['simulate_error']
    - Configurable number of items via config.options['item_count']

    The plugin generates 1-5 dummy PluginData items by default, or the number
    specified in options['item_count'].

    Example:
        >>> config = PluginConfig(name="mock", enabled=True, interval_minutes=60)
        >>> plugin = MockPlugin(config)
        >>> data = plugin.fetch()
        >>> len(data) > 0
        True
    """

    def fetch(self) -> list[PluginData]:
        """
        Fetch mock data from the plugin.

        Returns empty list if plugin is disabled.
        Raises RuntimeError if simulate_error option is True.

        Returns:
            List of PluginData instances with dummy data.

        Raises:
            RuntimeError: If simulate_error option is enabled.
        """
        # Check if plugin is enabled
        if not self.config.enabled:
            return []

        # Check for error simulation
        options = self.config.options or {}
        if options.get("simulate_error", False):
            raise RuntimeError("Simulated error for testing")

        # Get item count from options or use default
        item_count = options.get("item_count", 3)

        # Generate dummy data
        items: list[PluginData] = []
        base_timestamp = datetime.now(timezone.utc)

        for i in range(item_count):
            data = PluginData(
                id=f"mock-{i + 1}",
                source=self.config.name,
                title=f"Mock Item {i + 1}",
                content=f"This is mock content for item {i + 1}",
                timestamp=base_timestamp,
                metadata={"index": i + 1, "plugin": "mock"},
                read=False,
            )
            items.append(data)

        return items
