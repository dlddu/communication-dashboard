"""Plugin system public interface."""

from communication_dashboard.plugins.base import BasePlugin
from communication_dashboard.plugins.schema import (
    PluginConfig,
    PluginData,
    ValidationResult,
)

__all__ = [
    "BasePlugin",
    "PluginConfig",
    "PluginData",
    "ValidationResult",
]
