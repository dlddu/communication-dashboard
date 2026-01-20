"""
Plugin system exceptions.

This module defines custom exceptions for the plugin system:
- ConfigurationError: Raised when plugin configuration is invalid
"""


class ConfigurationError(Exception):
    """
    Exception raised when plugin configuration is invalid.

    This exception is raised when a plugin's configuration fails validation,
    such as missing required credentials or invalid configuration values.

    Attributes:
        message: Error message describing the configuration problem
    """

    def __init__(self, message: str) -> None:
        """
        Initialize ConfigurationError.

        Args:
            message: Error message describing the configuration problem
        """
        self.message = message
        super().__init__(self.message)
