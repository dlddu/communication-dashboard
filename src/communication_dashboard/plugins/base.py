"""Base plugin abstract class."""

from abc import ABC, abstractmethod

from communication_dashboard.plugins.schemas import PluginConfig, PluginData


class BasePlugin(ABC):
    """Abstract base class for communication plugins."""

    def __init__(self, config: PluginConfig | None = None) -> None:
        """Initialize the plugin with optional config.

        Args:
            config: Optional plugin configuration.
        """
        self._config = config

    @property
    def config(self) -> PluginConfig | None:
        """Get the plugin configuration."""
        return self._config

    @abstractmethod
    def fetch(self) -> list[PluginData]:
        """Fetch data from the communication source.

        Returns:
            List of PluginData objects.
        """
        pass
