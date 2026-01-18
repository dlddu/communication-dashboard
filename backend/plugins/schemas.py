"""
Plugin data schemas and configuration models.

This module defines the core data structures for the plugin system:
- PluginData: Dataclass for plugin-fetched data
- PluginConfig: Pydantic model for plugin configuration with validation
- ValidationResult: Type for validation results
"""

from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Optional

from pydantic import BaseModel, ConfigDict, Field


@dataclass
class PluginData:
    """
    Dataclass representing data fetched by a plugin.

    Attributes:
        id: Unique identifier for the data item
        source: Source plugin name
        title: Title of the data item
        content: Main content of the data item
        timestamp: When the data was created/received
        metadata: Additional metadata as key-value pairs
        read: Whether the data has been read
    """

    id: str
    source: str
    title: str
    content: str
    timestamp: datetime
    metadata: dict[str, Any] = field(default_factory=dict)
    read: bool = False


class PluginConfig(BaseModel):
    """
    Pydantic model for plugin configuration with validation.

    Attributes:
        name: Plugin name
        enabled: Whether the plugin is enabled
        interval_minutes: Fetch interval in minutes (1-1440)
        credentials: Optional credentials dictionary
        options: Optional plugin-specific options
    """

    model_config = ConfigDict(strict=True)

    name: str
    enabled: bool = True
    interval_minutes: int = Field(ge=1, le=1440, default=60)
    credentials: Optional[dict[str, Any]] = None
    options: Optional[dict[str, Any]] = None


class ValidationResult(BaseModel):
    """
    Model for validation results.

    Attributes:
        is_valid: Whether validation passed
        errors: List of error messages if validation failed
        warnings: List of warning messages
    """

    is_valid: bool
    errors: Optional[list[str]] = None
    warnings: Optional[list[str]] = None
