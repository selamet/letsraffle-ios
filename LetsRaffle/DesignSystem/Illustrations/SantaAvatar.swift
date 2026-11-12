import AVFoundation
import SwiftUI
import UIKit

/// Santa moods rendered in Blender (art/build_santa.py in letsraffle-web) and
/// shipped as small HEVC-with-alpha videos in Resources/Santa. Video is
/// hardware decoded, so playback stays smooth and the files stay tiny.
enum SantaMood: String, CaseIterable {
    case wave, thinking, sad, celebrate, draw, list, cover, watch, invite

    var fileURL: URL? { Bundle.main.url(forResource: "santa-\(rawValue)", withExtension: "mov") }

    /// Pixel size of the video, used to bottom-align the figure before the video loads.
    var pixelSize: CGSize {
        switch self {
        case .draw: CGSize(width: 626, height: 710)
        case .wave: CGSize(width: 546, height: 736)
        case .thinking: CGSize(width: 494, height: 704)
        case .sad: CGSize(width: 498, height: 644)
        case .celebrate: CGSize(width: 586, height: 814)
        case .list: CGSize(width: 612, height: 696)
        case .watch: CGSize(width: 574, height: 678)
        case .cover: CGSize(width: 416, height: 652)
        case .invite: CGSize(width: 632, height: 678)
        }
    }
}

/// Animated Santa. Keeps the old `SantaAvatar(size:thinking:)` call sites working.
/// Width is `size`, height is `size * 1.25`; the figure is bottom aligned.
struct SantaAvatar: View {
    var size: CGFloat = 160
    var thinking = false
    var mood: SantaMood? = nil

    private var resolvedMood: SantaMood { mood ?? (thinking ? .thinking : .wave) }

    var body: some View {
        AnimatedSanta(mood: resolvedMood)
            .frame(width: size, height: size * 1.25)
            .accessibilityHidden(true)
    }
}

/// Fills its frame (aspect fit, bottom aligned).
struct AnimatedSanta: UIViewRepresentable {
    let mood: SantaMood
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeUIView(context: Context) -> SantaVideoView {
        let view = SantaVideoView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return view
    }

    func updateUIView(_ view: SantaVideoView, context: Context) {
        view.show(mood: mood, animated: !reduceMotion)
    }

    static func dismantleUIView(_ view: SantaVideoView, coordinator: ()) {
        view.teardown()
    }
}

/// Loops a transparent Santa video. Plays only while on screen and in the
/// foreground; with Reduce Motion it shows the first frame.
final class SantaVideoView: UIView {
    private let playerLayer = AVPlayerLayer()
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var readyObservation: NSKeyValueObservation?
    private var current: (SantaMood, Bool)?

    private static let configureAudio: Void = {
        // Silent videos must never interrupt the user's music.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        playerLayer.videoGravity = .resizeAspect
        playerLayer.pixelBufferAttributes = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        playerLayer.opacity = 0
        layer.addSublayer(playerLayer)
        NotificationCenter.default.addObserver(self, selector: #selector(updatePlayback),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func show(mood: SantaMood, animated: Bool) {
        if let current, current.0 == mood {
            if current.1 != animated {
                self.current = (mood, animated)
                updatePlayback()
            }
            return
        }
        current = (mood, animated)
        teardown()
        _ = Self.configureAudio
        guard let url = mood.fileURL else { return }

        let player = AVQueuePlayer()
        player.isMuted = true
        player.preventsDisplaySleepDuringVideoPlayback = false
        player.allowsExternalPlayback = false
        looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
        self.player = player
        playerLayer.player = player
        readyObservation = playerLayer.observe(\.isReadyForDisplay, options: [.initial, .new]) { layer, _ in
            guard layer.isReadyForDisplay else { return }
            DispatchQueue.main.async { layer.opacity = 1 }
        }
        setNeedsLayout()
        updatePlayback()
    }

    func stop() {
        player?.pause()
    }

    func teardown() {
        readyObservation = nil
        looper?.disableLooping()
        looper = nil
        player?.pause()
        player = nil
        playerLayer.player = nil
        playerLayer.opacity = 0
    }

    @objc private func updatePlayback() {
        guard let player else { return }
        if window != nil, current?.1 == true {
            player.play()
        } else {
            player.pause()
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updatePlayback()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let size = current?.0.pixelSize, size.width > 0, size.height > 0 else {
            playerLayer.frame = bounds
            return
        }
        let scale = min(bounds.width / size.width, bounds.height / size.height)
        let w = size.width * scale
        let h = size.height * scale
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = CGRect(x: (bounds.width - w) / 2, y: bounds.height - h, width: w, height: h)
        CATransaction.commit()
    }
}

#Preview {
    HStack {
        SantaAvatar(size: 140, mood: .draw)
        SantaAvatar(size: 120, thinking: true)
    }
    .padding()
    .background(Palette.heroGradient)
}
