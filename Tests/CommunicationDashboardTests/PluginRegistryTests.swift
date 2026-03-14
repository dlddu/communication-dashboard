import XCTest
@testable import CommunicationDashboard

// MARK: - Test Doubles

final class MockPlugin: PluginProtocol {
    let id: String
    let name: String
    let icon: String
    let config: PluginConfig

    var fetchCallCount = 0
    var testConnectionCallCount = 0
    var fetchResult: [PluginNotification] = []
    var fetchError: Error?
    var testConnectionResult: Bool = true

    init(
        id: String = "mock-plugin",
        name: String = "Mock Plugin",
        icon: String = "mock.icon",
        interval: Int = 300
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.config = PluginConfig(id: id, name: name, enabled: true, interval: interval)
    }

    func fetch() async throws -> [PluginNotification] {
        fetchCallCount += 1
        if let error = fetchError {
            throw error
        }
        return fetchResult
    }

    func testConnection() async throws -> Bool {
        testConnectionCallCount += 1
        return testConnectionResult
    }
}

// MARK: - PluginRegistryTests

final class PluginRegistryTests: XCTestCase {

    private var sut: PluginRegistry!

    override func setUp() {
        super.setUp()
        sut = PluginRegistry()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - 초기 상태

    func test_init_isEmpty() {
        // Assert
        XCTAssertEqual(sut.count, 0)
    }

    func test_init_listAllReturnsEmpty() {
        // Assert
        XCTAssertTrue(sut.listAll().isEmpty)
    }

    func test_init_listEnabledReturnsEmpty() {
        // Assert
        XCTAssertTrue(sut.listEnabled().isEmpty)
    }

    // MARK: - register - 정상 케이스

    func test_register_singlePlugin_incrementsCount() throws {
        // Arrange
        let plugin = MockPlugin(id: "slack")

        // Act
        try sut.register(plugin)

        // Assert
        XCTAssertEqual(sut.count, 1)
    }

    func test_register_multiplePlugins_incrementsCountCorrectly() throws {
        // Arrange
        let plugin1 = MockPlugin(id: "slack")
        let plugin2 = MockPlugin(id: "github")
        let plugin3 = MockPlugin(id: "jira")

        // Act
        try sut.register(plugin1)
        try sut.register(plugin2)
        try sut.register(plugin3)

        // Assert
        XCTAssertEqual(sut.count, 3)
    }

    func test_register_plugin_isEnabledByDefault() throws {
        // Arrange
        let plugin = MockPlugin(id: "slack")

        // Act
        try sut.register(plugin)

        // Assert
        XCTAssertEqual(sut.isEnabled(id: "slack"), true)
    }

    // MARK: - register - 에러 케이스

    func test_register_duplicateId_throwsAlreadyRegisteredError() throws {
        // Arrange
        let plugin1 = MockPlugin(id: "slack")
        let plugin2 = MockPlugin(id: "slack")
        try sut.register(plugin1)

        // Act & Assert
        XCTAssertThrowsError(try sut.register(plugin2)) { error in
            guard case PluginRegistryError.alreadyRegistered(let id) = error else {
                XCTFail("PluginRegistryError.alreadyRegistered가 발생해야 합니다, 실제: \(error)")
                return
            }
            XCTAssertEqual(id, "slack")
        }
    }

    func test_register_duplicateId_doesNotIncrementCount() throws {
        // Arrange
        let plugin1 = MockPlugin(id: "slack")
        let plugin2 = MockPlugin(id: "slack")
        try sut.register(plugin1)

        // Act
        try? sut.register(plugin2)

        // Assert
        XCTAssertEqual(sut.count, 1)
    }

    // MARK: - get - 정상 케이스

    func test_get_existingPlugin_returnsPlugin() throws {
        // Arrange
        let plugin = MockPlugin(id: "slack")
        try sut.register(plugin)

        // Act
        let retrieved = sut.get(id: "slack")

        // Assert
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.id, "slack")
    }

    func test_get_existingPlugin_returnsCorrectName() throws {
        // Arrange
        let plugin = MockPlugin(id: "github", name: "GitHub Integration")
        try sut.register(plugin)

        // Act
        let retrieved = sut.get(id: "github")

        // Assert
        XCTAssertEqual(retrieved?.name, "GitHub Integration")
    }

    // MARK: - get - 에러 케이스

    func test_get_nonExistentPlugin_returnsNil() {
        // Act
        let retrieved = sut.get(id: "non-existent")

        // Assert
        XCTAssertNil(retrieved)
    }

    // MARK: - listAll

    func test_listAll_withRegisteredPlugins_returnsAllPlugins() throws {
        // Arrange
        let plugin1 = MockPlugin(id: "slack")
        let plugin2 = MockPlugin(id: "github")
        try sut.register(plugin1)
        try sut.register(plugin2)

        // Act
        let all = sut.listAll()

        // Assert
        XCTAssertEqual(all.count, 2)
    }

