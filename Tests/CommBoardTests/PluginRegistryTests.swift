import XCTest
@testable import CommBoard

final class PluginRegistryTests: XCTestCase {

    // MARK: - Properties

    private var sut: PluginRegistry!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        sut = PluginRegistry()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - 초기 상태 테스트

    func test_initialState_hasZeroPlugins() {
        XCTAssertEqual(sut.count, 0)
    }

    func test_initialState_allPluginsIsEmpty() {
        XCTAssertTrue(sut.allPlugins.isEmpty)
    }

    func test_initialState_enabledPluginsIsEmpty() {
        XCTAssertTrue(sut.enabledPlugins.isEmpty)
    }

    func test_initialState_disabledPluginsIsEmpty() {
        XCTAssertTrue(sut.disabledPlugins.isEmpty)
    }

    // MARK: - register(plugin:) 테스트

    func test_register_incrementsCount() {
        // Arrange
        let plugin = MockPlugin(id: "slack")

        // Act
        sut.register(plugin: plugin)

        // Assert
        XCTAssertEqual(sut.count, 1)
    }

    func test_register_multiplePlugins_incrementsCountCorrectly() {
        // Arrange
        let slack = MockPlugin(id: "slack")
        let github = MockPlugin(id: "github")
        let jira = MockPlugin(id: "jira")

        // Act
        sut.register(plugin: slack)
        sut.register(plugin: github)
        sut.register(plugin: jira)

        // Assert
        XCTAssertEqual(sut.count, 3)
    }

    func test_register_sameId_doesNotDuplicatePlugin() {
        // Arrange
        let plugin1 = MockPlugin(id: "slack", name: "Slack v1")
        let plugin2 = MockPlugin(id: "slack", name: "Slack v2")

        // Act
        sut.register(plugin: plugin1)
        sut.register(plugin: plugin2)

        // Assert - 동일 id는 덮어쓰므로 count는 1
        XCTAssertEqual(sut.count, 1)
    }

    func test_register_sameId_overwritesExistingPlugin() {
        // Arrange
        let plugin1 = MockPlugin(id: "slack", name: "Slack v1")
        let plugin2 = MockPlugin(id: "slack", name: "Slack v2")

        // Act
        sut.register(plugin: plugin1)
        sut.register(plugin: plugin2)

        // Assert - 두 번째로 등록된 플러그인이 반환되어야 함
        XCTAssertEqual(sut.plugin(id: "slack")?.name, "Slack v2")
    }

    // MARK: - plugin(id:) 조회 테스트

