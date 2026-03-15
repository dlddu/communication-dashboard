import Foundation

/// 플러그인이 준수해야 하는 프로토콜입니다.
protocol Plugin: AnyObject {

    /// 플러그인 고유 식별자
    var id: String { get }

    /// 플러그인 표시 이름
    var name: String { get }

    /// SF Symbols 아이콘 이름
    var icon: String { get }

    /// 플러그인 설정 (선택 사항)
    var config: PluginConfig? { get set }

    /// 최신 알림을 가져옵니다.
    func fetch() async throws -> [AppNotification]

    /// 연결 상태를 테스트합니다.
    func testConnection() async throws -> Bool
}