    func test_listAll_includesDisabledPlugins() throws {
        // Arrange
        let plugin1 = MockPlugin(id: "slack")
        let plugin2 = MockPlugin(id: "github")
        try sut.register(plugin1)
        try sut.register(plugin2)
        try sut.disable(id: "slack")

        // Act
        let all = sut.listAll()

        // Assert
        XCTAssertEqual(all.count, 2, "listAll은 비활성화된 플러그인도 포함해야 합니다")
    }

    // MARK: - listEnabled

    func test_listEnabled_afterRegistering_returnsAllPlugins() throws {
        // Arrange
        let plugin1 = MockPlugin(id: "slack")
        let plugin2 = MockPlugin(id: "github")
        try sut.register(plugin1)
        try sut.register(plugin2)

        // Act
        let enabled = sut.listEnabled()

        // Assert
        XCTAssertEqual(enabled.count, 2)
    }

    func test_listEnabled_afterDisablingOne_excludesDisabledPlugin() throws {
        // Arrange
        let plugin1 = MockPlugin(id: "slack")
        let plugin2 = MockPlugin(id: "github")
        try sut.register(plugin1)
        try sut.register(plugin2)

        // Act
        try sut.disable(id: "slack")
        let enabled = sut.listEnabled()

        // Assert
        XCTAssertEqual(enabled.count, 1)
        XCTAssertEqual(enabled.first?.id, "github")
    }

    func test_listEnabled_afterDisablingAll_returnsEmpty() throws {
        // Arrange
        let plugin1 = MockPlugin(id: "slack")
        let plugin2 = MockPlugin(id: "github")
        try sut.register(plugin1)
        try sut.register(plugin2)

        // Act
        try sut.disable(id: "slack")
        try sut.disable(id: "github")
        let enabled = sut.listEnabled()

        // Assert
        XCTAssertTrue(enabled.isEmpty)
    }

    // MARK: - enable

    func test_enable_disabledPlugin_setsEnabledTrue() throws {
        // Arrange
        let plugin = MockPlugin(id: "slack")
        try sut.register(plugin)
        try sut.disable(id: "slack")
        XCTAssertEqual(sut.isEnabled(id: "slack"), false)

        // Act
        try sut.enable(id: "slack")

        // Assert
        XCTAssertEqual(sut.isEnabled(id: "slack"), true)
    }

    func test_enable_nonExistentPlugin_throwsNotFoundError() throws {
        // Act & Assert
        XCTAssertThrowsError(try sut.enable(id: "non-existent")) { error in
            guard case PluginRegistryError.notFound(let id) = error else {
                XCTFail("PluginRegistryError.notFound가 발생해야 합니다, 실제: \(error)")
                return
            }
            XCTAssertEqual(id, "non-existent")
        }
    }

    func test_enable_alreadyEnabledPlugin_remainsEnabled() throws {
        // Arrange
        let plugin = MockPlugin(id: "slack")
        try sut.register(plugin)
        XCTAssertEqual(sut.isEnabled(id: "slack"), true)

        // Act
        try sut.enable(id: "slack")

        // Assert
        XCTAssertEqual(sut.isEnabled(id: "slack"), true)
    }

    // MARK: - disable

    func test_disable_enabledPlugin_setsEnabledFalse() throws {
        // Arrange
        let plugin = MockPlugin(id: "github")
        try sut.register(plugin)

        // Act
        try sut.disable(id: "github")

        // Assert
        XCTAssertEqual(sut.isEnabled(id: "github"), false)
    }

    func test_disable_nonExistentPlugin_throwsNotFoundError() throws {
        // Act & Assert
        XCTAssertThrowsError(try sut.disable(id: "non-existent")) { error in
            guard case PluginRegistryError.notFound(let id) = error else {
                XCTFail("PluginRegistryError.notFound가 발생해야 합니다, 실제: \(error)")
                return
            }
            XCTAssertEqual(id, "non-existent")
        }
    }

    func test_disable_alreadyDisabledPlugin_remainsDisabled() throws {
        // Arrange
        let plugin = MockPlugin(id: "slack")
        try sut.register(plugin)
        try sut.disable(id: "slack")
        XCTAssertEqual(sut.isEnabled(id: "slack"), false)

        // Act
        try sut.disable(id: "slack")

        // Assert
        XCTAssertEqual(sut.isEnabled(id: "slack"), false)
    }

    // MARK: - isEnabled

    func test_isEnabled_nonExistentPlugin_returnsNil() {
        // Act
        let result = sut.isEnabled(id: "non-existent")

        // Assert
        XCTAssertNil(result)
    }

    func test_isEnabled_enableAndDisableToggle_reflectsCorrectState() throws {
        // Arrange
        let plugin = MockPlugin(id: "slack")
        try sut.register(plugin)

        // Act & Assert - 초기 상태: enabled
        XCTAssertEqual(sut.isEnabled(id: "slack"), true)

        try sut.disable(id: "slack")
        XCTAssertEqual(sut.isEnabled(id: "slack"), false)

        try sut.enable(id: "slack")
        XCTAssertEqual(sut.isEnabled(id: "slack"), true)
    }
}
