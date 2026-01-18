"""Base plugin interface for communication dashboard.

This module defines the abstract base class that all communication plugins
must implement to integrate with the dashboard system.
"""

from abc import ABC, abstractmethod

from communication_dashboard.plugins.models import PluginData


class BasePlugin(ABC):
    """Abstract base class for all communication plugins.

    All plugins must inherit from this class and implement the fetch method
    to retrieve communication data from their respective sources.
    """

    @abstractmethod
    def fetch(self) -> list[PluginData]:
        """Fetch communication data from the plugin source.

        Returns:
            List of PluginData objects containing the fetched communication items.
            Can return an empty list if no data is available.

        Raises:
            NotImplementedError: If the method is not implemented by a subclass.
        """
        raise NotImplementedError("Subclasses must implement fetch method")
