import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var store: ConfigStore
    @ObservedObject var manager: WallpaperManager
    @ObservedObject var displays: DisplayList

    @State private var selectedKey: String = ""
    @State private var loginItemError: String?

    private static let rates: [Float] = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    /// 편집 대상 모니터 키. 공통 설정을 편집 중이면 nil.
    private var editKey: String? {
        store.config.perDisplaySettings ? selectedKey : nil
    }

    private var current: DisplayConfig {
        store.config.editingConfig(for: editKey)
    }

    private var config: Binding<DisplayConfig> {
        let key = editKey
        return Binding(
            get: { store.config.editingConfig(for: key) },
            set: { store.config.setConfig($0, for: key) }
        )
    }

    var body: some View {
        Form {
            displaySection
            videoSection
            layoutSection
            playbackSection
            generalSection
        }
        .formStyle(.grouped)
        .frame(minWidth: 520, minHeight: 640)
        .onAppear(perform: ensureSelection)
        .onChange(of: displays.displays) { _ in ensureSelection() }
        .onChange(of: store.config.perDisplaySettings) { _ in ensureSelection() }
    }

    // MARK: - Sections

    private var displaySection: some View {
        Section {
            Toggle("모니터마다 다른 설정 사용", isOn: $store.config.perDisplaySettings)

            if store.config.perDisplaySettings {
                Picker("설정할 모니터", selection: $selectedKey) {
                    ForEach(displays.displays) { display in
                        Text(display.label).tag(display.id)
                    }
                }
                Button("현재 모니터 설정을 모든 모니터에 적용") {
                    store.config.applyToAllDisplays(current)
                }
            } else {
                Text("연결된 모니터 \(displays.displays.count)대에 같은 설정이 적용됩니다.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("디스플레이")
        }
    }

    private var videoSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "film")
                    .font(.title2)
                    .foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(fileName)
                        .lineLimit(1)
                    if let path = current.videoPath {
                        Text(path)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                Spacer()
                Button("선택…") { chooseFile() }
                if current.videoPath != nil {
                    Button("제거") { update { $0.videoPath = nil } }
                }
            }
            .onDrop(of: [UTType.fileURL], isTargeted: nil, perform: handleDrop)

            Text("mp4, mov, m4v 등 macOS가 재생할 수 있는 영상과 mp3, m4a 등 오디오 파일을 쓸 수 있습니다. 파일을 이 영역에 끌어다 놓아도 됩니다.")
                .font(.caption)
                .foregroundColor(.secondary)

            Toggle(store.config.perDisplaySettings ? "이 모니터에 배경 영상 표시" : "배경 영상 표시", isOn: config.enabled)
        } header: {
            Text("영상 파일")
        }
    }

    private var layoutSection: some View {
        Section {
            Picker("맞춤 방식", selection: config.fitMode) {
                ForEach(FitMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            Text(current.fitMode.detail)
                .font(.caption)
                .foregroundColor(.secondary)

            Picker("회전", selection: config.rotation) {
                ForEach(Rotation.allCases) { rotation in
                    Text(rotation.title).tag(rotation)
                }
            }
            Text("세로 영상을 가로 화면에 세워 보이게 하거나, 세로로 세운 모니터에 맞출 때 사용합니다.")
                .font(.caption)
                .foregroundColor(.secondary)

            if current.fitMode.canLeaveEmptySpace {
                Picker("남는 부분", selection: config.background) {
                    ForEach(BackgroundStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }
                if current.background == .color {
                    ColorPicker("배경색", selection: colorBinding, supportsOpacity: false)
                }
            }
        } header: {
            Text("화면 맞춤")
        }
    }

    private var playbackSection: some View {
        Section {
            Toggle("반복 재생", isOn: config.loop)
            Toggle("소리 끄기", isOn: config.muted)
            HStack {
                Text("볼륨")
                Slider(value: config.volume, in: 0...1)
                Text("\(Int(current.volume * 100))%")
                    .monospacedDigit()
                    .frame(width: 44, alignment: .trailing)
            }
            .disabled(current.muted)

            Picker("재생 속도", selection: config.playbackRate) {
                ForEach(Self.rates, id: \.self) { rate in
                    Text(String(format: "%gx", Double(rate))).tag(rate)
                }
            }
        } header: {
            Text("재생")
        }
    }

    private var generalSection: some View {
        Section {
            Toggle("로그인 시 자동 실행", isOn: launchAtLoginBinding)
            if let loginItemError {
                Text(loginItemError)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            Toggle("다른 창에 완전히 가려지면 일시정지 (배터리 절약)", isOn: $store.config.pauseWhenHidden)

            HStack {
                Button(manager.isPaused ? "재생" : "일시정지") {
                    manager.togglePause()
                }
                Spacer()
                Text("메뉴바 아이콘에서도 제어할 수 있습니다.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("종료") {
                    NSApp.terminate(nil)
                }
            }
        } header: {
            Text("일반")
        }
    }

    // MARK: - Helpers

    private var fileName: String {
        if let path = current.videoPath {
            return (path as NSString).lastPathComponent
        }
        return "선택된 파일 없음"
    }

    private var colorBinding: Binding<Color> {
        Binding(
            get: {
                Color(nsColor: NSColor(hex: store.config.editingConfig(for: editKey).backgroundColorHex) ?? .black)
            },
            set: { newColor in
                update { $0.backgroundColorHex = NSColor(newColor).hexString }
            }
        )
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { store.config.launchAtLogin },
            set: { enabled in
                do {
                    try LoginItemManager.setEnabled(enabled)
                    store.config.launchAtLogin = enabled
                    loginItemError = nil
                } catch {
                    loginItemError = error.localizedDescription
                }
            }
        )
    }

    private func update(_ change: (inout DisplayConfig) -> Void) {
        var value = store.config.editingConfig(for: editKey)
        change(&value)
        store.config.setConfig(value, for: editKey)
    }

    private func ensureSelection() {
        let list = displays.displays
        if list.contains(where: { $0.id == selectedKey }) { return }
        selectedKey = list.first(where: { $0.isMain })?.id ?? list.first?.id ?? ""
    }

    private func chooseFile() {
        guard let url = MediaFilePicker.pick() else { return }
        update { $0.videoPath = url.path }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: {
            $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
        }) else { return false }

        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            guard let url else { return }
            DispatchQueue.main.async {
                update { $0.videoPath = url.path }
            }
        }
        return true
    }
}
