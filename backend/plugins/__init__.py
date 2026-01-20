"""
Plugin system module.

This module provides the core plugin system components:
- BasePlugin: Abstract base class for plugins
- PluginConfig: Configuration model for plugins
- PluginData: Data structure for plugin-fetched data
- ValidationResult: Validation result type
- MockPlugin: Mock plugin for testing
"""

from .base import BasePlugin
from .mock_plugin import MockPlugin
from .schemas import PluginConfig, PluginData, ValidationResult

__all__ = ["BasePlugin", "MockPlugin", "PluginConfig", "PluginData", "ValidationResult"]
