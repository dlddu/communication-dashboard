"""
Tests for APScheduler plugin scheduler integration.

This test suite verifies the PluginScheduler class that integrates APScheduler
for periodic plugin data fetching:
- Job registration and scheduling
- Periodic execution at configured intervals
- Error handling and resilience
- Job removal when plugins are disabled

These tests are written in TDD style (Red Phase) and will fail until implementation is complete.
"""

import asyncio
from datetime import datetime
from unittest.mock import patch

import pytest

from backend.plugins.schemas import PluginData


class TestPluginScheduler:
    """Test cases for PluginScheduler class."""

    @pytest.mark.asyncio
    async def test_scheduler_starts_and_stops(self) -> None:
        """
        Test that scheduler can be started and shut down properly.

        Expected behavior:
        - start() should initialize and start the APScheduler
        - shutdown() should gracefully stop the scheduler
        - No exceptions should be raised during lifecycle
        """
        from backend.scheduler.plugin_scheduler import PluginScheduler

        # Arrange
        scheduler = PluginScheduler()

        # Act
        await scheduler.start()

        # Assert: Scheduler should be running
        assert scheduler.is_running()

        # Act: Shutdown
        await scheduler.shutdown()

        # Assert: Scheduler should not be running
        assert not scheduler.is_running()

    @pytest.mark.asyncio
    async def test_register_plugin_creates_job(self) -> None:
        """
        Test that registering a plugin creates an APScheduler job.

        Expected behavior:
        - After register_plugin() is called, a job should exist in scheduler
        - Job should have correct plugin name as identifier
        - Job should be scheduled to run at configured interval
        """
        from backend.scheduler.plugin_scheduler import PluginScheduler

        # Arrange
        scheduler = PluginScheduler()
        await scheduler.start()

        async def mock_fetch_callback() -> list[PluginData]:
            return []

        # Act
        await scheduler.register_plugin(
            plugin_name="test-plugin",
            interval_minutes=5,
            fetch_callback=mock_fetch_callback,
        )

        # Assert
        jobs = scheduler.get_jobs()
        assert len(jobs) > 0

        # Find job with matching ID
        test_job = None
        for job in jobs:
            if job.id == "plugin:test-plugin":
                test_job = job
                break

        assert test_job is not None
        assert test_job.id == "plugin:test-plugin"

        # Cleanup
        await scheduler.shutdown()

    @pytest.mark.asyncio
    async def test_job_runs_at_configured_interval(self) -> None:
        """
        Test that scheduled job executes fetch_callback at configured interval.

        Expected behavior:
        - fetch_callback should be called periodically
        - Interval should match configured interval_minutes
        - Multiple executions should occur over time
        """
        from backend.scheduler.plugin_scheduler import PluginScheduler

        # Arrange
        scheduler = PluginScheduler()
        await scheduler.start()

        call_count = 0
        call_timestamps: list[datetime] = []

        async def mock_fetch_callback() -> list[PluginData]:
            nonlocal call_count
            call_count += 1
            call_timestamps.append(datetime.now())
            return []

        # Act: Register plugin with 1-second interval (for faster testing)
        # Note: In production, minimum is 1 minute, but for tests we need faster execution
        await scheduler.register_plugin(
            plugin_name="test-plugin",
            interval_minutes=1,  # Will be converted to seconds in test
            fetch_callback=mock_fetch_callback,
        )

        # Wait for at least 2 executions
        # Using a short interval for testing purposes
        await asyncio.sleep(2.5)

        # Assert: Callback should have been called at least twice
        assert call_count >= 2, f"Expected at least 2 calls, got {call_count}"

        # Verify intervals between calls are roughly consistent
        if len(call_timestamps) >= 2:
            interval_seconds = (call_timestamps[1] - call_timestamps[0]).total_seconds()
            assert 0.8 <= interval_seconds <= 1.5, \
                f"Expected ~1 second interval, got {interval_seconds}"

        # Cleanup
        await scheduler.shutdown()

    @pytest.mark.asyncio
    async def test_failed_fetch_does_not_crash_scheduler(self) -> None:
        """
        Test that fetch exceptions don't crash the scheduler.

        Expected behavior:
        - If fetch_callback raises an exception, scheduler continues running
        - Subsequent scheduled executions still occur
        - Exception is logged but doesn't propagate
        """
        from backend.scheduler.plugin_scheduler import PluginScheduler

        # Arrange
        scheduler = PluginScheduler()
        await scheduler.start()

        call_count = 0

        async def failing_fetch_callback() -> list[PluginData]:
            nonlocal call_count
            call_count += 1
            if call_count == 1:
                raise RuntimeError("Simulated fetch failure")
            return []

        # Act
        await scheduler.register_plugin(
            plugin_name="failing-plugin",
            interval_minutes=1,
            fetch_callback=failing_fetch_callback,
        )

        # Wait for multiple execution attempts
        await asyncio.sleep(2.5)

        # Assert: Despite first failure, callback should be called again
        assert call_count >= 2, \
            f"Expected at least 2 calls (including failed one), got {call_count}"

        # Scheduler should still be running
        assert scheduler.is_running()

        # Cleanup
        await scheduler.shutdown()

    @pytest.mark.asyncio
    async def test_unregister_plugin_removes_job(self) -> None:
        """
        Test that unregistering a plugin removes its job from scheduler.

        Expected behavior:
        - After unregister_plugin(), job should not exist in scheduler
        - Job should stop executing
        - No exceptions should be raised
        """
        from backend.scheduler.plugin_scheduler import PluginScheduler

        # Arrange
        scheduler = PluginScheduler()
        await scheduler.start()

        call_count = 0

        async def mock_fetch_callback() -> list[PluginData]:
            nonlocal call_count
            call_count += 1
            return []

        # Register plugin
        await scheduler.register_plugin(
            plugin_name="test-plugin",
            interval_minutes=1,
            fetch_callback=mock_fetch_callback,
        )

        # Verify job exists
        jobs_before = scheduler.get_jobs()
        assert any(job.id == "plugin:test-plugin" for job in jobs_before)

        # Wait a bit to let it execute once
        await asyncio.sleep(1.2)
        calls_before_unregister = call_count

        # Act: Unregister plugin
        await scheduler.unregister_plugin("test-plugin")

        # Assert: Job should be removed
        jobs_after = scheduler.get_jobs()
        assert not any(job.id == "plugin:test-plugin" for job in jobs_after)

        # Wait to verify job doesn't execute anymore
        await asyncio.sleep(1.5)
        calls_after_unregister = call_count

        # Call count should not have increased (or increased minimally due to timing)
        assert calls_after_unregister <= calls_before_unregister + 1, \
            "Job should have stopped executing after unregister"

        # Cleanup
        await scheduler.shutdown()

    @pytest.mark.asyncio
    async def test_register_multiple_plugins(self) -> None:
        """
        Test that multiple plugins can be registered simultaneously.

        Expected behavior:
        - Each plugin should have its own job
        - Jobs should execute independently
        - Different intervals should be respected
        """
        from backend.scheduler.plugin_scheduler import PluginScheduler

        # Arrange
        scheduler = PluginScheduler()
        await scheduler.start()

        plugin1_calls = 0
        plugin2_calls = 0

        async def plugin1_fetch() -> list[PluginData]:
            nonlocal plugin1_calls
            plugin1_calls += 1
            return []

        async def plugin2_fetch() -> list[PluginData]:
            nonlocal plugin2_calls
            plugin2_calls += 1
            return []

        # Act: Register multiple plugins
        await scheduler.register_plugin(
            plugin_name="plugin-1",
            interval_minutes=1,
            fetch_callback=plugin1_fetch,
        )

        await scheduler.register_plugin(
            plugin_name="plugin-2",
            interval_minutes=1,
            fetch_callback=plugin2_fetch,
        )

        # Assert: Both jobs should exist
        jobs = scheduler.get_jobs()
        assert len(jobs) >= 2
        assert any(job.id == "plugin:plugin-1" for job in jobs)
        assert any(job.id == "plugin:plugin-2" for job in jobs)

        # Wait for executions
        await asyncio.sleep(2.5)

        # Both plugins should have been called
        assert plugin1_calls >= 1
        assert plugin2_calls >= 1

        # Cleanup
        await scheduler.shutdown()

    @pytest.mark.asyncio
    async def test_unregister_nonexistent_plugin(self) -> None:
        """
        Test that unregistering a non-existent plugin doesn't raise exception.

        Expected behavior:
        - Should handle gracefully (no exception)
        - Or raise a specific PluginNotFoundError
        """
        from backend.scheduler.plugin_scheduler import PluginScheduler

        # Arrange
        scheduler = PluginScheduler()
        await scheduler.start()

        # Act & Assert: Should not raise exception
        await scheduler.unregister_plugin("nonexistent-plugin")

        # Cleanup
        await scheduler.shutdown()

    @pytest.mark.asyncio
    async def test_register_plugin_with_invalid_interval(self) -> None:
        """
        Test that registering plugin with invalid interval is handled.

        Expected behavior:
        - interval_minutes <= 0 should raise ValueError
        - interval_minutes > 1440 should raise ValueError
        """
        from backend.scheduler.plugin_scheduler import PluginScheduler

        # Arrange
        scheduler = PluginScheduler()
        await scheduler.start()

        async def mock_fetch() -> list[PluginData]:
            return []

        # Act & Assert: Zero interval
        with pytest.raises(ValueError) as exc_info:
            await scheduler.register_plugin(
                plugin_name="invalid-plugin",
                interval_minutes=0,
                fetch_callback=mock_fetch,
            )
        assert "interval" in str(exc_info.value).lower()

        # Act & Assert: Negative interval
        with pytest.raises(ValueError):
            await scheduler.register_plugin(
                plugin_name="invalid-plugin",
                interval_minutes=-5,
                fetch_callback=mock_fetch,
            )

        # Act & Assert: Too large interval
        with pytest.raises(ValueError):
            await scheduler.register_plugin(
                plugin_name="invalid-plugin",
                interval_minutes=1441,
                fetch_callback=mock_fetch,
            )

        # Cleanup
        await scheduler.shutdown()

    @pytest.mark.asyncio
    async def test_scheduler_double_start(self) -> None:
        """
        Test that starting an already running scheduler is handled gracefully.

        Expected behavior:
        - Calling start() twice should not cause issues
        - Should either be idempotent or raise a clear exception
        """
        from backend.scheduler.plugin_scheduler import PluginScheduler

        # Arrange
        scheduler = PluginScheduler()

        # Act
        await scheduler.start()

        # Calling start again should be safe
        await scheduler.start()

        # Assert
        assert scheduler.is_running()

        # Cleanup
        await scheduler.shutdown()

    @pytest.mark.asyncio
    async def test_scheduler_shutdown_without_start(self) -> None:
        """
        Test that shutting down a non-started scheduler is handled gracefully.

        Expected behavior:
        - Should not raise exception
        - Should be safe to call
        """
        from backend.scheduler.plugin_scheduler import PluginScheduler

        # Arrange
        scheduler = PluginScheduler()

        # Act & Assert: Should not raise exception
        await scheduler.shutdown()

    @pytest.mark.asyncio
    async def test_fetch_callback_returns_plugin_data(self) -> None:
        """
        Test that fetch_callback results are properly handled.

        Expected behavior:
        - fetch_callback should return list[PluginData]
        - Returned data should be accessible for processing
        """
        from backend.scheduler.plugin_scheduler import PluginScheduler

        # Arrange
        scheduler = PluginScheduler()
        await scheduler.start()

        test_data = [
            PluginData(
                id="test-1",
                source="test-plugin",
                title="Test Message",
                content="Test content",
                timestamp=datetime.now(),
                metadata={},
                read=False,
            )
        ]

        async def mock_fetch_callback() -> list[PluginData]:
            return test_data

        # Act
        await scheduler.register_plugin(
            plugin_name="data-plugin",
            interval_minutes=1,
            fetch_callback=mock_fetch_callback,
        )

        # Wait for execution
        await asyncio.sleep(1.5)

        # Assert: Job should have executed successfully
        # The actual data handling will depend on implementation
        # For now, just verify no exceptions occurred
        assert scheduler.is_running()

        # Cleanup
        await scheduler.shutdown()


