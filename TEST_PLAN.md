# Test Plan for BasePlugin System

## TDD Phase: RED

All tests are written and will fail until implementation is complete.

## Test Summary

### Total Test Cases: 24

#### 1. TestBasePluginAbstract (3 tests)
- `test_plugin_must_implement_fetch` - Validates TypeError when fetch() not implemented
- `test_plugin_must_implement_validate_config` - Validates TypeError when validate_config() not implemented  
- `test_plugin_fetch_returns_plugin_data_list` - Validates proper implementation returns List[PluginData]

#### 2. TestPluginData (4 tests)
- `test_plugin_data_fields` - Validates all fields are present with correct types
- `test_plugin_data_with_read_true` - Validates read=True can be set
- `test_plugin_data_immutable` - Validates frozen=True (immutability)
- `test_plugin_data_metadata_can_contain_any_type` - Validates metadata dict[str, Any]

#### 3. TestPluginConfig (9 tests)
- `test_plugin_config_validation_valid` - Validates correct config creation with defaults
- `test_plugin_config_with_all_fields` - Validates all fields can be explicitly set
- `test_plugin_config_interval_boundary_valid` - Validates interval_minutes=1 and 1440
- `test_plugin_config_interval_boundary_invalid_zero` - Validates interval_minutes=0 raises ValidationError
- `test_plugin_config_interval_boundary_invalid_negative` - Validates interval_minutes=-1 raises ValidationError
- `test_plugin_config_interval_boundary_invalid_too_large` - Validates interval_minutes=1441 raises ValidationError
- `test_plugin_config_missing_required_field_name` - Validates missing 'name' raises ValidationError
- `test_plugin_config_missing_required_field_interval` - Validates missing 'interval_minutes' raises ValidationError

#### 4. TestValidationResult (3 tests)
- `test_validation_result_structure_valid` - Validates ValidationResult structure for success case
- `test_validation_result_structure_invalid` - Validates ValidationResult can represent errors
- `test_validation_result_can_be_used_in_plugin` - Validates ValidationResult usage in plugin context

#### 5. TestIntegration (2 tests)
- `test_complete_plugin_workflow` - Validates end-to-end plugin workflow
- `test_plugin_with_invalid_config_workflow` - Validates error handling in workflow

## Test Categories

### Happy Path (8 tests)
- Valid plugin implementation
- Valid configuration
- Successful data fetching
- Proper validation results

### Edge Cases (4 tests)
- Boundary values for interval_minutes (1, 1440)
- Complex metadata types
- Empty credentials/options
- Read status toggling

### Error Cases (12 tests)
- Missing abstract method implementations
- Invalid interval ranges (0, -1, 1441)
- Missing required fields
- Immutability violations

## Coverage Targets

- **Overall Coverage**: ≥80%
- **Branch Coverage**: Enabled
- **Strict Type Checking**: mypy --strict

## Test Execution

```bash
# Run all tests (will be skipped until implementation exists)
pytest tests/plugins/test_base.py

# Run with verbose output
pytest tests/plugins/test_base.py -v

# Run specific test class
pytest tests/plugins/test_base.py::TestPluginConfig

# Run with coverage
pytest tests/plugins/test_base.py --cov=src/plugins --cov-report=term-missing
```

## Expected Implementation

### File: src/plugins/base.py

Must implement:

1. **BasePlugin (ABC)**
   ```python
   from abc import ABC, abstractmethod
   
   class BasePlugin(ABC):
       @abstractmethod
       def fetch(self) -> list[PluginData]:
           ...
       
       @abstractmethod
       def validate_config(self, config: PluginConfig) -> ValidationResult:
           ...
   ```

2. **PluginData (dataclass)**
   ```python
   from dataclasses import dataclass
   from datetime import datetime
   from typing import Any
   
   @dataclass(frozen=True)
   class PluginData:
       id: str
       source: str
       title: str
       content: str
       timestamp: datetime
       metadata: dict[str, Any]
       read: bool = False
   ```

3. **PluginConfig (Pydantic BaseModel)**
   ```python
   from pydantic import BaseModel, Field
   
   class PluginConfig(BaseModel):
       name: str
       enabled: bool = True
       interval_minutes: int = Field(ge=1, le=1440)
       credentials: dict[str, str] = {}
       options: dict[str, Any] = {}
   ```

4. **ValidationResult (TypedDict)**
   ```python
   from typing import TypedDict
   
   class ValidationResult(TypedDict):
       valid: bool
       errors: list[str]
   ```

## Dependencies Required

```toml
[project]
dependencies = [
    "pydantic>=2.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "pytest-cov>=4.0.0",
    "mypy>=1.0.0",
]
```

## Next Steps (GREEN Phase)

1. Implement `src/plugins/base.py` with all required classes
2. Run tests: `pytest tests/plugins/test_base.py`
3. Verify all tests pass
4. Run type checking: `mypy src --strict`
5. Check coverage: `pytest --cov --cov-report=term-missing`
6. Ensure coverage ≥80%

## Refactor Phase

After GREEN phase is complete, consider:

- Performance optimizations
- Additional utility methods
- Better error messages
- Documentation strings
- Example plugin implementations
