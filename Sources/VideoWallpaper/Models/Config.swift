import Foundation
import CoreGraphics

/// 영상이 화면 크기와 다를 때 어떻게 맞출지 결정합니다.
enum FitMode: String, Codable, CaseIterable, Identifiable {
    /// 화면을 빈틈없이 채우고, 넘치는 부분은 잘라냅니다. (기본값)
    case fill
    /// 영상 전체가 보이도록 화면 안에 맞추고, 남는 부분은 배경으로 채웁니다.
    case fit
    /// 영상의 가로 폭을 화면 가로 폭에 맞춥니다. 위아래는 잘리거나 남을 수 있습니다.
    case fitWidth
    /// 영상의 세로 높이를 화면 세로 높이에 맞춥니다. 좌우는 잘리거나 남을 수 있습니다.
    case fitHeight
    /// 비율을 무시하고 화면에 꽉 차도록 늘립니다.
    case stretch

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fill: return "화면 채우기 (넘치는 부분 잘림)"
        case .fit: return "화면에 맞추기 (남는 부분 배경)"
        case .fitWidth: return "가로 폭 기준으로 맞추기"
        case .fitHeight: return "세로 높이 기준으로 맞추기"
        case .stretch: return "늘려서 채우기 (비율 무시)"
        }
    }

    var detail: String {
        switch self {
        case .fill: return "영상 비율을 유지하면서 화면을 가득 채웁니다. 화면 밖으로 나가는 부분은 보이지 않습니다."
        case .fit: return "영상이 잘리지 않고 전체가 보입니다. 남는 영역은 아래 '남는 부분' 설정으로 채웁니다."
        case .fitWidth: return "영상의 가로 폭을 화면 가로에 정확히 맞춥니다. 세로가 길면 위아래가 잘리고, 짧으면 위아래에 여백이 생깁니다."
        case .fitHeight: return "영상의 세로 높이를 화면 세로에 정확히 맞춥니다. 가로가 길면 좌우가 잘리고, 짧으면 좌우에 여백이 생깁니다."
        case .stretch: return "영상이 화면 비율에 맞게 늘어나거나 눌립니다."
        }
    }

    /// 남는 영역(여백)이 생길 수 있는 모드인지 여부
    var canLeaveEmptySpace: Bool {
        switch self {
        case .fit, .fitWidth, .fitHeight: return true
        case .fill, .stretch: return false
        }
    }
}

/// 영상 회전. 세로 영상을 가로 화면에 세워서 보이게 하거나, 그 반대로 쓸 때 사용합니다.
enum Rotation: Int, Codable, CaseIterable, Identifiable {
    case degrees0 = 0
    case degrees90 = 90
    case degrees180 = 180
    case degrees270 = 270

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .degrees0: return "회전 없음 (원본 방향)"
        case .degrees90: return "시계 방향 90°"
        case .degrees180: return "180°"
        case .degrees270: return "반시계 방향 90°"
        }
    }

    /// Core Animation은 양수 각도가 반시계 방향이므로, 시계 방향 표기를 위해 부호를 뒤집습니다.
    var radians: CGFloat { -CGFloat(rawValue) * .pi / 180 }

    /// 90° / 270° 회전 시 가로·세로가 뒤바뀝니다.
    var swapsAxes: Bool { self == .degrees90 || self == .degrees270 }
}

/// 화면에 맞췄을 때 남는 영역을 무엇으로 채울지 결정합니다.
enum BackgroundStyle: String, Codable, CaseIterable, Identifiable {
    case black
    case color
    case blur

    var id: String { rawValue }

    var title: String {
        switch self {
        case .black: return "검정"
        case .color: return "단색"
        case .blur: return "영상을 흐리게 확대해서 채우기"
        }
    }
}

/// 한 디스플레이(모니터)에 적용되는 설정입니다.
struct DisplayConfig: Codable, Equatable {
    var enabled: Bool = true
    var videoPath: String? = nil
    var fitMode: FitMode = .fill
    var rotation: Rotation = .degrees0
    var loop: Bool = true
    var muted: Bool = true
    var volume: Float = 0.5
    var playbackRate: Float = 1.0
    var background: BackgroundStyle = .blur
    var backgroundColorHex: String = "#000000"

    init() {}

