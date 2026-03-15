import XCTest
@testable import CommBoard

// MARK: - ConfigManagerTests
//
// ConfigManager는 ~/.commboard/config.yaml 및
// ~/.commboard/plugins/*.yaml 파일을 읽고 씁니다.
// 테스트에서는 임시 디렉토리를 사용합니다.

final class ConfigManagerTests: XCTestCase {

    // MARK: - Properties

    var sut: ConfigManager!
    var tempDirectory: URL!

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()

        // 각 테스트마다 격리된 임시 디렉토리 생성
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("commboard_test_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        sut = ConfigManager(baseDirectory: tempDirectory)
    }

    override func tearDown() async throws {
        sut = nil

        // 임시 디렉토리 정리
        try? FileManager.default.removeItem(at: tempDirectory)
        tempDirectory = nil

        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization_WithCustomDirectory_Succeeds() {
        // Assert
        XCTAssertNotNil(sut, "ConfigManager가 임시 디렉토리로 초기화되어야 합니다")
    }

    func testInitialization_CreatesBaseDirectory_IfNotExists() throws {
        // Arrange
        let newDir = tempDirectory.appendingPathComponent("new_config_dir", isDirectory: true)
        XCTAssertFalse(FileManager.default.fileExists(atPath: newDir.path))

        // Act
        _ = ConfigManager(baseDirectory: newDir)

        // Assert
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: newDir.path),
            "ConfigManager 초기화 시 기본 디렉토리가 생성되어야 합니다"
        )

