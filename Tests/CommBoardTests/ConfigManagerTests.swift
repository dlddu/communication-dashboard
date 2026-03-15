import XCTest
@testable import CommBoard

final class ConfigManagerTests: XCTestCase {

    // MARK: - Setup

    var tempDirectory: URL!
    var configManager: ConfigManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        // 각 테스트마다 독립적인 임시 디렉토리 사용
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CommBoardTests_\(UUID().uuidString)")
        configManager = ConfigManager(baseDirectory: tempDirectory)
    }

    override func tearDownWithError() throws {
        // 임시 디렉토리 정리
        try? FileManager.default.removeItem(at: tempDirectory)
        configManager = nil
        tempDirectory = nil
        try super.tearDownWithError()
    }

    // MARK: - 디렉토리 자동 생성

    func test_ensureDirectoriesExist_createsBaseDirectory() throws {
        // Arrange: 디렉토리가 없는 상태
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: tempDirectory.path),
            "테스트 시작 시 base 디렉토리가 없어야 합니다"
        )

        // Act
        try configManager.ensureDirectoriesExist()

        // Assert
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: tempDirectory.path),
            "ensureDirectoriesExist() 호출 후 base 디렉토리가 생성되어야 합니다"
        )
    }

    func test_ensureDirectoriesExist_createsPluginsSubdirectory() throws {
        // Act
        try configManager.ensureDirectoriesExist()

        // Assert
        let pluginsPath = tempDirectory.appendingPathComponent("plugins").path
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: pluginsPath),
            "ensureDirectoriesExist() 호출 후 plugins 디렉토리가 생성되어야 합니다"
        )
    }

    func test_ensureDirectoriesExist_isIdempotent() throws {
        // Act: 두 번 호출해도 에러 없음
        try configManager.ensureDirectoriesExist()

        XCTAssertNoThrow(
            try configManager.ensureDirectoriesExist(),
            "ensureDirectoriesExist()는 여러 번 호출해도 에러가 없어야 합니다"
        )
    }

    // MARK: - 앱 설정 로드

    func test_loadAppConfig_returnsDefaultWhenFileDoesNotExist() throws {
        // Arrange: 설정 파일 없는 상태

        // Act
        let config = try configManager.loadAppConfig()

        // Assert
        XCTAssertEqual(config, AppConfig.default, "설정 파일이 없으면 기본값을 반환해야 합니다")
    }

    func test_loadAppConfig_returnsDefaultRefreshInterval() throws {
        // Act
        let config = try configManager.loadAppConfig()

        // Assert
        XCTAssertEqual(config.refreshInterval, 60, accuracy: 0.001, "기본 refreshInterval은 60초여야 합니다")
    }

    func test_loadAppConfig_returnsDefaultShowNotificationBadge() throws {
        // Act
        let config = try configManager.loadAppConfig()

        // Assert
        XCTAssertTrue(config.showNotificationBadge, "기본 showNotificationBadge는 true여야 합니다")
    }

    func test_loadAppConfig_returnsDefaultMaxNotifications() throws {
        // Act
        let config = try configManager.loadAppConfig()

        // Assert
        XCTAssertEqual(config.maxNotificationsPerPlugin, 100, "기본 maxNotificationsPerPlugin은 100이어야 합니다")
    }

    // MARK: - 앱 설정 저장/로드 왕복

    func test_saveAndLoadAppConfig_roundtrip() throws {
        // Arrange
        let originalConfig = AppConfig(
            refreshInterval: 30,
            showNotificationBadge: false,
            maxNotificationsPerPlugin: 50
        )

        // Act
        try configManager.saveAppConfig(originalConfig)
        let loadedConfig = try configManager.loadAppConfig()

        // Assert
        XCTAssertEqual(loadedConfig, originalConfig, "저장한 앱 설정을 동일하게 로드할 수 있어야 합니다")
    }

    func test_saveAppConfig_createsConfigFile() throws {
        // Arrange
        let config = AppConfig.default

        // Act
        try configManager.saveAppConfig(config)

        // Assert
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: configManager.configFileURL.path),
            "saveAppConfig() 호출 후 config.yaml 파일이 생성되어야 합니다"
        )
    }

    func test_saveAppConfig_createsDirectoriesAutomatically() throws {
        // Arrange: 디렉토리를 미리 생성하지 않음
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempDirectory.path))

        // Act
        try configManager.saveAppConfig(AppConfig.default)

        // Assert
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: tempDirectory.path),
            "saveAppConfig()는 디렉토리를 자동으로 생성해야 합니다"
        )
    }

    func test_saveAppConfig_overwritesExistingConfig() throws {
        // Arrange
        let firstConfig = AppConfig(refreshInterval: 30, showNotificationBadge: true, maxNotificationsPerPlugin: 100)
        let secondConfig = AppConfig(refreshInterval: 120, showNotificationBadge: false, maxNotificationsPerPlugin: 200)

        // Act
        try configManager.saveAppConfig(firstConfig)
        try configManager.saveAppConfig(secondConfig)
        let loaded = try configManager.loadAppConfig()

        // Assert
        XCTAssertEqual(loaded, secondConfig, "두 번째 저장된 설정이 최종적으로 로드되어야 합니다")
    }

    func test_loadAppConfig_withCustomRefreshInterval_preservesValue() throws {
        // Arrange
        let config = AppConfig(refreshInterval: 300, showNotificationBadge: true, maxNotificationsPerPlugin: 100)

        // Act
        try configManager.saveAppConfig(config)
        let loaded = try configManager.loadAppConfig()

        // Assert
        XCTAssertEqual(loaded.refreshInterval, 300, accuracy: 0.001, "커스텀 refreshInterval이 보존되어야 합니다")
    }

    // MARK: - 플러그인 설정 저장/로드

    func test_saveAndLoadPluginConfig_roundtrip() throws {
        // Arrange
        let pluginConfig = PluginConfigFile(
            pluginId: "slack",
            enabled: true,
            settings: ["token": "xoxb-test", "workspace": "myteam"]
        )

        // Act
        try configManager.savePluginConfig(pluginConfig)
        let loaded = try configManager.loadPluginConfig(pluginId: "slack")

        // Assert
        XCTAssertEqual(loaded, pluginConfig, "저장한 플러그인 설정을 동일하게 로드할 수 있어야 합니다")
    }

    func test_loadPluginConfig_throwsFileNotFoundWhenMissing() throws {
        // Act & Assert
        XCTAssertThrowsError(
            try configManager.loadPluginConfig(pluginId: "nonexistent"),
            "존재하지 않는 플러그인 설정을 로드하면 에러가 발생해야 합니다"
        ) { error in
            guard case ConfigManager.ConfigError.fileNotFound = error else {
                XCTFail("ConfigError.fileNotFound가 발생해야 합니다. 실제: \(error)")
                return
            }
        }
    }

    func test_savePluginConfig_createsPluginYamlFile() throws {
        // Arrange
        let pluginConfig = PluginConfigFile(pluginId: "github", enabled: true, settings: [:])

        // Act
        try configManager.savePluginConfig(pluginConfig)

        // Assert
        let expectedPath = configManager.pluginConfigURL(for: "github").path
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: expectedPath),
            "플러그인 설정 저장 후 github.yaml 파일이 존재해야 합니다"
        )
    }

    func test_savePluginConfig_createsDirectoriesAutomatically() throws {
        // Arrange: 디렉토리를 미리 생성하지 않음
        let pluginConfig = PluginConfigFile(pluginId: "jira", enabled: false, settings: [:])

        // Act
        try configManager.savePluginConfig(pluginConfig)

        // Assert
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: configManager.pluginsDirectoryURL.path),
            "savePluginConfig()는 plugins 디렉토리를 자동으로 생성해야 합니다"
        )
    }

    func test_loadPluginConfig_preservesEnabledFalse() throws {
        // Arrange
        let pluginConfig = PluginConfigFile(pluginId: "disabled-plugin", enabled: false, settings: [:])

        // Act
        try configManager.savePluginConfig(pluginConfig)
        let loaded = try configManager.loadPluginConfig(pluginId: "disabled-plugin")

        // Assert
        XCTAssertFalse(loaded.enabled, "enabled: false가 보존되어야 합니다")
    }

    func test_loadPluginConfig_preservesAllSettings() throws {
        // Arrange
        let settings = ["apiKey": "key-123", "baseUrl": "https://api.example.com", "timeout": "30"]
        let pluginConfig = PluginConfigFile(pluginId: "custom", enabled: true, settings: settings)

        // Act
        try configManager.savePluginConfig(pluginConfig)
        let loaded = try configManager.loadPluginConfig(pluginId: "custom")

        // Assert
        XCTAssertEqual(loaded.settings, settings, "모든 설정 값이 보존되어야 합니다")
    }

    // MARK: - 모든 플러그인 설정 로드

    func test_loadAllPluginConfigs_returnsEmptyWhenNoPluginsDirectory() throws {
        // Arrange: plugins 디렉토리가 없는 상태

        // Act
        let configs = try configManager.loadAllPluginConfigs()

        // Assert
        XCTAssertTrue(configs.isEmpty, "plugins 디렉토리가 없으면 빈 배열을 반환해야 합니다")
    }

    func test_loadAllPluginConfigs_returnsEmptyWhenNoFiles() throws {
        // Arrange: plugins 디렉토리만 생성, 파일 없음
        try configManager.ensureDirectoriesExist()

        // Act
        let configs = try configManager.loadAllPluginConfigs()

        // Assert
        XCTAssertTrue(configs.isEmpty, "yaml 파일이 없으면 빈 배열을 반환해야 합니다")
    }

    func test_loadAllPluginConfigs_returnsAllSavedPluginConfigs() throws {
        // Arrange
        let slackConfig = PluginConfigFile(pluginId: "slack", enabled: true, settings: [:])
        let githubConfig = PluginConfigFile(pluginId: "github", enabled: false, settings: [:])
        let jiraConfig = PluginConfigFile(pluginId: "jira", enabled: true, settings: ["url": "https://jira.example.com"])

        try configManager.savePluginConfig(slackConfig)
        try configManager.savePluginConfig(githubConfig)
        try configManager.savePluginConfig(jiraConfig)

        // Act
        let configs = try configManager.loadAllPluginConfigs()

        // Assert
        XCTAssertEqual(configs.count, 3, "저장한 3개의 플러그인 설정이 모두 로드되어야 합니다")

        let pluginIds = Set(configs.map { $0.pluginId })
        XCTAssertTrue(pluginIds.contains("slack"), "slack 플러그인 설정이 포함되어야 합니다")
        XCTAssertTrue(pluginIds.contains("github"), "github 플러그인 설정이 포함되어야 합니다")
        XCTAssertTrue(pluginIds.contains("jira"), "jira 플러그인 설정이 포함되어야 합니다")
    }

    // MARK: - 경로 검증

    func test_configFileURL_hasCorrectPath() throws {
        // Act
        let url = configManager.configFileURL

        // Assert
        XCTAssertEqual(url.lastPathComponent, "config.yaml", "설정 파일 이름은 config.yaml이어야 합니다")
        XCTAssertTrue(url.path.hasPrefix(tempDirectory.path), "설정 파일은 base 디렉토리 하위에 있어야 합니다")
    }

    func test_pluginsDirectoryURL_hasCorrectPath() throws {
        // Act
        let url = configManager.pluginsDirectoryURL

        // Assert
        XCTAssertEqual(url.lastPathComponent, "plugins", "plugins 디렉토리 이름은 'plugins'여야 합니다")
        XCTAssertTrue(url.path.hasPrefix(tempDirectory.path), "plugins 디렉토리는 base 디렉토리 하위에 있어야 합니다")
    }

    func test_pluginConfigURL_hasCorrectFilename() throws {
        // Act
        let url = configManager.pluginConfigURL(for: "my-plugin")

        // Assert
        XCTAssertEqual(url.lastPathComponent, "my-plugin.yaml", "플러그인 설정 파일 이름은 '{pluginId}.yaml'이어야 합니다")
    }
}
