import SwiftUI

/// "Gift box" button: filled face, darker 5pt base and a thin gold inner rim.
struct PrimaryButtonStyle: ButtonStyle {
    var background: Color = Palette.brand
    var foreground: Color = .white
    var edge: Color? = nil
    var rim: Color = Palette.goldLight.opacity(0.6)
    var isLoading = false
    var height: CGFloat = 56

    func makeBody(configuration: Configuration) -> some View {
        PrimaryButtonBody(
            configuration: configuration,
            background: background,
            foreground: foreground,
            edge: edge ?? Self.defaultEdge(for: background),
            rim: rim,
            isLoading: isLoading,
            height: height
        )
    }

    private static func defaultEdge(for color: Color) -> Color {
        if color == Palette.brand { return Palette.brandEdge }
        if color == .white || color == Palette.snow { return Color(hex: 0xE2CDB8) }
        if color == Palette.pine { return Palette.pineEdge }
        if color == .black { return Color(hex: 0x000000) }
        return Color.black.opacity(0.25)
    }
}

private struct PrimaryButtonBody: View {
    let configuration: ButtonStyle.Configuration
    let background: Color
    let foreground: Color
    let edge: Color
    let rim: Color
    let isLoading: Bool
    let height: CGFloat
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        let pressed = configuration.isPressed
        let shape = RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
        ZStack {
            configuration.label.opacity(isLoading ? 0 : 1)
            if isLoading {
                ProgressView().tint(foreground)
            }
        }
        .font(.buttonLabel)
        .foregroundStyle(foreground)
        .frame(maxWidth: .infinity, minHeight: height)
        .background(background, in: shape)
        .overlay(shape.strokeBorder(rim, lineWidth: 2))
        .background(edge, in: shape.offset(y: pressed ? 2 : 5))
        .offset(y: pressed ? 3 : 0)
        .padding(.bottom, 5)
        .opacity(isEnabled ? 1 : 0.45)
        .animation(.easeOut(duration: 0.12), value: pressed)
    }
}

/// Gold gradient variant (invite / "Davet linki oluştur").
struct GoldButtonStyle: ButtonStyle {
    var isLoading = false

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let shape = RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
        return ZStack {
            configuration.label.opacity(isLoading ? 0 : 1)
            if isLoading { ProgressView().tint(Palette.goldText) }
        }
        .font(.buttonLabel)
        .foregroundStyle(Palette.goldText)
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(Palette.goldGradient, in: shape)
        .overlay(shape.strokeBorder(.white.opacity(0.6), lineWidth: 2))
        .background(Palette.goldDark, in: shape.offset(y: pressed ? 2 : 5))
        .offset(y: pressed ? 3 : 0)
        .padding(.bottom, 5)
        .animation(.easeOut(duration: 0.12), value: pressed)
    }
}

/// Christmas call-to-action: glossy red with a gold foil rim and sparkles beside the label.
struct FestiveButtonStyle: ButtonStyle {
    var isLoading = false

    func makeBody(configuration: Configuration) -> some View {
        FestiveButtonBody(configuration: configuration, isLoading: isLoading)
    }
}

private struct FestiveButtonBody: View {
    let configuration: ButtonStyle.Configuration
    let isLoading: Bool
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        let pressed = configuration.isPressed
        let shape = RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
        ZStack {
            HStack(spacing: 10) {
                Image(systemName: "sparkle").font(.system(size: 11, weight: .bold)).foregroundStyle(Palette.goldLight)
                configuration.label
                Image(systemName: "sparkle").font(.system(size: 11, weight: .bold)).foregroundStyle(Palette.goldLight)
            }
            .opacity(isLoading ? 0 : 1)
            if isLoading { ProgressView().tint(.white) }
        }
        .font(.buttonLabel)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, minHeight: 58)
        .contentShape(shape)
        .background(
            ZStack {
                LinearGradient(colors: [Color(hex: 0xD0282F), Palette.cranberry, Palette.cranberryDark], startPoint: .top, endPoint: .bottom)
                LinearGradient(colors: [.white.opacity(0.18), .clear], startPoint: .top, endPoint: .center)
            }
            .clipShape(shape)
        )
        .overlay(shape.strokeBorder(Palette.goldLight, lineWidth: 2.5))
        .background(Color(hex: 0x4A080C), in: shape.offset(y: pressed ? 2 : 5))
        .offset(y: pressed ? 3 : 0)
        .padding(.bottom, 5)
        .opacity(isEnabled ? 1 : 0.45)
        .animation(.easeOut(duration: 0.12), value: pressed)
    }
}

extension ButtonStyle where Self == FestiveButtonStyle {
    static func festive(loading: Bool) -> FestiveButtonStyle { FestiveButtonStyle(isLoading: loading) }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }

    static func primary(loading: Bool) -> PrimaryButtonStyle {
        PrimaryButtonStyle(isLoading: loading)
    }

    static var pine: PrimaryButtonStyle {
        PrimaryButtonStyle(background: Palette.pine, edge: Palette.pineEdge, height: 50)
    }

    /// Black button used for Sign in with Apple (per Apple's guidelines).
    static var inverted: PrimaryButtonStyle {
        PrimaryButtonStyle(background: .black, foreground: .white, edge: .black, rim: .clear, height: 54)
    }

    /// White outlined button used for Google sign-in.
    static var outlinedWhite: PrimaryButtonStyle {
        PrimaryButtonStyle(background: .white, foreground: Color(hex: 0x1F1F1F), edge: .clear, rim: Color(hex: 0x747775), height: 54)
    }
}

