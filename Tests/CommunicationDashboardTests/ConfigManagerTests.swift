import XCTest
@testable import CommunicationDashboard

final class ConfigManagerTests: XCTestCase {

    // MARK: - Properties

    private var tempDirectory: URL!
    private var sut: ConfigManager!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("commboard-test-\(UUID().uuidString)")
        sut = ConfigManager(baseDirectory: tempDirectory)
    }

    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: tempDirectory)
        sut = nil
    }

    // MARK: - loadAppConfig - 파일 없을 때 기본값 생성

    func test_loadAppConfig_whenFileDoesNotExist_returnsDefaultConfig() throws {
        // Arrange - tempDirectory에는 config.yaml이 없음

        // Act
        let config = try sut.loadAppConfig()

        // Assert
        XCTAssertEqual(config.refreshInterval, 60)
        XCTAssertEqual(config.theme, "system")
        XCTAssertEqual(config.plugins, [])
    }

    func test_loadAppConfig_whenFileDoesNotExist_createsConfigFile() throws {
        // Arrange - 파일이 없음

        // Act
        _ = try sut.loadAppConfig()

        // Assert
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: sut.configFileURL.path),
            "기본값으로 config.yaml 파일이 생성되어야 합니다"
        )
    }

    func test_loadAppConfig_whenFileDoesNotExist_createsBaseDirectory() throws {
        // Arrange - baseDirectory가 존재하지 않음
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempDirectory.path))

        // Act
        _ = try sut.loadAppConfig()

        // Assert
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: tempDirectory.path),
            "baseDirectory가 자동으로 생성되어야 합니다"
        )
    }

    // MARK: - saveAppConfig / loadAppConfig - 왕복 테스트

    func test_saveAndLoadAppConfig_roundTrip_preservesRefreshInterval() throws {
        // Arrange
        let expected = AppConfig(refreshInterval: 120, theme: "dark", plugins: ["slack", "github"])

        // Act
        try sut.saveAppConfig(expected)
        let loaded = try sut.loadAppConfig()

        // Assert
        XCTAssertEqual(loaded.refreshInterval, 120)
    }

    func test_saveAndLoadAppConfig_roundTrip_preservesTheme() throws {
        // Arrange
        let expected = AppConfig(refreshInterval: 30, theme: "dark", plugins: [])

        // Act
        try sut.saveAppConfig(expected)
        let loaded = try sut.loadAppConfig()

        // Assert
        XCTAssertEqual(loaded.theme, "dark")
    }

    func test_saveAndLoadAppConfig_roundTrip_preservesPluginList() throws {
        // Arrange
        let expectedPlugins = ["slack", "github", "jira"]
        let config = AppConfig(refreshInterval: 60, theme: "system", plugins: expectedPlugins)

        // Act
        try sut.saveAppConfig(config)
        let loaded = try sut.loadAppConfig()

        // Assert
        XCTAssertEqual(Set(loaded.plugins), Set(expectedPlugins))
    }

    func test_saveAppConfig_createsYamlFile() throws {
        // Arrange
        let config = AppConfig(refreshInterval: 60, theme: "system", plugins: [])

        // Act
        try sut.saveAppConfig(config)

        // Assert
        XCTAssertTrue(FileManager.default.fileExists(atPath: sut.configFileURL.path))
    }

    func test_saveAppConfig_writesValidYamlContent() throws {
        // Arrange
        let config = AppConfig(refreshInterval: 90, theme: "light", plugins: ["slack"])

        // Act
        try sut.saveAppConfig(config)

        // Assert
        let content = try String(contentsOf: sut.configFileURL, encoding: .utf8)
        XCTAssertFalse(content.isEmpty, "YAML 파일 내용이 비어있으면 안 됩니다")
    }

    func test_saveAppConfig_overwritesExistingFile() throws {
        // Arrange
        let firstConfig = AppConfig(refreshInterval: 60, theme: "system", plugins: [])
        let secondConfig = AppConfig(refreshInterval: 30, theme: "dark", plugins: ["github"])
        try sut.saveAppConfig(firstConfig)

        // Act
        try sut.saveAppConfig(secondConfig)
        let loaded = try sut.loadAppConfig()

        // Assert
        XCTAssertEqual(loaded.refreshInterval, 30)
        XCTAssertEqual(loaded.theme, "dark")
    }

    // MARK: - loadPluginConfig - 파일 없을 때

    func test_loadPluginConfig_whenFileDoesNotExist_throwsFileNotFoundError() throws {
        // Arrange
        let nonExistentPluginId = "non-existent-plugin"

        // Act & Assert
        XCTAssertThrowsError(try sut.loadPluginConfig(pluginId: nonExistentPluginId)) { error in
            guard case ConfigManagerError.fileNotFound = error else {
                XCTFail("ConfigManagerError.fileNotFound 오류가 발생해야 합니다, 실제: \(error)")
                return
            }
        }
    }

    // MARK: - savePluginConfig / loadPluginConfig - 왕복 테스트

    func test_saveAndLoadPluginConfig_roundTrip_preservesId() throws {
        // Arrange
        let expected = PluginConfig(id: "slack", name: "Slack", enabled: true, interval: 300)

        // Act
        try sut.savePluginConfig(expected)
        let loaded = try sut.loadPluginConfig(pluginId: expected.id)

        // Assert
        XCTAssertEqual(loaded.id, "slack")
    }

    func test_saveAndLoadPluginConfig_roundTrip_preservesName() throws {
        // Arrange
        let expected = PluginConfig(id: "slack", name: "Slack Integration", enabled: true, interval: 300)

        // Act
        try sut.savePluginConfig(expected)
        let loaded = try sut.loadPluginConfig(pluginId: expected.id)

        // Assert
        XCTAssertEqual(loaded.name, "Slack Integration")
    }

    func test_saveAndLoadPluginConfig_roundTrip_preservesEnabledState() throws {
        // Arrange
        let expected = PluginConfig(id: "jira", name: "Jira", enabled: false, interval: 600)

        // Act
        try sut.savePluginConfig(expected)
        let loaded = try sut.loadPluginConfig(pluginId: expected.id)

        // Assert
        XCTAssertEqual(loaded.enabled, false)
    }

    func test_saveAndLoadPluginConfig_roundTrip_preservesInterval() throws {
        // Arrange
        let expected = PluginConfig(id: "github", name: "GitHub", enabled: true, interval: 120)

        // Act
        try sut.savePluginConfig(expected)
        let loaded = try sut.loadPluginConfig(pluginId: expected.id)

        // Assert
        XCTAssertEqual(loaded.interval, 120)
    }

    func test_saveAndLoadPluginConfig_roundTrip_preservesSettings() throws {
        // Arrange
        let settings = ["token": "abc123", "workspace": "myteam"]
        let expected = PluginConfig(id: "slack", name: "Slack", enabled: true, interval: 300, settings: settings)

        // Act
        try sut.savePluginConfig(expected)
        let loaded = try sut.loadPluginConfig(pluginId: expected.id)

        // Assert
        XCTAssertEqual(loaded.settings["token"], "abc123")
        XCTAssertEqual(loaded.settings["workspace"], "myteam")
    }

    func test_savePluginConfig_createsPluginsDirectory() throws {
        // Arrange
        let config = PluginConfig(id: "slack", name: "Slack", enabled: true, interval: 300)

        // Act
        try sut.savePluginConfig(config)

        // Assert
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: sut.pluginsDirectory.path),
            "plugins 디렉토리가 자동으로 생성되어야 합니다"
        )
    }

    func test_savePluginConfig_createsYamlFileWithPluginId() throws {
        // Arrange
        let config = PluginConfig(id: "github", name: "GitHub", enabled: true, interval: 120)

        // Act
        try sut.savePluginConfig(config)

        // Assert
        let expectedPath = sut.pluginsDirectory.appendingPathComponent("github.yaml").path
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedPath))
    }

    // MARK: - loadAllPluginConfigs

    func test_loadAllPluginConfigs_whenNoPluginsDirectory_returnsEmptyArray() throws {
        // Arrange - plugins 디렉토리가 없음

        // Act
        let configs = try sut.loadAllPluginConfigs()

        // Assert
        XCTAssertTrue(configs.isEmpty, "플러그인 디렉토리가 없으면 빈 배열을 반환해야 합니다")
    }

    func test_loadAllPluginConfigs_withMultiplePlugins_returnsAllConfigs() throws {
        // Arrange
        let slackConfig = PluginConfig(id: "slack", name: "Slack", enabled: true, interval: 300)
        let githubConfig = PluginConfig(id: "github", name: "GitHub", enabled: true, interval: 120)
        let jiraConfig = PluginConfig(id: "jira", name: "Jira", enabled: false, interval: 600)
        try sut.savePluginConfig(slackConfig)
        try sut.savePluginConfig(githubConfig)
        try sut.savePluginConfig(jiraConfig)

        // Act
        let configs = try sut.loadAllPluginConfigs()

        // Assert
        XCTAssertEqual(configs.count, 3, "저장된 플러그인 수만큼 반환해야 합니다")
    }

    func test_loadAllPluginConfigs_returnsOnlyYamlFiles() throws {
        // Arrange
        let config = PluginConfig(id: "slack", name: "Slack", enabled: true, interval: 300)
        try sut.savePluginConfig(config)

        // yaml이 아닌 파일 생성
        try FileManager.default.createDirectory(at: sut.pluginsDirectory, withIntermediateDirectories: true)
        let txtFile = sut.pluginsDirectory.appendingPathComponent("notes.txt")
        try "not a plugin".write(to: txtFile, atomically: true, encoding: .utf8)

        // Act
        let configs = try sut.loadAllPluginConfigs()

        // Assert
        XCTAssertEqual(configs.count, 1, ".yaml 파일만 로드해야 합니다")
    }

    // MARK: - 엣지 케이스

    func test_loadAppConfig_withEmptyPluginList_returnsEmptyArray() throws {
        // Arrange
        let config = AppConfig(refreshInterval: 60, theme: "system", plugins: [])
        try sut.saveAppConfig(config)

        // Act
        let loaded = try sut.loadAppConfig()

        // Assert
        XCTAssertEqual(loaded.plugins, [])
    }

    func test_configFileURL_pointsToCorrectPath() throws {
        // Assert
        XCTAssertTrue(sut.configFileURL.path.hasSuffix("config.yaml"))
        XCTAssertTrue(sut.configFileURL.path.contains(tempDirectory.lastPathComponent))
    }

    func test_pluginsDirectory_isSubdirectoryOfBaseDirectory() throws {
        // Assert
        XCTAssertTrue(sut.pluginsDirectory.path.hasPrefix(tempDirectory.path))
        XCTAssertTrue(sut.pluginsDirectory.lastPathComponent == "plugins")
    }
}
