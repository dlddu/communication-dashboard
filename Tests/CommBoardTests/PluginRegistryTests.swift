import XCTest
@testable import CommBoard

final class PluginRegistryTests: XCTestCase {

    // MARK: - Setup

    var registry: PluginRegistry!

    override func setUp() {
        super.setUp()
        registry = PluginRegistry()
    }

    override func tearDown() {
        registry = nil
        super.tearDown()
    }

    // MARK: - 헬퍼

    private func makePlugin(id: String, name: String = "Test Plugin") -> MockPlugin {
        return MockPlugin(id: id, name: name)
    }

    // MARK: - 초기 상태

    func test_registry_initiallyHasNoPlugins() {
        // Assert
        XCTAssertTrue(registry.allPlugins.isEmpty, "초기화 시 등록된 플러그인이 없어야 합니다")
    }

    func test_registry_initiallyHasNoActivePlugins() {
        // Assert
        XCTAssertTrue(registry.activePlugins.isEmpty, "초기화 시 활성화된 플러그인이 없어야 합니다")
    }

    // MARK: - 플러그인 등록

    func test_register_addsPluginToRegistry() {
        // Arrange
        let plugin = makePlugin(id: "slack")

        // Act
        registry.register(plugin: plugin)

        // Assert
        XCTAssertEqual(registry.allPlugins.count, 1, "플러그인이 1개 등록되어야 합니다")
    }

    func test_register_multiplePlugins_allAreAccessible() {
        // Arrange
        let slack = makePlugin(id: "slack")
        let github = makePlugin(id: "github")
        let jira = makePlugin(id: "jira")

        // Act
        registry.register(plugin: slack)
        registry.register(plugin: github)
        registry.register(plugin: jira)

        // Assert
        XCTAssertEqual(registry.allPlugins.count, 3, "3개의 플러그인이 등록되어야 합니다")
    }

    func test_register_overwritesExistingPluginWithSameId() {
        // Arrange
        let firstPlugin = makePlugin(id: "slack", name: "Old Slack")
        let updatedPlugin = makePlugin(id: "slack", name: "New Slack")

        // Act
        registry.register(plugin: firstPlugin)
        registry.register(plugin: updatedPlugin)

        // Assert
        XCTAssertEqual(registry.allPlugins.count, 1, "같은 ID로 덮어쓰면 플러그인이 1개여야 합니다")
        XCTAssertEqual(registry.plugin(byId: "slack")?.name, "New Slack", "새 플러그인으로 교체되어야 합니다")
    }

    // MARK: - ID로 플러그인 조회

    func test_pluginById_returnsRegisteredPlugin() {
        // Arrange
        let plugin = makePlugin(id: "github")
        registry.register(plugin: plugin)

        // Act
        let found = registry.plugin(byId: "github")

        // Assert
        XCTAssertNotNil(found, "등록한 플러그인을 ID로 찾을 수 있어야 합니다")
        XCTAssertEqual(found?.id, "github")
    }

    func test_pluginById_returnsNilForUnregisteredId() {
        // Act
        let found = registry.plugin(byId: "nonexistent")

        // Assert
        XCTAssertNil(found, "등록되지 않은 ID 조회는 nil을 반환해야 합니다")
    }

    func test_pluginById_returnsCorrectPluginAmongMultiple() {
        // Arrange
        let slack = makePlugin(id: "slack", name: "Slack")
        let github = makePlugin(id: "github", name: "GitHub")
        registry.register(plugin: slack)
        registry.register(plugin: github)

        // Act
        let found = registry.plugin(byId: "github")

        // Assert
        XCTAssertEqual(found?.name, "GitHub", "올바른 플러그인이 반환되어야 합니다")
    }

    // MARK: - 플러그인 활성화

    func test_activate_activatesRegisteredPlugin() throws {
        // Arrange
        let plugin = makePlugin(id: "slack")
        registry.register(plugin: plugin)

        // Act
        try registry.activate(pluginId: "slack")

        // Assert
        XCTAssertTrue(registry.isActive(pluginId: "slack"), "플러그인이 활성화되어야 합니다")
    }

    func test_activate_throwsNotFoundForUnregisteredPlugin() {
        // Act & Assert
        XCTAssertThrowsError(
            try registry.activate(pluginId: "nonexistent"),
            "등록되지 않은 플러그인 활성화는 에러가 발생해야 합니다"
        ) { error in
            guard case PluginRegistryError.notFound(let id) = error else {
                XCTFail("PluginRegistryError.notFound가 발생해야 합니다. 실제: \(error)")
                return
            }
            XCTAssertEqual(id, "nonexistent", "에러에 올바른 ID가 포함되어야 합니다")
        }
    }

    func test_activate_canActivateMultiplePlugins() throws {
        // Arrange
        let slack = makePlugin(id: "slack")
        let github = makePlugin(id: "github")
        registry.register(plugin: slack)
        registry.register(plugin: github)

        // Act
        try registry.activate(pluginId: "slack")
        try registry.activate(pluginId: "github")

        // Assert
        XCTAssertEqual(registry.activePlugins.count, 2, "두 플러그인 모두 활성화되어야 합니다")
    }

