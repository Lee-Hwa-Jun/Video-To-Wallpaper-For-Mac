import Foundation
import ServiceManagement

enum LoginItemError: LocalizedError {
    case notRunningFromAppBundle

    var errorDescription: String? {
        switch self {
        case .notRunningFromAppBundle:
            return "로그인 시 자동 실행은 .app 번들로 실행했을 때만 설정할 수 있습니다. Scripts/build-app.sh 로 앱을 만든 뒤 사용하세요."
        }
    }
}

/// macOS 13+ SMAppService를 사용한 로그인 항목 등록/해제
enum LoginItemManager {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) throws {
        guard Bundle.main.bundleIdentifier != nil, Bundle.main.bundleURL.pathExtension == "app" else {
            throw LoginItemError.notRunningFromAppBundle
        }
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
