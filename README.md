# Communication Dashboard

A plugin-based communication dashboard built with Python 3.12.

## Features

- Plugin system with abstract base class
- Pydantic-based data validation
- Type-safe with mypy strict mode
- 100% test coverage
- Linted with ruff

## Project Structure

```
communication-dashboard/
├── src/
│   ├── __init__.py
│   └── plugins/
│       ├── __init__.py
│       ├── base.py        # BasePlugin ABC
│       └── models.py      # PluginData, PluginConfig, ValidationResult
├── tests/
│   ├── __init__.py
│   └── plugins/
│       ├── __init__.py
│       ├── test_base.py   # BasePlugin tests
│       └── test_models.py # Model tests
├── .github/
│   └── workflows/
│       └── test.yml       # CI/CD pipeline
└── pyproject.toml         # Project configuration
```

## Setup

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -e ".[dev]"
```

## Development

### Run Tests

```bash
# Run all tests with coverage
pytest --cov

# Run specific test file
pytest tests/plugins/test_base.py

# Run with verbose output
pytest -v
```

### Type Checking

```bash
# Run mypy with strict mode
mypy src --strict
```

### Linting

```bash
# Check code style
ruff check src tests

# Format code
ruff format src tests

# Auto-fix issues
ruff check --fix src tests
```

### Coverage Report

```bash
# Generate HTML coverage report
pytest --cov --cov-report=html

# View report in browser
open htmlcov/index.html
```

## Requirements

- Python 3.12+
- pydantic >= 2.0
- pytest >= 7.0
- pytest-cov >= 4.0
- mypy >= 1.0
- ruff >= 0.1.0

## License

MIT
