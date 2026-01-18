"""Base plugin abstract class and related data structures.

This module provides the foundation for all communication plugins in the dashboard.
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass
from datetime import datetime
from typing import Any

from pydantic import BaseModel, field_validator
from typing_extensions import TypedDict


class ValidationResult(TypedDict):
    """Result of configuration validation."""

    valid: bool
    errors: list[str]


@dataclass
class PluginData:
    """Data structure for plugin messages/items."""

    id: str
    source: str
    title: str
    content: str
    timestamp: datetime
    metadata: dict[str, Any]
    read: bool = False


class PluginConfig(BaseModel):
    """Configuration for a plugin."""

    name: str
    enabled: bool
    interval_minutes: int
    credentials: dict[str, str] | None = None
    options: dict[str, Any]

    @field_validator("interval_minutes")
    @classmethod
    def validate_interval_minutes(cls, v: int) -> int:
        """Validate that interval_minutes is in range 1-1440."""
        if v < 1:
            raise ValueError("Input should be greater than or equal to 1")
        if v > 1440:
            raise ValueError("Input should be less than or equal to 1440")
        return v


class BasePlugin(ABC):
    """Abstract base class for all communication plugins."""

    @abstractmethod
    def fetch(self) -> list[PluginData]:
        """Fetch data from the communication source.

        Returns:
            List of PluginData objects containing messages/items.
        """
        pass

    @abstractmethod
    def validate_config(self, config: Any) -> ValidationResult:
        """Validate plugin configuration.

        Args:
            config: Configuration to validate.

        Returns:
            ValidationResult with validation status and any errors.
        """
        pass
