"""Base plugin abstract interface."""

from abc import ABC, abstractmethod

from communication_dashboard.plugins.schema import PluginData, ValidationResult


class BasePlugin(ABC):
    """Abstract base class for communication plugins.

    All plugins must inherit from this class and implement the required methods.
    """

    @abstractmethod
    def fetch(self) -> list[PluginData]:
        """Fetch communication items from the source.

        Returns:
            List of PluginData instances representing fetched items.

        Raises:
            Exception: Implementation-specific exceptions on fetch failure.
        """
        ...

    @abstractmethod
    def validate_config(self) -> ValidationResult:
        """Validate plugin configuration.

        Returns:
            ValidationResult indicating whether the config is valid.
        """
        ...
