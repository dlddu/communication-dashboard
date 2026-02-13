# Test Infrastructure

E2E 테스트를 위한 인프라 컴포넌트 모음입니다.

## Components

### 1. MockHTTPServer

HTTP 요청을 인터셉트하고 fixture 기반 응답을 반환하는 Mock HTTP 서버입니다.

**Usage:**

```swift
import TestInfrastructure

let mockServer = MockHTTPServer()
try mockServer.start()

// Register endpoint with fixture
try mockServer.registerFixture(
    endpoint: "/api/plugin",
    method: "GET",
    fixturePath: "HTTP/plugin_response.json"
)

// Or register with direct data
mockServer.register(
    endpoint: "/api/test",
    method: "POST",
    statusCode: 200,
    responseData: jsonData,
    headers: ["Content-Type": "application/json"]
)

// Verify requests
let count = mockServer.requestCount(for: "/api/test", method: "POST")
let bodies = mockServer.capturedRequestBodies(for: "/api/test", method: "POST")

// Cleanup
mockServer.stop()
```

### 2. ShellExecutorProtocol & MockShellExecutor

Process 기반 셸 명령 실행을 모킹하기 위한 프로토콜 기반 추상화입니다.

**Usage:**

```swift
import TestInfrastructure

let mockShell = MockShellExecutor()

// Register command with output
mockShell.registerCommand(
    command: "git status",
    output: "On branch main\nnothing to commit",
    exitCode: 0
)

// Register with fixture
try mockShell.registerCommandWithFixture(
    command: "cat config.yaml",
    fixturePath: "Shell/cat_config_output.txt",
    exitCode: 0
)

// Register pattern matching
mockShell.registerCommandPattern(
    pattern: "git commit -m .*",
    output: "[main abc1234] Commit message",
    exitCode: 0
)

// Execute
let result = try mockShell.execute("git status")
print(result.output) // "On branch main\nnothing to commit"
print(result.exitCode) // 0

// Verify executions
let count = mockShell.executionCount(for: "git status")
let executions = mockShell.capturedExecutions(for: "git status")
```

### 3. FixtureLoader

YAML/JSON fixture 파일을 로드하고 파싱하는 유틸리티입니다.

**Usage:**

```swift
import TestInfrastructure

let loader = FixtureLoader()

// Load raw data
let data = try loader.loadFixture(path: "HTTP/plugin_response.json")

// Load as string
let text = try loader.loadFixtureAsString(path: "Shell/output.txt")

// Parse JSON
struct Response: Codable {
    let status: String
    let data: ResponseData
}

let response: Response = try loader.loadAndParse(
    path: "HTTP/plugin_response.json"
)

// Parse YAML
struct Config: Codable {
    let plugins: [PluginConfig]
}

let config: Config = try loader.loadYAMLAndParse(
    path: "YAML/config.yaml"
)

// List fixtures
let httpFixtures = try loader.listFixtures(in: "HTTP")

// Check existence
if loader.fixtureExists(path: "HTTP/plugin_response.json") {
    // ...
}
```

### 4. In-memory SQLite Database

Already supported by `DatabaseManager(inMemory: true)`.

**Usage:**

```swift
import CommunicationDashboard

let dbManager = DatabaseManager(inMemory: true)
try dbManager.initialize()

let dbQueue = try dbManager.getDatabaseQueue()
try dbQueue.write { db in
    // Perform database operations
}
```

## Fixture Organization

```
Tests/Fixtures/
├── HTTP/           # HTTP response fixtures (JSON)
│   └── plugin_response.json
├── YAML/           # YAML configuration fixtures
│   ├── config.yaml
│   └── app_config.yaml
├── JSON/           # JSON data fixtures
│   ├── empty.json
│   └── invalid.json
└── Shell/          # Shell command output fixtures
    ├── cat_config_output.txt
    └── output_with_whitespace.txt
```

## Example E2E Test

```swift
import XCTest
import TestInfrastructure
import CommunicationDashboard

final class PluginE2ETests: XCTestCase {
    var mockServer: MockHTTPServer!
    var mockShell: MockShellExecutor!
    var dbManager: DatabaseManager!

    override func setUp() {
        super.setUp()
        mockServer = MockHTTPServer()
        mockShell = MockShellExecutor()
        dbManager = DatabaseManager(inMemory: true)

        try! mockServer.start()
        try! dbManager.initialize()
    }

    override func tearDown() {
        mockServer.stop()
        super.tearDown()
    }

    func testPluginWorkflow() throws {
        // Setup mocks
        try mockServer.registerFixture(
            endpoint: "/api/messages",
            method: "GET",
            fixturePath: "HTTP/plugin_response.json"
        )

        mockShell.registerCommand(
            command: "process-data",
            output: "Processed successfully",
            exitCode: 0
        )

        // Execute test scenario
        // 1. Fetch from API
        // 2. Process with shell
        // 3. Store in DB
        // 4. Verify results

        // Assertions
        XCTAssertEqual(mockServer.requestCount(for: "/api/messages", method: "GET"), 1)
        XCTAssertEqual(mockShell.executionCount(for: "process-data"), 1)
    }
}
```

## Running Tests

```bash
# Run all tests
swift test

# Run specific test target
swift test --filter TestInfrastructureTests

# Run with code coverage
swift test --enable-code-coverage

# Run in parallel
swift test --parallel
```

## CI Integration

Tests automatically run in GitHub Actions on:
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

See `.github/workflows/test.yml` for CI configuration.

## Notes

- All tests use isolated environments (in-memory DB, fresh mock instances)
- Tests are independent and can run in any order
- Fixtures are version-controlled and should be updated when API contracts change
- Mock server automatically finds available ports to avoid conflicts
