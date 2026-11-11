import AVFoundation
import SwiftUI
import UIKit

// Christmas scenery shared with letsraffle-web: the 2027 door wreath, the
// mountain range, Santa's friends, the fairy-light loader and the transparent
// gift videos. Everything decorative here is hidden from accessibility.

// MARK: - Wreath

/// Small door wreath pinned where two arcs of the garland meet, year inside.
struct GarlandWreath: View {
    var size: CGFloat = 34
    var year = "2027"

    var body: some View {
        Canvas { ctx, canvasSize in
            let s = canvasSize.width / 60
            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }

            // ring of needles
            let ring = Path(ellipseIn: CGRect(x: 11 * s, y: 15 * s, width: 38 * s, height: 38 * s))
            ctx.stroke(
                ring,
                with: .linearGradient(Gradient(colors: [Color(hex: 0x3F9A63), Color(hex: 0x1F5C3E)]), startPoint: pt(18, 15), endPoint: pt(42, 53)),
                lineWidth: 10 * s
            )
            for i in 0..<20 {
                let a = CGFloat(i) / 20 * 2 * .pi
                let r: CGFloat = i % 2 == 1 ? 22.5 : 16
                let center = pt(30 + cos(a) * r, 34 + sin(a) * r)
                let tilt: CGFloat = i % 2 == 1 ? 0.44 : -0.44
                let transform = CGAffineTransform(translationX: center.x, y: center.y).rotated(by: a + .pi / 2 + tilt)
                let leaf = Path(ellipseIn: CGRect(x: -5 * s, y: -2.5 * s, width: 10 * s, height: 5 * s)).applying(transform)
                ctx.fill(leaf, with: .color(Color(hex: 0x2F7A55)))
            }

            // berries
            let berries: [(CGFloat, CGFloat, CGFloat)] = [(13, 40, 2.6), (16, 45, 2.2), (47, 40, 2.6), (44, 45, 2.2), (30, 54, 2.4)]
            for (x, y, r) in berries {
                let berry = Path(ellipseIn: CGRect(x: (x - r) * s, y: (y - r) * s, width: 2 * r * s, height: 2 * r * s))
                ctx.fill(berry, with: .color(Color(hex: 0xE6343A)))
                ctx.stroke(berry, with: .color(Color(hex: 0x7A0F14)), lineWidth: 0.8 * s)
            }

            // year in the middle (dark outline first, gold on top)
            let label = Text(year).font(.custom("Fraunces-Black", size: 10 * s))
            for (dx, dy) in [(-1.0, 0.0), (1, 0), (0, -1), (0, 1), (-0.7, -0.7), (0.7, 0.7), (-0.7, 0.7), (0.7, -0.7)] {
                ctx.draw(label.foregroundColor(Color(hex: 0x7A0F14)), at: pt(30 + dx * 1.1, 34.5 + dy * 1.1))
            }
            ctx.draw(label.foregroundColor(Palette.goldLight), at: pt(30, 34.5))

            // bow on top
            let edge = Color(hex: 0x7A0F14)
            func ribbon(_ points: [(CGFloat, CGFloat)]) -> Path {
                var p = Path()
                p.move(to: pt(points[0].0, points[0].1))
                for q in points.dropFirst() { p.addLine(to: pt(q.0, q.1)) }
                p.closeSubpath()
                return p
            }
            for tail in [ribbon([(30, 13), (24, 24), (27.5, 23.5), (28.5, 27), (31, 15)]), ribbon([(30, 13), (36, 24), (32.5, 23.5), (31.5, 27), (29, 15)])] {
                ctx.fill(tail, with: .color(Color(hex: 0xC4242A)))
                ctx.stroke(tail, with: .color(edge), lineWidth: 1.2 * s)
            }
            for side: CGFloat in [-1, 1] {
                var loop = Path()
                loop.move(to: pt(30, 13))
                loop.addCurve(to: pt(30 + side * 13, 13), control1: pt(30 + side * 8, 5), control2: pt(30 + side * 15, 7))
                loop.addCurve(to: pt(30, 13), control1: pt(30 + side * 11, 19), control2: pt(30 + side * 4, 16))
                ctx.fill(loop, with: .color(Color(hex: 0xD9363C)))
                ctx.stroke(loop, with: .color(edge), lineWidth: 1.2 * s)
            }
            let knot = Path(ellipseIn: CGRect(x: 26.6 * s, y: 9.6 * s, width: 6.8 * s, height: 6.8 * s))
            ctx.fill(knot, with: .color(Color(hex: 0xE6343A)))
            ctx.stroke(knot, with: .color(edge), lineWidth: 1.2 * s)
        }
        .frame(width: size, height: size)
        .shadow(color: Color(hex: 0x280000, alpha: 0.3), radius: 2, y: 2)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Mountains

/// Soft, hazy mountain range with snow caps behind the red scenes.
struct MountainRange: View {
    private struct Peak { let x: CGFloat; let h: CGFloat; let w: CGFloat }
    private struct Layer { let peaks: [Peak]; let top: Color; let opacity: Double; let snow: Double }

