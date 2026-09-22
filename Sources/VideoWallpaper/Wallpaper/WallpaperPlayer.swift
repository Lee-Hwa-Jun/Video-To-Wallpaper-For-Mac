import AVFoundation
import Foundation

/// 모니터 한 대의 영상 재생을 담당합니다. 반복 재생은 끊김이 없는 AVPlayerLooper를 사용합니다.
final class WallpaperPlayer {
    let player = AVQueuePlayer()

    private var looper: AVPlayerLooper?
    private(set) var currentURL: URL?
    private var loop = true
    private var rate: Float = 1.0
    private var wantsPlaying = false

    /// 영상 원본 크기(회전 메타데이터 적용 후). 오디오 파일이거나 아직 로드 전이면 nil.
    private(set) var videoSize: CGSize?
    var onVideoSizeChange: ((CGSize?) -> Void)?

    init() {
        // 배경화면이 화면 잠자기를 막으면 안 됩니다.
        player.preventsDisplaySleepDuringVideoPlayback = false
        player.automaticallyWaitsToMinimizeStalling = false
        player.isMuted = true
    }

    func load(url: URL?, loop: Bool) {
        if url == currentURL && loop == self.loop { return }

        self.loop = loop
        currentURL = url
        videoSize = nil
        onVideoSizeChange?(nil)

        looper?.disableLooping()
        looper = nil
        player.pause()
        player.removeAllItems()

        guard let url else { return }

        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        if loop {
            player.actionAtItemEnd = .advance
            looper = AVPlayerLooper(player: player, templateItem: item)
        } else {
            player.actionAtItemEnd = .pause
            player.insert(item, after: nil)
        }

        loadVideoSize(from: asset)

        if wantsPlaying {
            play()
        }
    }

    func setRate(_ newRate: Float) {
        rate = newRate
        player.defaultRate = newRate
        if player.rate != 0 {
            player.rate = newRate
        }
    }

    func play() {
        wantsPlaying = true
        guard currentURL != nil else { return }

        // 반복이 꺼진 상태로 끝까지 재생된 뒤 다시 '재생'을 누르면 처음부터 시작합니다.
        if !loop, let item = player.currentItem, item.duration.isNumeric, item.currentTime() >= item.duration {
            player.seek(to: .zero)
        }
        player.playImmediately(atRate: rate)
    }

    func pause() {
        wantsPlaying = false
        player.pause()
    }

    func stop() {
        pause()
        looper?.disableLooping()
        looper = nil
        player.removeAllItems()
        currentURL = nil
        videoSize = nil
    }

    private func loadVideoSize(from asset: AVURLAsset) {
        Task { @MainActor [weak self] in
            var size: CGSize?
            if let tracks = try? await asset.loadTracks(withMediaType: .video), let track = tracks.first,
               let loaded = try? await track.load(.naturalSize, .preferredTransform) {
                let rect = CGRect(origin: .zero, size: loaded.0).applying(loaded.1)
                size = CGSize(width: abs(rect.width), height: abs(rect.height))
            }
            guard let self, self.currentURL == asset.url else { return }
            self.videoSize = size
            self.onVideoSizeChange?(size)
        }
    }
}
