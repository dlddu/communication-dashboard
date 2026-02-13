import XCTest
import Foundation
@testable import TestInfrastructure

final class FixtureLoaderTests: XCTestCase {
    var fixtureLoader: FixtureLoader!

    override func setUp() {
        super.setUp()
        // Use Bundle.module to locate test fixtures
        let fixturesDirectory = Bundle.module.resourceURL!.appendingPathComponent("Fixtures")
        fixtureLoader = FixtureLoader(fixturesDirectory: fixturesDirectory)
    }

    override func tearDown() {
        fixtureLoader = nil
        super.tearDown()
    }

    // MARK: - Happy Path Tests

    func testLoadJSONFixture() throws {
        // Act
        let data = try fixtureLoader.loadFixture(path: "HTTP/plugin_response.json")

        // Assert
        XCTAssertFalse(data.isEmpty, "Fixture data should not be empty")

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json, "Should be valid JSON")
    }

    func testLoadYAMLFixture() throws {
        // Act
        let data = try fixtureLoader.loadFixture(path: "YAML/config.yaml")

        // Assert
        XCTAssertFalse(data.isEmpty, "Fixture data should not be empty")

        let yamlString = String(data: data, encoding: .utf8)
        XCTAssertNotNil(yamlString, "Should be valid YAML text")
    }

    func testLoadTextFixture() throws {
        // Act
        let data = try fixtureLoader.loadFixture(path: "Shell/cat_config_output.txt")

        // Assert
        XCTAssertFalse(data.isEmpty, "Fixture data should not be empty")

        let text = String(data: data, encoding: .utf8)
        XCTAssertNotNil(text, "Should be valid text")
    }

    func testParseJSONFixture() throws {
        // Arrange
        struct TestResponse: Codable {
            let status: String
            let data: DataPayload

            struct DataPayload: Codable {
                let message: String
            }
        }

        // Act
        let parsed: TestResponse = try fixtureLoader.loadAndParse(
            path: "HTTP/plugin_response.json"
        )

        // Assert
        XCTAssertEqual(parsed.status, "success", "Should parse JSON fixture correctly")
        XCTAssertFalse(parsed.data.message.isEmpty, "Should have data payload")
    }

    func testParseYAMLFixture() throws {
        // Arrange
        struct Config: Codable {
            let plugins: [PluginConfig]

            struct PluginConfig: Codable {
                let name: String
                let enabled: Bool
            }
        }

        // Act
        let parsed: Config = try fixtureLoader.loadYAMLAndParse(
            path: "YAML/config.yaml"
        )

        // Assert
        XCTAssertFalse(parsed.plugins.isEmpty, "Should parse YAML fixture correctly")
        XCTAssertNotNil(parsed.plugins.first?.name, "Should have plugin configuration")
    }

    func testLoadFixtureAsString() throws {
        // Act
        let content = try fixtureLoader.loadFixtureAsString(path: "Shell/cat_config_output.txt")

        // Assert
        XCTAssertFalse(content.isEmpty, "String content should not be empty")
        XCTAssertTrue(content is String, "Should return String type")
    }

    func testLoadMultipleFixtures() throws {
        // Act
        let json = try fixtureLoader.loadFixture(path: "HTTP/plugin_response.json")
        let yaml = try fixtureLoader.loadFixture(path: "YAML/config.yaml")
        let text = try fixtureLoader.loadFixture(path: "Shell/cat_config_output.txt")

        // Assert
        XCTAssertFalse(json.isEmpty, "JSON fixture should load")
        XCTAssertFalse(yaml.isEmpty, "YAML fixture should load")
        XCTAssertFalse(text.isEmpty, "Text fixture should load")
    }

    func testFixturePathResolution() throws {
        // Act
        let absolutePath = try fixtureLoader.resolveFixturePath("HTTP/plugin_response.json")

        // Assert
        XCTAssertTrue(absolutePath.contains("Fixtures"), "Should resolve to Fixtures directory")
        XCTAssertTrue(absolutePath.hasSuffix("plugin_response.json"), "Should preserve filename")
    }

    func testListFixturesInDirectory() throws {
        // Act
        let httpFixtures = try fixtureLoader.listFixtures(in: "HTTP")

        // Assert
        XCTAssertFalse(httpFixtures.isEmpty, "Should find fixtures in HTTP directory")
        XCTAssertTrue(
            httpFixtures.contains { $0.hasSuffix(".json") },
            "Should list JSON files"
        )
    }

    // MARK: - Edge Case Tests

    func testLoadEmptyFixture() throws {
        // Act
        let data = try fixtureLoader.loadFixture(path: "JSON/empty.json")

        // Assert
        XCTAssertNotNil(data, "Should handle empty fixture")
    }

    func testLoadFixtureWithSpecialCharacters() throws {
        // Act
        let data = try fixtureLoader.loadFixture(path: "JSON/special_chars_😀.json")

        // Assert
        XCTAssertFalse(data.isEmpty, "Should handle special characters in filename")
    }

    func testLoadNestedDirectoryFixture() throws {
        // Act
        let data = try fixtureLoader.loadFixture(path: "HTTP/v2/plugin_response.json")

        // Assert
        XCTAssertFalse(data.isEmpty, "Should handle nested directory paths")
    }

    func testCaseInsensitiveFileExtension() throws {
        // Act
        let data = try fixtureLoader.loadFixture(path: "YAML/config.YAML")

        // Assert
        XCTAssertFalse(data.isEmpty, "Should handle case-insensitive extensions")
    }

    func testLoadFixtureWithWhitespace() throws {
        // Act
        let content = try fixtureLoader.loadFixtureAsString(path: "Shell/output_with_whitespace.txt")

        // Assert
        XCTAssertTrue(content.contains("\n"), "Should preserve whitespace")
        XCTAssertTrue(content.contains("\t"), "Should preserve tabs")
    }

    func testFixtureLoaderCaching() throws {
        // Arrange
        let path = "HTTP/plugin_response.json"

        // Act
        let data1 = try fixtureLoader.loadFixture(path: path)
        let data2 = try fixtureLoader.loadFixture(path: path)

        // Assert
        XCTAssertEqual(data1, data2, "Should return same data for repeated loads")
    }

    func testClearCache() throws {
        // Arrange
        let path = "HTTP/plugin_response.json"
        _ = try fixtureLoader.loadFixture(path: path)

        // Act
        fixtureLoader.clearCache()
        let dataAfterClear = try fixtureLoader.loadFixture(path: path)

        // Assert
        XCTAssertFalse(dataAfterClear.isEmpty, "Should reload after cache clear")
    }

    // MARK: - Error Case Tests

    func testLoadNonexistentFixtureThrows() {
        // Act & Assert
        XCTAssertThrowsError(
            try fixtureLoader.loadFixture(path: "nonexistent.json"),
            "Should throw error for nonexistent fixture"
        ) { error in
            XCTAssertTrue(
                error is FixtureLoader.FixtureError,
                "Should throw FixtureError"
            )
        }
    }

    func testLoadFixtureWithInvalidPathThrows() {
        // Act & Assert
        XCTAssertThrowsError(
            try fixtureLoader.loadFixture(path: "../../../etc/passwd"),
            "Should throw error for path traversal attempt"
        ) { error in
            XCTAssertTrue(
                error is FixtureLoader.FixtureError,
                "Should throw FixtureError"
            )
        }
    }

    func testParseInvalidJSONThrows() {
        // Act & Assert
        XCTAssertThrowsError(
            try fixtureLoader.loadAndParse(path: "JSON/invalid.json") as [String: Any],
            "Should throw error for invalid JSON"
        ) { error in
            XCTAssertTrue(
                error is FixtureLoader.ParseError,
                "Should throw ParseError"
            )
        }
    }

    func testParseInvalidYAMLThrows() {
        // Act & Assert
        XCTAssertThrowsError(
            try fixtureLoader.loadYAMLAndParse(path: "YAML/invalid.yaml") as [String: Any],
            "Should throw error for invalid YAML"
        ) { error in
            XCTAssertTrue(
                error is FixtureLoader.ParseError,
                "Should throw ParseError"
            )
        }
    }

    func testLoadFixtureWithWrongEncodingThrows() {
        // Act & Assert
        XCTAssertThrowsError(
            try fixtureLoader.loadFixtureAsString(path: "Binary/image.png"),
            "Should throw error when trying to load binary as string"
        ) { error in
            XCTAssertTrue(
                error is FixtureLoader.EncodingError,
                "Should throw EncodingError"
            )
        }
    }

    func testLoadFixtureWithEmptyPathThrows() {
        // Act & Assert
        XCTAssertThrowsError(
            try fixtureLoader.loadFixture(path: ""),
            "Should throw error for empty path"
        ) { error in
            XCTAssertTrue(
                error is FixtureLoader.FixtureError,
                "Should throw FixtureError"
            )
        }
    }

    // MARK: - Type Safety Tests

    func testTypeSafeJSONParsing() throws {
        // Arrange
        struct PluginResponse: Codable, Equatable {
            let status: String
            let version: String
            let data: ResponseData

            struct ResponseData: Codable, Equatable {
                let items: [String]
                let count: Int
            }
        }

        // Act
        let response: PluginResponse = try fixtureLoader.loadAndParse(
            path: "HTTP/plugin_response.json"
        )

        // Assert
        XCTAssertEqual(response.status, "success")
        XCTAssertGreaterThan(response.data.count, 0)
    }

    func testTypeSafeYAMLParsing() throws {
        // Arrange
        struct AppConfig: Codable {
            let appName: String
            let version: String
            let features: [String: Bool]
        }

        // Act
        let config: AppConfig = try fixtureLoader.loadYAMLAndParse(
            path: "YAML/app_config.yaml"
        )

        // Assert
        XCTAssertFalse(config.appName.isEmpty)
        XCTAssertFalse(config.features.isEmpty)
    }

    // MARK: - Helper Method Tests

    func testFixtureExists() {
        // Act
        let exists = fixtureLoader.fixtureExists(path: "HTTP/plugin_response.json")
        let notExists = fixtureLoader.fixtureExists(path: "nonexistent.json")

        // Assert
        XCTAssertTrue(exists, "Should return true for existing fixture")
        XCTAssertFalse(notExists, "Should return false for nonexistent fixture")
    }

    func testGetFixtureURL() throws {
        // Act
        let url = try fixtureLoader.getFixtureURL(path: "HTTP/plugin_response.json")

        // Assert
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "URL should point to existing file")
    }

    func testLoadAllFixturesInDirectory() throws {
        // Act
        let fixtures = try fixtureLoader.loadAllFixtures(in: "HTTP")

        // Assert
        XCTAssertFalse(fixtures.isEmpty, "Should load all fixtures in directory")
        XCTAssertTrue(fixtures.keys.contains { $0.contains("plugin_response") })
    }
}
