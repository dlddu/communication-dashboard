import Foundation

/// 플러그인이 반드시 구현해야 하는 계약을 정의합니다.
public protocol PluginProtocol: AnyObject {
    /// 플러그인 고유 식별자
    var id: String { get }

    /// 사용자에게 표시되는 플러그인 이름
    var name: String { get }

    /// SF Symbols 아이콘 이름.
    /// 현재는 SF Symbols 이름(String)만 지원합니다.
    /// 커스텀 이미지 리소스 지원이 필요할 경우 `enum IconType { case sfSymbol(String); case resource(String) }` 등으로 확장을 검토하세요.
    var icon: String { get }

    /// 플러그인 활성화 상태
    var isEnabled: Bool { get set }

    /// 플러그인 설정 딕셔너리 (YAML 파일로부터 로드됨)
    var config: [String: Any] { get set }

    /// 최신 알림/데이터를 원격에서 가져옵니다.
    /// - Returns: 새로 가져온 NotificationRecord 배열
    /// - Throws: 네트워크 오류 또는 인증 오류
    func fetch() async throws -> [NotificationRecord]

    /// 플러그인 연결 상태를 테스트합니다.
    /// - Returns: 연결 성공 여부
    func testConnection() async throws -> Bool
}
