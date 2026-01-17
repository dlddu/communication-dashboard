"""Tests for APScheduler integration."""

from pathlib import Path
from unittest.mock import MagicMock, patch

from communication_dashboard.scheduler import cleanup_task, setup_scheduler


def test_cleanup_task_success(tmp_path: Path) -> None:
    """Test successful cleanup task execution.

    Args:
        tmp_path: Pytest temporary directory
    """
    db_path = tmp_path / "test.db"

    with patch("communication_dashboard.scheduler.get_db_connection") as mock_conn:
        with patch("communication_dashboard.scheduler.cleanup_old_records") as mock_cleanup:
            mock_cleanup.return_value = 5

            cleanup_task(db_path)

            mock_conn.assert_called_once_with(db_path)
            mock_cleanup.assert_called_once()


def test_cleanup_task_handles_exception(tmp_path: Path) -> None:
    """Test cleanup task handles exceptions gracefully.

    Args:
        tmp_path: Pytest temporary directory
    """
    db_path = tmp_path / "test.db"

    with patch("communication_dashboard.scheduler.get_db_connection") as mock_conn:
        mock_conn.side_effect = Exception("Database error")

        # Should not raise exception
        cleanup_task(db_path)


def test_setup_scheduler_creates_scheduler(tmp_path: Path) -> None:
    """Test that setup_scheduler creates a scheduler.

    Args:
        tmp_path: Pytest temporary directory
    """
    db_path = tmp_path / "test.db"
    scheduler = setup_scheduler(db_path)

    assert scheduler is not None
    assert len(scheduler.get_jobs()) == 1

    job = scheduler.get_jobs()[0]
    assert job.id == "cleanup_old_records"


def test_setup_scheduler_job_configuration(tmp_path: Path) -> None:
    """Test that cleanup job is configured correctly.

    Args:
        tmp_path: Pytest temporary directory
    """
    db_path = tmp_path / "test.db"
    scheduler = setup_scheduler(db_path)

    job = scheduler.get_jobs()[0]
    assert job.id == "cleanup_old_records"

    # Check trigger configuration (cron job at 2 AM)
    trigger = job.trigger
    assert trigger is not None
