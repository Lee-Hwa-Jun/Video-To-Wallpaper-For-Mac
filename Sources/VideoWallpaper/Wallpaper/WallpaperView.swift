import AppKit
import AVFoundation
import QuartzCore
import CoreImage

/// 영상 레이어를 배치하는 뷰입니다. 맞춤 방식·회전·배경(여백) 처리를 담당합니다.
final class WallpaperView: NSView {
    private let rootLayer = CALayer()
    private let blurLayer = CALayer()
    private let blurPlayerLayer = AVPlayerLayer()
    private let dimLayer = CALayer()
    private let playerLayer = AVPlayerLayer()

    private var config = DisplayConfig()

    var videoSize: CGSize? {
        didSet { needsLayout = true }
    }

    var player: AVPlayer? {
        didSet {
            playerLayer.player = player
            blurPlayerLayer.player = player
        }
    }

    override init(frame: NSRect) {
        super.init(frame: frame)

        // 레이어 호스팅 뷰: layer를 먼저 지정한 뒤 wantsLayer를 켭니다.
        layer = rootLayer
        wantsLayer = true
        layerUsesCoreImageFilters = true
        layerContentsRedrawPolicy = .never

        rootLayer.backgroundColor = NSColor.black.cgColor
        rootLayer.masksToBounds = true

        // 여백을 채우는 '흐린 배경' 레이어
        blurLayer.masksToBounds = true
        if let blur = CIFilter(name: "CIGaussianBlur") {
            blur.setValue(60, forKey: kCIInputRadiusKey)
            blurLayer.filters = [blur]
        }
        blurPlayerLayer.videoGravity = .resizeAspectFill
        blurLayer.addSublayer(blurPlayerLayer)

        dimLayer.backgroundColor = NSColor.black.withAlphaComponent(0.35).cgColor

        rootLayer.addSublayer(blurLayer)
        rootLayer.addSublayer(dimLayer)
        rootLayer.addSublayer(playerLayer)

        // 설정을 바꿀 때 레이어가 스르륵 움직이는 암시적 애니메이션을 끕니다.
        let noActions: [String: CAAction] = [
            "bounds": NSNull(), "position": NSNull(), "transform": NSNull(),
            "hidden": NSNull(), "contents": NSNull(), "backgroundColor": NSNull(),
        ]
        for l in [rootLayer, blurLayer, blurPlayerLayer, dimLayer, playerLayer] {
            l.actions = noActions
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func apply(_ config: DisplayConfig) {
        self.config = config
        needsLayout = true
    }

    override func layout() {
        super.layout()
        relayout()
    }

    // MARK: - Layout

    private func relayout() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }

        let b = bounds
        rootLayer.frame = b
        rootLayer.backgroundColor = backgroundColor().cgColor

        let showBlur = config.background == .blur && config.fitMode.canLeaveEmptySpace && config.videoPath != nil
        blurLayer.isHidden = !showBlur
        dimLayer.isHidden = !showBlur
        blurLayer.frame = b
        dimLayer.frame = b
        // 블러 가장자리가 투명하게 비치지 않도록 살짝 확대합니다.
        place(blurPlayerLayer, size: rotatedSize(of: b.size), in: b, rotation: config.rotation, scale: 1.15)

        switch config.fitMode {
        case .fill:
            playerLayer.videoGravity = .resizeAspectFill
            place(playerLayer, size: rotatedSize(of: b.size), in: b, rotation: config.rotation)
        case .fit:
            playerLayer.videoGravity = .resizeAspect
            place(playerLayer, size: rotatedSize(of: b.size), in: b, rotation: config.rotation)
        case .stretch:
            playerLayer.videoGravity = .resize
            place(playerLayer, size: rotatedSize(of: b.size), in: b, rotation: config.rotation)
        case .fitWidth, .fitHeight:
            guard let videoSize, videoSize.width > 0, videoSize.height > 0 else {
                // 원본 크기를 아직 모르면 일단 채우기 모드처럼 표시합니다.
                playerLayer.videoGravity = .resizeAspectFill
                place(playerLayer, size: rotatedSize(of: b.size), in: b, rotation: config.rotation)
                return
            }
            playerLayer.videoGravity = .resize
            // 화면에 보이는 방향 기준의 영상 크기
            let displayed = config.rotation.swapsAxes
                ? CGSize(width: videoSize.height, height: videoSize.width)
                : videoSize
            let scale = config.fitMode == .fitWidth
                ? b.width / displayed.width
                : b.height / displayed.height
            let layerSize = CGSize(width: videoSize.width * scale, height: videoSize.height * scale)
            place(playerLayer, size: layerSize, in: b, rotation: config.rotation)
        }
    }

    /// 회전 후 화면을 정확히 덮는 레이어 크기 (90°/270°면 가로·세로 교환)
    private func rotatedSize(of size: CGSize) -> CGSize {
        config.rotation.swapsAxes ? CGSize(width: size.height, height: size.width) : size
    }

    private func place(_ layer: CALayer, size: CGSize, in container: CGRect, rotation: Rotation, scale: CGFloat = 1) {
        layer.bounds = CGRect(origin: .zero, size: size)
        layer.position = CGPoint(x: container.midX, y: container.midY)
        var transform = CATransform3DMakeRotation(rotation.radians, 0, 0, 1)
        if scale != 1 {
            transform = CATransform3DScale(transform, scale, scale, 1)
        }
        layer.transform = transform
    }

    private func backgroundColor() -> NSColor {
        switch config.background {
        case .black, .blur:
            return .black
        case .color:
            return NSColor(hex: config.backgroundColorHex) ?? .black
        }
    }
}
