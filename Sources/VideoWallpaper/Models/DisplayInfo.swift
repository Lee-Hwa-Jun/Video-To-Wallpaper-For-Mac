import AppKit
import Combine

/// 연결된 모니터 한 대에 대한 정보입니다.
struct DisplayInfo: Identifiable, Hashable {
    /// 케이블을 뽑았다 다시 꽂아도 유지되는 고유 키 (디스플레이 UUID)
    let id: String
    let displayID: CGDirectDisplayID
    let name: String
    let frame: CGRect
    let pixelSize: CGSize
    let isMain: Bool

    var label: String {
        var text = "\(name) · \(Int(pixelSize.width))×\(Int(pixelSize.height))"
        if isMain { text += " (메인)" }
        return text
    }

    static func == (lhs: DisplayInfo, rhs: DisplayInfo) -> Bool {
        lhs.id == rhs.id
            && lhs.displayID == rhs.displayID
            && lhs.name == rhs.name
            && lhs.frame == rhs.frame
            && lhs.pixelSize == rhs.pixelSize
            && lhs.isMain == rhs.isMain
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return (deviceDescription[key] as? NSNumber)?.uint32Value ?? 0
    }

    /// 재부팅/재연결 후에도 같은 모니터를 식별하기 위한 안정적인 키
    var stableKey: String {
        let id = displayID
        if let unmanaged = CGDisplayCreateUUIDFromDisplayID(id) {
            let uuid = unmanaged.takeRetainedValue()
            if let string = CFUUIDCreateString(nil, uuid) {
                return string as String
            }
        }
        return "display-\(id)"
    }

    var info: DisplayInfo {
        let scale = backingScaleFactor
        return DisplayInfo(
            id: stableKey,
            displayID: displayID,
            name: localizedName,
            frame: frame,
            pixelSize: CGSize(width: frame.width * scale, height: frame.height * scale),
            isMain: self == NSScreen.main
        )
    }
}

/// 현재 연결된 모니터 목록을 관찰 가능한 형태로 제공합니다.
final class DisplayList: ObservableObject {
    @Published private(set) var displays: [DisplayInfo] = []
    private var observer: NSObjectProtocol?

    init() {
        refresh()
        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    func refresh() {
        var seen = Set<String>()
        var result: [DisplayInfo] = []
        for screen in NSScreen.screens {
            let info = screen.info
            // 미러링된 모니터는 같은 키를 가질 수 있으므로 한 번만 넣습니다.
            if seen.insert(info.id).inserted {
                result.append(info)
            }
        }
        displays = result
    }
}
