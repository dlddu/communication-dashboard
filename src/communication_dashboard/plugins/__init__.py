"""Plugin system for communication dashboard."""

from communication_dashboard.plugins.base import BasePlugin
from communication_dashboard.plugins.schemas import (
    PluginConfig,
    PluginData,
    ValidationResult,
)

__all__ = ["BasePlugin", "PluginData", "PluginConfig", "ValidationResult"]
