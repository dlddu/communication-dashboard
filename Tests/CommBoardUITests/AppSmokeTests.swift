import XCTest
import GRDB
@testable import CommBoard

// MARK: - AppSmokeTests
//
// SPM 환경에서 XCUIApplication(앱 UI 자동화)은 사용이 제한적이므로,
// XCTest 기반 integration test로 smoke test를 구현합니다.
//
// Smoke test의 목표:
// - 앱의 핵심 컴포넌트(ConfigManager, DatabaseSchema, PluginRegistry)가
//   정상적으로 초기화되는지 확인합니다.
// - 컴포넌트 간 연동이 오류 없이 동작하는지 검증합니다.
// - 실제 파일 시스템과 DB를 사용하는 end-to-end 경로를 검증합니다.

final class AppSmokeTests: XCTestCase {

    // MARK: - Properties

    private var env: TestEnvironment!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        // 각 테스트마다 격리된 임시 환경 생성
        env = try! TestEnvironment.make()
    }

    override func tearDown() {
        // 임시 디렉토리 정리
        env.cleanup()
        env = nil
        super.tearDown()
    }

    // MARK: - 앱 초기화 Smoke Test

    /// 앱 시작 시 설정 파일이 올바르게 로드되는지 검증합니다.
    /// (메인 윈도우 표시 전 필수 초기화 경로)
    func test_appBootstrap_configManagerInitializesSuccessfully() throws {
        // Arrange - TestEnvironment가 ConfigManager를 이미 초기화함
        let sut = env.configManager

        // Act - 설정 로드 (앱 시작 시 수행되는 동작)
        let config = try sut.loadConfig()

        // Assert - 설정이 유효한 구조를 가져야 함
        XCTAssertFalse(config.isEmpty, "앱 시작 시 설정이 로드되어야 합니다")
        XCTAssertNotNil(config["version"], "설정에 version 키가 존재해야 합니다")
        XCTAssertNotNil(config["refresh_interval"], "설정에 refresh_interval 키가 존재해야 합니다")
        XCTAssertNotNil(config["theme"], "설정에 theme 키가 존재해야 합니다")
    }

    /// 앱 시작 시 데이터베이스가 정상적으로 초기화되는지 검증합니다.
    func test_appBootstrap_databaseInitializesSuccessfully() throws {
        // Arrange & Act - DB 생성 및 마이그레이션 적용
        let dbQueue = try env.makeDatabase()

        // Assert - 핵심 테이블이 존재해야 함
        let notificationsExists = try dbQueue.read { db in
            try db.tableExists("notifications")
        }
        let widgetLayoutExists = try dbQueue.read { db in
            try db.tableExists("widget_layout")
        }

        XCTAssertTrue(notificationsExists, "앱 시작 시 notifications 테이블이 생성되어야 합니다")
        XCTAssertTrue(widgetLayoutExists, "앱 시작 시 widget_layout 테이블이 생성되어야 합니다")
    }

    /// 앱 시작 시 PluginRegistry가 빈 상태로 올바르게 초기화되는지 검증합니다.
    func test_appBootstrap_pluginRegistryInitializesEmpty() {
        // Arrange & Act - PluginRegistry 생성 (앱 시작 시 수행되는 동작)
        let sut = PluginRegistry()

        // Assert - 초기 상태는 빈 레지스트리여야 함
        XCTAssertEqual(sut.count, 0, "앱 시작 시 플러그인 레지스트리는 비어 있어야 합니다")
        XCTAssertTrue(sut.allPlugins.isEmpty, "앱 시작 시 등록된 플러그인이 없어야 합니다")
    }

    // MARK: - 앱 핵심 경로 통합 Smoke Test

    /// 플러그인 등록 → 설정 저장 → 설정 로드의 전체 경로를 검증합니다.
    func test_appCoreFlow_registerPlugin_saveConfig_loadConfig() throws {
        // Arrange
        let registry = PluginRegistry()
        let plugin = SmokeTestMockPlugin(id: "smoke-slack", name: "Slack")
        registry.register(plugin: plugin)

        // Act - 플러그인 설정 저장 (앱에서 설정을 유지하는 경로)
        let pluginConfig: [String: Any] = [
            "token": "xoxb-smoke-test-token",
            "workspace": "smoke-workspace"
        ]
        try env.configManager.savePluginConfig(pluginConfig, pluginId: plugin.id)

        // 저장된 설정 다시 로드
        let loaded = try env.configManager.loadPluginConfig(pluginId: plugin.id)

        // Assert
        XCTAssertEqual(loaded["token"] as? String, "xoxb-smoke-test-token",
            "저장된 플러그인 토큰이 올바르게 로드되어야 합니다")
        XCTAssertEqual(loaded["workspace"] as? String, "smoke-workspace",
            "저장된 플러그인 워크스페이스가 올바르게 로드되어야 합니다")
        XCTAssertEqual(registry.count, 1, "플러그인이 레지스트리에 등록되어 있어야 합니다")
    }

    /// 알림 레코드 생성 → DB 저장 → DB 조회의 전체 경로를 검증합니다.
    func test_appCoreFlow_createNotification_persistAndFetch() throws {
        // Arrange
        let dbQueue = try env.makeDatabase()
        let record = NotificationRecord.makeStub(
            id: "smoke-notif-001",
            pluginId: "smoke-slack",
            title: "Smoke Test 알림",
            body: "앱 기본 동작 검증용 알림입니다."
        )

        // Act - DB에 저장
        try dbQueue.write { db in
            try record.insert(db)
        }

        // DB에서 조회
        let fetched = try dbQueue.read { db in
            try NotificationRecord.fetchOne(db, key: "smoke-notif-001")
        }

        // Assert
        XCTAssertNotNil(fetched, "저장된 알림이 DB에서 조회되어야 합니다")
        XCTAssertEqual(fetched?.id, "smoke-notif-001")
        XCTAssertEqual(fetched?.pluginId, "smoke-slack")
        XCTAssertEqual(fetched?.title, "Smoke Test 알림")
        XCTAssertFalse(fetched?.isRead ?? true, "새 알림은 읽지 않은 상태여야 합니다")
    }

    /// 앱 설정 디렉토리 구조가 올바르게 초기화되는지 검증합니다.
    func test_appBootstrap_directoryStructureCreatedCorrectly() throws {
        // Arrange - TestEnvironment setUp에서 ensureDirectoriesExist() 호출됨
        let baseDir = env.configManager.baseDirectory
        let pluginsDir = env.configManager.pluginsDirectory

        // Assert - 디렉토리 구조가 생성되어야 함
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: baseDir.path),
            "앱 기반 디렉토리가 존재해야 합니다"
        )
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: pluginsDir.path),
            "plugins 하위 디렉토리가 존재해야 합니다"
        )
    }

    /// fixture 설정 파일이 올바른 값을 가지고 있는지 검증합니다.
    func test_appBootstrap_fixtureConfigHasExpectedValues() throws {
        // Arrange & Act
        let config = try env.configManager.loadConfig()

        // Assert - fixture(config.yaml)의 예상값과 일치해야 함
        XCTAssertEqual(config["version"] as? String, "1.0",
            "fixture의 version은 '1.0'이어야 합니다")
        XCTAssertEqual(config["refresh_interval"] as? Int, 60,
            "fixture의 refresh_interval은 60이어야 합니다")
        XCTAssertEqual(config["theme"] as? String, "system",
            "fixture의 theme은 'system'이어야 합니다")

        let notifications = config["notifications"] as? [String: Any]
        XCTAssertNotNil(notifications, "notifications 섹션이 존재해야 합니다")
        XCTAssertEqual(notifications?["enabled"] as? Bool, true,
            "fixture의 notifications.enabled는 true여야 합니다")
        XCTAssertEqual(notifications?["max_count"] as? Int, 50,
            "fixture의 notifications.max_count는 50이어야 합니다")
    }

    // MARK: - MockURLProtocol Smoke Test

    /// MockURLProtocol이 네트워크 요청을 올바르게 인터셉트하는지 검증합니다.
    func test_mockURLProtocol_interceptsRegisteredURL() async throws {
        // Arrange - mock 응답 등록
        let expectedJSON: [String: Any] = ["status": "ok", "count": 3]
        let mockResponse = try MockURLResponse(
            statusCode: 200,
            json: expectedJSON
        )
        MockURLProtocol.register(
            urlPattern: "api.commboard.test/notifications",
            response: mockResponse
        )
        defer { MockURLProtocol.removeAll() }

        // MockURLProtocol을 사용하는 URLSession 구성
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)

        // Act - 등록된 URL로 요청
        let url = URL(string: "https://api.commboard.test/notifications")!
        let (data, response) = try await session.data(from: url)

        // Assert
        let httpResponse = response as? HTTPURLResponse
        XCTAssertEqual(httpResponse?.statusCode, 200,
            "mock 응답의 HTTP 상태 코드는 200이어야 합니다")

        let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(decoded?["status"] as? String, "ok",
            "mock 응답 바디의 status가 올바르게 반환되어야 합니다")
        XCTAssertEqual(decoded?["count"] as? Int, 3,
            "mock 응답 바디의 count가 올바르게 반환되어야 합니다")

        XCTAssertEqual(
            MockURLProtocol.requestCount(for: "api.commboard.test/notifications"),
            1,
            "해당 URL 패턴에 대한 요청이 1회 기록되어야 합니다"
        )
    }

    /// MockURLProtocol이 404 에러 응답을 올바르게 반환하는지 검증합니다.
    func test_mockURLProtocol_returns404ForNotFound() async throws {
        // Arrange
        MockURLProtocol.register(
            urlPattern: "api.commboard.test/missing",
            response: MockURLResponse(statusCode: 404, body: nil)
        )
        defer { MockURLProtocol.removeAll() }

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)

        // Act
        let url = URL(string: "https://api.commboard.test/missing")!
        let (_, response) = try await session.data(from: url)

        // Assert
        let httpResponse = response as? HTTPURLResponse
        XCTAssertEqual(httpResponse?.statusCode, 404,
            "mock 응답의 HTTP 상태 코드는 404여야 합니다")
    }
}

// MARK: - SmokeTestMockPlugin
//
// AppSmokeTests 내에서만 사용하는 경량 Mock Plugin입니다.
// CommBoardTests의 MockPlugin과는 독립적으로 정의합니다.

private final class SmokeTestMockPlugin: PluginProtocol {
    var id: String
    var name: String
    var icon: String = "bolt.fill"
    var isEnabled: Bool = true
    var config: [String: Any] = [:]

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    func fetch() async throws -> [NotificationRecord] {
        return []
    }

    func testConnection() async throws -> Bool {
        return true
    }
}
