# Communication Dashboard

A macOS application built with SwiftUI for managing communication data with embedded vector search capabilities.

## Features

- Configuration directory management
- SQLite database with GRDB
- Full-text search with FTS5
- Vector embeddings storage
- Modern SwiftUI interface

## Requirements

- macOS 13.0+
- Swift 5.9+
- Xcode 15.0+

## Development

### Building

```bash
swift build
```

### Running Tests

```bash
swift test
```

### Running Tests with Coverage

```bash
swift test --enable-code-coverage
```

## Project Structure

```
communication-dashboard/
├── Sources/
│   └── CommunicationDashboard/
│       ├── CommunicationDashboardApp.swift
│       ├── ContentView.swift
│       ├── ConfigService.swift
│       └── DatabaseManager.swift
└── Tests/
    └── CommunicationDashboardTests/
        ├── ConfigServiceTests.swift
        ├── DatabaseManagerTests.swift
        └── AppStructureTests.swift
```

## Testing Strategy

This project follows Test-Driven Development (TDD):

1. Tests are written first (Red phase)
2. Implementation follows to make tests pass (Green phase)
3. Code is refactored for quality (Refactor phase)

### Test Coverage

- ConfigService: Directory creation and management
- DatabaseManager: Database initialization, migrations, and schema
- App Structure: SwiftUI app lifecycle and navigation

## CI/CD

GitHub Actions workflow runs on every push and pull request:
- Swift package validation
- Unit tests with coverage
- SwiftLint checks

## License

MIT