"""
Plugin system module.

This module provides the core plugin system components:
- BasePlugin: Abstract base class for plugins
- PluginConfig: Configuration model for plugins
- PluginData: Data structure for plugin-fetched data
- ValidationResult: Validation result type
- MockPlugin: Mock plugin for testing
- SlackPlugin: Slack integration plugin
- ConfigurationError: Exception for configuration errors
"""

from .base import BasePlugin
from .exceptions import ConfigurationError
from .mock_plugin import MockPlugin
from .schemas import PluginConfig, PluginData, ValidationResult
from .slack_plugin import SlackPlugin

__all__ = [
    "BasePlugin",
    "ConfigurationError",
    "MockPlugin",
    "PluginConfig",
    "PluginData",
    "SlackPlugin",
    "ValidationResult",
]