class TestPluginSchedulerIntegration:
    """Integration tests for PluginScheduler with plugin system."""

    @pytest.mark.asyncio
    async def test_scheduler_with_real_plugin_config(self) -> None:
        """
        Test scheduler integration with PluginConfig.

        Expected behavior:
        - Should work with plugin configuration objects
        - interval_minutes from config should be used
        """
        from backend.plugins.schemas import PluginConfig
        from backend.scheduler.plugin_scheduler import PluginScheduler

        # Arrange
        scheduler = PluginScheduler()
        await scheduler.start()

        config = PluginConfig(
            name="integration-test-plugin",
            enabled=True,
            interval_minutes=1,
            credentials={},
            options={},
        )

        call_count = 0

        async def fetch_callback() -> list[PluginData]:
            nonlocal call_count
            call_count += 1
            return []

        # Act
        await scheduler.register_plugin(
            plugin_name=config.name,
            interval_minutes=config.interval_minutes,
            fetch_callback=fetch_callback,
        )

        # Wait for execution
        await asyncio.sleep(1.5)

        # Assert
        assert call_count >= 1

        # Cleanup
        await scheduler.shutdown()

    @pytest.mark.asyncio
    async def test_scheduler_logs_errors(self) -> None:
        """
        Test that scheduler logs errors from failed fetch operations.

        Expected behavior:
        - Errors should be logged (we'll mock the logger)
        - Scheduler should continue running
        """
        from backend.scheduler.plugin_scheduler import PluginScheduler

        # Arrange
        scheduler = PluginScheduler()
        await scheduler.start()

        async def failing_fetch() -> list[PluginData]:
            raise RuntimeError("Test error message")

        # Act
        with patch("backend.scheduler.plugin_scheduler.logger") as mock_logger:
            await scheduler.register_plugin(
                plugin_name="error-plugin",
                interval_minutes=1,
                fetch_callback=failing_fetch,
            )

            # Wait for execution
            await asyncio.sleep(1.5)

            # Assert: Error should have been logged
            # Check that logger.error or logger.exception was called
            assert mock_logger.error.called or mock_logger.exception.called

        # Cleanup
        await scheduler.shutdown()
