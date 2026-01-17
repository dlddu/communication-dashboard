"""APScheduler configuration for periodic cleanup tasks."""

import logging
from pathlib import Path
from typing import Any

from apscheduler.schedulers.background import BackgroundScheduler  # type: ignore[import-untyped]

from communication_dashboard.db import cleanup_old_records
from communication_dashboard.db.connection import DEFAULT_DB_PATH, get_db_connection

logger = logging.getLogger(__name__)


def cleanup_task(db_path: Path | str = DEFAULT_DB_PATH) -> None:
    """Execute database cleanup task.

    Args:
        db_path: Path to SQLite database file
    """
    try:
        with get_db_connection(db_path) as conn:
            deleted_count = cleanup_old_records(conn, days=7)
            logger.info(f"Cleanup completed: {deleted_count} records deleted")
    except Exception as e:
        logger.error(f"Cleanup task failed: {e}")


def setup_scheduler(db_path: Path | str = DEFAULT_DB_PATH) -> Any:
    """Set up APScheduler for periodic cleanup tasks.

    Args:
        db_path: Path to SQLite database file

    Returns:
        BackgroundScheduler: Configured scheduler instance

    Example:
        >>> scheduler = setup_scheduler()
        >>> scheduler.start()
        >>> # ... application runs ...
        >>> scheduler.shutdown()
    """
    scheduler = BackgroundScheduler()

    # Run cleanup daily at 2 AM
    scheduler.add_job(
        cleanup_task,
        'cron',
        hour=2,
        minute=0,
        args=[db_path],
        id='cleanup_old_records',
        replace_existing=True
    )

    return scheduler
