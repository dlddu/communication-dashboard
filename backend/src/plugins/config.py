"""Plugin configuration models and validation."""

from typing import Any, TypedDict

from pydantic import BaseModel, Field, field_validator


class ValidationResult(TypedDict):
    """Result of a validation operation.

    Attributes:
        valid: Whether the validation passed
        errors: List of error messages (empty if valid)
    """

    valid: bool
    errors: list[str]


class PluginConfig(BaseModel):
    """Configuration for a plugin.

    Attributes:
        name: Plugin name (must not be empty)
        enabled: Whether the plugin is enabled
        interval_minutes: Fetch interval in minutes (1-1440)
        credentials: Plugin credentials as key-value pairs
        options: Plugin options as key-value pairs
    """

    name: str = Field(..., min_length=1)
    enabled: bool = Field(..., strict=True)
    interval_minutes: int = Field(..., ge=1, le=1440, strict=True)
    credentials: dict[str, Any] = Field(default_factory=dict)
    options: dict[str, Any] = Field(default_factory=dict)

    @field_validator("name")
    @classmethod
    def validate_name_not_empty(cls, v: str) -> str:
        """Validate that name is not empty."""
        if not v or not v.strip():
            raise ValueError("name cannot be empty")
        return v