    func test_activate_isIdempotent() throws {
        // Arrange
        let plugin = makePlugin(id: "slack")
        registry.register(plugin: plugin)

        // Act: 두 번 활성화
        try registry.activate(pluginId: "slack")
        try registry.activate(pluginId: "slack")

        // Assert
        XCTAssertEqual(registry.activePlugins.count, 1, "중복 활성화 시 activePlugins는 1개여야 합니다")
    }

    // MARK: - 활성 플러그인 목록

    func test_activePlugins_returnsOnlyActivatedPlugins() throws {
        // Arrange
        let slack = makePlugin(id: "slack")
        let github = makePlugin(id: "github")
        let jira = makePlugin(id: "jira")
        registry.register(plugin: slack)
        registry.register(plugin: github)
        registry.register(plugin: jira)

        // Act: slack과 github만 활성화
        try registry.activate(pluginId: "slack")
        try registry.activate(pluginId: "github")

        // Assert
        let activeIds = registry.activePlugins.map { $0.id }
        XCTAssertTrue(activeIds.contains("slack"), "slack이 활성 플러그인에 포함되어야 합니다")
        XCTAssertTrue(activeIds.contains("github"), "github이 활성 플러그인에 포함되어야 합니다")
        XCTAssertFalse(activeIds.contains("jira"), "jira는 활성 플러그인에 포함되지 않아야 합니다")
    }

    // MARK: - 플러그인 비활성화

    func test_deactivate_deactivatesActivePlugin() throws {
        // Arrange
        let plugin = makePlugin(id: "slack")
        registry.register(plugin: plugin)
        try registry.activate(pluginId: "slack")

        // Act
        registry.deactivate(pluginId: "slack")

        // Assert
        XCTAssertFalse(registry.isActive(pluginId: "slack"), "비활성화 후 플러그인이 비활성 상태여야 합니다")
    }

    func test_deactivate_doesNotThrowForInactivePlugin() {
        // Arrange
        let plugin = makePlugin(id: "slack")
        registry.register(plugin: plugin)
        // 활성화 없이 비활성화 시도

        // Act & Assert
        XCTAssertNoThrow(
            registry.deactivate(pluginId: "slack"),
            "비활성 상태인 플러그인 비활성화는 에러 없이 동작해야 합니다"
        )
    }

    func test_deactivate_doesNotThrowForUnregisteredPlugin() {
        // Act & Assert
        XCTAssertNoThrow(
            registry.deactivate(pluginId: "nonexistent"),
            "미등록 플러그인 비활성화는 에러 없이 동작해야 합니다"
        )
    }

    func test_deactivate_removesOnlyTargetPlugin() throws {
        // Arrange
        let slack = makePlugin(id: "slack")
        let github = makePlugin(id: "github")
        registry.register(plugin: slack)
        registry.register(plugin: github)
        try registry.activate(pluginId: "slack")
        try registry.activate(pluginId: "github")

        // Act
        registry.deactivate(pluginId: "slack")

        // Assert
        XCTAssertFalse(registry.isActive(pluginId: "slack"), "slack이 비활성화되어야 합니다")
        XCTAssertTrue(registry.isActive(pluginId: "github"), "github은 여전히 활성 상태여야 합니다")
    }

    // MARK: - 모두 비활성화

    func test_deactivateAll_deactivatesAllPlugins() throws {
        // Arrange
        let slack = makePlugin(id: "slack")
        let github = makePlugin(id: "github")
        registry.register(plugin: slack)
        registry.register(plugin: github)
        try registry.activate(pluginId: "slack")
        try registry.activate(pluginId: "github")

        // Act
        registry.deactivateAll()

        // Assert
        XCTAssertTrue(registry.activePlugins.isEmpty, "모두 비활성화 후 활성 플러그인이 없어야 합니다")
    }

    // MARK: - isActive 확인

    func test_isActive_returnsFalseBeforeActivation() {
        // Arrange
        let plugin = makePlugin(id: "slack")
        registry.register(plugin: plugin)

        // Assert
        XCTAssertFalse(registry.isActive(pluginId: "slack"), "활성화 전에는 false여야 합니다")
    }

    func test_isActive_returnsFalseForUnregisteredPlugin() {
        // Assert
        XCTAssertFalse(registry.isActive(pluginId: "unknown"), "미등록 플러그인은 false여야 합니다")
    }

    func test_isActive_returnsTrueAfterActivation() throws {
        // Arrange
        let plugin = makePlugin(id: "slack")
        registry.register(plugin: plugin)
        try registry.activate(pluginId: "slack")

        // Assert
        XCTAssertTrue(registry.isActive(pluginId: "slack"), "활성화 후에는 true여야 합니다")
    }
}
