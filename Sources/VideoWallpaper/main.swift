import AppKit

// 메뉴바(accessory) 앱이므로 Storyboard/`@main` 대신 수동으로 NSApplication을 구동합니다.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
