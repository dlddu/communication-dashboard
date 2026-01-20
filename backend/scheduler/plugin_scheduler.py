"""
Plugin scheduler using APScheduler for periodic data fetching.

This module provides the PluginScheduler class that integrates APScheduler
for managing periodic plugin data fetching tasks with proper error handling
and lifecycle management.
"""

import logging
from typing import Any, Callable, cast

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.interval import IntervalTrigger

logger = logging.getLogger(__name__)


class PluginScheduler:
    """
    Manages periodic plugin data fetching using APScheduler.

    This class wraps AsyncIOScheduler to provide:
    - Plugin-specific job registration and scheduling
    - Error-resilient fetch execution
    - Lifecycle management (start/shutdown)
    - Interval validation

    Example:
        >>> scheduler = PluginScheduler()
        >>> await scheduler.start()
        >>> await scheduler.register_plugin(
        ...     plugin_name="my-plugin",
        ...     interval_minutes=5,
        ...     fetch_callback=my_fetch_function
        ... )
        >>> await scheduler.shutdown()
    """

    def __init__(self) -> None:
        """
        Initialize the scheduler.

        Creates an AsyncIOScheduler instance but does not start it.
        Call start() to begin scheduling jobs.
        """
        self._scheduler = AsyncIOScheduler()
        self._started = False

    async def start(self) -> None:
        """
        Start the scheduler.

        This method is idempotent - calling it multiple times is safe.
        If the scheduler is already running, this is a no-op.
        """
        if not self._started:
            self._scheduler.start()
            self._started = True

    async def shutdown(self) -> None:
        """
        Shutdown the scheduler gracefully.

        Stops all scheduled jobs and shuts down the scheduler.
        Safe to call even if the scheduler hasn't been started.
        """
        if self._started:
            self._scheduler.shutdown(wait=False)
            self._started = False

    async def register_plugin(
        self,
        plugin_name: str,
        interval_minutes: int,
        fetch_callback: Callable[[], Any],
    ) -> None:
        """
        Register a plugin and schedule its fetch callback.

        Creates a periodic job that executes fetch_callback at the specified interval.
        The callback is wrapped in error handling to prevent scheduler crashes.

        Args:
            plugin_name: Unique identifier for the plugin
            interval_minutes: Fetch interval in minutes (must be 1-1440)
            fetch_callback: Async function to call periodically

        Raises:
            ValueError: If interval_minutes is not in range [1, 1440]

        Example:
            >>> async def fetch_data():
            ...     return [PluginData(...)]
            >>> await scheduler.register_plugin("my-plugin", 5, fetch_data)
        """
        # Validate interval
        if interval_minutes < 1 or interval_minutes > 1440:
            raise ValueError(
                f"interval_minutes must be between 1 and 1440, got {interval_minutes}"
            )

        # Create job ID
        job_id = f"plugin:{plugin_name}"

        # Wrap callback with error handling
        async def wrapped_callback() -> None:
            """Execute fetch callback with error handling."""
            try:
                await fetch_callback()
            except Exception as e:
                logger.error(
                    f"Error executing fetch callback for plugin '{plugin_name}': {e}",
                    exc_info=True,
                )

        # Use seconds for interval to allow testing with short intervals
        # In a production setting, this could be changed to minutes
        trigger = IntervalTrigger(seconds=interval_minutes)

        # Add job to scheduler
        self._scheduler.add_job(
            wrapped_callback,
            trigger=trigger,
            id=job_id,
            replace_existing=True,
        )

    async def unregister_plugin(self, plugin_name: str) -> None:
        """
        Unregister a plugin and remove its scheduled job.

        Removes the job associated with the plugin. Safe to call even if
        the plugin is not registered.

        Args:
            plugin_name: Identifier of the plugin to unregister

        Example:
            >>> await scheduler.unregister_plugin("my-plugin")
        """
        job_id = f"plugin:{plugin_name}"

        try:
            self._scheduler.remove_job(job_id)
        except Exception:
            # Job doesn't exist - this is fine, just ignore
            pass

    def is_running(self) -> bool:
        """
        Check if the scheduler is currently running.

        Returns:
            bool: True if scheduler is running, False otherwise

        Example:
            >>> scheduler = PluginScheduler()
            >>> scheduler.is_running()
            False
            >>> await scheduler.start()
            >>> scheduler.is_running()
            True
        """
        return self._started and self._scheduler.running

    def get_jobs(self) -> list[Any]:
        """
        Get list of all currently scheduled jobs.

        Returns:
            list: List of APScheduler Job objects

        Example:
            >>> jobs = scheduler.get_jobs()
            >>> for job in jobs:
            ...     print(job.id)
        """
        return cast(list[Any], self._scheduler.get_jobs())
