import AppKit

/// 모니터 한 대 = 창 하나 + 플레이어 하나
final class WallpaperWindowController {
    let key: String
    let window: WallpaperWindow
    let view: WallpaperView
    let player = WallpaperPlayer()

    private var config: DisplayConfig?
    private var globallyPaused = false
    private var pauseWhenHidden = true
    private var occlusionObserver: NSObjectProtocol?

    init(screen: NSScreen) {
        key = screen.stableKey
        window = WallpaperWindow(screen: screen)
        view = WallpaperView(frame: NSRect(origin: .zero, size: screen.frame.size))
        window.contentView = view
        view.player = player.player

        player.onVideoSizeChange = { [weak self] size in
            self?.view.videoSize = size
        }

        // 전체화면 앱 등으로 완전히 가려지면 재생을 멈춥니다.
        occlusionObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didChangeOcclusionStateNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.updatePlayback()
        }
    }

    deinit {
        if let occlusionObserver { NotificationCenter.default.removeObserver(occlusionObserver) }
    }

    func move(to screen: NSScreen) {
        if window.frame != screen.frame {
            window.setFrame(screen.frame, display: true)
        }
    }

    func apply(_ config: DisplayConfig, globallyPaused: Bool, pauseWhenHidden: Bool) {
        self.config = config
        self.globallyPaused = globallyPaused
        self.pauseWhenHidden = pauseWhenHidden

        view.apply(config)

        var url = config.videoURL
        if let candidate = url, !FileManager.default.fileExists(atPath: candidate.path) {
            NSLog("[VideoWallpaper] 파일을 찾을 수 없습니다: %@", candidate.path)
            url = nil
        }
        player.load(url: url, loop: config.loop)
        player.player.isMuted = config.muted
        player.player.volume = config.volume
        player.setRate(config.playbackRate)

        if config.enabled && url != nil {
            window.orderFrontRegardless()
        } else {
            window.orderOut(nil)
        }
        updatePlayback()
    }

    func close() {
        player.stop()
        window.orderOut(nil)
        window.close()
    }

    private func updatePlayback() {
        guard let config, config.enabled, player.currentURL != nil, !globallyPaused else {
            player.pause()
            return
        }
        if pauseWhenHidden && window.isVisible && !window.occlusionState.contains(.visible) {
            player.pause()
            return
        }
        player.play()
    }
}
