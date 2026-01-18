"""Data models for plugin system."""

from dataclasses import dataclass
from datetime import datetime
from typing import Any


@dataclass
class PluginData:
    """Data structure for plugin fetched data.

    Attributes:
        id: Unique identifier for the data item
        source: Source name (e.g., 'slack', 'email')
        title: Title of the message/item
        content: Main content/body of the message
        timestamp: When the message was created
        metadata: Additional metadata as key-value pairs
        read: Whether the message has been read (default: False)
    """

    id: str
    source: str
    title: str
    content: str
    timestamp: datetime
    metadata: dict[str, Any]
    read: bool = False
