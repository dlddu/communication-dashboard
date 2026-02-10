# E2E Test Suite

This directory contains End-to-End (E2E) and integration tests for the Communication Dashboard application.

## Test Structure

### Test Files

- **HTTPClientTests.swift** - Tests for the HTTPClient protocol and MockHTTPClient implementation
  - Validates HTTP request/response mocking
  - Tests error handling and status codes
  - Verifies header validation

- **ShellExecutorTests.swift** - Tests for the ShellExecutor protocol and MockShellExecutor implementation
  - Validates shell command execution mocking
  - Tests working directory handling
  - Verifies command history tracking

- **FixtureLoaderTests.swift** - Tests for loading fixture data from JSON and YAML files
  - Validates JSON deserialization
  - Tests YAML configuration loading
  - Verifies fixture data structure

- **IntegrationTests.swift** - Full integration tests combining all components
  - Tests complete data ingestion pipeline
  - Validates plugin interactions
  - Tests database persistence across plugins

### Fixture Data

Located in `../Fixtures/`:

- **config.yaml** - Test configuration with plugin settings
- **slack_messages.json** - Mock Slack message data
- **gmail_messages.json** - Mock Gmail message data
- **linear_issues.json** - Mock Linear issue data
- **github_notifications.json** - Mock GitHub notification data
- **calendar_events.json** - Mock calendar event data

## Running Tests

### Run All Tests
```bash
swift test
```

### Run Specific Test File
```bash
swift test --filter HTTPClientTests
swift test --filter ShellExecutorTests
swift test --filter FixtureLoaderTests
swift test --filter IntegrationTests
```

### Run with Coverage
```bash
swift test --enable-code-coverage
```

### Generate Coverage Report
```bash
swift test --enable-code-coverage
xcrun llvm-cov export -format="lcov" \
  .build/debug/CommunicationDashboardPackageTests.xctest/Contents/MacOS/CommunicationDashboardPackageTests \
  -instr-profile .build/debug/codecov/default.profdata > coverage.lcov
```

## Test Status (TDD Red Phase)

**All tests are expected to fail** as this is the Red phase of TDD. The following components need to be implemented:

### Required Implementations

1. **HTTPClient Protocol** (`Sources/CommunicationDashboard/Protocols/HTTPClient.swift`)
   ```swift
   protocol HTTPClient {
       func get(url: String, headers: [String: String]?) async throws -> String
       func post(url: String, body: String, headers: [String: String]?) async throws -> String
       func put(url: String, body: String, headers: [String: String]?) async throws -> String
       func delete(url: String, headers: [String: String]?) async throws -> String
   }
   ```

2. **MockHTTPClient** (`Tests/CommunicationDashboardTests/Mocks/MockHTTPClient.swift`)
   - Implements HTTPClient protocol
   - Registers fixture responses per endpoint
   - Simulates network errors

3. **ShellExecutor Protocol** (`Sources/CommunicationDashboard/Protocols/ShellExecutor.swift`)
   ```swift
   protocol ShellExecutor {
       func execute(command: String, workingDirectory: String?, environment: [String: String]?) async throws -> String
       func executeInteractive(command: String, inputs: [String]) async throws -> String
   }
   ```

4. **MockShellExecutor** (`Tests/CommunicationDashboardTests/Mocks/MockShellExecutor.swift`)
   - Implements ShellExecutor protocol
   - Registers command outputs
   - Tracks execution history

5. **FixtureLoader** (`Tests/CommunicationDashboardTests/Support/FixtureLoader.swift`)
   - Loads JSON fixture files
   - Loads YAML configuration files
   - Handles decoding to typed models

6. **Plugin Implementations**
   - SlackPlugin
   - GmailPlugin
   - LinearPlugin
   - GitHubPlugin
   - CalendarPlugin

7. **Error Types**
   - HTTPClientError
   - ShellExecutorError
   - FixtureLoaderError

## CI/CD Integration

Tests run automatically on GitHub Actions for:
- Push to `main` and `develop` branches
- Pull requests to `main` and `develop` branches

The workflow:
1. Checks out code
2. Sets up Xcode 15.2
3. Resolves Swift dependencies
4. Builds the package
5. Runs all tests in parallel
6. Generates coverage reports

See `.github/workflows/test.yml` for full configuration.

## Best Practices

1. **Test Isolation** - Each test uses fresh instances with in-memory database
2. **Fixture Management** - All test data is centralized in Fixtures directory
3. **Mock Injection** - Dependencies are injected for easy testing
4. **Async Testing** - Tests use async/await for concurrent operations
5. **Error Validation** - Tests verify both success and error paths

## Next Steps (Green Phase)

After implementing the components listed above:
1. Run tests to verify they pass (Green phase)
2. Refactor implementations for code quality (Refactor phase)
3. Add more test cases as needed
4. Integrate real HTTP client and shell executor for production use
