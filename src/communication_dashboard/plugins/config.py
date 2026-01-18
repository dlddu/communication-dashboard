"""Configuration models for plugins."""

from typing import Any

from pydantic import BaseModel, Field


class ValidationResult(BaseModel):
    """Result of configuration validation.

    Attributes:
        success: Whether validation passed
        message: Optional message describing the result
        errors: Optional list of error messages
    """

    success: bool
    message: str | None = None
    errors: list[str] | None = None


class PluginConfig(BaseModel):
    """Configuration for plugins.

    Attributes:
        name: Plugin name (required)
        enabled: Whether the plugin is enabled (default: True)
        interval_minutes: Fetch interval in minutes (1-1440)
        credentials: Optional credentials dictionary
        options: Optional configuration options dictionary
    """

    name: str
    enabled: bool = True
    interval_minutes: int = Field(default=60, ge=1, le=1440)
    credentials: dict[str, str] | None = None
    options: dict[str, Any] | None = None
