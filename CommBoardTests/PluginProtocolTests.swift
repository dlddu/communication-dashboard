import XCTest
@testable import CommBoard

// MARK: - Mock Plugin

/// 테스트용 Mock 플러그인입니다.
/// Plugin 프로토콜의 모든 요구사항을 구현합니다.
final class MockPlugin: Plugin {

    // MARK: - Protocol Requirements

    var id: String
    var name: String
    var icon: String
    var config: PluginConfig?

    // MARK: - Test State

    var fetchCallCount = 0
    var testConnectionCallCount = 0
    var fetchResult: Result<[AppNotification], Error>
    var testConnectionResult: Result<Bool, Error>

    // MARK: - Init

    init(
        id: String = "mock-plugin",
        name: String = "Mock Plugin",
        icon: String = "star",
        config: PluginConfig? = nil,
        fetchResult: Result<[AppNotification], Error> = .success([]),
        testConnectionResult: Result<Bool, Error> = .success(true)
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.config = config
        self.fetchResult = fetchResult
        self.testConnectionResult = testConnectionResult
    }

    // MARK: - Protocol Methods

    func fetch() async throws -> [AppNotification] {
        fetchCallCount += 1
        return try fetchResult.get()
    }

    func testConnection() async throws -> Bool {
        testConnectionCallCount += 1
        return try testConnectionResult.get()
    }
}

// MARK: - PluginProtocolTests
//
// Plugin 프로토콜의 적합성(conformance)과
// 프로토콜 요구사항을 검증합니다.

