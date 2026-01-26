"""
Plugin exceptions module.

This module defines custom exceptions for the plugin system:
- ConfigurationError: Raised when plugin configuration is invalid
"""


class ConfigurationError(Exception):
    """Exception raised when plugin configuration is invalid."""

    pass
