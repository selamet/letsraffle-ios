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

/// Plays an animated WebP smoothly: frames are decoded ahead of time on a
/// background queue and shown in step with the display via CADisplayLink, so
/// decoding never blocks the main thread and frame timing stays even.
final class AnimatedWebPView: UIView {
    private let imageLayer = CALayer()
    private var current: (SantaMood, Bool)?
    private var pixelSize: CGSize = .zero

    private var source: CGImageSource?
    private var frameTimes: [CFTimeInterval] = []   // cumulative end time of each frame
    private var totalDuration: CFTimeInterval = 0
    private var displayLink: CADisplayLink?
    private var startTime: CFTimeInterval?
    private var shownIndex = -1
    private var buffer: [Int: CGImage] = [:]
    private var pending = Set<Int>()
    private var generation = 0
    private let decodeQueue = DispatchQueue(label: "santa.webp.decode", qos: .userInitiated)

    private static let lookahead = 6
    private static var dataCache: [SantaMood: Data] = [:]

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        imageLayer.contentsGravity = .resize
        imageLayer.actions = ["contents": NSNull(), "bounds": NSNull(), "position": NSNull()]
        layer.addSublayer(imageLayer)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func show(mood: SantaMood, animated: Bool) {
        if let current, current.0 == mood, current.1 == animated { return }
        current = (mood, animated)
        stop()
        generation += 1
        buffer.removeAll()
        pending.removeAll()
        shownIndex = -1
        startTime = nil

        guard let data = Self.data(for: mood),
              let source = CGImageSourceCreateWithData(data as CFData, nil) else { return }
        self.source = source
        let options = [kCGImageSourceShouldCacheImmediately: true] as CFDictionary
        if let first = CGImageSourceCreateImageAtIndex(source, 0, options) {
            pixelSize = CGSize(width: first.width, height: first.height)
            imageLayer.contents = first
            shownIndex = 0
            setNeedsLayout()
        }

        let count = CGImageSourceGetCount(source)
        var time: CFTimeInterval = 0
        frameTimes = (0..<count).map { index in
            time += Self.delay(of: source, at: index)
            return time
        }
        totalDuration = time
        guard animated, count > 1, window != nil else { return }
        start()
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    private func start() {
        guard displayLink == nil, frameTimes.count > 1 else { return }
        prefetch(after: max(shownIndex, 0))
        let link = CADisplayLink(target: DisplayLinkProxy(self), selector: #selector(DisplayLinkProxy.tick(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    fileprivate func tick(_ link: CADisplayLink) {
        guard totalDuration > 0 else { return }
        if startTime == nil {
            // Resume from the frame currently on screen.
            let offset = shownIndex > 0 ? frameTimes[shownIndex - 1] : 0
            startTime = link.targetTimestamp - offset
        }
        let elapsed = (link.targetTimestamp - (startTime ?? 0)).truncatingRemainder(dividingBy: totalDuration)
        let index = frameTimes.firstIndex { elapsed < $0 } ?? 0
        if index != shownIndex, let image = buffer[index] {
            imageLayer.contents = image
            shownIndex = index
            // Drop frames that are behind us.
            buffer = buffer.filter { Self.distance(from: index, to: $0.key, count: frameTimes.count) <= Self.lookahead }
        }
        prefetch(after: index)
    }

    private func prefetch(after index: Int) {
        guard let source else { return }
        let count = frameTimes.count
        let generation = generation
        for step in 1...Self.lookahead {
            let next = (index + step) % count
            guard buffer[next] == nil, !pending.contains(next) else { continue }
            pending.insert(next)
            decodeQueue.async { [weak self] in
                let options = [kCGImageSourceShouldCacheImmediately: true] as CFDictionary
                let image = CGImageSourceCreateImageAtIndex(source, next, options)
                DispatchQueue.main.async {
                    guard let self, self.generation == generation else { return }
                    self.pending.remove(next)
                    if let image { self.buffer[next] = image }
                }
            }
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // Pause off-screen, resume when shown again.
        if window == nil {
            stop()
            startTime = nil
        } else if let current, current.1 {
            start()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard pixelSize.width > 0, pixelSize.height > 0 else {
            imageLayer.frame = bounds
            return
        }
        let scale = min(bounds.width / pixelSize.width, bounds.height / pixelSize.height)
        let w = pixelSize.width * scale
        let h = pixelSize.height * scale
        imageLayer.frame = CGRect(x: (bounds.width - w) / 2, y: bounds.height - h, width: w, height: h)
    }

    private static func distance(from a: Int, to b: Int, count: Int) -> Int {
        (b - a + count) % count
    }

    private static func delay(of source: CGImageSource, at index: Int) -> CFTimeInterval {
        let fallback = 1.0 / 30
        guard let props = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
              let webp = props[kCGImagePropertyWebPDictionary] as? [CFString: Any] else { return fallback }
        let value = (webp[kCGImagePropertyWebPUnclampedDelayTime] as? Double)
            ?? (webp[kCGImagePropertyWebPDelayTime] as? Double)
        guard let value, value > 0.005 else { return fallback }
        return value
    }

    private static func data(for mood: SantaMood) -> Data? {
        if let cached = dataCache[mood] { return cached }
        guard let url = mood.fileURL, let data = try? Data(contentsOf: url) else { return nil }
        dataCache[mood] = data
        return data
    }
}

/// Breaks the CADisplayLink -> target retain cycle.
private final class DisplayLinkProxy: NSObject {
    weak var view: AnimatedWebPView?
    init(_ view: AnimatedWebPView) { self.view = view }
    @objc func tick(_ link: CADisplayLink) {
        guard let view else { link.invalidate(); return }
        view.tick(link)
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