    private enum CodingKeys: String, CodingKey {
        case enabled, videoPath, fitMode, rotation, loop, muted, volume, playbackRate, background, backgroundColorHex
    }

    /// 설정 항목이 추가되어도 이전 버전에서 저장한 값을 읽을 수 있도록 누락된 키는 기본값을 사용합니다.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? enabled
        videoPath = try c.decodeIfPresent(String.self, forKey: .videoPath) ?? videoPath
        fitMode = try c.decodeIfPresent(FitMode.self, forKey: .fitMode) ?? fitMode
        rotation = try c.decodeIfPresent(Rotation.self, forKey: .rotation) ?? rotation
        loop = try c.decodeIfPresent(Bool.self, forKey: .loop) ?? loop
        muted = try c.decodeIfPresent(Bool.self, forKey: .muted) ?? muted
        volume = try c.decodeIfPresent(Float.self, forKey: .volume) ?? volume
        playbackRate = try c.decodeIfPresent(Float.self, forKey: .playbackRate) ?? playbackRate
        background = try c.decodeIfPresent(BackgroundStyle.self, forKey: .background) ?? background
        backgroundColorHex = try c.decodeIfPresent(String.self, forKey: .backgroundColorHex) ?? backgroundColorHex
    }

    var videoURL: URL? {
        guard let videoPath, !videoPath.isEmpty else { return nil }
        return URL(fileURLWithPath: videoPath)
    }
}

/// 앱 전체 설정입니다.
struct AppConfig: Codable, Equatable {
    /// true이면 모니터별로 다른 설정을 사용하고, false이면 `shared` 설정을 모든 모니터에 적용합니다.
    var perDisplaySettings: Bool = false
    /// 공통 설정 (모니터별 설정이 없는 모니터의 기본값으로도 쓰입니다)
    var shared: DisplayConfig = DisplayConfig()
    /// 모니터 고유 키 → 모니터별 설정
    var displays: [String: DisplayConfig] = [:]
    var launchAtLogin: Bool = false
    /// 다른 창에 완전히 가려졌을 때 재생을 멈춰 배터리/GPU를 절약합니다.
    var pauseWhenHidden: Bool = true

    init() {}

    private enum CodingKeys: String, CodingKey {
        case perDisplaySettings, shared, displays, launchAtLogin, pauseWhenHidden
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        perDisplaySettings = try c.decodeIfPresent(Bool.self, forKey: .perDisplaySettings) ?? perDisplaySettings
        shared = try c.decodeIfPresent(DisplayConfig.self, forKey: .shared) ?? shared
        displays = try c.decodeIfPresent([String: DisplayConfig].self, forKey: .displays) ?? displays
        launchAtLogin = try c.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? launchAtLogin
        pauseWhenHidden = try c.decodeIfPresent(Bool.self, forKey: .pauseWhenHidden) ?? pauseWhenHidden
    }

    /// 실제로 해당 모니터에 적용할 설정
    func resolvedConfig(for displayKey: String) -> DisplayConfig {
        guard perDisplaySettings else { return shared }
        return displays[displayKey] ?? shared
    }

    /// 설정 화면에서 편집 중인 설정. `displayKey`가 nil이면 공통 설정을 의미합니다.
    func editingConfig(for displayKey: String?) -> DisplayConfig {
        guard perDisplaySettings, let displayKey else { return shared }
        return displays[displayKey] ?? shared
    }

    mutating func setConfig(_ config: DisplayConfig, for displayKey: String?) {
        if perDisplaySettings, let displayKey {
            displays[displayKey] = config
        } else {
            shared = config
        }
    }

    /// 주어진 설정을 공통 설정으로 삼고 모니터별 설정을 모두 지웁니다.
    mutating func applyToAllDisplays(_ config: DisplayConfig) {
        shared = config
        displays = [:]
    }

    /// 모든 모니터의 영상 파일만 바꿉니다. (메뉴바 '영상 열기…' 등에서 사용)
    mutating func setVideoForAllDisplays(_ path: String?) {
        shared.videoPath = path
        for key in displays.keys {
            displays[key]?.videoPath = path
        }
    }

    var hasAnyVideo: Bool {
        if shared.videoPath != nil { return true }
        return displays.values.contains { $0.videoPath != nil }
    }
}
