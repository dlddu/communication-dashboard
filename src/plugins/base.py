"""Base plugin classes and data structures.

This module provides the foundation for the plugin system, including:
- BasePlugin ABC for implementing custom plugins
- PluginData dataclass for representing fetched data
- PluginConfig Pydantic model for plugin configuration
- ValidationResult TypedDict for validation results
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass
from datetime import datetime
from typing import Any, TypedDict

from pydantic import BaseModel, Field


class ValidationResult(TypedDict):
    """Validation result structure.

    Attributes:
        valid: Whether the validation passed
        errors: List of validation error messages
    """

    valid: bool
    errors: list[str]


@dataclass(frozen=True)
class PluginData:
    """Immutable data structure for plugin-fetched data.

    Attributes:
        id: Unique identifier for the data item
        source: Source plugin name
        title: Title or summary of the data
        content: Main content of the data
        timestamp: When the data was created/fetched
        metadata: Additional arbitrary metadata
        read: Whether the data has been read (default: False)
    """

    id: str
    source: str
    title: str
    content: str
    timestamp: datetime
    metadata: dict[str, Any]
    read: bool = False


class PluginConfig(BaseModel):
    """Configuration model for plugins with validation.

    Attributes:
        name: Plugin name (required)
        enabled: Whether the plugin is enabled (default: True)
        interval_minutes: Fetch interval in minutes, must be 1-1440 (required)
        credentials: Dictionary of credential key-value pairs (default: empty)
        options: Dictionary of plugin-specific options (default: empty)
    """

    name: str
    enabled: bool = True
    interval_minutes: int = Field(ge=1, le=1440)
    credentials: dict[str, str] = Field(default_factory=dict)
    options: dict[str, Any] = Field(default_factory=dict)


class BasePlugin(ABC):
    """Abstract base class for all plugins.

    All plugins must implement the fetch() and validate_config() methods.
    """

    @abstractmethod
    def fetch(self) -> list[PluginData]:
        """Fetch data from the plugin source.

        Returns:
            List of PluginData objects representing fetched data
        """
        pass

    @abstractmethod
    def validate_config(self, config: PluginConfig) -> ValidationResult:
        """Validate plugin-specific configuration.

        Args:
            config: The plugin configuration to validate

        Returns:
            ValidationResult with valid status and any error messages
        """
        pass
