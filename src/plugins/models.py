"""Data models for plugin system."""

from datetime import datetime
from typing import Any, TypedDict

from pydantic import BaseModel, Field, field_validator


class PluginData(BaseModel):
    """Data structure for items fetched by plugins.

    Attributes:
        id: Unique identifier for the item
        source: Name of the source plugin
        title: Title or subject of the item
        content: Main content or body of the item
        timestamp: When the item was created or received
        metadata: Additional metadata as key-value pairs
        read: Whether the item has been marked as read
    """

    id: str
    source: str
    title: str
    content: str
    timestamp: datetime
    metadata: dict[str, Any] = Field(default_factory=dict)
    read: bool = False

    model_config = {"frozen": False, "validate_assignment": True}


class PluginConfig(BaseModel):
    """Configuration model for plugins.

    Attributes:
        name: Name of the plugin (must not be empty or whitespace-only)
        enabled: Whether the plugin is enabled
        interval_minutes: Fetch interval in minutes (1-1440, i.e., 1 min to 24 hours)
        credentials: Plugin-specific credentials as key-value pairs
        options: Plugin-specific options as key-value pairs
    """

    name: str
    enabled: bool = True
    interval_minutes: int = Field(ge=1, le=1440)
    credentials: dict[str, Any] = Field(default_factory=dict)
    options: dict[str, Any] = Field(default_factory=dict)

    model_config = {"frozen": False, "validate_assignment": True}

    @field_validator("name")
    @classmethod
    def validate_name_not_empty(cls, v: str) -> str:
        """Validate that name is not empty or whitespace-only."""
        if not v or not v.strip():
            msg = "Name cannot be empty or whitespace-only"
            raise ValueError(msg)
        return v


class ValidationResult(TypedDict):
    """Result of a validation operation.

    Attributes:
        valid: Whether the validation passed
        errors: List of error messages if validation failed
    """

    valid: bool
    errors: list[str]
