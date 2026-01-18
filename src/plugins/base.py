"""Base plugin abstract class."""

from abc import ABC, abstractmethod

from src.plugins.models import PluginData


class BasePlugin(ABC):
    """Abstract base class for all communication plugins.

    All plugins must inherit from this class and implement the fetch method.
    The fetch method should return a list of PluginData objects representing
    the items fetched from the communication source.
    """

    @abstractmethod
    def fetch(self) -> list[PluginData]:
        """Fetch data from the communication source.

        Returns:
            A list of PluginData objects.

        Raises:
            NotImplementedError: This method must be implemented by subclasses.
        """
        ...
