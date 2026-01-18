"""
Base plugin abstract class.

This module defines the BasePlugin abstract class that all plugins must inherit from.
Plugins must implement the fetch() method to retrieve data from their respective sources.
"""

from abc import ABC, abstractmethod

from .schemas import PluginConfig, PluginData


class BasePlugin(ABC):
    """
    Abstract base class for all plugins.

    All plugin implementations must inherit from this class and implement
    the fetch() method to retrieve data from their respective sources.

    Attributes:
        config: Plugin configuration
    """

    def __init__(self, config: PluginConfig) -> None:
        """
        Initialize the plugin with configuration.

        Args:
            config: Plugin configuration
        """
        self.config = config

    @abstractmethod
    def fetch(self) -> list[PluginData]:
        """
        Fetch data from the plugin source.

        This method must be implemented by all plugin subclasses.

        Returns:
            List of PluginData instances
        """
        pass
