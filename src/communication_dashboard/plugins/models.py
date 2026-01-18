"""Data models for plugin system."""

from dataclasses import dataclass
from datetime import datetime
from typing import Any


@dataclass
class PluginData:
    """Data structure returned by plugins.

    Attributes:
        id: Unique identifier for the data item
        source: Source plugin identifier
        title: Title of the data item
        content: Main content of the data item
        timestamp: When the data was created/fetched
        metadata: Additional metadata as key-value pairs
        read: Whether the item has been read (default: False)
    """

    id: str
    source: str
    title: str
    content: str
    timestamp: datetime
    metadata: dict[str, Any]
    read: bool = False
