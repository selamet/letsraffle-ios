import SwiftUI

/// Eyebrow + large title + subtitle block used at the top of most screens.
struct ScreenHeader: View {
    var eyebrow: String?
    let title: String
    var subtitle: String?
    var titleSize: CGFloat = 34

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let eyebrow {
                Text(eyebrow)
                    .font(.eyebrow)
                    .tracking(3)
                    .textCase(.uppercase)
                    .foregroundStyle(Palette.brandText)
            }
            Text(title)
                .font(.system(size: titleSize, weight: .bold))
                .foregroundStyle(Palette.text)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.sub)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Rounded inset-grouped card container.
struct CardSection<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .background(Palette.card, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
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
                .frame(width: 32, height: 32)
                .background(iconBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 17)).foregroundStyle(Palette.text)
                if let subtitle {
                    Text(subtitle).font(.system(size: 13)).foregroundStyle(Palette.sub)
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
                Rectangle().fill(Palette.sep).frame(height: 0.5).padding(.leading, 60)
            }
        }
    }
}

/// Small uppercase status capsule ("ACTIVE", "COMPLETED"...).
struct StatusChip: View {
    let title: String
    let foreground: Color
    let background: Color

    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .bold))
            .tracking(0.6)
            .textCase(.uppercase)
            .foregroundStyle(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
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
        .font(.system(size: 14))
        .foregroundStyle(foreground)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
        case .info, .error: Palette.card2
        case .success: Palette.greenSoft
        }
    }
}

/// Decorative white "snow" dots used over hero gradients.
struct SnowDots: View {
    struct Dot { let x: CGFloat; let y: CGFloat; let size: CGFloat; let opacity: Double }

    var dots: [Dot] = [
        Dot(x: 0.07, y: 0.14, size: 6, opacity: 0.8),
        Dot(x: 0.88, y: 0.23, size: 4, opacity: 0.6),
        Dot(x: 0.15, y: 0.34, size: 5, opacity: 0.5),
        Dot(x: 0.70, y: 0.10, size: 5, opacity: 0.7),
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(dots.indices, id: \.self) { i in
                let d = dots[i]
                Circle()
                    .fill(.white.opacity(d.opacity))
                    .frame(width: d.size, height: d.size)
                    .position(x: geo.size.width * d.x, y: geo.size.height * d.y)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
