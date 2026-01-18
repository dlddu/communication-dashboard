"""Base plugin interface."""

from abc import ABC, abstractmethod

from communication_dashboard.plugins.config import ValidationResult
from communication_dashboard.plugins.models import PluginData


class BasePlugin(ABC):
    """Abstract base class for all plugins.

    Plugins must implement the fetch() and validate_config() methods.
    """

    @abstractmethod
    def fetch(self) -> list[PluginData]:
        """Fetch data from the plugin source.

        Returns:
            List of PluginData objects

        Raises:
            NotImplementedError: If not implemented by subclass
        """
        ...

    @abstractmethod
    def validate_config(self) -> ValidationResult:
        """Validate the plugin configuration.

        Returns:
            ValidationResult indicating success or failure

        Raises:
            NotImplementedError: If not implemented by subclass
        """
        ...
