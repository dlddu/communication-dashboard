import Foundation

/// 앱 전체 설정 모델. config.yaml과 매핑됩니다.
struct AppConfig: Codable, Equatable {

    // MARK: - Properties

    var refreshInterval: Int
    var theme: String
    var language: String

    // MARK: - Init

    init(refreshInterval: Int, theme: String, language: String) {
        self.refreshInterval = refreshInterval
        self.theme = theme
        self.language = language
    }
}
