"""
Plugin system module.

This module provides the core plugin system components:
- BasePlugin: Abstract base class for plugins
- PluginConfig: Configuration model for plugins
- PluginData: Data structure for plugin-fetched data
- ValidationResult: Validation result type
"""

from .base import BasePlugin
from .schemas import PluginConfig, PluginData, ValidationResult

__all__ = ["BasePlugin", "PluginConfig", "PluginData", "ValidationResult"]