extension ButtonStyle where Self == GoldButtonStyle {
    static var gold: GoldButtonStyle { GoldButtonStyle() }
}

/// Circular navigation button (back / close).
struct CircleIconButton: View {
    var systemName = "chevron.left"
    var onDark = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(onDark ? Palette.snow : Palette.brandText)
                .frame(width: 36, height: 36)
                .background(onDark ? Color.white.opacity(0.16) : Palette.card, in: Circle())
                .overlay(Circle().strokeBorder(onDark ? Color.white.opacity(0.35) : Palette.fieldBorder, lineWidth: 1.5))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Back button shaped like a gold Christmas bauble hanging on a string,
/// swinging gently. Used on red headers.
///
/// On screens with the fairy-light garland the string is tied to the wire: whatever part of
/// it would stick out above the wire is left out, and the bauble swings from that knot.
struct OrnamentBackButton: View {
    var stringLength: CGFloat = 18
    var systemName = "chevron.left"
    /// False on screens without a garland (the string then simply comes down from the top).
    var hangsFromGarland = true
    var action: () -> Void
    @State private var swing = false
    /// Length of string above the garland wire, not drawn.
    @State private var hidden: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.strings) private var t

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Color.clear.frame(width: 1.5, height: hidden)
                VStack(spacing: 0) {
                Rectangle()
                    .fill(Palette.goldLight.opacity(0.75))
                    .frame(width: 1.5, height: stringLength - hidden)
                Circle()
                    .strokeBorder(Palette.goldLight, lineWidth: 1.5)
                    .frame(width: 8, height: 8)
                    .padding(.bottom, -3)
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(LinearGradient(colors: [Palette.goldLight, Palette.goldDark], startPoint: .top, endPoint: .bottom))
                    .frame(width: 15, height: 7)
                    .overlay(
                        HStack(spacing: 2.5) {
                            ForEach(0..<3, id: \.self) { _ in
                                Rectangle().fill(Palette.goldDark.opacity(0.6)).frame(width: 1, height: 7)
                            }
                        }
                    )
                    .zIndex(1)
                ZStack {
                    Circle().fill(
                        RadialGradient(colors: [Palette.goldLight, Palette.gold, Palette.goldDark],
                                       center: UnitPoint(x: 0.35, y: 0.3), startRadius: 1, endRadius: 26)
                    )
                    Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                    // Painted band around the bauble.
                    Capsule()
                        .fill(Palette.cranberry.opacity(0.18))
                        .frame(height: 6)
                        .offset(y: 9)
                        .mask(Circle())
                    Image(systemName: systemName)
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(Palette.cranberryDark)
                        .offset(x: systemName == "chevron.left" ? -1 : 0)
                    Ellipse()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 9, height: 5)
                        .rotationEffect(.degrees(-35))
                        .offset(x: -9, y: -10)
                }
                .frame(width: 38, height: 38)
                .padding(.top, -1)
                .shadow(color: Color(hex: 0x3A0006, alpha: 0.35), radius: 4, y: 3)
                }
                .rotationEffect(.degrees(swing ? 5 : -5), anchor: .top)
            }
            .frame(width: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(OrnamentPressStyle())
        .accessibilityLabel(t.backLabel)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
            guard hangsFromGarland else { return }
            // The garland sits 50pt below the top of the screen (see ChristmasBackdrop).
            let wire = 50 + Garland.wireY(atX: frame.midX, width: UIScreen.main.bounds.width)
            let above = min(max(0, wire - frame.minY), max(0, stringLength - 6))
            if abs(above - hidden) > 0.5 { hidden = above }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true)) { swing = true }
        }
    }
}

private struct OrnamentPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1, anchor: .top)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

/// Pill shaped text button (e.g. "Register" in the login header).
struct PillButton: View {
    let title: String
    var onDark = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.body(15, .bold))
                .foregroundStyle(onDark ? Palette.snow : Palette.brandText)
                .padding(.horizontal, 14)
                .frame(height: 36)
                .background(onDark ? Color.white.opacity(0.16) : Palette.card, in: Capsule())
                .overlay(Capsule().strokeBorder(onDark ? Color.white.opacity(0.35) : Palette.fieldBorder, lineWidth: 1.5))
                .frame(height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Apple logo + title label used by `AppleSignInButton`.
///
/// The logo is Apple's official left-aligned artwork from Apple Design Resources
/// (`siwa-logo-white`, white logo on pure black). App Review rejects Sign in with Apple
/// buttons with any other logo (e.g. the `applelogo` SF Symbol), so never redraw or
/// recolor it, keep the button background pure black, and use the system font.
struct AppleLabel: View {
    let title: String

    var body: some View {
        HStack(spacing: 0) {
            Image("siwa-logo-white")
                .resizable()
                .scaledToFit()
                .frame(height: 44)
                .accessibilityHidden(true)
            Text(title)
                .font(.system(size: 19, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.trailing, 12)
        }
    }
}
