"""Plugin data models and validation."""
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, TypedDict

from pydantic import BaseModel, Field, field_validator


class ValidationResult(TypedDict):
    """Validation result structure."""
    is_valid: bool
    errors: list[str]


@dataclass
class PluginData:
    """Data structure returned by plugins."""
    id: str
    source: str
    title: str
    content: str
    timestamp: datetime
    metadata: dict[str, Any]
    read: bool = False


class PluginConfig(BaseModel):
    """Plugin configuration model."""
    name: str
    enabled: bool
    interval_minutes: int = Field(ge=1, le=1440)
    credentials: dict[str, str] | None = None
    options: dict[str, Any] = Field(default_factory=dict)

    @field_validator('interval_minutes')
    @classmethod
    def validate_interval(cls, v: int) -> int:
        """Validate interval_minutes is within acceptable range."""
        if not 1 <= v <= 1440:
            raise ValueError('interval_minutes must be between 1 and 1440')
        return v
