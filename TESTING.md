# Testing Guide

## Overview

This project follows Test-Driven Development (TDD) methodology. Tests are written first (Red phase), then implementation follows to make them pass (Green phase), and finally code is refactored for quality.

## Current Status: RED PHASE

All tests are currently in a failing state, which is expected. The implementation stubs throw `fatalError("Not implemented")` to ensure tests fail until proper implementation is provided.

## Test Structure

### ConfigServiceTests.swift

Tests for configuration directory management:

**Happy Path Tests:**
- `testInitializeCreatesBaseDirectory` - Verifies ~/.config/commdash/ is created
- `testInitializeCreatesAllSubdirectories` - Verifies db/, models/, cache/, logs/ subdirectories
- `testInitializeCreatesDirectoriesWithCorrectAttributes` - Checks directory permissions
- `testGetDirectoryPathReturnsCorrectPath` - Validates path retrieval
- `testGetDirectoryPathForAllSubdirectoryTypes` - Tests all subdirectory types

**Edge Case Tests:**
- `testInitializeWhenDirectoryAlreadyExists` - Handles existing directories without error
- `testInitializeWhenSubdirectoryAlreadyExists` - Idempotent initialization
- `testInitializeWithFilesInDirectory` - Preserves existing files

**Error Case Tests:**
- `testGetDirectoryPathThrowsWhenNotInitialized` - Validates initialization requirement
- `testInitializeThrowsWhenPermissionDenied` - Handles permission errors
- `testDirectoryExistsReturnsFalseWhenNotInitialized` - State checking
- `testDirectoryExistsReturnsTrueAfterInitialization` - State validation

**Total Test Cases: 12**

### DatabaseManagerTests.swift

Tests for database initialization and migrations:

**Happy Path Tests:**
- `testInitializeDatabaseCreatesConnection` - GRDB DatabaseQueue creation
- `testInitializeRunsMigrations` - Migration execution verification
- `testInitializeCreatesItemsTable` - Items table with all columns (id, title, content, created_at, updated_at)
- `testInitializeCreatesEmbeddingsTable` - Embeddings table with columns (id, item_id, embedding, model_version, created_at)
- `testInitializeCreatesConfigVersionsTable` - Config table with columns (id, key, value, updated_at)
- `testInitializeCreatesFTSVirtualTable` - FTS5 virtual table for full-text search
- `testEmbeddingsTableHasForeignKeyToItems` - Foreign key constraint verification
- `testConfigVersionsTableHasUniqueConstraintOnKey` - Unique constraint on config keys
- `testItemsTableHasPrimaryKey` - Primary key validation

**Edge Case Tests:**
- `testInitializeCanBeCalledMultipleTimes` - Idempotent initialization
- `testDatabaseSupportsTransactions` - Transaction commit behavior
- `testDatabaseRollsBackOnError` - Transaction rollback on errors
- `testFTSTableCanBeQueried` - FTS5 search functionality

**Error Case Tests:**
- `testGetDatabaseQueueThrowsWhenNotInitialized` - Validates initialization requirement
- `testInsertIntoItemsFailsWithInvalidData` - Data validation
- `testEmbeddingsCannotBeInsertedWithInvalidItemId` - Foreign key constraint enforcement
- `testDatabaseMigrationVersionIsTracked` - Migration history tracking
- `testConcurrentReadsAreSupported` - Thread safety

**Total Test Cases: 18**

### AppStructureTests.swift

Tests for SwiftUI app structure:

**App Lifecycle Tests:**
- `testCommunicationDashboardAppExists` - App instantiation
- `testAppConformsToAppProtocol` - SwiftUI App protocol conformance
- `testAppHasBodyProperty` - App body property

**ContentView Tests:**
- `testContentViewCanBeInstantiated` - View instantiation
- `testContentViewConformsToViewProtocol` - SwiftUI View protocol conformance
- `testContentViewHasBodyProperty` - View body property
- `testContentViewUsesNavigationSplitView` - Navigation structure

**Integration Tests:**
- `testAppProvidesContentView` - App-View integration
- `testContentViewCanBeEmbeddedInWindowGroup` - WindowGroup compatibility

**View Hierarchy Tests:**
- `testContentViewHasNavigationStructure` - Navigation components
- `testAppWindowGroupHasContentView` - Scene structure

**State Management Tests:**
- `testContentViewCanMaintainState` - @State property support
- `testContentViewSupportsMultipleNavigationLevels` - Multi-level navigation

**macOS Specific Tests:**
- `testAppTargetsMacOSPlatform` - Platform verification
- `testAppUsesSwiftUILifecycle` - SwiftUI lifecycle validation

**Error Handling Tests:**
- `testContentViewHandlesNoSelectionState` - Nil selection handling
- `testContentViewCanDisplayEmptyState` - Empty state UI

**Accessibility Tests:**
- `testContentViewSupportsAccessibility` - Accessibility support

**Total Test Cases: 18**

## Test Summary

- **Total Test Files:** 3
- **Total Test Cases:** 48
- **New Test Cases:** 48
- **Modified Test Cases:** 0

## Running Tests

### Run All Tests
```bash
swift test
```

### Run Specific Test File
```bash
swift test --filter ConfigServiceTests
swift test --filter DatabaseManagerTests
swift test --filter AppStructureTests
```

### Run With Coverage
```bash
swift test --enable-code-coverage
```

### Generate Coverage Report
```bash
swift test --enable-code-coverage
xcrun llvm-cov report \
  .build/debug/CommunicationDashboardPackageTests.xctest/Contents/MacOS/CommunicationDashboardPackageTests \
  -instr-profile .build/debug/codecov/default.profdata
```

## Dependencies

The following dependencies are required for testing:

- **GRDB.swift** (v6.24.0+) - Database framework for testing DatabaseManager
- **XCTest** - Built-in Swift testing framework
- **SwiftUI** - For testing app structure and views

## CI/CD Integration

GitHub Actions workflow (`.github/workflows/test.yml`) runs:

1. Package validation
2. Dependency resolution
3. Build verification
4. Test execution with parallelization
5. Code coverage generation
6. SwiftLint checks

**Important:** Tests are expected to FAIL in CI until implementation is complete. This is the Red phase of TDD.

## Next Steps

1. Implement `ConfigService.initialize()` to create directories
2. Implement `ConfigService.getDirectoryPath()` to return paths
3. Implement `DatabaseManager.initialize()` to create database
4. Implement database migrations for all tables
5. Run tests again - they should pass (Green phase)
6. Refactor code for quality and maintainability

## Test Isolation

- ConfigService tests use temporary directories
- DatabaseManager tests use in-memory databases
- Each test has independent setup/teardown
- No test dependencies or shared state

## Notes

- All tests use AAA pattern (Arrange, Act, Assert)
- Test names describe expected behavior clearly
- Tests are independent and can run in any order
- In-memory databases ensure fast test execution
- Temporary directories are cleaned up automatically
