import XCTest
@testable import CommBoard

final class ConfigManagerTests: XCTestCase {

    // MARK: - Properties

    private var tempDirectory: URL!
    private var sut: ConfigManager!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        // 각 테스트마다 격리된 임시 디렉토리 사용
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CommBoardTests_\(UUID().uuidString)")
        sut = ConfigManager(baseDirectory: tempDirectory)
    }

    override func tearDown() {
        // 임시 디렉토리 정리
        try? FileManager.default.removeItem(at: tempDirectory)
        sut = nil
        tempDirectory = nil
        super.tearDown()
    }

    // MARK: - ensureDirectoriesExist 테스트

    func test_ensureDirectoriesExist_createsBaseDirectory() throws {
        // Arrange
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempDirectory.path))

        // Act
        try sut.ensureDirectoriesExist()

        // Assert
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDirectory.path))
    }

    func test_ensureDirectoriesExist_createsPluginsSubdirectory() throws {
        // Arrange
        let pluginsDir = tempDirectory.appendingPathComponent("plugins")
        XCTAssertFalse(FileManager.default.fileExists(atPath: pluginsDir.path))

        // Act
        try sut.ensureDirectoriesExist()

        // Assert
        XCTAssertTrue(FileManager.default.fileExists(atPath: pluginsDir.path))
    }

    func test_ensureDirectoriesExist_isIdempotent() throws {
        // Act & Assert - 두 번 호출해도 오류 없음
        XCTAssertNoThrow(try sut.ensureDirectoriesExist())
        XCTAssertNoThrow(try sut.ensureDirectoriesExist())
    }

    // MARK: - loadConfig 기본값 테스트

    func test_loadConfig_returnsDefaultConfig_whenFileDoesNotExist() throws {
        // Arrange - 파일 없음 (setUp에서 tempDirectory만 생성, 파일은 없음)

        // Act
        let config = try sut.loadConfig()

        // Assert
        XCTAssertNotNil(config["version"])
        XCTAssertNotNil(config["refresh_interval"])
        XCTAssertNotNil(config["theme"])
        XCTAssertNotNil(config["notifications"])
    }

    func test_loadConfig_defaultConfig_hasCorrectVersion() throws {
        // Act
        let config = try sut.loadConfig()

        // Assert
        XCTAssertEqual(config["version"] as? String, "1.0")
    }

    func test_loadConfig_defaultConfig_hasCorrectRefreshInterval() throws {
        // Act
        let config = try sut.loadConfig()

        // Assert
        XCTAssertEqual(config["refresh_interval"] as? Int, 300)
    }

    func test_loadConfig_defaultConfig_hasSystemTheme() throws {
        // Act
        let config = try sut.loadConfig()

        // Assert
        XCTAssertEqual(config["theme"] as? String, "system")
    }

    // MARK: - saveConfig / loadConfig 왕복 테스트

    func test_saveConfig_thenLoadConfig_returnsOriginalData() throws {
        // Arrange
        let config: [String: Any] = [
            "version": "2.0",
            "refresh_interval": 60,
            "theme": "dark"
        ]

        // Act
        try sut.saveConfig(config)
        let loaded = try sut.loadConfig()

        // Assert
        XCTAssertEqual(loaded["version"] as? String, "2.0")
        XCTAssertEqual(loaded["refresh_interval"] as? Int, 60)
        XCTAssertEqual(loaded["theme"] as? String, "dark")
    }

    func test_saveConfig_createsYamlFile() throws {
        // Arrange
        let config: [String: Any] = ["version": "1.0"]

        // Act
        try sut.saveConfig(config)

        // Assert
        XCTAssertTrue(FileManager.default.fileExists(atPath: sut.configFileURL.path))
    }

    func test_saveConfig_writesValidYamlContent() throws {
        // Arrange
        let config: [String: Any] = ["version": "1.0", "theme": "light"]

        // Act
        try sut.saveConfig(config)
        let content = try String(contentsOf: sut.configFileURL, encoding: .utf8)

        // Assert
        XCTAssertTrue(content.contains("version"), "YAML에 version 키가 있어야 합니다")
        XCTAssertTrue(content.contains("theme"), "YAML에 theme 키가 있어야 합니다")
    }

    func test_saveConfig_overwritesExistingFile() throws {
        // Arrange
        try sut.saveConfig(["version": "1.0"])

        // Act
        try sut.saveConfig(["version": "2.0", "theme": "dark"])
        let loaded = try sut.loadConfig()

        // Assert
        XCTAssertEqual(loaded["version"] as? String, "2.0")
        XCTAssertEqual(loaded["theme"] as? String, "dark")
    }

    // MARK: - createDefaultConfigIfNeeded 테스트

    func test_createDefaultConfigIfNeeded_createsFile_whenNotExists() throws {
        // Arrange
        XCTAssertFalse(FileManager.default.fileExists(atPath: sut.configFileURL.path))

        // Act
        try sut.createDefaultConfigIfNeeded()

        // Assert
        XCTAssertTrue(FileManager.default.fileExists(atPath: sut.configFileURL.path))
    }

    func test_createDefaultConfigIfNeeded_doesNotOverwrite_whenFileExists() throws {
        // Arrange - 기존 파일 생성
        let customConfig: [String: Any] = ["version": "99.0", "custom_key": "custom_value"]
        try sut.saveConfig(customConfig)

        // Act
        try sut.createDefaultConfigIfNeeded()
        let loaded = try sut.loadConfig()

        // Assert - 기존 파일이 유지되어야 함
        XCTAssertEqual(loaded["version"] as? String, "99.0")
        XCTAssertEqual(loaded["custom_key"] as? String, "custom_value")
    }

    // MARK: - Plugin Config 테스트

    func test_savePluginConfig_thenLoadPluginConfig_returnsOriginalData() throws {
        // Arrange
        let pluginConfig: [String: Any] = [
            "token": "xoxb-test-token",
            "workspace": "my-workspace",
            "channels": ["general", "dev"]
        ]

        // Act
        try sut.savePluginConfig(pluginConfig, pluginId: "slack")
        let loaded = try sut.loadPluginConfig(pluginId: "slack")

        // Assert
        XCTAssertEqual(loaded["token"] as? String, "xoxb-test-token")
        XCTAssertEqual(loaded["workspace"] as? String, "my-workspace")
    }

    func test_loadPluginConfig_returnsEmptyDict_whenFileDoesNotExist() throws {
        // Act
        let config = try sut.loadPluginConfig(pluginId: "nonexistent-plugin")

        // Assert
        XCTAssertTrue(config.isEmpty, "존재하지 않는 플러그인 설정은 빈 딕셔너리를 반환해야 합니다")
    }

    func test_savePluginConfig_createsYamlFileInPluginsDirectory() throws {
        // Arrange
        let expectedPath = tempDirectory
            .appendingPathComponent("plugins")
            .appendingPathComponent("github.yaml")

        // Act
        try sut.savePluginConfig(["token": "ghp_test"], pluginId: "github")

        // Assert
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedPath.path))
    }

    func test_loadAllPluginConfigs_returnsAllSavedPlugins() throws {
        // Arrange
        try sut.savePluginConfig(["token": "slack-token"], pluginId: "slack")
        try sut.savePluginConfig(["token": "github-token"], pluginId: "github")
        try sut.savePluginConfig(["token": "jira-token"], pluginId: "jira")

        // Act
        let allConfigs = try sut.loadAllPluginConfigs()

        // Assert
        XCTAssertEqual(allConfigs.count, 3)
        XCTAssertNotNil(allConfigs["slack"])
        XCTAssertNotNil(allConfigs["github"])
        XCTAssertNotNil(allConfigs["jira"])
    }

    func test_loadAllPluginConfigs_returnsEmptyDict_whenNoPluginsDirectory() throws {
        // Arrange - plugins 디렉토리 생성 없이 테스트

        // Act
        let allConfigs = try sut.loadAllPluginConfigs()

        // Assert
        XCTAssertTrue(allConfigs.isEmpty)
    }

    func test_loadAllPluginConfigs_onlyReturnsYamlFiles() throws {
        // Arrange
        try sut.ensureDirectoriesExist()
        try sut.savePluginConfig(["token": "t"], pluginId: "slack")

        // plugins 디렉토리에 .yaml이 아닌 파일 추가
        let nonYamlFile = sut.pluginsDirectory.appendingPathComponent("readme.txt")
        try "hello".write(to: nonYamlFile, atomically: true, encoding: .utf8)

        // Act
        let allConfigs = try sut.loadAllPluginConfigs()

        // Assert
        XCTAssertEqual(allConfigs.count, 1, ".yaml 파일만 로드해야 합니다")
        XCTAssertNotNil(allConfigs["slack"])
    }

    func test_savePluginConfig_overwritesExistingConfig() throws {
        // Arrange
        try sut.savePluginConfig(["token": "old-token"], pluginId: "slack")

        // Act
        try sut.savePluginConfig(["token": "new-token", "workspace": "new-ws"], pluginId: "slack")
        let loaded = try sut.loadPluginConfig(pluginId: "slack")

        // Assert
        XCTAssertEqual(loaded["token"] as? String, "new-token")
        XCTAssertEqual(loaded["workspace"] as? String, "new-ws")
    }
}
