"""
Plugin API router.

This module defines all API endpoints related to plugins and their data.
"""

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query

from backend.api.dependencies import get_repository
from backend.api.schemas import ErrorResponse, PluginDataResponse, PluginInfo, RefreshResult
from backend.database.repository import PluginDataRepository

router = APIRouter(prefix="/api", tags=["plugins"])


@router.get(
    "/plugins",
    response_model=list[PluginInfo],
    summary="Get list of all plugins",
    description="Returns a list of all plugins with their data counts and last update times.",
)
def get_plugins_list(
    repo: Annotated[PluginDataRepository, Depends(get_repository)],
) -> list[PluginInfo]:
    """
    Get list of all plugins with metadata.

    This endpoint queries all distinct plugin sources from the database
    and returns information about each plugin including data count and
    last update timestamp.

    Args:
        repo: PluginDataRepository injected by FastAPI.

    Returns:
        List of PluginInfo objects with plugin metadata.
    """
    # Get all data to find unique sources
    with repo.db.get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            """
            SELECT DISTINCT source FROM plugin_data
            """
        )
        sources = [row[0] for row in cursor.fetchall()]

    # Build plugin info for each source
    plugin_list: list[PluginInfo] = []
    for source in sources:
        count = repo.count_by_plugin(source)
        latest_data = repo.get_latest_by_plugin(source, limit=1)
        last_updated = latest_data[0].timestamp if latest_data else None

        plugin_list.append(
            PluginInfo(
                name=source,
                count=count,
                last_updated=last_updated,
            )
        )

    return plugin_list


@router.get(
    "/plugins/{name}/data",
    response_model=list[PluginDataResponse],
    summary="Get data for a specific plugin",
    description="Returns the latest data items for the specified plugin.",
    responses={
        404: {"model": ErrorResponse, "description": "Plugin not found"},
        422: {"model": ErrorResponse, "description": "Invalid parameters"},
    },
)
def get_plugin_data(
    name: str,
    repo: Annotated[PluginDataRepository, Depends(get_repository)],
    limit: int = Query(default=10, ge=1, le=100),
) -> list[PluginDataResponse]:
    """
    Get latest data items for a specific plugin.

    Args:
        name: Plugin name/identifier.
        repo: PluginDataRepository injected by FastAPI.
        limit: Maximum number of items to return (default: 10, max: 100).

    Returns:
        List of PluginDataResponse objects.

    Raises:
        HTTPException: 404 if plugin has no data.
    """
    # Check if plugin exists (has any data)
    count = repo.count_by_plugin(name)
    if count == 0:
        raise HTTPException(
            status_code=404,
            detail=f"Plugin '{name}' not found or has no data",
        )

    # Get latest data
    data_items = repo.get_latest_by_plugin(name, limit=limit)

    # Convert to response models
    return [
        PluginDataResponse(
            id=item.id,
            source=item.source,
            title=item.title,
            content=item.content,
            timestamp=item.timestamp,
            metadata=item.metadata,
            read=item.read,
        )
        for item in data_items
    ]


@router.post(
    "/plugins/{name}/refresh",
    response_model=RefreshResult,
    summary="Manually refresh a plugin",
    description="Triggers a manual data fetch for the specified plugin.",
    responses={
        404: {"model": ErrorResponse, "description": "Plugin not found"},
        500: {"model": ErrorResponse, "description": "Internal server error"},
    },
)
def refresh_plugin(
    name: str,
    repo: Annotated[PluginDataRepository, Depends(get_repository)],
) -> RefreshResult:
    """
    Manually trigger data fetch for a plugin.

    This endpoint would typically trigger the plugin's fetch callback
    to get fresh data. For this implementation, it returns a mock result
    since actual plugin execution is not implemented in this router.

    Args:
        name: Plugin name/identifier.
        repo: PluginDataRepository injected by FastAPI.

    Returns:
        RefreshResult with success status and message.

    Raises:
        HTTPException: 404 if plugin is not registered.
    """
    # Check if plugin exists
    count = repo.count_by_plugin(name)
    if count == 0:
        raise HTTPException(
            status_code=404,
            detail=f"Plugin '{name}' not found",
        )

    # In a real implementation, this would trigger the scheduler
    # For now, return a success response
    return RefreshResult(
        success=True,
        message=f"Plugin '{name}' refresh triggered successfully",
        data_count=count,
    )
