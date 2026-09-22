import AppKit
import UniformTypeIdentifiers

enum MediaFilePicker {
    /// 영상/오디오 파일 선택 패널을 띄우고 선택된 파일 URL을 돌려줍니다.
    static func pick() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "배경 영상 선택"
        panel.message = "배경화면으로 재생할 영상(또는 오디오) 파일을 선택하세요"
        panel.prompt = "선택"
        panel.allowedContentTypes = [.movie, .video, .audio]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }
}