        // Cleanup
        try? FileManager.default.removeItem(at: newDir)
    }

    // MARK: - Config File Load Tests

    func testLoadConfig_WhenFileExists_ReturnsConfig() throws {
        // Arrange
        let configContent = """
        refreshInterval: 30
        theme: dark
        language: ko
        """
        let configURL = tempDirectory.appendingPathComponent("config.yaml")
        try configContent.write(to: configURL, atomically: true, encoding: .utf8)

        // Act
        let config = try sut.loadConfig()

        // Assert
        XCTAssertNotNil(config, "설정 파일이 존재할 때 config가 반환되어야 합니다")
        XCTAssertEqual(config.refreshInterval, 30, "refreshInterval이 올바르게 파싱되어야 합니다")
        XCTAssertEqual(config.theme, "dark", "theme이 올바르게 파싱되어야 합니다")
        XCTAssertEqual(config.language, "ko", "language가 올바르게 파싱되어야 합니다")
    }

    func testLoadConfig_WhenFileDoesNotExist_ReturnsDefaultConfig() throws {
        // Arrange: 설정 파일이 없는 상태 (setUp에서 빈 임시 디렉토리 생성)

        // Act
        let config = try sut.loadConfig()

        // Assert
        XCTAssertNotNil(config, "파일이 없을 때 기본 설정이 반환되어야 합니다")
    }

    func testLoadConfig_WhenFileHasInvalidYAML_ThrowsError() throws {
        // Arrange
        let invalidContent = "{ invalid yaml content ::::"
        let configURL = tempDirectory.appendingPathComponent("config.yaml")
        try invalidContent.write(to: configURL, atomically: true, encoding: .utf8)

        // Act & Assert
        XCTAssertThrowsError(
            try sut.loadConfig(),
            "잘못된 YAML 파일 파싱 시 에러가 발생해야 합니다"
        )
    }

    // MARK: - Config File Save Tests

    func testSaveConfig_Succeeds() throws {
        // Arrange
        let config = AppConfig(
            refreshInterval: 60,
            theme: "light",
            language: "en"
        )

        // Act
        try sut.saveConfig(config)

        // Assert
        let configURL = tempDirectory.appendingPathComponent("config.yaml")
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: configURL.path),
            "설정 저장 후 config.yaml 파일이 존재해야 합니다"
        )
    }

    func testSaveConfig_ThenLoad_ReturnsSameValues() throws {
        // Arrange
        let originalConfig = AppConfig(
            refreshInterval: 45,
            theme: "auto",
            language: "ja"
        )

        // Act
        try sut.saveConfig(originalConfig)
        let loadedConfig = try sut.loadConfig()

        // Assert
        XCTAssertEqual(loadedConfig.refreshInterval, 45, "저장/로드 후 refreshInterval이 동일해야 합니다")
        XCTAssertEqual(loadedConfig.theme, "auto", "저장/로드 후 theme이 동일해야 합니다")
        XCTAssertEqual(loadedConfig.language, "ja", "저장/로드 후 language가 동일해야 합니다")
    }

    func testSaveConfig_OverwritesExistingFile() throws {
        // Arrange
        let firstConfig = AppConfig(refreshInterval: 10, theme: "dark", language: "ko")
        let secondConfig = AppConfig(refreshInterval: 20, theme: "light", language: "en")
        try sut.saveConfig(firstConfig)

        // Act
        try sut.saveConfig(secondConfig)
        let loadedConfig = try sut.loadConfig()

        // Assert
        XCTAssertEqual(loadedConfig.refreshInterval, 20, "덮어쓰기 후 새 값이 반영되어야 합니다")
        XCTAssertEqual(loadedConfig.theme, "light")
    }

    // MARK: - Plugin Config Load Tests

    func testLoadPluginConfig_WhenFileExists_ReturnsPluginConfig() throws {
        // Arrange
        let pluginsDir = tempDirectory.appendingPathComponent("plugins", isDirectory: true)
        try FileManager.default.createDirectory(at: pluginsDir, withIntermediateDirectories: true)

        let pluginConfigContent = """
        id: slack
        enabled: true
        interval: 60
        token: test-token
        """
        let pluginConfigURL = pluginsDir.appendingPathComponent("slack.yaml")
        try pluginConfigContent.write(to: pluginConfigURL, atomically: true, encoding: .utf8)

        // Act
        let pluginConfig = try sut.loadPluginConfig(pluginId: "slack")

        // Assert
        XCTAssertNotNil(pluginConfig, "플러그인 설정 파일이 존재할 때 config가 반환되어야 합니다")
        XCTAssertEqual(pluginConfig?.pluginId, "slack", "플러그인 ID가 올바르게 파싱되어야 합니다")
        XCTAssertEqual(pluginConfig?.isEnabled, true, "enabled 값이 올바르게 파싱되어야 합니다")
        XCTAssertEqual(pluginConfig?.interval, 60, "interval이 올바르게 파싱되어야 합니다")
    }

    func testLoadPluginConfig_WhenFileDoesNotExist_ReturnsNil() throws {
        // Act
        let pluginConfig = try sut.loadPluginConfig(pluginId: "nonexistent-plugin")

        // Assert
        XCTAssertNil(pluginConfig, "존재하지 않는 플러그인 설정은 nil을 반환해야 합니다")
    }

    func testLoadAllPluginConfigs_ReturnsAllPluginFiles() throws {
        // Arrange
        let pluginsDir = tempDirectory.appendingPathComponent("plugins", isDirectory: true)
        try FileManager.default.createDirectory(at: pluginsDir, withIntermediateDirectories: true)

        let pluginIds = ["github", "jira", "slack"]
        for pluginId in pluginIds {
            let content = "id: \(pluginId)\nenabled: true\ninterval: 30\n"
            let url = pluginsDir.appendingPathComponent("\(pluginId).yaml")
            try content.write(to: url, atomically: true, encoding: .utf8)
        }

        // Act
        let configs = try sut.loadAllPluginConfigs()

        // Assert
        XCTAssertEqual(configs.count, 3, "플러그인 설정 파일 3개가 로드되어야 합니다")
    }

    func testSavePluginConfig_Succeeds() throws {
        // Arrange
        let pluginConfig = PluginConfig(
            pluginId: "github",
            isEnabled: true,
            interval: 120,
            settings: ["token": "ghp_test"]
        )

        // Act
        try sut.savePluginConfig(pluginConfig)

        // Assert
        let pluginsDir = tempDirectory.appendingPathComponent("plugins")
        let pluginFile = pluginsDir.appendingPathComponent("github.yaml")
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: pluginFile.path),
            "플러그인 설정 저장 후 파일이 존재해야 합니다"
        )
    }

    // MARK: - Default Config Tests

    func testCreateDefaultConfig_ReturnsValidConfig() {
        // Act
        let defaultConfig = sut.createDefaultConfig()

        // Assert
        XCTAssertNotNil(defaultConfig, "기본 설정이 반환되어야 합니다")
        XCTAssertGreaterThan(defaultConfig.refreshInterval, 0, "기본 refreshInterval은 양수여야 합니다")
        XCTAssertFalse(defaultConfig.theme.isEmpty, "기본 theme이 비어있지 않아야 합니다")
        XCTAssertFalse(defaultConfig.language.isEmpty, "기본 language가 비어있지 않아야 합니다")
    }

    func testCreateDefaultConfig_AndSave_Succeeds() throws {
        // Arrange
        let defaultConfig = sut.createDefaultConfig()

        // Act & Assert
        XCTAssertNoThrow(
            try sut.saveConfig(defaultConfig),
            "기본 설정 저장이 에러 없이 완료되어야 합니다"
        )
    }
}
