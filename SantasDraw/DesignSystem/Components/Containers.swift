import SwiftUI
import UIKit
import ObjectiveC

/// Eyebrow + title + subtitle block used at the top of most screens.
struct ScreenHeader: View {
    var eyebrow: String?
    let title: String
    var subtitle: String?
    var titleSize: CGFloat = 32
    var script: String? = nil
    var onDark = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let eyebrow {
                Text(eyebrow)
                    .font(.eyebrow)
                    .tracking(2.4)
                    .textCase(.uppercase)
                    .foregroundStyle(onDark ? Palette.goldLight : Palette.brandText)
            }
            if let script {
                Text(script)
                    .font(AppFont.script(36))
                    .foregroundStyle(onDark ? Palette.goldLight : Color(hex: 0xB8892B))
            }
            Text(title)
                .font(AppFont.display(titleSize))
                .foregroundStyle(onDark ? Palette.snow : Palette.brandText)
            CandyStripe(width: 80)
                .padding(.top, 2)
            if let subtitle {
                Text(subtitle)
                    .font(AppFont.body(15, .medium))
                    .foregroundStyle(onDark ? Palette.snow.opacity(0.9) : Palette.sub)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Red & white candy-cane stripe used as a divider under titles.
struct CandyStripe: View {
    var width: CGFloat = 80
    var height: CGFloat = 8
    @State private var phase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Palette.snow))
            var x: CGFloat = -size.height * 2 + phase
            while x < size.width + size.height {
                var p = Path()
                p.move(to: CGPoint(x: x, y: size.height))
                p.addLine(to: CGPoint(x: x + size.height, y: 0))
                p.addLine(to: CGPoint(x: x + size.height + 9, y: 0))
                p.addLine(to: CGPoint(x: x + 9, y: size.height))
                p.closeSubpath()
                ctx.fill(p, with: .color(Palette.brand))
                x += 18
            }
        }
        .frame(width: width, height: height)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Palette.fieldBorder, lineWidth: 1))
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) { phase = 18 }
        }
        .accessibilityHidden(true)
    }
}

/// White card with the warm inset border.
struct CardSection<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
        VStack(spacing: 0) { content }
            .background(Palette.card, in: shape)
            .clipShape(shape)
            .overlay(shape.strokeBorder(Palette.cardBorder, lineWidth: 2))
    }
}

/// Settings-style row with a tinted icon tile, title, subtitle and trailing accessory.
struct IconRow<Trailing: View>: View {
    let icon: String
    let iconTint: Color
    let iconBackground: Color
    let title: String
    var subtitle: String?
    var showsSeparator = false
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(iconTint)
                .frame(width: 34, height: 34)
                .background(iconBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(AppFont.body(16, .bold)).foregroundStyle(Palette.text)
                if let subtitle {
                    Text(subtitle).font(AppFont.body(13, .medium)).foregroundStyle(Palette.sub)
                }
            }
            Spacer(minLength: 8)
            trailing
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 60)
        .overlay(alignment: .bottom) {
            if showsSeparator {
                Rectangle().fill(Palette.sep).frame(height: 1).padding(.leading, 62)
            }
        }
    }
}

/// Small status capsule ("Aktif", "Bitti"...).
struct StatusChip: View {
    let title: String
    let foreground: Color
    let background: Color

    var body: some View {
        Text(title)
            .font(AppFont.body(12, .black))
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(background, in: Capsule())
    }
}

/// Inline info / success / error banner.
struct Banner: View {
    enum Style { case info, success, error }

    let text: String
    var style: Style = .info

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
            Text(text).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .font(AppFont.body(14, .bold))
        .foregroundStyle(foreground)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var icon: String {
        switch style {
        case .info: "info.circle"
        case .success: "checkmark.circle"
        case .error: "exclamationmark.triangle"
        }
    }

    private var foreground: Color {
        switch style {
        case .info, .error: Palette.brandText
        case .success: Palette.greenText
        }
    }

    private var background: Color {
        switch style {
        case .info, .error: Palette.chip
        case .success: Palette.greenSoft
        }
    }
}

/// Decorative falling snow flakes over the red scenes.
struct SnowDots: View {
    struct Dot { let x: CGFloat; let y: CGFloat; let size: CGFloat; let opacity: Double }

