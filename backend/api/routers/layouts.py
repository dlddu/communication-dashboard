"""
Layouts API router.

This module defines all API endpoints related to layout persistence.
"""

from typing import Annotated, Any

from fastapi import APIRouter, Depends, Query

from backend.api.schemas import LayoutSaveRequest, LayoutSaveResponse
from backend.database.connection import DatabaseConnection
from backend.database.repository import LayoutRepository

from ..dependencies import get_db

router = APIRouter(prefix="/api", tags=["layouts"])


def get_layout_repository(
    db: Annotated[DatabaseConnection, Depends(get_db)],
) -> LayoutRepository:
    """
    Get layout repository dependency.

    Args:
        db: DatabaseConnection injected by FastAPI.

    Returns:
        Repository instance for layout operations.
    """
    return LayoutRepository(db)


@router.get(
    "/layouts",
    response_model=dict[str, Any],
    summary="Get user layout",
    description="Returns the saved layout configuration for a specific user.",
)
def get_layout(
    user_id: Annotated[str, Query(..., description="User ID to retrieve layout for")],
    repo: Annotated[LayoutRepository, Depends(get_layout_repository)],
) -> dict[str, Any]:
    """
    Get saved layout for a user.

    Args:
        user_id: User identifier from query parameter.
        repo: LayoutRepository injected by FastAPI.

    Returns:
        Layout configuration dictionary, or empty dict if not found.
    """
    layout_data = repo.get_layout(user_id)

    if layout_data is None:
        return {}

    return layout_data.layouts


@router.post(
    "/layouts",
    response_model=LayoutSaveResponse,
    summary="Save user layout",
    description="Saves the layout configuration for a specific user.",
)
def save_layout(
    request: LayoutSaveRequest,
    repo: Annotated[LayoutRepository, Depends(get_layout_repository)],
) -> LayoutSaveResponse:
    """
    Save layout configuration for a user.

    Args:
        request: Layout save request with user_id, layouts, and timestamp.
        repo: LayoutRepository injected by FastAPI.

    Returns:
        Success response indicating layout was saved.
    """
    repo.save_layout(
        user_id=request.user_id,
        layouts=request.layouts,
        timestamp=request.timestamp,
    )

    return LayoutSaveResponse(success=True)
