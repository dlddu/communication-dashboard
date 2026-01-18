"""Configuration models for plugin system."""

from typing import Any

from pydantic import BaseModel, Field


class PluginConfig(BaseModel):
    """Configuration for a plugin.

    Attributes:
        name: Name of the plugin
        enabled: Whether the plugin is enabled (default: True)
        interval_minutes: Fetch interval in minutes (1-1440)
        credentials: Optional credentials dictionary
        options: Additional plugin-specific options (default: {})
    """

    name: str
    enabled: bool = True
    interval_minutes: int = Field(..., ge=1, le=1440)
    credentials: dict[str, str] | None = None
    options: dict[str, Any] = {}