    var dots: [Dot] = [
        Dot(x: 0.07, y: 0.14, size: 5, opacity: 0.8),
        Dot(x: 0.88, y: 0.23, size: 4, opacity: 0.6),
        Dot(x: 0.15, y: 0.34, size: 5, opacity: 0.5),
        Dot(x: 0.70, y: 0.10, size: 4, opacity: 0.7),
        Dot(x: 0.42, y: 0.05, size: 3, opacity: 0.6),
        Dot(x: 0.58, y: 0.28, size: 5, opacity: 0.5),
    ]

    /// Denser snowfall for big red scenes.
    static let heavy: [Dot] = [
        Dot(x: 0.62, y: 0.74, size: 7, opacity: 0.78),
        Dot(x: 0.82, y: 0.65, size: 5, opacity: 0.51),
        Dot(x: 0.47, y: 0.94, size: 6, opacity: 0.52),
        Dot(x: 0.18, y: 0.37, size: 7, opacity: 0.60),
        Dot(x: 0.54, y: 0.57, size: 3, opacity: 0.79),
        Dot(x: 0.41, y: 0.18, size: 7, opacity: 0.81),
        Dot(x: 0.18, y: 0.80, size: 4, opacity: 0.75),
        Dot(x: 0.45, y: 0.13, size: 7, opacity: 0.50),
        Dot(x: 0.76, y: 0.96, size: 4, opacity: 0.85),
        Dot(x: 0.30, y: 0.96, size: 5, opacity: 0.85),
        Dot(x: 0.62, y: 0.18, size: 6, opacity: 0.58),
        Dot(x: 0.94, y: 0.38, size: 3, opacity: 0.64),
        Dot(x: 0.19, y: 0.15, size: 3, opacity: 0.63),
        Dot(x: 0.80, y: 0.59, size: 5, opacity: 0.77),
        Dot(x: 0.35, y: 0.31, size: 7, opacity: 0.62),
        Dot(x: 0.68, y: 0.18, size: 5, opacity: 0.78),
        Dot(x: 0.08, y: 0.98, size: 3, opacity: 0.88),
        Dot(x: 0.37, y: 0.40, size: 5, opacity: 0.82),
        Dot(x: 0.37, y: 0.58, size: 3, opacity: 0.68),
        Dot(x: 0.70, y: 0.62, size: 4, opacity: 0.55),
        Dot(x: 0.26, y: 0.82, size: 5, opacity: 0.64),
        Dot(x: 0.36, y: 0.52, size: 7, opacity: 0.69),
        Dot(x: 0.58, y: 0.78, size: 4, opacity: 0.84),
        Dot(x: 0.06, y: 0.95, size: 3, opacity: 0.58),
        Dot(x: 0.51, y: 0.36, size: 4, opacity: 0.64),
        Dot(x: 0.90, y: 0.55, size: 4, opacity: 0.77),
        Dot(x: 0.32, y: 0.80, size: 6, opacity: 0.56),
        Dot(x: 0.68, y: 1.00, size: 4, opacity: 0.79),
        Dot(x: 0.11, y: 0.60, size: 5, opacity: 0.51),
        Dot(x: 0.73, y: 0.34, size: 4, opacity: 0.68),
        Dot(x: 0.43, y: 0.06, size: 6, opacity: 0.51),
        Dot(x: 0.49, y: 0.84, size: 4, opacity: 0.89),
        Dot(x: 0.56, y: 0.13, size: 7, opacity: 0.67),
        Dot(x: 0.19, y: 0.37, size: 3, opacity: 0.84),
        Dot(x: 0.31, y: 0.45, size: 5, opacity: 0.84),
        Dot(x: 0.95, y: 0.45, size: 5, opacity: 0.78),
        Dot(x: 0.33, y: 0.27, size: 5, opacity: 0.66),
        Dot(x: 0.17, y: 0.38, size: 5, opacity: 0.88),
        Dot(x: 0.62, y: 0.50, size: 4, opacity: 0.57),
        Dot(x: 0.49, y: 0.52, size: 5, opacity: 0.85),
        Dot(x: 0.37, y: 0.79, size: 7, opacity: 0.64),
        Dot(x: 0.58, y: 0.03, size: 4, opacity: 0.65),
        Dot(x: 0.69, y: 0.28, size: 5, opacity: 0.61),
        Dot(x: 0.95, y: 0.72, size: 4, opacity: 0.76),
        Dot(x: 0.58, y: 0.01, size: 5, opacity: 0.81),
        Dot(x: 0.34, y: 0.27, size: 4, opacity: 0.83),
        Dot(x: 0.64, y: 0.80, size: 4, opacity: 0.61),
        Dot(x: 0.35, y: 0.94, size: 5, opacity: 0.64),
        Dot(x: 0.82, y: 0.87, size: 6, opacity: 0.68),
        Dot(x: 0.37, y: 0.33, size: 4, opacity: 0.71),
        Dot(x: 0.19, y: 0.84, size: 7, opacity: 0.69),
        Dot(x: 0.68, y: 0.72, size: 6, opacity: 0.67),
        Dot(x: 0.61, y: 0.94, size: 5, opacity: 0.77),
        Dot(x: 0.43, y: 0.62, size: 7, opacity: 0.85),
    ]

