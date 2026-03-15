import XCTest
import Foundation
@testable import CommBoard

final class ConfigManagerTests: XCTestCase {

    // MARK: - Setup / Teardown

    var tempDirectory: URL!
    var configManager: ConfigManager!

    override func setUp() async throws {
        try await super.setUp()
        // Use a fresh temporary directory for each test
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CommBoardTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true
        )
        configManager = ConfigManager(baseDirectory: tempDirectory)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        configManager = nil
        tempDirectory = nil
        try await super.tearDown()
    }

    // MARK: - AppConfig: loadAppConfig

    func test_loadAppConfig_returnsDefaultConfig_whenFileDoesNotExist() throws {
        // Arrange: no config file exists

        // Act
        let config = try configManager.loadAppConfig()

        // Assert: should return a default config without throwing
        XCTAssertNotNil(config)
    }

    func test_loadAppConfig_parsesValidYAML() throws {
        // Arrange
        let yaml = """
        refresh_interval: 30
        theme: dark
        enable_notifications: true
        """
        let configURL = tempDirectory.appendingPathComponent("config.yaml")
        try yaml.write(to: configURL, atomically: true, encoding: .utf8)

        // Act
        let config = try configManager.loadAppConfig()

        // Assert
        XCTAssertEqual(config.refreshInterval, 30)
        XCTAssertEqual(config.theme, "dark")
        XCTAssertEqual(config.enableNotifications, true)
    }

    func test_loadAppConfig_throwsError_whenYAMLisMalformed() throws {
        // Arrange
        let malformedYAML = """
        refresh_interval: [this is not valid yaml for an int
        """
        let configURL = tempDirectory.appendingPathComponent("config.yaml")
        try malformedYAML.write(to: configURL, atomically: true, encoding: .utf8)

        // Act & Assert
        XCTAssertThrowsError(try configManager.loadAppConfig())
    }

    // MARK: - AppConfig: saveAppConfig

    func test_saveAppConfig_createsFileAtExpectedPath() throws {
        // Arrange
        let config = AppConfig(refreshInterval: 60, theme: "light", enableNotifications: false)

        // Act
        try configManager.saveAppConfig(config)

        // Assert
        let configURL = tempDirectory.appendingPathComponent("config.yaml")
        XCTAssertTrue(FileManager.default.fileExists(atPath: configURL.path))
    }

    func test_saveAppConfig_writesValidYAML_thatCanBeLoadedBack() throws {
        // Arrange
        let original = AppConfig(refreshInterval: 45, theme: "dark", enableNotifications: true)

        // Act
        try configManager.saveAppConfig(original)
        let loaded = try configManager.loadAppConfig()

        // Assert
        XCTAssertEqual(loaded, original)
    }

    func test_saveAppConfig_overwritesExistingFile() throws {
        // Arrange
        let first = AppConfig(refreshInterval: 10, theme: "light", enableNotifications: false)
        let second = AppConfig(refreshInterval: 99, theme: "dark", enableNotifications: true)

        // Act
        try configManager.saveAppConfig(first)
        try configManager.saveAppConfig(second)
        let loaded = try configManager.loadAppConfig()

        // Assert
        XCTAssertEqual(loaded, second)
    }

    func test_saveAppConfig_createsIntermediateDirectories() throws {
        // Arrange: use a nested directory that doesn't yet exist
        let nestedDir = tempDirectory.appendingPathComponent("nested/deep/dir")
        let nestedConfigManager = ConfigManager(baseDirectory: nestedDir)
        let config = AppConfig(refreshInterval: 15, theme: "system", enableNotifications: true)

        // Act & Assert: should not throw even though parent dirs don't exist
        XCTAssertNoThrow(try nestedConfigManager.saveAppConfig(config))
    }

    // MARK: - PluginConfig: loadPluginConfig

    func test_loadPluginConfig_parsesValidYAML() throws {
        // Arrange
        let pluginsDir = tempDirectory.appendingPathComponent("plugins")
        try FileManager.default.createDirectory(at: pluginsDir, withIntermediateDirectories: true)
        let yaml = """
        id: slack
        name: Slack
        enabled: true
        settings:
          token: xoxb-test-token
          workspace: myworkspace
        """
        let pluginURL = pluginsDir.appendingPathComponent("slack.yaml")
        try yaml.write(to: pluginURL, atomically: true, encoding: .utf8)

        // Act
        let config = try configManager.loadPluginConfig(pluginId: "slack")

        // Assert
        XCTAssertEqual(config.id, "slack")
        XCTAssertEqual(config.name, "Slack")
        XCTAssertTrue(config.enabled)
        XCTAssertEqual(config.settings["token"], "xoxb-test-token")
        XCTAssertEqual(config.settings["workspace"], "myworkspace")
    }

    func test_loadPluginConfig_throwsError_whenPluginFileDoesNotExist() throws {
        // Arrange: no plugins directory

        // Act & Assert
        XCTAssertThrowsError(try configManager.loadPluginConfig(pluginId: "nonexistent"))
    }

    // MARK: - PluginConfig: savePluginConfig

    func test_savePluginConfig_createsFileInPluginsDirectory() throws {
        // Arrange
        let config = PluginConfig(
            id: "github",
            name: "GitHub",
            enabled: true,
            settings: ["token": "ghp_testtoken"]
        )

        // Act
        try configManager.savePluginConfig(config)

        // Assert
        let pluginURL = tempDirectory
            .appendingPathComponent("plugins")
            .appendingPathComponent("github.yaml")
        XCTAssertTrue(FileManager.default.fileExists(atPath: pluginURL.path))
    }

    func test_savePluginConfig_roundtrip_preservesAllFields() throws {
        // Arrange
        let original = PluginConfig(
            id: "jira",
            name: "Jira",
            enabled: false,
            settings: ["host": "https://company.atlassian.net", "user": "testuser"]
        )

        // Act
        try configManager.savePluginConfig(original)
        let loaded = try configManager.loadPluginConfig(pluginId: "jira")

        // Assert
        XCTAssertEqual(loaded, original)
    }

    // MARK: - loadAllPluginConfigs

    func test_loadAllPluginConfigs_returnsEmptyArray_whenNoPluginsExist() throws {
        // Arrange: no plugins directory

        // Act
        let configs = try configManager.loadAllPluginConfigs()

        // Assert
        XCTAssertTrue(configs.isEmpty)
    }

    func test_loadAllPluginConfigs_returnsAllYAMLFilesFromPluginsDirectory() throws {
        // Arrange: save two plugin configs
        let slack = PluginConfig(id: "slack", name: "Slack", enabled: true, settings: [:])
        let github = PluginConfig(id: "github", name: "GitHub", enabled: false, settings: [:])
        try configManager.savePluginConfig(slack)
        try configManager.savePluginConfig(github)

        // Act
        let configs = try configManager.loadAllPluginConfigs()

        // Assert
        XCTAssertEqual(configs.count, 2)
        let ids = Set(configs.map { $0.id })
        XCTAssertTrue(ids.contains("slack"))
        XCTAssertTrue(ids.contains("github"))
    }

    func test_loadAllPluginConfigs_ignoresNonYAMLFiles() throws {
        // Arrange
        let pluginsDir = tempDirectory.appendingPathComponent("plugins")
        try FileManager.default.createDirectory(at: pluginsDir, withIntermediateDirectories: true)
        // Write a valid yaml plugin file and a random file
        let slack = PluginConfig(id: "slack", name: "Slack", enabled: true, settings: [:])
        try configManager.savePluginConfig(slack)
        let junkURL = pluginsDir.appendingPathComponent("notes.txt")
        try "some text".write(to: junkURL, atomically: true, encoding: .utf8)

        // Act
        let configs = try configManager.loadAllPluginConfigs()

        // Assert: only the yaml file should be loaded
        XCTAssertEqual(configs.count, 1)
        XCTAssertEqual(configs[0].id, "slack")
    }
}
