import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = ConfigStore()
    private let displays = DisplayList()
    private lazy var manager = WallpaperManager(store: store)
    private var statusBar: StatusBarController?
    private var settingsWindow: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Dock 아이콘 없이 메뉴바에만 표시
        NSApp.setActivationPolicy(.accessory)

        manager.start()

        let settings = SettingsWindowController(store: store, manager: manager, displays: displays)
        settingsWindow = settings
        statusBar = StatusBarController(store: store, manager: manager) { [weak settings] in
            settings?.show()
        }

        // 아직 영상을 고르지 않았다면 설정 창을 바로 보여줍니다.
        if !store.config.hasAnyVideo {
            settings.show()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        settingsWindow?.show()
        return true
    }

    /// Finder에서 영상 파일을 앱 아이콘에 떨어뜨렸을 때
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        store.config.setVideoForAllDisplays(url.path)
        settingsWindow?.show()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
