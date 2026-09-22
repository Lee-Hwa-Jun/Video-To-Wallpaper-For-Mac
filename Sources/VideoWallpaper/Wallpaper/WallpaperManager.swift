import AppKit
import Combine

/// 연결된 모든 모니터의 배경 창을 만들고, 설정 변경·모니터 연결 변경·잠자기 등을 반영합니다.
final class WallpaperManager: ObservableObject {
    @Published private(set) var isPaused = false

    private let store: ConfigStore
    private var controllers: [String: WallpaperWindowController] = [:]
    private var screensAsleep = false
    private var cancellables = Set<AnyCancellable>()
    private var observers: [NSObjectProtocol] = []

    init(store: ConfigStore) {
        self.store = store
    }

    func start() {
        store.$config
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.applyConfig() }
            .store(in: &cancellables)

        let center = NotificationCenter.default
        observers.append(center.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in self?.rebuild() })

        let workspace = NSWorkspace.shared.notificationCenter
        observers.append(workspace.addObserver(
            forName: NSWorkspace.screensDidSleepNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.screensAsleep = true
            self?.applyConfig()
        })
        observers.append(workspace.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.screensAsleep = false
            self?.applyConfig()
        })

        rebuild()
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers.forEach { NSWorkspace.shared.notificationCenter.removeObserver($0) }
    }

    func togglePause() {
        isPaused.toggle()
        applyConfig()
    }

    func setPaused(_ paused: Bool) {
        guard isPaused != paused else { return }
        isPaused = paused
        applyConfig()
    }

    /// 모니터 구성에 맞춰 창을 만들거나 정리합니다.
    func rebuild() {
        var seen = Set<String>()
        for screen in NSScreen.screens {
            let key = screen.stableKey
            guard seen.insert(key).inserted else { continue } // 미러링 중복 방지
            if let controller = controllers[key] {
                controller.move(to: screen)
            } else {
                controllers[key] = WallpaperWindowController(screen: screen)
            }
        }
        for (key, controller) in controllers where !seen.contains(key) {
            controller.close()
            controllers.removeValue(forKey: key)
        }
        applyConfig()
    }

    private func applyConfig() {
        let config = store.config
        let paused = isPaused || screensAsleep
        for (key, controller) in controllers {
            controller.apply(
                config.resolvedConfig(for: key),
                globallyPaused: paused,
                pauseWhenHidden: config.pauseWhenHidden
            )
        }
    }
}
