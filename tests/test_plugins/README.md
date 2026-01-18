# Plugin Tests

This directory contains tests for the plugin system.

## Test Files

- `test_base.py`: Tests for base plugin functionality (BasePlugin, PluginData, PluginConfig)

## Running Tests

### Run all plugin tests

```bash
pytest tests/test_plugins/
```

### Run specific test file

```bash
pytest tests/test_plugins/test_base.py
```

### Run specific test class

```bash
pytest tests/test_plugins/test_base.py::TestBasePlugin
```

### Run specific test

```bash
pytest tests/test_plugins/test_base.py::TestBasePlugin::test_plugin_must_implement_fetch
```

### Run with coverage

```bash
pytest tests/test_plugins/ --cov=backend.plugins --cov-report=term-missing
```

### Run with verbose output

```bash
pytest tests/test_plugins/ -v
```

## Current Status

These tests are written in TDD style (Red Phase) and will fail until the implementation is complete.

Expected implementation files:
- `backend/plugins/base.py`: BasePlugin abstract class
- `backend/plugins/schemas.py`: PluginData, PluginConfig, ValidationResult

## Test Coverage

The test suite covers:

1. **BasePlugin Abstract Class**
   - Abstract method enforcement
   - fetch() method signature
   - List[PluginData] return type

2. **PluginData Dataclass**
   - Field creation and access
   - Empty metadata handling
   - Datetime timestamp support

3. **PluginConfig Pydantic Model**
   - Valid configuration creation
   - Type validation
   - interval_minutes boundary validation (1-1440)
   - Pydantic v2 compatibility

4. **Integration Tests**
   - Plugin with configuration
   - Disabled plugin behavior
