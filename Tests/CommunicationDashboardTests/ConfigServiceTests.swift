import XCTest
import Foundation
@testable import CommunicationDashboard

final class ConfigServiceTests: XCTestCase {
    var tempDirectory: URL!
    var configService: ConfigService!

    override func setUp() {
        super.setUp()
        // Create temporary directory for testing
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        configService = ConfigService(baseDirectory: tempDirectory)
    }

    override func tearDown() {
        // Clean up temporary directory
        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        super.tearDown()
    }

    // MARK: - Happy Path Tests

    func testInitializeCreatesBaseDirectory() throws {
        // Act
        try configService.initialize()

        // Assert
        let baseDirectoryPath = tempDirectory.appendingPathComponent(".config/commdash")
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: baseDirectoryPath.path),
            "Base directory should be created"
        )
    }

    func testInitializeCreatesAllSubdirectories() throws {
        // Act
        try configService.initialize()

        // Assert
        let baseDirectory = tempDirectory.appendingPathComponent(".config/commdash")
        let expectedSubdirectories = ["db", "models", "cache", "logs"]

        for subdirectory in expectedSubdirectories {
            let subdirectoryPath = baseDirectory.appendingPathComponent(subdirectory)
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: subdirectoryPath.path),
                "\(subdirectory) subdirectory should be created"
            )
        }
    }

    func testInitializeCreatesDirectoriesWithCorrectAttributes() throws {
        // Act
        try configService.initialize()

        // Assert
        let baseDirectory = tempDirectory.appendingPathComponent(".config/commdash")
        let attributes = try FileManager.default.attributesOfItem(atPath: baseDirectory.path)
        let fileType = attributes[.type] as? FileAttributeType

        XCTAssertEqual(fileType, .typeDirectory, "Should be a directory")
    }

    func testGetDirectoryPathReturnsCorrectPath() throws {
        // Arrange
        try configService.initialize()

        // Act
        let dbPath = try configService.getDirectoryPath(for: .db)

        // Assert
        let expectedPath = tempDirectory
            .appendingPathComponent(".config/commdash")
            .appendingPathComponent("db")
        XCTAssertEqual(dbPath.path, expectedPath.path, "Should return correct db directory path")
    }

    func testGetDirectoryPathForAllSubdirectoryTypes() throws {
        // Arrange
        try configService.initialize()

        // Act & Assert
        let subdirectoryTypes: [ConfigService.SubdirectoryType] = [.db, .models, .cache, .logs]

        for type in subdirectoryTypes {
            let path = try configService.getDirectoryPath(for: type)
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: path.path),
                "\(type) path should exist and be accessible"
            )
        }
    }

    // MARK: - Edge Case Tests

    func testInitializeWhenDirectoryAlreadyExists() throws {
        // Arrange
        try configService.initialize()

        // Act - Call initialize again
        try configService.initialize()

        // Assert - Should not throw error
        let baseDirectory = tempDirectory.appendingPathComponent(".config/commdash")
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: baseDirectory.path),
            "Directory should still exist after second initialization"
        )
    }

    func testInitializeWhenSubdirectoryAlreadyExists() throws {
        // Arrange
        let baseDirectory = tempDirectory.appendingPathComponent(".config/commdash/db")
        try FileManager.default.createDirectory(
            at: baseDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )

        // Act
        try configService.initialize()

        // Assert - Should not throw error
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: baseDirectory.path),
            "Existing subdirectory should remain intact"
        )
    }

    func testInitializeWithFilesInDirectory() throws {
        // Arrange
        let baseDirectory = tempDirectory.appendingPathComponent(".config/commdash/db")
        try FileManager.default.createDirectory(
            at: baseDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        let testFile = baseDirectory.appendingPathComponent("test.db")
        try Data().write(to: testFile)

        // Act
        try configService.initialize()

        // Assert
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: testFile.path),
            "Existing files should not be affected"
        )
    }

    // MARK: - Error Case Tests

    func testGetDirectoryPathThrowsWhenNotInitialized() {
        // Arrange
        let uninitializedService = ConfigService(baseDirectory: tempDirectory)

        // Act & Assert
        XCTAssertThrowsError(
            try uninitializedService.getDirectoryPath(for: .db),
            "Should throw error when accessing path before initialization"
        ) { error in
            XCTAssertTrue(
                error is ConfigService.ConfigError,
                "Should throw ConfigError"
            )
        }
    }

    func testInitializeThrowsWhenPermissionDenied() throws {
        // Arrange - Create a read-only parent directory
        let readOnlyDirectory = tempDirectory.appendingPathComponent("readonly")
        try FileManager.default.createDirectory(
            at: readOnlyDirectory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o444]
        )

        let restrictedService = ConfigService(baseDirectory: readOnlyDirectory)

        // Act & Assert
        XCTAssertThrowsError(
            try restrictedService.initialize(),
            "Should throw error when unable to create directory due to permissions"
        )

        // Cleanup - restore permissions
        try? FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: readOnlyDirectory.path
        )
    }

    func testDirectoryExistsReturnsFalseWhenNotInitialized() {
        // Arrange
        let uninitializedService = ConfigService(baseDirectory: tempDirectory)

        // Act
        let exists = uninitializedService.directoryExists()

        // Assert
        XCTAssertFalse(exists, "Should return false when directory doesn't exist")
    }

    func testDirectoryExistsReturnsTrueAfterInitialization() throws {
        // Arrange
        try configService.initialize()

        // Act
        let exists = configService.directoryExists()

        // Assert
        XCTAssertTrue(exists, "Should return true after successful initialization")
    }
}
