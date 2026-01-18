"""Plugin data schemas and validation models."""

from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, NotRequired, TypedDict

from pydantic import BaseModel, Field, field_validator


@dataclass(frozen=True)
class PluginData:
    """Immutable data structure for plugin messages."""

    id: str
    source: str
    title: str
    content: str
    timestamp: datetime
    metadata: dict[str, Any] = field(default_factory=dict)
    read: bool = False


class PluginConfig(BaseModel):
    """Configuration model for plugins."""

    name: str
    enabled: bool = True
    interval_minutes: int = 60
    credentials: dict[str, Any] = Field(default_factory=dict)
    options: dict[str, Any] = Field(default_factory=dict)

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str) -> str:
        """Validate that name is not empty."""
        if not v or not v.strip():
            raise ValueError("name cannot be empty")
        return v

    @field_validator("interval_minutes")
    @classmethod
    def validate_interval(cls, v: int) -> int:
        """Validate interval_minutes is between 1 and 1440."""
        if v < 1 or v > 1440:
            raise ValueError("interval_minutes must be between 1 and 1440")
        return v


class ValidationResult(TypedDict):
    """Type definition for validation results."""

    valid: bool
    errors: list[str]
    warnings: NotRequired[list[str]]
