"""Base plugin abstract class."""
from abc import ABC, abstractmethod

from backend.models.plugin import PluginConfig, PluginData, ValidationResult


class BasePlugin(ABC):
    """Abstract base class for all plugins."""

    def __init__(self, config: PluginConfig) -> None:
        """Initialize plugin with configuration.
        
        Args:
            config: Plugin configuration
        """
        self.config = config

    @abstractmethod
    def fetch(self) -> list[PluginData]:
        """Fetch data from the plugin source.
        
        Returns:
            List of PluginData objects
            
        Raises:
            NotImplementedError: If not implemented by subclass
        """
        raise NotImplementedError("Subclasses must implement fetch()")

    def validate_config(self) -> ValidationResult:
        """Validate plugin configuration.
        
        Returns:
            ValidationResult with is_valid and errors
        """
        errors: list[str] = []
        
        if not self.config.name:
            errors.append("Plugin name is required")
            
        if self.config.interval_minutes < 1 or self.config.interval_minutes > 1440:
            errors.append("interval_minutes must be between 1 and 1440")
            
        return ValidationResult(
            is_valid=len(errors) == 0,
            errors=errors
        )