    var falling = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !falling || reduceMotion)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                ForEach(dots.indices, id: \.self) { i in
                    let d = dots[i]
                    let moving = falling && !reduceMotion
                    let speed: Double = 0.035 + Double(i % 3) * 0.012
                    let base = Double(d.y)
                    let yv: Double = moving ? (base + t * speed).truncatingRemainder(dividingBy: 1.08) - 0.04 : base
                    let sway: Double = moving ? sin(t * 0.8 + Double(i)) * 10 : 0
                    Circle()
                        .fill(.white.opacity(d.opacity))
                        .frame(width: d.size, height: d.size)
                        .position(x: geo.size.width * d.x + CGFloat(sway), y: geo.size.height * CGFloat(yv))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// String of fairy lights drooping across the top of a red scene.
struct Garland: View {
    @State private var on = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .topLeading) {
                Path { p in
                    p.move(to: CGPoint(x: -10, y: 8))
                    p.addQuadCurve(to: CGPoint(x: w / 2, y: 18), control: CGPoint(x: w / 4, y: 46))
                    p.addQuadCurve(to: CGPoint(x: w + 10, y: 6), control: CGPoint(x: w * 0.75, y: -6))
                }
                .stroke(Color(hex: 0x2C1210).opacity(0.6), lineWidth: 2)
                ForEach(0..<6, id: \.self) { i in
                    let colors: [Color] = [Palette.goldLight, Color(hex: 0x4FB87E), Palette.snow]
                    let xs: [CGFloat] = [0.07, 0.24, 0.41, 0.6, 0.78, 0.93]
                    let ys: [CGFloat] = [22, 34, 30, 18, 12, 14]
                    Capsule()
                        .fill(colors[i % 3])
                        .frame(width: 9, height: 13)
                        .shadow(color: colors[i % 3], radius: 6)
                        .opacity(reduceMotion ? 1 : ((i % 2 == 0) == on ? 1 : 0.4))
                        .position(x: w * xs[i], y: ys[i])
                }
            }
        }
        .frame(height: 50)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever()) { on.toggle() }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Wavy snow bank used at the bottom of red scenes / top of cream sheets.
struct SnowWave: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: 0, y: h * 0.5))
        p.addCurve(to: CGPoint(x: w * 0.54, y: h * 0.4), control1: CGPoint(x: w * 0.18, y: h * 0.1), control2: CGPoint(x: w * 0.36, y: h * 0.75))
        p.addCurve(to: CGPoint(x: w, y: h * 0.36), control1: CGPoint(x: w * 0.72, y: h * 0.08), control2: CGPoint(x: w * 0.88, y: h * 0.0))
        p.addLine(to: CGPoint(x: w, y: h))
        p.addLine(to: CGPoint(x: 0, y: h))
        p.closeSubpath()
        return p
    }
}

