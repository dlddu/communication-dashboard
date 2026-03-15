import Foundation

/// 플러그인 개별 설정 모델. plugins/{pluginId}.yaml과 매핑됩니다.
struct PluginConfig: Codable, Equatable {

    // MARK: - Properties

    var pluginId: String
    var isEnabled: Bool
    var interval: Int
    var settings: [String: String]

    // MARK: - CodingKeys (YAML 키 매핑)

    enum CodingKeys: String, CodingKey {
        case pluginId = "id"
        case isEnabled = "enabled"
        case interval
        case settings
    }

    // MARK: - Init

    init(pluginId: String, isEnabled: Bool, interval: Int, settings: [String: String]) {
        self.pluginId = pluginId
        self.isEnabled = isEnabled
        self.interval = interval
        self.settings = settings
    }

    // MARK: - Codable

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pluginId = try container.decode(String.self, forKey: .pluginId)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        interval = try container.decodeIfPresent(Int.self, forKey: .interval) ?? 60
        settings = try container.decodeIfPresent([String: String].self, forKey: .settings) ?? [:]
    }
}
