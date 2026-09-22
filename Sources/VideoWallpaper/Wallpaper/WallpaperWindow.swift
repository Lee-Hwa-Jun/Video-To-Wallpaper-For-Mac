import AppKit

/// 데스크톱 배경 바로 위, 바탕화면 아이콘 아래에 놓이는 테두리 없는 창입니다.
final class WallpaperWindow: NSWindow {
    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        // 시스템 배경화면(desktop level)보다 한 단계 위, 바탕화면 아이콘(desktop icon level)보다는 아래
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindowLevel)) + 1)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        isOpaque = true
        hasShadow = false
        ignoresMouseEvents = true
        backgroundColor = .black
        isReleasedWhenClosed = false
        isExcludedFromWindowsMenu = true
        animationBehavior = .none
        hidesOnDeactivate = false
        canHide = false
        isMovable = false
        isRestorable = false
        displaysWhenScreenProfileChanges = true
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
