import Foundation
import Combine

/// 설정을 UserDefaults에 JSON으로 저장/복원하고, 변경 사항을 Combine으로 알립니다.
final class ConfigStore: ObservableObject {
    private static let defaultsKey = "VideoWallpaper.config.v1"

    @Published var config: AppConfig {
        didSet { save() }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.defaultsKey),
           let decoded = try? JSONDecoder().decode(AppConfig.self, from: data) {
            config = decoded
        } else {
            config = AppConfig()
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(config) else { return }
        defaults.set(data, forKey: Self.defaultsKey)
    }
}