    func test_pluginById_returnsPlugin_whenRegistered() {
        // Arrange
        let plugin = MockPlugin(id: "github")
        sut.register(plugin: plugin)

        // Act
        let found = sut.plugin(id: "github")

        // Assert
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.id, "github")
    }

    func test_pluginById_returnsNil_whenNotRegistered() {
        // Act
        let found = sut.plugin(id: "nonexistent")

        // Assert
        XCTAssertNil(found)
    }

    func test_pluginById_returnsCorrectPlugin_withMultiplePlugins() {
        // Arrange
        let slack = MockPlugin(id: "slack", name: "Slack")
        let github = MockPlugin(id: "github", name: "GitHub")
        sut.register(plugin: slack)
        sut.register(plugin: github)

        // Act
        let found = sut.plugin(id: "github")

        // Assert
        XCTAssertEqual(found?.name, "GitHub")
    }

    // MARK: - allPlugins 테스트

    func test_allPlugins_returnsAllRegisteredPlugins() {
        // Arrange
        let slack = MockPlugin(id: "slack")
        let github = MockPlugin(id: "github")
        sut.register(plugin: slack)
        sut.register(plugin: github)

        // Act
        let all = sut.allPlugins

        // Assert
        XCTAssertEqual(all.count, 2)
        let ids = Set(all.map { $0.id })
        XCTAssertTrue(ids.contains("slack"))
        XCTAssertTrue(ids.contains("github"))
    }

    // MARK: - enabledPlugins 필터링 테스트

    func test_enabledPlugins_returnsOnlyEnabledPlugins() {
        // Arrange
        let enabled1 = MockPlugin(id: "slack", isEnabled: true)
        let enabled2 = MockPlugin(id: "github", isEnabled: true)
        let disabled = MockPlugin(id: "jira", isEnabled: false)
        sut.register(plugin: enabled1)
        sut.register(plugin: enabled2)
        sut.register(plugin: disabled)

        // Act
        let enabled = sut.enabledPlugins

        // Assert
        XCTAssertEqual(enabled.count, 2)
        let ids = Set(enabled.map { $0.id })
        XCTAssertTrue(ids.contains("slack"))
        XCTAssertTrue(ids.contains("github"))
        XCTAssertFalse(ids.contains("jira"))
    }

    func test_enabledPlugins_returnsEmpty_whenAllDisabled() {
        // Arrange
        sut.register(plugin: MockPlugin(id: "slack", isEnabled: false))
        sut.register(plugin: MockPlugin(id: "github", isEnabled: false))

        // Act & Assert
        XCTAssertTrue(sut.enabledPlugins.isEmpty)
    }

    func test_enabledPlugins_returnsAll_whenAllEnabled() {
        // Arrange
        sut.register(plugin: MockPlugin(id: "slack", isEnabled: true))
        sut.register(plugin: MockPlugin(id: "github", isEnabled: true))

        // Act & Assert
        XCTAssertEqual(sut.enabledPlugins.count, 2)
    }

    // MARK: - disabledPlugins 필터링 테스트

    func test_disabledPlugins_returnsOnlyDisabledPlugins() {
        // Arrange
        let enabled = MockPlugin(id: "slack", isEnabled: true)
        let disabled1 = MockPlugin(id: "github", isEnabled: false)
        let disabled2 = MockPlugin(id: "jira", isEnabled: false)
        sut.register(plugin: enabled)
        sut.register(plugin: disabled1)
        sut.register(plugin: disabled2)

        // Act
        let disabled = sut.disabledPlugins

        // Assert
        XCTAssertEqual(disabled.count, 2)
        let ids = Set(disabled.map { $0.id })
        XCTAssertTrue(ids.contains("github"))
        XCTAssertTrue(ids.contains("jira"))
        XCTAssertFalse(ids.contains("slack"))
    }

    func test_enabledAndDisabled_areMutuallyExclusive() {
        // Arrange
        sut.register(plugin: MockPlugin(id: "slack", isEnabled: true))
        sut.register(plugin: MockPlugin(id: "github", isEnabled: false))
        sut.register(plugin: MockPlugin(id: "jira", isEnabled: true))

        // Act
        let enabledIds = Set(sut.enabledPlugins.map { $0.id })
        let disabledIds = Set(sut.disabledPlugins.map { $0.id })

        // Assert - 교집합이 없어야 함
        XCTAssertTrue(enabledIds.intersection(disabledIds).isEmpty)
        // 합집합이 전체 플러그인과 같아야 함
        XCTAssertEqual(enabledIds.union(disabledIds).count, sut.count)
    }

    // MARK: - setEnabled 활성화 관리 테스트

    func test_setEnabled_true_enablesPlugin() {
        // Arrange
        sut.register(plugin: MockPlugin(id: "slack", isEnabled: false))

        // Act
        let success = sut.setEnabled(true, forPluginId: "slack")

        // Assert
        XCTAssertTrue(success)
        XCTAssertEqual(sut.enabledPlugins.count, 1)
        XCTAssertEqual(sut.enabledPlugins.first?.id, "slack")
    }

    func test_setEnabled_false_disablesPlugin() {
        // Arrange
        sut.register(plugin: MockPlugin(id: "slack", isEnabled: true))

        // Act
        let success = sut.setEnabled(false, forPluginId: "slack")

        // Assert
        XCTAssertTrue(success)
        XCTAssertTrue(sut.enabledPlugins.isEmpty)
        XCTAssertEqual(sut.disabledPlugins.count, 1)
    }

    func test_setEnabled_returnsFalse_whenPluginNotFound() {
        // Act
        let success = sut.setEnabled(true, forPluginId: "nonexistent")

        // Assert
        XCTAssertFalse(success)
    }

    func test_setEnabled_changesAreReflectedInFiltering() {
        // Arrange
        sut.register(plugin: MockPlugin(id: "slack", isEnabled: false))
        sut.register(plugin: MockPlugin(id: "github", isEnabled: true))

        // Act - slack 활성화, github 비활성화
        sut.setEnabled(true, forPluginId: "slack")
        sut.setEnabled(false, forPluginId: "github")

        // Assert
        let enabledIds = sut.enabledPlugins.map { $0.id }
        let disabledIds = sut.disabledPlugins.map { $0.id }
        XCTAssertTrue(enabledIds.contains("slack"))
        XCTAssertTrue(disabledIds.contains("github"))
        XCTAssertFalse(enabledIds.contains("github"))
        XCTAssertFalse(disabledIds.contains("slack"))
    }

    // MARK: - removeAll 테스트

    func test_removeAll_clearsAllPlugins() {
        // Arrange
        sut.register(plugin: MockPlugin(id: "slack"))
        sut.register(plugin: MockPlugin(id: "github"))

        // Act
        sut.removeAll()

        // Assert
        XCTAssertEqual(sut.count, 0)
        XCTAssertTrue(sut.allPlugins.isEmpty)
    }

    func test_removeAll_canRegisterAfterClear() {
        // Arrange
        sut.register(plugin: MockPlugin(id: "slack"))
        sut.removeAll()

        // Act
        sut.register(plugin: MockPlugin(id: "new-plugin"))

        // Assert
        XCTAssertEqual(sut.count, 1)
        XCTAssertNotNil(sut.plugin(id: "new-plugin"))
    }

    func test_removeAll_onEmptyRegistry_doesNotThrow() {
        // Arrange - 이미 빈 레지스트리

        // Act & Assert - 빈 상태에서 removeAll을 호출해도 안전해야 함
        sut.removeAll()
        XCTAssertEqual(sut.count, 0)
    }

    // MARK: - allPlugins id 집합 테스트

    func test_allPlugins_containsCorrectIds_regardlessOfInsertionOrder() {
        // Arrange
        let ids = ["gamma", "alpha", "beta"]
        ids.forEach { sut.register(plugin: MockPlugin(id: $0)) }

        // Act
        let allIds = Set(sut.allPlugins.map { $0.id })

        // Assert - 삽입 순서와 무관하게 모든 id가 포함되어야 함
        XCTAssertEqual(allIds, Set(ids))
    }

    // MARK: - setEnabled 반환값 테스트

    func test_setEnabled_returnsTrueForExistingPlugin() {
        // Arrange
        sut.register(plugin: MockPlugin(id: "slack", isEnabled: true))

        // Act & Assert - 이미 활성화된 플러그인을 다시 활성화해도 true 반환
        XCTAssertTrue(sut.setEnabled(true, forPluginId: "slack"))
    }

    func test_setEnabled_sameValue_doesNotChangeCount() {
        // Arrange
        sut.register(plugin: MockPlugin(id: "slack", isEnabled: true))

        // Act - 이미 활성화된 상태에서 다시 활성화
        sut.setEnabled(true, forPluginId: "slack")

        // Assert - 플러그인 수는 변함없음
        XCTAssertEqual(sut.count, 1)
        XCTAssertEqual(sut.enabledPlugins.count, 1)
    }
}
