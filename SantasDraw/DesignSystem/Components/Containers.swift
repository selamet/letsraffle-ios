import SwiftUI

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
            SnowDots()
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