/// Dark pine silhouettes behind content on red scenes.
struct PineSilhouettes: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let trees: [(CGFloat, CGFloat, CGFloat)] = [(0.0, 0.35, 0.13), (0.15, 0.15, 0.15), (0.77, 0.2, 0.15), (0.96, 0.5, 0.12)]
            for (cx, top, half) in trees {
                var p = Path()
                p.move(to: CGPoint(x: w * cx, y: h * top))
                p.addLine(to: CGPoint(x: w * (cx + half), y: h))
                p.addLine(to: CGPoint(x: w * (cx - half), y: h))
                p.closeSubpath()
                ctx.fill(p, with: .color(Color(hex: 0x5A0A0F).opacity(0.55)))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Full-bleed red Christmas backdrop: gradient, snow, optional garland and pines.
struct ChristmasBackdrop: View {
    var garland = true
    var pines = true
    var heavySnow = false

    var body: some View {
        ZStack(alignment: .top) {
            Palette.heroGradient
            RadialGradient(colors: [.white.opacity(0.12), .clear], center: UnitPoint(x: 0.6, y: 0.25), startRadius: 0, endRadius: 420)
            if pines {
                VStack {
                    Spacer()
                    PineSilhouettes().frame(height: 170).padding(.bottom, 180)
                }
            }
            SnowDots(dots: heavySnow ? SnowDots.heavy : SnowDots().dots)
            if garland {
                Garland().padding(.top, 50)
            }
        }
        .ignoresSafeArea()
    }
}

/// Round wax seal badge ("Ücretsiz").
struct WaxSeal: View {
    let title: String
    var size: CGFloat = 62

    var body: some View {
        Text(title)
            .font(AppFont.body(11, .black))
            .foregroundStyle(Palette.brandText)
            .multilineTextAlignment(.center)
            .frame(width: size, height: size)
            .background(Palette.snow, in: Circle())
            .overlay(Circle().strokeBorder(Palette.gold, lineWidth: 3))
            .shadow(color: Color(hex: 0x3C0000, alpha: 0.3), radius: 7, y: 6)
    }
}

/// Cream gift tag with a punched hole, slightly tilted (used for card titles).
struct GiftTag: View {
    let title: String
    var size: CGFloat = 21

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Palette.brandText)
                .overlay(Circle().strokeBorder(Palette.gold, lineWidth: 2))
                .frame(width: 12, height: 12)
            Text(title)
                .font(AppFont.display(size))
                .foregroundStyle(Palette.brandText)
        }
        .padding(.leading, 14)
        .padding(.trailing, 18)
        .padding(.vertical, 9)
        .background(Palette.snow, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Palette.gold, lineWidth: 2))
        .shadow(color: Color(hex: 0x3C0000, alpha: 0.32), radius: 8, y: 6)
        .rotationEffect(.degrees(-2))
    }
}

/// Cream bottom sheet that sits over a red scene (login, join, forgot password).
struct SnowSheet<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 26)
            .padding(.bottom, 24)
            .background(
                UnevenRoundedRectangle(topLeadingRadius: 34, topTrailingRadius: 34, style: .continuous)
                    .fill(Palette.page)
                    .overlay(alignment: .top) {
                        UnevenRoundedRectangle(topLeadingRadius: 34, topTrailingRadius: 34, style: .continuous)
                            .stroke(Palette.gold, lineWidth: 2)
                            .mask(Rectangle().frame(height: 6).frame(maxHeight: .infinity, alignment: .top))
                    }
                    .shadow(color: Color(hex: 0x320000, alpha: 0.35), radius: 25, y: -10)
                    .ignoresSafeArea(edges: .bottom)
            )
    }
}

// MARK: - Status bar

/// Per-screen status bar style. SwiftUI has no API for this, so the hosting
/// controllers' `preferredStatusBarStyle` is redirected to a shared value
/// that screens set when they appear (light on red headers, dark on cream).
@MainActor
enum StatusBar {
    private(set) static var style: UIStatusBarStyle = .lightContent
    private static var patched = Set<ObjectIdentifier>()

    static func set(_ newStyle: UIStatusBarStyle) {
        style = newStyle
        refresh()
    }

    private static func refresh() {
        for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
            for window in scene.windows {
                var controller = window.rootViewController
                while let current = controller {
                    patchIfNeeded(current)
                    current.setNeedsStatusBarAppearanceUpdate()
                    controller = current.presentedViewController
                }
            }
        }
    }

    private static func patchIfNeeded(_ controller: UIViewController) {
        let cls: AnyClass = type(of: controller)
        let id = ObjectIdentifier(cls)
        guard !patched.contains(id), NSStringFromClass(cls).contains("Hosting") else { return }
        patched.insert(id)
        let selector = #selector(getter: UIViewController.preferredStatusBarStyle)
        guard let method = class_getInstanceMethod(UIViewController.self, selector) else { return }
        let block: @convention(block) (AnyObject) -> Int = { _ in
            MainActor.assumeIsolated { StatusBar.style.rawValue }
        }
        class_replaceMethod(cls, selector, imp_implementationWithBlock(block), method_getTypeEncoding(method))
    }
}

extension View {
    /// Sets the status bar style while this screen is on top.
    func statusBarStyle(_ style: UIStatusBarStyle) -> some View {
        onAppear { StatusBar.set(style) }
            .onChange(of: style) { _, newStyle in StatusBar.set(newStyle) }
    }
}