    private static let layers: [Layer] = [
        Layer(peaks: [Peak(x: 0.08, h: 0.78, w: 0.26), Peak(x: 0.36, h: 1.0, w: 0.3), Peak(x: 0.68, h: 0.84, w: 0.28), Peak(x: 0.95, h: 0.94, w: 0.26)],
              top: Color(hex: 0xD9666A), opacity: 0.26, snow: 0.34),
        Layer(peaks: [Peak(x: 0.2, h: 0.62, w: 0.26), Peak(x: 0.52, h: 0.74, w: 0.3), Peak(x: 0.84, h: 0.6, w: 0.28)],
              top: Color(hex: 0xC2474C), opacity: 0.4, snow: 0.38),
        Layer(peaks: [Peak(x: 0.04, h: 0.42, w: 0.24), Peak(x: 0.33, h: 0.5, w: 0.26), Peak(x: 0.64, h: 0.38, w: 0.24), Peak(x: 0.93, h: 0.48, w: 0.24)],
              top: Color(hex: 0xA5242A), opacity: 0.55, snow: 0.3),
    ]

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            for layer in Self.layers {
                for peak in layer.peaks {
                    let cx = w * peak.x, top = h * (1 - peak.h), half = w * peak.w
                    var body = Path()
                    body.move(to: CGPoint(x: cx - half, y: h))
                    body.addLine(to: CGPoint(x: cx - half * 0.12, y: top + (h - top) * 0.1))
                    body.addQuadCurve(to: CGPoint(x: cx + half * 0.12, y: top + (h - top) * 0.1), control: CGPoint(x: cx, y: top - (h - top) * 0.02))
                    body.addLine(to: CGPoint(x: cx + half, y: h))
                    body.closeSubpath()
                    ctx.fill(body, with: .linearGradient(
                        Gradient(colors: [layer.top.opacity(layer.opacity), layer.top.opacity(0)]),
                        startPoint: CGPoint(x: cx, y: top), endPoint: CGPoint(x: cx, y: h)
                    ))

                    // snow cap with a jagged lower edge
                    let capH = (h - top) * 0.3
                    let capHalf = half * 0.36
                    var cap = Path()
                    cap.move(to: CGPoint(x: cx - half * 0.1, y: top + (h - top) * 0.085))
                    cap.addQuadCurve(to: CGPoint(x: cx + half * 0.1, y: top + (h - top) * 0.085), control: CGPoint(x: cx, y: top - (h - top) * 0.02))
                    cap.addLine(to: CGPoint(x: cx + capHalf, y: top + capH))
                    cap.addLine(to: CGPoint(x: cx + capHalf * 0.5, y: top + capH * 0.78))
                    cap.addLine(to: CGPoint(x: cx + capHalf * 0.12, y: top + capH * 1.05))
                    cap.addLine(to: CGPoint(x: cx - capHalf * 0.3, y: top + capH * 0.8))
                    cap.addLine(to: CGPoint(x: cx - capHalf * 0.62, y: top + capH * 1.02))
                    cap.addLine(to: CGPoint(x: cx - capHalf, y: top + capH))
                    cap.closeSubpath()
                    ctx.fill(cap, with: .color(Palette.snow.opacity(layer.snow)))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Santa's friends

/// Blender-rendered friends (still frames of the web figures).
enum Friend: String {
    case hug, snowman, rudolph, tree, candy

    /// height / width of the artwork
    var aspect: CGFloat {
        switch self {
        case .hug: 574.0 / 520
        case .snowman: 488.0 / 380
        case .rudolph: 633.0 / 360
        case .tree: 526.0 / 340
        case .candy: 273.0 / 360
        }
    }
}

struct FriendImage: View {
    let friend: Friend
    var width: CGFloat

    var body: some View {
        Image("fig-\(friend.rawValue)")
            .resizable()
            .interpolation(.high)
            .frame(width: width, height: width * friend.aspect)
            .accessibilityHidden(true)
    }
}

/// Snow drift with the snowman pair on the left and a row of trees fading
/// into the distance on the right, half buried in the snow.
struct SnowFriends: View {
    /// colour of the snow (the surface underneath, usually the page colour)
    var fill: Color = Palette.snow
    var height: CGFloat = 96

    var body: some View {
        ZStack(alignment: .bottom) {
            HStack(alignment: .bottom, spacing: 0) {
                FriendImage(friend: .hug, width: 88).padding(.leading, 12).padding(.bottom, 20)
                Spacer(minLength: 0)
                ZStack(alignment: .bottomTrailing) {
                    FriendImage(friend: .tree, width: 34).saturation(0.6).brightness(-0.14).opacity(0.75).padding(.trailing, 86).padding(.bottom, 24)
                    FriendImage(friend: .tree, width: 44).saturation(0.8).brightness(-0.07).opacity(0.9).padding(.trailing, 48).padding(.bottom, 14)
                    FriendImage(friend: .tree, width: 56).padding(.bottom, 2)
                }
                .padding(.trailing, 18)
            }
            SnowWave().fill(fill).frame(height: 52)
        }
        .frame(height: height, alignment: .bottom)
        .frame(maxWidth: .infinity)
        .clipped()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Evenly spaced little crowd for the bottom of the reveal screens.
struct FriendsRow: View {
    var body: some View {
        HStack(alignment: .bottom) {
            Spacer(minLength: 0)
            FriendImage(friend: .snowman, width: 50)
            Spacer(minLength: 0)
            FriendImage(friend: .candy, width: 40)
            Spacer(minLength: 0)
            FriendImage(friend: .hug, width: 62)
            Spacer(minLength: 0)
            FriendImage(friend: .rudolph, width: 46)
            Spacer(minLength: 0)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Loader

/// Christmas loading indicator: a short string of lights twinkling one after another.
struct ChristmasLoader: View {
    var label: String? = nil
    /// true on the red scenes, false on cream cards
    var onDark = false
    var width: CGFloat = 132

    @State private var lit = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var bulbs: [(CGFloat, CGFloat, Color)] {
        [
            (20, 18, Palette.goldLight), (47, 22, Color(hex: 0x4FB87E)), (75, 14, Color(hex: 0xFF6B6B)),
            (103, 10, onDark ? Palette.snow : Color(hex: 0xE6343A)), (130, 11, Palette.goldLight),
        ]
    }

    var body: some View {
        VStack(spacing: 8) {
            let s = width / 150
            ZStack(alignment: .topLeading) {
                Path { p in
                    p.move(to: CGPoint(x: 4 * s, y: 10 * s))
                    p.addQuadCurve(to: CGPoint(x: 75 * s, y: 14 * s), control: CGPoint(x: 40 * s, y: 34 * s))
                    p.addQuadCurve(to: CGPoint(x: 146 * s, y: 10 * s), control: CGPoint(x: 110 * s, y: -6 * s))
                }
                .stroke(Color(hex: onDark ? 0x3B2A1E : 0x6B4A33), style: StrokeStyle(lineWidth: 2.2 * s, lineCap: .round))
                ForEach(Array(bulbs.enumerated()), id: \.offset) { index, bulb in
                    VStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 1.4 * s).fill(Color(hex: 0x4A3A2C)).frame(width: 6.8 * s, height: 6 * s)
                        Ellipse().fill(bulb.2).frame(width: 12.8 * s, height: 17.2 * s)
                            .shadow(color: bulb.2, radius: 5)
                    }
                    .opacity(reduceMotion ? 1 : (lit ? 1 : 0.28))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.55).repeatForever(autoreverses: true).delay(Double(index) * 0.18), value: lit)
                    .position(x: bulb.0 * s, y: (bulb.1 + 10.5) * s)
                }
            }
            .frame(width: width, height: width * 0.36)

            if let label {
                Text(label)
                    .font(AppFont.body(14, .bold))
                    .foregroundStyle(onDark ? Palette.snow.opacity(0.9) : Palette.sub)
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear { lit = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label ?? "")
    }
}

// MARK: - Transparent video

/// Plays a bundled HEVC-with-alpha clip (Resources/Figures). Loops, or plays
/// once from the start whenever `isPlaying` flips to true and then holds the
/// last frame.
struct AlphaVideo: UIViewRepresentable {
    let name: String
    var loops = true
    var isPlaying = true

    func makeUIView(context: Context) -> AlphaVideoUIView {
        let view = AlphaVideoUIView()
        view.load(name: name, loops: loops)
        return view
    }

    func updateUIView(_ view: AlphaVideoUIView, context: Context) {
        view.setPlaying(isPlaying)
    }

    static func dismantleUIView(_ view: AlphaVideoUIView, coordinator: ()) {
        view.teardown()
    }
}

final class AlphaVideoUIView: UIView {
    private let playerLayer = AVPlayerLayer()
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var loops = true
    private var wantsPlayback = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        playerLayer.videoGravity = .resizeAspect
        playerLayer.pixelBufferAttributes = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        layer.addSublayer(playerLayer)
        NotificationCenter.default.addObserver(self, selector: #selector(resume), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func load(name: String, loops: Bool) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mov") else { return }
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        self.loops = loops
        let player = AVQueuePlayer()
        player.isMuted = true
        player.preventsDisplaySleepDuringVideoPlayback = false
        player.allowsExternalPlayback = false
        let item = AVPlayerItem(url: url)
        if loops {
            looper = AVPlayerLooper(player: player, templateItem: item)
        } else {
            player.actionAtItemEnd = .pause
            player.insert(item, after: nil)
        }
        self.player = player
        playerLayer.player = player
    }

    func setPlaying(_ playing: Bool) {
        guard playing != wantsPlayback else { return }
        wantsPlayback = playing
        guard let player else { return }
        if playing {
            if !loops { player.seek(to: .zero) }
            if window != nil { player.play() }
        } else {
            player.pause()
        }
    }

    @objc private func resume() {
        if wantsPlayback, window != nil, loops { player?.play() }
    }

    func teardown() {
        looper?.disableLooping()
        looper = nil
        player?.pause()
        player = nil
        playerLayer.player = nil
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil, wantsPlayback { player?.play() } else { player?.pause() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = bounds
        CATransaction.commit()
    }
}

// MARK: - Confetti

/// One light confetti burst, drawn in a single Canvas.
struct ConfettiBurst: View {
    /// change to fire a new burst
    let trigger: Int
    @State private var start: Date?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Piece { let angle: Double; let speed: Double; let size: CGFloat; let color: Color; let spin: Double }
    private static let pieces: [Piece] = (0..<60).map { i in
        let colors: [Color] = [Palette.goldLight, Palette.gold, Palette.snow, Color(hex: 0xC4242A), Color(hex: 0x4FB87E)]
        let f = Double(i)
        return Piece(
            angle: -Double.pi / 2 + (sin(f * 12.9898) * 0.5) * 1.9,
            speed: 260 + abs(sin(f * 78.233)) * 300,
            size: 6 + CGFloat(abs(sin(f * 3.7))) * 5,
            color: colors[i % colors.count],
            spin: 3 + abs(cos(f * 5.1)) * 6
        )
    }
    private let duration = 1.9

    var body: some View {
        TimelineView(.animation(paused: start == nil)) { timeline in
            Canvas { ctx, size in
                guard let start else { return }
                let t = timeline.date.timeIntervalSince(start)
                guard t >= 0, t < duration else { return }
                let origin = CGPoint(x: size.width / 2, y: size.height * 0.5)
                let fade = t > duration - 0.5 ? (duration - t) / 0.5 : 1
                for piece in Self.pieces {
                    let x = origin.x + CGFloat(cos(piece.angle) * piece.speed * t * 0.9)
                    let y = origin.y + CGFloat(sin(piece.angle) * piece.speed * t + 420 * t * t)
                    var local = ctx
                    local.translateBy(x: x, y: y)
                    local.rotate(by: .radians(piece.spin * t))
                    local.opacity = fade
                    local.fill(Path(CGRect(x: -piece.size / 2, y: -piece.size / 4, width: piece.size, height: piece.size / 2)), with: .color(piece.color))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) { _, _ in
            guard !reduceMotion else { return }
            start = .now
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) { start = nil }
        }
    }
}
