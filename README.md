# communication-dashboard

A communication dashboard with plugin support for aggregating messages from various sources.

## Project Structure

```
communication-dashboard/
├── src/
│   └── plugins/
│       ├── __init__.py
│       └── base.py          # To be implemented
├── tests/
│   └── plugins/
│       ├── __init__.py
│       └── test_base.py     # Tests written (TDD Red Phase)
├── .github/
│   └── workflows/
│       └── test.yml         # CI/CD pipeline
├── pyproject.toml           # Project configuration
├── requirements.txt         # Runtime dependencies
├── requirements-dev.txt     # Development dependencies
└── README.md
```

## Development Setup

### Prerequisites

- Python 3.11 or higher
- pip

### Installation

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -e ".[dev]"

# Or using requirements files
pip install -r requirements-dev.txt
```

## Running Tests

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov

# Run with coverage report
pytest --cov --cov-report=term-missing

# Run specific test file
pytest tests/plugins/test_base.py

# Run specific test
pytest tests/plugins/test_base.py::TestPluginConfig::test_plugin_config_interval_boundary_valid
```

## Type Checking

```bash
# Run mypy on source code
mypy src --strict
```

## Test Coverage

Target coverage: 80% or higher

```bash
# Generate coverage report
pytest --cov --cov-report=html

# View coverage report
open htmlcov/index.html
```

## TDD Status

This project follows Test-Driven Development (TDD) principles.

**Current Phase: RED**

- Tests have been written for `src/plugins/base.py`
- Implementation is pending
- Tests will fail until implementation is complete

### Next Steps (GREEN Phase)

Implement the following in `src/plugins/base.py`:

1. **BasePlugin** - Abstract Base Class
   - Abstract method: `fetch() -> List[PluginData]`
   - Abstract method: `validate_config(config: PluginConfig) -> ValidationResult`

2. **PluginData** - Immutable dataclass
   - Fields: id, source, title, content, timestamp, metadata, read
   - Must be frozen (immutable)

3. **PluginConfig** - Pydantic model
   - Fields: name, enabled, interval_minutes, credentials, options
   - Validation: interval_minutes must be between 1 and 1440

4. **ValidationResult** - TypedDict
   - Fields: valid (bool), errors (list[str])

## CI/CD

GitHub Actions workflow runs on every push and pull request:

- Python setup and dependency installation
- Type checking with mypy (strict mode)
- Test execution with pytest
- Coverage reporting (minimum 80%)
- Coverage upload to Codecov

## License

TBD
