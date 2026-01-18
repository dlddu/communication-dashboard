"""
Database module for managing plugin data persistence.

This module provides:
- DatabaseConnection: SQLite connection management with context manager support
- PluginDataRepository: CRUD operations for PluginData
"""

from backend.database.connection import DatabaseConnection
from backend.database.repository import PluginDataRepository

__all__ = ["DatabaseConnection", "PluginDataRepository"]
