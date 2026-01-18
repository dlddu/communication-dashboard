"""Plugin system for communication dashboard."""

from communication_dashboard.plugins.base import BasePlugin
from communication_dashboard.plugins.config import PluginConfig, ValidationResult
from communication_dashboard.plugins.models import PluginData

__all__ = ["BasePlugin", "PluginConfig", "PluginData", "ValidationResult"]
