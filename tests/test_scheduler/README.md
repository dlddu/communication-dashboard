# APScheduler Plugin Scheduler Tests

TDD Red Phase tests for the PluginScheduler class that integrates APScheduler for periodic plugin data fetching.

## Test Coverage

### TestPluginScheduler

1. **test_scheduler_starts_and_stops**: Lifecycle management
2. **test_register_plugin_creates_job**: Job registration
3. **test_job_runs_at_configured_interval**: Periodic execution
4. **test_failed_fetch_does_not_crash_scheduler**: Error resilience
5. **test_unregister_plugin_removes_job**: Job removal
6. **test_register_multiple_plugins**: Multiple plugin support
7. **test_unregister_nonexistent_plugin**: Edge case handling
8. **test_register_plugin_with_invalid_interval**: Validation
9. **test_scheduler_double_start**: Idempotency
10. **test_scheduler_shutdown_without_start**: Safe shutdown
11. **test_fetch_callback_returns_plugin_data**: Data handling

### TestPluginSchedulerIntegration

1. **test_scheduler_with_real_plugin_config**: PluginConfig integration
2. **test_scheduler_logs_errors**: Error logging

## Running Tests

```bash
# Install dependencies
pip install -e ".[dev]"

# Run all scheduler tests
pytest tests/test_scheduler/

# Run specific test
pytest tests/test_scheduler/test_plugin_scheduler.py::TestPluginScheduler::test_register_plugin_creates_job

# Run with verbose output
pytest tests/test_scheduler/ -v

# Run with coverage
pytest tests/test_scheduler/ --cov=backend.scheduler
```

## Expected Behavior (Red Phase)

All tests should FAIL with `ModuleNotFoundError: No module named 'backend.scheduler.plugin_scheduler'` until the implementation is complete.

## Implementation Requirements

The implementation must create:
- `backend/scheduler/plugin_scheduler.py` with `PluginScheduler` class
- Async methods: `start()`, `shutdown()`, `register_plugin()`, `unregister_plugin()`
- Instance methods: `is_running()`, `get_jobs()`
- Integration with APScheduler AsyncIOScheduler
- Error handling with logging
