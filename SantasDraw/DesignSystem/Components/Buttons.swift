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
        PrimaryButtonStyle(background: .white, foreground: Color(hex: 0x1F1F1F), edge: Color(hex: 0xD6D6D6), rim: Color(hex: 0x747775), height: 54)
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
struct AppleLabel: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "applelogo").font(.system(size: 18, weight: .semibold))
            Text(title)
        }
    }
}
