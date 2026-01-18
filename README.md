# communication-dashboard

Communication dashboard with plugin-based architecture.

## Development Setup

### Prerequisites

- Python 3.9 or higher
- pip

### Installation

1. Create a virtual environment:

```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install development dependencies:

```bash
pip install -e ".[dev]"
```

Or using requirements file:

```bash
pip install -r requirements-dev.txt
```

## Running Tests

### Run all tests

```bash
pytest
```

### Run with coverage

```bash
pytest --cov --cov-report=term-missing
```

### Run specific test file

```bash
pytest tests/test_plugins/test_base.py
```

### Run with verbose output

```bash
pytest -v
```

## Code Quality

### Run linting

```bash
ruff check backend/ tests/
```

### Run type checking

```bash
mypy backend/
```

### Auto-fix linting issues

```bash
ruff check --fix backend/ tests/
```

## Project Structure

```
communication-dashboard/
├── backend/
│   └── plugins/
│       ├── __init__.py
│       ├── base.py         # (to be implemented)
│       └── schemas.py      # (to be implemented)
├── tests/
│   └── test_plugins/
│       ├── __init__.py
│       ├── test_base.py    # Plugin system tests
│       └── README.md
├── .github/
│   └── workflows/
│       └── test.yml        # CI/CD pipeline
├── pyproject.toml          # Project configuration
├── requirements-dev.txt    # Development dependencies
└── README.md
```

## TDD Workflow

This project follows Test-Driven Development (TDD) methodology:

1. **Red Phase**: Tests are written first and fail (current state)
2. **Green Phase**: Implementation code is written to make tests pass
3. **Refactor Phase**: Code is improved while keeping tests green

### Current Status: Red Phase

Tests have been written for the plugin system but implementation is pending.

Run tests to see failures:

```bash
pytest tests/test_plugins/test_base.py -v
```

Expected implementation:
- `backend/plugins/base.py`: BasePlugin abstract class
- `backend/plugins/schemas.py`: PluginData, PluginConfig, ValidationResult

## CI/CD

GitHub Actions workflow runs automatically on:
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

The workflow runs:
- Linting (ruff)
- Type checking (mypy)
- Tests with coverage (pytest)

## Next Steps

1. Implement `backend/plugins/base.py` with BasePlugin abstract class
2. Implement `backend/plugins/schemas.py` with PluginData, PluginConfig, ValidationResult
3. Run tests to verify implementation: `pytest tests/test_plugins/test_base.py`
4. All tests should pass (TDD Green Phase)
