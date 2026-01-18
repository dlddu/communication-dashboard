"""Data models for the plugin system.

This module defines the data structures used throughout the plugin system:
- PluginData: Dataclass for storing communication items
- PluginConfig: Pydantic model for plugin configuration with validation
- ValidationResult: Type alias for validation results
"""

from dataclasses import dataclass
from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field


@dataclass
class PluginData:
    """Data structure for a communication item from a plugin.

    Attributes:
        id: Unique identifier for the communication item
        source: Source plugin name (e.g., 'email', 'slack', 'teams')
        title: Title or subject of the communication
        content: Main content/body of the communication
        timestamp: When the communication was created/received
        metadata: Additional metadata as key-value pairs
        read: Whether the item has been read (defaults to False)
    """

    id: str
    source: str
    title: str
    content: str
    timestamp: datetime
    metadata: dict[str, Any]
    read: bool = False


class PluginConfig(BaseModel):
    """Configuration model for a plugin with validation.

    Attributes:
        name: Plugin name (unique identifier)
        enabled: Whether the plugin is currently enabled
        interval_minutes: Fetch interval in minutes (1-1440, i.e., 1 min to 24 hours)
        credentials: Plugin-specific credentials (API keys, tokens, etc.)
        options: Additional plugin-specific configuration options
    """

    name: str
    enabled: bool
    interval_minutes: int = Field(ge=1, le=1440)
    credentials: dict[str, Any]
    options: dict[str, Any]


# Type alias for validation results
ValidationResult = tuple[bool, str | None]
"""Validation result tuple: (is_valid, error_message)."""
