import Foundation
import GRDB
@testable import CommBoard

// MARK: - TestEnvironment

/// E2E 테스트에서 사용하는 격리된 임시 환경을 관리합니다.
///
/// 각 테스트마다 독립된 임시 디렉토리를 생성하고,
/// tearDown 시 자동으로 정리합니다.
///
/// 사용 예시:
/// ```swift
/// private var env: TestEnvironment!
///
/// override func setUp() {
///     super.setUp()
///     env = try! TestEnvironment.make()
/// }
///
/// override func tearDown() {
///     env.cleanup()
///     env = nil
///     super.tearDown()
/// }
/// ```
final class TestEnvironment {

    // MARK: - Properties

    /// 이 테스트 환경의 격리된 임시 디렉토리 루트
    let rootDirectory: URL

    /// 테스트용 SQLite DB 파일 경로
    let databaseURL: URL

    /// 테스트용 설정 파일 기반 ConfigManager
    let configManager: ConfigManager

    // MARK: - Initializer

    private init(rootDirectory: URL) {
        self.rootDirectory = rootDirectory
        self.databaseURL = rootDirectory.appendingPathComponent("test.sqlite")
        self.configManager = ConfigManager(baseDirectory: rootDirectory)
    }

    // MARK: - Factory

    /// 격리된 임시 디렉토리를 생성하고 TestEnvironment를 반환합니다.
    ///
    /// - Returns: 초기화된 TestEnvironment 인스턴스
    /// - Throws: 디렉토리 또는 설정 파일 생성 실패 시 에러
    static func make() throws -> TestEnvironment {
        // 테스트마다 고유한 임시 디렉토리 생성
        let rootDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("CommBoardUITests_\(UUID().uuidString)")

        let env = TestEnvironment(rootDirectory: rootDir)

        // 기본 디렉토리 구조 초기화
        try env.configManager.ensureDirectoriesExist()

        // fixture 기반 설정 파일 배포
        try env.installConfigFixture()

        return env
    }

    // MARK: - Database

    /// 임시 SQLite DatabaseQueue를 생성하고 마이그레이션을 적용합니다.
    ///
    /// - Returns: 마이그레이션이 완료된 DatabaseQueue
    /// - Throws: DB 파일 생성 또는 마이그레이션 실패 시 에러
    func makeDatabase() throws -> DatabaseQueue {
        let dbQueue = try DatabaseQueue(path: databaseURL.path)
        try DatabaseSchema.migrate(dbQueue)
        return dbQueue
    }

    /// 인메모리 DatabaseQueue를 생성하고 마이그레이션을 적용합니다.
    /// 파일 I/O가 필요 없는 단위 테스트에 적합합니다.
    ///
    /// - Returns: 마이그레이션이 완료된 인메모리 DatabaseQueue
    /// - Throws: DB 초기화 또는 마이그레이션 실패 시 에러
    func makeInMemoryDatabase() throws -> DatabaseQueue {
        let dbQueue = try DatabaseQueue()
        try DatabaseSchema.migrate(dbQueue)
        return dbQueue
    }

    // MARK: - Config

    /// fixture 파일(config.yaml)을 테스트 환경 디렉토리에 복사합니다.
    private func installConfigFixture() throws {
        // Bundle에서 fixture 파일 탐색 (SPM resources)
        if let fixtureURL = Bundle.module.url(
            forResource: "config",
            withExtension: "yaml",
            subdirectory: "Fixtures"
        ) {
            let destination = configManager.configFileURL
            // 이미 존재하면 제거 후 복사
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: fixtureURL, to: destination)
        } else {
            // Bundle에서 fixture를 찾지 못한 경우 기본 설정으로 대체
            try configManager.createDefaultConfigIfNeeded()
        }
    }

    /// 테스트용 임시 설정 파일을 생성합니다.
    ///
    /// - Parameter config: 저장할 설정 딕셔너리. nil이면 기본 설정 사용.
    /// - Throws: 파일 저장 실패 시 에러
    func writeConfig(_ config: [String: Any]? = nil) throws {
        let configToWrite = config ?? [
            "version": ConfigManager.defaultVersion,
            "refresh_interval": ConfigManager.defaultRefreshInterval,
            "theme": ConfigManager.defaultTheme,
            "notifications": [
                "enabled": ConfigManager.defaultNotificationsEnabled,
                "max_count": ConfigManager.defaultNotificationsMaxCount
            ]
        ]
        try configManager.saveConfig(configToWrite)
    }

    /// 테스트용 플러그인 설정 파일을 생성합니다.
    ///
    /// - Parameters:
    ///   - config: 저장할 플러그인 설정
    ///   - pluginId: 플러그인 식별자
    /// - Throws: 파일 저장 실패 시 에러
    func writePluginConfig(_ config: [String: Any], pluginId: String) throws {
        try configManager.savePluginConfig(config, pluginId: pluginId)
    }

    // MARK: - Cleanup

    /// 임시 디렉토리 전체를 삭제합니다.
    /// tearDown에서 반드시 호출해야 합니다.
    func cleanup() {
        try? FileManager.default.removeItem(at: rootDirectory)
    }

    /// DB 파일만 삭제합니다 (재생성이 필요한 경우 사용).
    func cleanupDatabase() {
        try? FileManager.default.removeItem(at: databaseURL)
    }
}

// MARK: - NotificationRecord Test Helpers

extension NotificationRecord {

    /// 테스트용 NotificationRecord를 생성하는 팩토리 메서드입니다.
    static func makeStub(
        id: String = UUID().uuidString,
        pluginId: String = "test-plugin",
        title: String = "테스트 알림",
        subtitle: String? = nil,
        body: String? = nil,
        timestamp: Date = Date(),
        isRead: Bool = false,
        metadata: String? = nil
    ) -> NotificationRecord {
        NotificationRecord(
            id: id,
            pluginId: pluginId,
            title: title,
            subtitle: subtitle,
            body: body,
            timestamp: timestamp,
            isRead: isRead,
            metadata: metadata
        )
    }
}
