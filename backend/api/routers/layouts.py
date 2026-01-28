"""
Layouts API router.

This module defines all API endpoints related to dashboard layout persistence.
"""

from fastapi import APIRouter, HTTPException

from backend.api.schemas import ErrorResponse, LayoutResponse, LayoutSaveRequest
from backend.database.layout_repository import LayoutRepository

router = APIRouter(prefix="/api", tags=["layouts"])

# Create a global repository instance (will be :memory: for tests)
layout_repo = LayoutRepository(":memory:")


@router.get(
    "/layouts",
    response_model=LayoutResponse,
    summary="Get saved layout",
    description="Returns the currently saved dashboard layout configuration.",
)
def get_layout() -> LayoutResponse:
    """
    Get the saved dashboard layout.

    Returns:
        LayoutResponse with layout configuration and metadata.
    """
    data = layout_repo.get_layout()
    return LayoutResponse(**data)


@router.post(
    "/layouts",
    response_model=LayoutResponse,
    summary="Save dashboard layout",
    description="Save the current dashboard layout configuration.",
    responses={
        422: {"model": ErrorResponse, "description": "Invalid layout data"},
    },
)
def save_layout(request: LayoutSaveRequest) -> LayoutResponse:
    """
    Save a new dashboard layout.

    Args:
        request: LayoutSaveRequest with layout configuration.

    Returns:
        LayoutResponse with saved layout and metadata.

    Raises:
        HTTPException: 422 if layout data is invalid.
    """
    try:
        # Convert layout to dict for storage
        layout_dict = request.layout.model_dump()
        result = layout_repo.save_layout(layout_dict)
        return LayoutResponse(**result)
    except Exception as e:
        raise HTTPException(
            status_code=422,
            detail=f"Failed to save layout: {str(e)}",
        ) from e
