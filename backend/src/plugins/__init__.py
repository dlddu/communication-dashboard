"""Plugin system for communication dashboard."""

from plugins.base import BasePlugin
from plugins.config import PluginConfig
from plugins.models import PluginData
from plugins.types import ValidationResult

__all__ = ["BasePlugin", "PluginConfig", "PluginData", "ValidationResult"]
