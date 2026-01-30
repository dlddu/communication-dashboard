"""
API Pydantic models for request/response validation.

This module defines all API-specific schemas used for request validation
and response serialization in the FastAPI application.
"""

from datetime import datetime
from typing import Any, Optional

from pydantic import BaseModel, ConfigDict, Field


class PluginInfo(BaseModel):
    """
    Plugin information for list endpoint.

    Attributes:
        name: Plugin name/identifier.
        count: Number of data items for this plugin.
        last_updated: Most recent update timestamp (None if no data).
    """

    model_config = ConfigDict(strict=True)

    name: str
    count: int
    last_updated: Optional[datetime] = None


class PluginDataResponse(BaseModel):
    """
    Response model for plugin data serialization.

    Attributes:
        id: Unique identifier for the data item.
        source: Source plugin name.
        title: Title of the data item.
        content: Main content of the data item.
        timestamp: When the data was created/received.
        metadata: Additional metadata as key-value pairs.
        read: Whether the data has been read.
    """

    model_config = ConfigDict(strict=True)

    id: str
    source: str
    title: str
    content: str
    timestamp: datetime
    metadata: dict[str, Any] = Field(default_factory=dict)
    read: bool = False


class RefreshResult(BaseModel):
    """
    Result of plugin refresh operation.

    Attributes:
        success: Whether the refresh was successful.
        message: Human-readable message about the result.
        data_count: Number of data items fetched (None if failed).
    """

    model_config = ConfigDict(strict=True)

    success: bool
    message: str
    data_count: Optional[int] = None


class ErrorResponse(BaseModel):
    """
    Standard error response model.

    Attributes:
        detail: Error message or details.
    """

    model_config = ConfigDict(strict=True)

    detail: str


class LayoutData(BaseModel):
    """
    Layout configuration data model.

    Attributes:
        user_id: User identifier for the layout.
        layouts: Layout configuration as a nested dictionary.
        timestamp: When the layout was last saved.
    """

    model_config = ConfigDict(strict=True)

    user_id: str
    layouts: dict[str, Any]
    timestamp: int


class LayoutResponse(BaseModel):
    """
    Response model for layout retrieval.

    Returns the layouts configuration directly.
    """

    model_config = ConfigDict(strict=True, extra="allow")


class LayoutSaveRequest(BaseModel):
    """
    Request model for saving layout.

    Attributes:
        user_id: User identifier for the layout.
        layouts: Layout configuration as a nested dictionary.
        timestamp: When the layout was saved on client.
    """

    model_config = ConfigDict(strict=True)

    user_id: str
    layouts: dict[str, Any]
    timestamp: int


class LayoutSaveResponse(BaseModel):
    """
    Response model for layout save operation.

    Attributes:
        success: Whether the save operation was successful.
    """

    model_config = ConfigDict(strict=True)

    success: bool
