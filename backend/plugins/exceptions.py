"""
Custom exceptions for the plugin system.

This module defines custom exceptions used across the plugin system
for handling configuration errors, API errors, and other plugin-related issues.
"""


class ConfigurationError(Exception):
    """
    Exception raised when plugin configuration is invalid.

    This exception is raised when:
    - Required configuration fields are missing
    - Configuration values are invalid (e.g., invalid token format)
    - Credentials validation fails
    """

    pass
