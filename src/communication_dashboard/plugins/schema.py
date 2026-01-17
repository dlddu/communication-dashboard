"""Plugin data schemas and configuration models."""

from dataclasses import dataclass
from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field


@dataclass
class PluginData:
    """Data structure for plugin output items.

    Represents a single communication item fetched by a plugin.
    """

    id: str
    source: str
    title: str
    content: str
    timestamp: datetime
    metadata: dict[str, Any]
    read: bool


@dataclass
class ValidationResult:
    """Result of configuration validation.

    Attributes:
        valid: Whether the configuration is valid.
        errors: List of error messages if invalid, None or empty list if valid.
    """

    valid: bool
    errors: list[str] | None = None


class PluginConfig(BaseModel):
    """Configuration model for plugins with validation.

    Attributes:
        name: Plugin name identifier.
        enabled: Whether the plugin is enabled.
        interval_minutes: Fetch interval in minutes (1-1440).
        credentials: Plugin-specific credentials dictionary.
        options: Additional plugin options dictionary.
    """

    name: str
    enabled: bool
    interval_minutes: int = Field(..., ge=1, le=1440)
    credentials: dict[str, Any]
    options: dict[str, Any]
