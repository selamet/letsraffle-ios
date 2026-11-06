import ImageIO
import SwiftUI
import UIKit

/// Santa moods rendered in Blender (art/build_santa.py in letsraffle-web) and
/// shipped as looping, transparent animated WebP files in Resources/Santa.
enum SantaMood: String, CaseIterable {
    case wave, thinking, sad, celebrate, draw, list, cover, watch, invite

    var fileURL: URL? { Bundle.main.url(forResource: "santa-\(rawValue)", withExtension: "webp") }
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

    func makeUIView(context: Context) -> AnimatedWebPView {
        let view = AnimatedWebPView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return view
    }

    func updateUIView(_ view: AnimatedWebPView, context: Context) {
        view.show(mood: mood, animated: !reduceMotion)
    }

    static func dismantleUIView(_ view: AnimatedWebPView, coordinator: ()) {
        view.stop()
    }
}

final class AnimatedWebPView: UIView {
    private let imageView = UIImageView()
    private var current: (SantaMood, Bool)?
    private var token = PlaybackToken()
    private var pixelSize: CGSize = .zero

    private final class PlaybackToken { var cancelled = false }

    private static var dataCache: [SantaMood: Data] = [:]

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        imageView.contentMode = .scaleToFill
        addSubview(imageView)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func show(mood: SantaMood, animated: Bool) {
        if let current, current.0 == mood, current.1 == animated { return }
        current = (mood, animated)
        stop()

        guard let data = Self.data(for: mood) else { return }
        if let source = CGImageSourceCreateWithData(data as CFData, nil),
           let first = CGImageSourceCreateImageAtIndex(source, 0, nil) {
            pixelSize = CGSize(width: first.width, height: first.height)
            imageView.image = UIImage(cgImage: first)
            setNeedsLayout()
        }
        guard animated else { return }

        let token = PlaybackToken()
        self.token = token
        _ = CGAnimateImageDataWithBlock(data as CFData, nil) { [weak self] _, image, stop in
            guard let self, !token.cancelled else {
                stop.pointee = true
                return
            }
            self.imageView.image = UIImage(cgImage: image)
        }
    }

    func stop() {
        token.cancelled = true
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // Pause off-screen, resume when shown again.
        if window == nil {
            stop()
        } else if let current {
            self.current = nil
            show(mood: current.0, animated: current.1)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard pixelSize.width > 0, pixelSize.height > 0 else {
            imageView.frame = bounds
            return
        }
        let scale = min(bounds.width / pixelSize.width, bounds.height / pixelSize.height)
        let w = pixelSize.width * scale
        let h = pixelSize.height * scale
        imageView.frame = CGRect(x: (bounds.width - w) / 2, y: bounds.height - h, width: w, height: h)
    }

    private static func data(for mood: SantaMood) -> Data? {
        if let cached = dataCache[mood] { return cached }
        guard let url = mood.fileURL, let data = try? Data(contentsOf: url) else { return nil }
        dataCache[mood] = data
        return data
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
