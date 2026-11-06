import SwiftUI

/// Filled 50pt brand button used for primary actions.
struct PrimaryButtonStyle: ButtonStyle {
    var background: Color = Palette.brand
    var foreground: Color = .white
    var isLoading = false

    func makeBody(configuration: Configuration) -> some View {
        PrimaryButtonBody(
            configuration: configuration,
            background: background,
            foreground: foreground,
            isLoading: isLoading
        )
    }
}

private struct PrimaryButtonBody: View {
    let configuration: ButtonStyle.Configuration
    let background: Color
    let foreground: Color
    let isLoading: Bool
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        ZStack {
            configuration.label.opacity(isLoading ? 0 : 1)
            if isLoading {
                ProgressView().tint(foreground)
            }
        }
        .font(.buttonLabel)
        .foregroundStyle(foreground)
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(background, in: RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
        .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.45)
        .scaleEffect(configuration.isPressed ? 0.98 : 1)
        .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }

    static func primary(loading: Bool) -> PrimaryButtonStyle {
        PrimaryButtonStyle(isLoading: loading)
    }

    /// Inverted button (`--text` background), used for the Apple sign-in row.
    static var inverted: PrimaryButtonStyle {
        PrimaryButtonStyle(background: Palette.text, foreground: Palette.page)
    }
}

/// 44pt circular navigation button (back / close) placed on a card background.
struct CircleIconButton: View {
    var systemName = "chevron.left"
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Palette.text)
                .frame(width: 44, height: 44)
                .background(Palette.card, in: Circle())
                .shadow(color: .black.opacity(0.07), radius: 1.5, y: 1)
        }
        .buttonStyle(.plain)
    }
}

/// Pill shaped text button on a card background (e.g. "Register" in the login header).
struct PillButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Palette.brandText)
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(Palette.card, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Apple logo + title label used by `AppleSignInButton`.
struct AppleLabel: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "applelogo")
            Text(title)
        }
    }
}
