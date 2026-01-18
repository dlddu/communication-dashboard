"""Base plugin interface and abstract classes."""

from abc import ABC, abstractmethod
from typing import Any

from plugins.config import PluginConfig
from plugins.models import PluginData


class BasePlugin(ABC):
    """Abstract base class for all plugins.

    All plugins must inherit from this class and implement
    the required abstract methods.
    """

    @abstractmethod
    async def fetch(self) -> list[PluginData]:
        """Fetch data from the plugin source.

        Returns:
            List of PluginData objects containing fetched messages/items.

        Raises:
            NotImplementedError: If the method is not implemented.
        """
        ...

    @abstractmethod
    def validate_config(self, config: PluginConfig) -> dict[str, Any]:
        """Validate the plugin configuration.

        Args:
            config: PluginConfig object to validate.

        Returns:
            ValidationResult dictionary with validation status and details.

        Raises:
            NotImplementedError: If the method is not implemented.
        """
        ...
