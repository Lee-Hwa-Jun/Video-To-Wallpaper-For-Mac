import AppKit

/// 메뉴바 아이콘과 메뉴
final class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let store: ConfigStore
    private let manager: WallpaperManager
    private let openSettings: () -> Void
    private let pauseItem: NSMenuItem

    init(store: ConfigStore, manager: WallpaperManager, openSettings: @escaping () -> Void) {
        self.store = store
        self.manager = manager
        self.openSettings = openSettings
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        pauseItem = NSMenuItem(title: "일시정지", action: nil, keyEquivalent: "p")
        super.init()

        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "play.display", accessibilityDescription: "Video Wallpaper")
                ?? NSImage(systemSymbolName: "play.rectangle", accessibilityDescription: "Video Wallpaper")
            image?.isTemplate = true
            button.image = image
            button.toolTip = "Video Wallpaper"
        }

        let menu = NSMenu()
        menu.delegate = self

        let settingsItem = NSMenuItem(title: "설정…", action: #selector(openSettingsAction), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let openItem = NSMenuItem(title: "영상 열기…", action: #selector(openVideoAction), keyEquivalent: "o")
        openItem.target = self
        menu.addItem(openItem)

        pauseItem.action = #selector(togglePauseAction)
        pauseItem.target = self
        menu.addItem(pauseItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Video Wallpaper 종료", action: #selector(quitAction), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        pauseItem.title = manager.isPaused ? "재생" : "일시정지"
    }

    @objc private func openSettingsAction() {
        openSettings()
    }

    @objc private func openVideoAction() {
        guard let url = MediaFilePicker.pick() else { return }
        store.config.setVideoForAllDisplays(url.path)
    }

    @objc private func togglePauseAction() {
        manager.togglePause()
    }

    @objc private func quitAction() {
        NSApp.terminate(nil)
    }
}
