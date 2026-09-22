import AppKit

extension NSColor {
    /// "#RRGGBB" 또는 "RRGGBB" 형식의 문자열로 색을 만듭니다.
    convenience init?(hex: String) {
        var text = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("#") { text.removeFirst() }
        guard text.count == 6, let value = UInt32(text, radix: 16) else { return nil }
        let r = CGFloat((value >> 16) & 0xFF) / 255
        let g = CGFloat((value >> 8) & 0xFF) / 255
        let b = CGFloat(value & 0xFF) / 255
        self.init(srgbRed: r, green: g, blue: b, alpha: 1)
    }

    /// "#RRGGBB" 문자열
    var hexString: String {
        let color = usingColorSpace(.sRGB) ?? self
        let r = Int(round(max(0, min(1, color.redComponent)) * 255))
        let g = Int(round(max(0, min(1, color.greenComponent)) * 255))
        let b = Int(round(max(0, min(1, color.blueComponent)) * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
