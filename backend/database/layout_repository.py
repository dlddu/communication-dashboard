"""
Layout repository for persisting dashboard layouts.

This module provides the LayoutRepository class for saving and loading
dashboard layouts using JSON file storage.
"""

import json
from datetime import datetime
from pathlib import Path
from typing import Any, Optional


class LayoutRepository:
    """
    Repository for layout persistence using JSON file storage.

    Attributes:
        storage_path: Path to the JSON file for storing layouts.
    """

    def __init__(self, storage_path: str = "data/layouts.json") -> None:
        """
        Initialize the layout repository.

        Args:
            storage_path: Path to JSON file for storing layouts.
        """
        self.storage_path = Path(storage_path)

        # Only create directories if storage_path is not :memory:
        if storage_path != ":memory:":
            self.storage_path.parent.mkdir(parents=True, exist_ok=True)
            # Initialize empty layout file if it doesn't exist
            if not self.storage_path.exists():
                self._write_empty_layout()

        # For :memory: storage, use in-memory dict
        self._memory_storage: Optional[dict[str, Any]] = None
        if storage_path == ":memory:":
            self._memory_storage = self._get_empty_layout()

    def _write_empty_layout(self) -> None:
        """Write an empty layout structure to the storage file."""
        empty_data: dict[str, Any] = {
            "layout": {
                "lg": [],
                "md": [],
                "sm": [],
            },
            "last_updated": None,
        }
        with open(self.storage_path, "w") as f:
            json.dump(empty_data, f, indent=2)

    def save_layout(self, layout_data: dict[str, Any]) -> dict[str, Any]:
        """
        Save layout to storage.

        Args:
            layout_data: Dictionary containing layout configuration.

        Returns:
            Dictionary with layout and metadata.
        """
        timestamp = datetime.utcnow()
        timestamp_str = timestamp.isoformat()
        data_to_save = {
            "layout": layout_data,
            "last_updated": timestamp_str,
        }

        # Use memory storage if configured
        if self._memory_storage is not None:
            self._memory_storage = data_to_save
        else:
            with open(self.storage_path, "w") as f:
                json.dump(data_to_save, f, indent=2)

        return {
            "layout": layout_data,
            "last_updated": timestamp,
            "timestamp": timestamp,
            "success": True,
        }

    def get_layout(self) -> dict[str, Any]:
        """
        Retrieve the saved layout.

        Returns:
            Dictionary containing layout and metadata.
        """
        try:
            # Use memory storage if configured
            if self._memory_storage is not None:
                data = self._memory_storage
            else:
                with open(self.storage_path) as f:
                    data = json.load(f)

            # Ensure layout has the required structure
            if "layout" not in data:
                return self._get_empty_layout()

            layout = data["layout"]
            if not isinstance(layout, dict):
                return self._get_empty_layout()

            # Ensure all required breakpoints exist
            for breakpoint in ["lg", "md", "sm"]:
                if breakpoint not in layout:
                    layout[breakpoint] = []

            # Parse timestamp if present
            last_updated_str = data.get("last_updated")
            last_updated = None
            if last_updated_str:
                try:
                    last_updated = datetime.fromisoformat(last_updated_str)
                except (ValueError, TypeError):
                    pass

            return {
                "layout": layout,
                "last_updated": last_updated,
                "timestamp": last_updated,
            }
        except (FileNotFoundError, json.JSONDecodeError):
            return self._get_empty_layout()

    def _get_empty_layout(self) -> dict[str, Any]:
        """
        Get an empty layout structure.

        Returns:
            Dictionary with empty layout.
        """
        return {
            "layout": {
                "lg": [],
                "md": [],
                "sm": [],
            },
            "last_updated": None,
        }
