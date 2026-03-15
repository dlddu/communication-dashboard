import Foundation

/// 플러그인이 반환하는 알림 데이터
public struct PluginNotification {
    public let pluginId: String
    public let title: String
    public let subtitle: String?
    public let body: String?
    public let timestamp: Date
    public let metadata: [String: String]?

    public init(
        pluginId: String,
        title: String,
        subtitle: String? = nil,
        body: String? = nil,
        timestamp: Date = Date(),
        metadata: [String: String]? = nil
    ) {
        self.pluginId = pluginId
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

/// 플러그인 설정을 나타내는 타입
public typealias PluginConfig = [String: String]

/// 모든 CommBoard 플러그인이 준수해야 하는 프로토콜
public protocol PluginProtocol: AnyObject {
    /// 플러그인 고유 식별자
    var id: String { get }

    /// 플러그인 표시 이름
    var name: String { get }

    /// 플러그인 아이콘 이름 (SF Symbols 또는 asset 이름)
    var icon: String { get }

    /// 플러그인 설정
    var config: PluginConfig { get set }

    /// 알림을 가져옵니다
    func fetch() async throws -> [PluginNotification]

    /// 연결을 테스트합니다
    func testConnection() async throws -> Bool
}
