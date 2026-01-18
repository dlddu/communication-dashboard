"""Base plugin interface for communication dashboard.

This module defines the abstract base class and data structures
for all communication plugins.
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass
from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field


@dataclass
class PluginData:
    """Data structure for plugin-fetched messages.

    Attributes:
        id: Unique identifier for the message
        source: Source plugin name
        title: Message title
        content: Message content/body
        timestamp: Message timestamp
        metadata: Additional metadata dictionary
        read: Whether the message has been read
    """

    id: str
    source: str
    title: str
    content: str
    timestamp: datetime
    metadata: dict[str, Any]
    read: bool


class PluginConfig(BaseModel):
    """Configuration model for plugins.

    Attributes:
        name: Plugin name
        enabled: Whether the plugin is enabled
        interval_minutes: Fetch interval in minutes (1-1440)
        credentials: Plugin credentials dictionary
        options: Additional plugin options
    """

    name: str
    enabled: bool = Field(default=True, strict=True)
    interval_minutes: int = Field(ge=1, le=1440)
    credentials: dict[str, Any] = Field(default_factory=dict)
    options: dict[str, Any] = Field(default_factory=dict)


class ValidationResult:
    """Result of a validation operation.

    Attributes:
        valid: Whether the validation passed
        errors: List of error messages if validation failed
    """

    def __init__(self, valid: bool, errors: list[str] | None = None) -> None:
        """Initialize a validation result.

        Args:
            valid: Whether the validation passed
            errors: List of error messages (defaults to empty list)
        """
        self.valid = valid
        self.errors = errors if errors is not None else []


class BasePlugin(ABC):
    """Abstract base class for all communication plugins.

    All plugins must implement the fetch method to retrieve data
    from their respective sources.
    """

    @abstractmethod
    def fetch(self) -> list[PluginData]:
        """Fetch data from the plugin source.

        Returns:
            List of PluginData objects retrieved from the source.
        """
        pass
