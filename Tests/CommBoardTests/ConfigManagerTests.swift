import XCTest
@testable import CommBoard

final class ConfigManagerTests: XCTestCase {

    // MARK: - Properties

    private var sut: ConfigManager!
    private var tempDir: URL!

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
        // Use a fresh temp directory for each test to avoid cross-test pollution.
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("CommBoardConfigTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: tempDir,
            withIntermediateDirectories: true
        )
        sut = ConfigManager(configDirectory: tempDir)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDir)
        sut = nil
        tempDir = nil
        try await super.tearDown()
    }

    // MARK: - Helpers

    private func writeFile(name: String, content: String, in directory: URL? = nil) throws {
        let dir = directory ?? tempDir!
        let url = dir.appendingPathComponent(name)
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - readConfig: happy path

    func test_readConfig_returns_parsed_yaml_dictionary() throws {
        // Arrange
        let yaml = """
        app_name: CommBoard
        version: 1
        debug: false
        """
        try writeFile(name: "config.yaml", content: yaml)

        // Act
        let config = try sut.readConfig()

        // Assert
        XCTAssertEqual(config["app_name"] as? String, "CommBoard")
        XCTAssertEqual(config["version"] as? Int, 1)
        XCTAssertEqual(config["debug"] as? Bool, false)
    }

    func test_readConfig_handles_nested_yaml_structure() throws {
        // Arrange
        let yaml = """
        database:
          path: ~/.commboard/data.sqlite
          version: 2
        """
        try writeFile(name: "config.yaml", content: yaml)

        // Act
        let config = try sut.readConfig()

        // Assert
        let db = config["database"] as? [String: Any]
        XCTAssertNotNil(db)
        XCTAssertEqual(db?["path"] as? String, "~/.commboard/data.sqlite")
        XCTAssertEqual(db?["version"] as? Int, 2)
    }

    func test_readConfig_handles_yaml_with_list_values() throws {
        // Arrange
        let yaml = """
        enabled_plugins:
          - slack
          - github
          - jira
        """
        try writeFile(name: "config.yaml", content: yaml)

        // Act
        let config = try sut.readConfig()

        // Assert
        let plugins = config["enabled_plugins"] as? [String]
        XCTAssertEqual(plugins, ["slack", "github", "jira"])
    }

    // MARK: - readConfig: error cases

    func test_readConfig_throws_fileNotFound_when_config_missing() throws {
        // Act & Assert
        XCTAssertThrowsError(try sut.readConfig()) { error in
            guard case ConfigManagerError.fileNotFound = error else {
                return XCTFail("Expected fileNotFound, got \(error)")
            }
        }
    }

    func test_readConfig_throws_parseError_when_yaml_is_invalid() throws {
        // Arrange — YAML with a non-mapping root (plain scalar)
        try writeFile(name: "config.yaml", content: "just a string")

        // Act & Assert
        XCTAssertThrowsError(try sut.readConfig()) { error in
            guard case ConfigManagerError.parseError = error else {
                return XCTFail("Expected parseError, got \(error)")
            }
        }
    }

    // MARK: - writeConfig: happy path

    func test_writeConfig_creates_config_file() throws {
        // Arrange
        let config: [String: Any] = ["key": "value"]

        // Act
        try sut.writeConfig(config)

        // Assert
        let configURL = tempDir.appendingPathComponent("config.yaml")
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: configURL.path),
            "config.yaml should be created after writeConfig"
        )
    }

    func test_writeConfig_then_readConfig_round_trips_string_value() throws {
        // Arrange
        let original: [String: Any] = ["greeting": "hello"]

        // Act
        try sut.writeConfig(original)
        let readBack = try sut.readConfig()

        // Assert
        XCTAssertEqual(readBack["greeting"] as? String, "hello")
    }

    func test_writeConfig_then_readConfig_round_trips_integer_value() throws {
        // Arrange
        let original: [String: Any] = ["count": 42]

        // Act
        try sut.writeConfig(original)
        let readBack = try sut.readConfig()

        // Assert
        XCTAssertEqual(readBack["count"] as? Int, 42)
    }

    func test_writeConfig_overwrites_existing_file() throws {
        // Arrange
        try sut.writeConfig(["version": 1])

        // Act
        try sut.writeConfig(["version": 2])
        let readBack = try sut.readConfig()

        // Assert
        XCTAssertEqual(readBack["version"] as? Int, 2)
    }

    func test_writeConfig_creates_parent_directory_if_missing() throws {
        // Arrange — point to a non-existent subdirectory
        let nested = tempDir
            .appendingPathComponent("deep")
            .appendingPathComponent("nested")
        let nestedSut = ConfigManager(configDirectory: nested)

        // Act & Assert — should not throw
        XCTAssertNoThrow(try nestedSut.writeConfig(["key": "val"]))
    }

    // MARK: - readPluginConfigs: happy path

    func test_readPluginConfigs_returns_empty_array_when_plugins_directory_missing() throws {
        // Act
        let configs = try sut.readPluginConfigs()

        // Assert
        XCTAssertTrue(
            configs.isEmpty,
            "readPluginConfigs should return [] when plugins dir does not exist"
        )
    }

    func test_readPluginConfigs_returns_single_plugin_config() throws {
        // Arrange
        try FileManager.default.createDirectory(
            at: sut.pluginsDirectory,
            withIntermediateDirectories: true
        )
        let yaml = "plugin_id: slack\ntoken: xoxb-test"
        try writeFile(name: "slack.yaml", content: yaml, in: sut.pluginsDirectory)

        // Act
        let configs = try sut.readPluginConfigs()

        // Assert
        XCTAssertEqual(configs.count, 1)
        XCTAssertEqual(configs.first?["plugin_id"] as? String, "slack")
        XCTAssertEqual(configs.first?["token"] as? String, "xoxb-test")
    }

    func test_readPluginConfigs_returns_all_yaml_files_in_plugins_directory() throws {
        // Arrange
        try FileManager.default.createDirectory(
            at: sut.pluginsDirectory,
            withIntermediateDirectories: true
        )
        try writeFile(name: "github.yaml", content: "name: github", in: sut.pluginsDirectory)
        try writeFile(name: "jira.yaml", content: "name: jira", in: sut.pluginsDirectory)
        try writeFile(name: "slack.yaml", content: "name: slack", in: sut.pluginsDirectory)

        // Act
        let configs = try sut.readPluginConfigs()

        // Assert
        XCTAssertEqual(configs.count, 3)
    }

    func test_readPluginConfigs_ignores_non_yaml_files() throws {
        // Arrange
        try FileManager.default.createDirectory(
            at: sut.pluginsDirectory,
            withIntermediateDirectories: true
        )
        try writeFile(name: "slack.yaml", content: "name: slack", in: sut.pluginsDirectory)
        try writeFile(name: "README.md", content: "# readme", in: sut.pluginsDirectory)
        try writeFile(name: "config.json", content: "{}", in: sut.pluginsDirectory)

        // Act
        let configs = try sut.readPluginConfigs()

        // Assert
        XCTAssertEqual(configs.count, 1)
    }

    // MARK: - readPluginConfig by id: happy path

    func test_readPluginConfig_returns_config_for_given_plugin_id() throws {
        // Arrange
        try FileManager.default.createDirectory(
            at: sut.pluginsDirectory,
            withIntermediateDirectories: true
        )
        let yaml = "plugin_id: github\nrepo: org/repo"
        try writeFile(name: "github.yaml", content: yaml, in: sut.pluginsDirectory)

        // Act
        let config = try sut.readPluginConfig(pluginId: "github")

        // Assert
        XCTAssertEqual(config["plugin_id"] as? String, "github")
        XCTAssertEqual(config["repo"] as? String, "org/repo")
    }

    // MARK: - readPluginConfig by id: error cases

    func test_readPluginConfig_throws_fileNotFound_when_plugin_config_missing() throws {
        // Arrange
        try FileManager.default.createDirectory(
            at: sut.pluginsDirectory,
            withIntermediateDirectories: true
        )

        // Act & Assert
        XCTAssertThrowsError(try sut.readPluginConfig(pluginId: "nonexistent")) { error in
            guard case ConfigManagerError.fileNotFound = error else {
                return XCTFail("Expected fileNotFound, got \(error)")
            }
        }
    }
}
