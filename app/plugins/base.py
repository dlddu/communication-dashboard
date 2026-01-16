"""Base plugin interface and data models for communication dashboard.

This module defines the core abstractions for the plugin system:
- BasePlugin: Abstract base class for all plugins
- PluginData: Immutable data container for plugin results
- PluginConfig: Validated configuration model for plugins
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass
from datetime import datetime
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field


@dataclass(frozen=True)
class PluginData:
    """Immutable data container for plugin results.
    
    Attributes:
        id: Unique identifier for the data item
        source: Source plugin name (e.g., 'slack', 'gmail')
        title: Human-readable title
        content: Main content/message body
        timestamp: When the data was created/received
        metadata: Additional source-specific data
        read: Whether the item has been read (default: False)
    """

    id: str
    source: str
    title: str
    content: str
    timestamp: datetime
    metadata: Dict[str, Any]
    read: bool = False


class PluginConfig(BaseModel):
    """Validated configuration for plugins.
    
    Attributes:
        name: Plugin name identifier
        enabled: Whether the plugin is active (default: True)
        interval_minutes: Fetch interval in minutes (1-1440, i.e., 1 min to 24 hours)
        credentials: Optional authentication credentials
        options: Additional plugin-specific options
    """

    name: str
    enabled: bool = True
    interval_minutes: int = Field(ge=1, le=1440)
    credentials: Optional[Dict[str, str]] = None
    options: Dict[str, Any] = Field(default_factory=dict)


class BasePlugin(ABC):
    """Abstract base class for all communication plugins.
    
    All plugins must implement the fetch() method to retrieve data
    from their respective sources.
    """

    def __init__(self, config: PluginConfig) -> None:
        """Initialize plugin with configuration.
        
        Args:
            config: Validated plugin configuration
        """
        self.config = config

    @abstractmethod
    async def fetch(self) -> List[PluginData]:
        """Fetch data from the plugin source.
        
        Returns:
            List of PluginData objects retrieved from the source
            
        Raises:
            NotImplementedError: Must be implemented by subclasses
        """
        pass

    def validate_config(self) -> bool:
        """Validate plugin configuration.
        
        Returns:
            True if configuration is valid, False otherwise
            
        Note:
            Default implementation always returns True.
            Override in subclasses for custom validation.
        """
        return True
