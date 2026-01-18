"""Plugin system for communication dashboard."""

from src.plugins.base import BasePlugin
from src.plugins.models import PluginConfig, PluginData, ValidationResult

__all__ = ["BasePlugin", "PluginConfig", "PluginData", "ValidationResult"]
