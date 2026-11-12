import SwiftUI
import UIKit

/// Design tokens mirrored from the "Lets Raffle iOS" design file
/// (cranberry / gold / pine on snow). Every token resolves dynamically for
/// light and dark appearance.
enum Palette {
    // Surfaces
    static let page = Color(light: 0xFFFBF5, dark: 0x170809)
    static let card = Color(light: 0xFFFFFF, dark: 0x2A1416)
    static let card2 = Color(light: 0xFFF7EC, dark: 0x351A1C)
    static let field = Color(light: 0xFFFFFF, dark: 0x2C1A1B)
    static let fieldBorder = Color(light: 0xECDCC9, dark: 0x5A3A3C)
    static let cardBorder = Color(light: 0xF0DFCB, dark: 0x4A2A2C)
    static let sep = Color(light: 0xF3E6D6, dark: 0x4A2A2C)

    // Text
    static let text = Color(light: 0x3A2626, dark: 0xFFF4EA)
    static let sub = Color(light: 0x6B5050, dark: 0xD9C2B8)
    static let ter = Color(light: 0x8A7066, dark: 0xA08880)

    // Brand
    static let brand = Color(light: 0xB91C1C, dark: 0xE5484D)
    static let brandText = Color(light: 0x9B1418, dark: 0xFF8A8A)
    static let brandEdge = Color(light: 0x7A0F14, dark: 0x5A0A0F)
    static let chip = Color(light: 0xFBE3E1, dark: 0x4A1A1C)
    static let card2Brand = Color(light: 0x8C1A1F, dark: 0x6E0D12)

    // Christmas accents (same in both appearances)
    static let cranberry = Color(hex: 0xA3171C)
    static let cranberryDark = Color(hex: 0x7A0F14)
    static let gold = Color(hex: 0xE6B94A)
    static let goldLight = Color(hex: 0xF6D98A)
    static let goldDark = Color(hex: 0xB08A2E)
    static let goldText = Color(hex: 0x5A0A0F)
    static let pine = Color(hex: 0x1F5C3E)
    static let pineEdge = Color(hex: 0x123826)
    static let snow = Color(hex: 0xFFFBF5)

    // Hero (red scene) gradient
    static let heroA = Color(light: 0xC4242A, dark: 0x9F1A1F)
    static let heroB = Color(light: 0xA3171C, dark: 0x7A0F14)
    static let heroC = Color(light: 0x6E0D12, dark: 0x3D0609)
    static let tabBar = Color(light: (0xFFFBF5, 1), dark: (0x2A1416, 1))

    // Status
    static let green = Color(light: 0x2F8A5A, dark: 0x30D158)
    static let greenSoft = Color(light: 0xE3F0E8, dark: 0x0F3D1F)
    static let greenText = Color(light: 0x1F5C3E, dark: 0x7BE0A0)
    static let amber = Color(light: 0xE6B94A, dark: 0xFFC94A)
    static let amberSoft = Color(light: 0xFDF0D2, dark: 0x3A2A0A)
    static let amberText = Color(light: 0x7A5410, dark: 0xFFD60A)
    static let blueSoft = Color(light: 0xEEF2FF, dark: 0x1D1F3A)
    static let blueText = Color(light: 0x432DD7, dark: 0xA5B4FC)

    /// Hero gradient used on the red "scene" screens and headers.
    static let heroGradient = LinearGradient(
        stops: [
            .init(color: heroA, location: 0),
            .init(color: heroB, location: 0.55),
            .init(color: heroC, location: 1),
        ],
        startPoint: UnitPoint(x: 0.3, y: 0),
        endPoint: UnitPoint(x: 0.7, y: 1)
    )

    static let goldGradient = LinearGradient(colors: [Color(hex: 0xF8E09A), gold], startPoint: .top, endPoint: .bottom)
}

enum Radius {
    static let field: CGFloat = 16
    static let button: CGFloat = 18
    static let card: CGFloat = 22
}

/// Bundled typefaces (Resources/Fonts, registered with UIAppFonts).
enum AppFont {
    static func display(_ size: CGFloat, black: Bool = true) -> Font {
        .custom(black ? "Fraunces-Black" : "Fraunces-Bold", size: size, relativeTo: .title)
    }

    static func script(_ size: CGFloat) -> Font {
        .custom("GreatVibes-Regular", size: size, relativeTo: .largeTitle)
    }

    static func body(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        let name: String
        switch weight {
        case .black, .heavy: name = "Nunito-Black"
        case .bold: name = "Nunito-ExtraBold"
        case .semibold: name = "Nunito-Bold"
        case .medium: name = "Nunito-SemiBold"
        default: name = "Nunito-Medium"
        }
        return .custom(name, size: size, relativeTo: .body)
    }
}

extension Font {
    static let largeTitleBold = AppFont.display(32)
    static let eyebrow = AppFont.body(12, .black)
    static let fieldLabel = AppFont.body(14, .bold)
    static let buttonLabel = AppFont.body(17, .bold)
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    init(light: UInt32, dark: UInt32) {
        self.init(light: (light, 1), dark: (dark, 1))
    }

    init(light: (UInt32, CGFloat), dark: (UInt32, CGFloat)) {
        self.init(uiColor: UIColor { traits in
            let (hex, alpha) = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(hex: hex, alpha: alpha)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

extension View {
    /// Soft cranberry-tinted shadow.
    func brandShadow() -> some View {
        modifier(BrandShadow())
    }

    /// Cream card with the double gold foil border used across the design.
    func foilCard(radius: CGFloat = Radius.card) -> some View {
        modifier(FoilCard(radius: radius))
    }
}

private struct BrandShadow: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content.shadow(
            color: scheme == .dark ? .black.opacity(0.5) : Color(hex: 0x6E0D12, alpha: 0.16),
            radius: 16, x: 0, y: 10
        )
    }
}

private struct FoilCard: ViewModifier {
    let radius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .background(Palette.page, in: shape)
            .overlay(shape.strokeBorder(Palette.gold, lineWidth: 2))
            .overlay(
                RoundedRectangle(cornerRadius: max(radius - 7, 4), style: .continuous)
                    .strokeBorder(Palette.gold.opacity(0.55), lineWidth: 1)
                    .padding(7)
            )
            .brandShadow()
    }
}