final class PluginProtocolTests: XCTestCase {

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
    }

    override func tearDown() async throws {
        try await super.tearDown()
    }

    // MARK: - Conformance Tests

    func testMockPlugin_ConformsToPluginProtocol() {
        // Arrange & Act
        let mock: Plugin = MockPlugin()

        // Assert
        XCTAssertNotNil(mock, "MockPlugin은 Plugin 프로토콜을 준수해야 합니다")
    }

    // MARK: - Property Tests

    func testPlugin_Id_IsAccessible() {
        // Arrange
        let expectedId = "test-plugin-id"
        let mock = MockPlugin(id: expectedId)

        // Act
        let actualId = mock.id

        // Assert
        XCTAssertEqual(actualId, expectedId, "플러그인 id가 접근 가능해야 합니다")
    }

    func testPlugin_Name_IsAccessible() {
        // Arrange
        let expectedName = "Test Plugin Name"
        let mock = MockPlugin(name: expectedName)

        // Act
        let actualName = mock.name

        // Assert
        XCTAssertEqual(actualName, expectedName, "플러그인 name이 접근 가능해야 합니다")
    }

    func testPlugin_Icon_IsAccessible() {
        // Arrange
        let expectedIcon = "bell.fill"
        let mock = MockPlugin(icon: expectedIcon)

        // Act
        let actualIcon = mock.icon

        // Assert
        XCTAssertEqual(actualIcon, expectedIcon, "플러그인 icon이 접근 가능해야 합니다")
    }

    func testPlugin_Config_IsOptionalAndNilByDefault() {
        // Arrange
        let mock = MockPlugin(config: nil)

        // Assert
        XCTAssertNil(mock.config, "config는 옵셔널이며 nil이 허용되어야 합니다")
    }

    func testPlugin_Config_IsAssignable() {
        // Arrange
        let pluginConfig = PluginConfig(
            pluginId: "mock-plugin",
            isEnabled: true,
            interval: 30,
            settings: [:]
        )
        let mock = MockPlugin(config: pluginConfig)

        // Assert
        XCTAssertNotNil(mock.config, "config가 설정되었을 때 접근 가능해야 합니다")
        XCTAssertEqual(mock.config?.pluginId, "mock-plugin")
        XCTAssertEqual(mock.config?.interval, 30)
    }

    // MARK: - fetch() Tests

    func testFetch_ReturnsEmptyArray_WhenNoNotifications() async throws {
        // Arrange
        let mock = MockPlugin(fetchResult: .success([]))

        // Act
        let notifications = try await mock.fetch()

        // Assert
        XCTAssertTrue(notifications.isEmpty, "알림이 없을 때 빈 배열이 반환되어야 합니다")
    }

    func testFetch_ReturnsNotifications_WhenAvailable() async throws {
        // Arrange
        let expectedNotifications = [
            AppNotification(
                pluginId: "mock-plugin",
                title: "Test Notification",
                subtitle: nil,
                body: "body",
                timestamp: Date(),
                isRead: false,
                metadata: nil
            )
        ]
        let mock = MockPlugin(fetchResult: .success(expectedNotifications))

        // Act
        let notifications = try await mock.fetch()

        // Assert
        XCTAssertEqual(notifications.count, 1, "알림 1개가 반환되어야 합니다")
        XCTAssertEqual(notifications.first?.title, "Test Notification")
    }

    func testFetch_ThrowsError_WhenFetchFails() async {
        // Arrange
        let expectedError = NSError(domain: "TestError", code: 1001, userInfo: nil)
        let mock = MockPlugin(fetchResult: .failure(expectedError))

        // Act & Assert
        do {
            _ = try await mock.fetch()
            XCTFail("fetch 실패 시 에러가 발생해야 합니다")
        } catch let error as NSError {
            XCTAssertEqual(error.code, 1001, "올바른 에러 코드가 전달되어야 합니다")
        }
    }

    func testFetch_CalledMultipleTimes_TracksCallCount() async throws {
        // Arrange
        let mock = MockPlugin(fetchResult: .success([]))

        // Act
        _ = try await mock.fetch()
        _ = try await mock.fetch()
        _ = try await mock.fetch()

        // Assert
        XCTAssertEqual(mock.fetchCallCount, 3, "fetch가 3회 호출되어야 합니다")
    }

    // MARK: - testConnection() Tests

    func testConnection_ReturnsTrue_WhenConnectionSucceeds() async throws {
        // Arrange
        let mock = MockPlugin(testConnectionResult: .success(true))

        // Act
        let isConnected = try await mock.testConnection()

        // Assert
        XCTAssertTrue(isConnected, "연결 성공 시 true가 반환되어야 합니다")
    }

    func testConnection_ReturnsFalse_WhenConnectionFails() async throws {
        // Arrange
        let mock = MockPlugin(testConnectionResult: .success(false))

        // Act
        let isConnected = try await mock.testConnection()

        // Assert
        XCTAssertFalse(isConnected, "연결 실패 시 false가 반환되어야 합니다")
    }

    func testConnection_ThrowsError_WhenNetworkError() async {
        // Arrange
        let networkError = NSError(
            domain: "NetworkError",
            code: -1009,
            userInfo: [NSLocalizedDescriptionKey: "The Internet connection appears to be offline."]
        )
        let mock = MockPlugin(testConnectionResult: .failure(networkError))

        // Act & Assert
        do {
            _ = try await mock.testConnection()
            XCTFail("네트워크 에러 시 에러가 발생해야 합니다")
        } catch let error as NSError {
            XCTAssertEqual(error.code, -1009, "올바른 에러 코드가 전달되어야 합니다")
        }
    }

    func testConnection_CalledOnce_TracksCallCount() async throws {
        // Arrange
        let mock = MockPlugin(testConnectionResult: .success(true))

        // Act
        _ = try await mock.testConnection()

        // Assert
        XCTAssertEqual(mock.testConnectionCallCount, 1, "testConnection이 1회 호출되어야 합니다")
    }

    // MARK: - Plugin Identity Tests

    func testPlugin_Id_IsUnique_ForDifferentInstances() {
        // Arrange
        let plugin1 = MockPlugin(id: "plugin-1")
        let plugin2 = MockPlugin(id: "plugin-2")

        // Assert
        XCTAssertNotEqual(plugin1.id, plugin2.id, "서로 다른 플러그인은 다른 id를 가져야 합니다")
    }

    func testPlugin_Id_IsNonEmpty() {
        // Arrange
        let mock = MockPlugin(id: "valid-id")

        // Assert
        XCTAssertFalse(mock.id.isEmpty, "플러그인 id는 비어있지 않아야 합니다")
    }

    func testPlugin_Name_IsNonEmpty() {
        // Arrange
        let mock = MockPlugin(name: "Valid Name")

        // Assert
        XCTAssertFalse(mock.name.isEmpty, "플러그인 name은 비어있지 않아야 합니다")
    }
}
