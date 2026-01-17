"""Base plugin interface and data models."""

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any


@dataclass(frozen=True)
class PluginData:
    """Data returned by plugins.

    Attributes:
        id: Unique identifier for the data item
        source: Source plugin identifier
        title: Title of the data item
        content: Content of the data item
        timestamp: When the data was created/fetched
        metadata: Additional metadata as key-value pairs
        read: Whether the data has been read (defaults to False)
    """

    id: str
    source: str
    title: str
    content: str
    timestamp: datetime
    metadata: dict[str, Any]
    read: bool = field(default=False)


class BasePlugin(ABC):
    """Abstract base class for all plugins.

    All plugins must inherit from this class and implement the fetch method.
    """

    @abstractmethod
    async def fetch(self) -> list[PluginData]:
        """Fetch data from the plugin source.

        Returns:
            A list of PluginData objects containing the fetched data.
        """
        ...
