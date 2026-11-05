import SwiftUI
import UIKit

/// Design tokens mirrored from the Claude Design file (`iOS Uygulama.dc.html`).
/// Every token resolves dynamically for light and dark appearance.
enum Palette {
    static let page = Color(light: 0xF2F2F7, dark: 0x000000)
    static let card = Color(light: 0xFFFFFF, dark: 0x1C1C1E)
    static let card2 = Color(light: 0xFEF2F2, dark: 0x2A1416)
    static let text = Color(light: 0x1D293D, dark: 0xFFFFFF)
    static let sub = Color(light: (0x3C3C43, 0.6), dark: (0xEBEBF5, 0.6))
    static let ter = Color(light: (0x3C3C43, 0.3), dark: (0xEBEBF5, 0.3))
    static let sep = Color(light: (0x3C3C43, 0.12), dark: (0x545458, 0.65))
    static let field = Color(light: 0xFFFFFF, dark: 0x2C2C2E)
    static let fieldBorder = Color(light: 0xE5E7EB, dark: 0x3A3A3C)
    static let brand = Color(light: 0xE7000B, dark: 0xFF453A)
    static let brandText = Color(light: 0xC10007, dark: 0xFF6B66)
    static let chip = Color(light: 0xFFE2E2, dark: 0x4A1A1C)
    static let heroA = Color(light: 0xE7000B, dark: 0x9F0712)
    static let heroB = Color(light: 0xC10007, dark: 0x6B0509)
    static let heroC = Color(light: 0x9F0712, dark: 0x2B0204)
    static let tabBar = Color(light: (0xFFFFFF, 0.78), dark: (0x2C2C2E, 0.82))
    static let green = Color(light: 0x00A63E, dark: 0x30D158)
    static let greenSoft = Color(light: 0xDCFCE7, dark: 0x0F3D1F)
    static let greenText = Color(light: 0x008236, dark: 0x7BE0A0)
    static let amber = Color(light: 0xFE9A00, dark: 0xFF9F0A)
    static let amberSoft = Color(light: 0xFFFBEB, dark: 0x3A2A0A)
    static let amberText = Color(light: 0xB45309, dark: 0xFFD60A)
    static let blueSoft = Color(light: 0xEEF2FF, dark: 0x1D1F3A)
    static let blueText = Color(light: 0x432DD7, dark: 0xA5B4FC)

    /// Hero gradient used on onboarding and the home header.
    static let heroGradient = LinearGradient(
        stops: [
            .init(color: heroA, location: 0),
            .init(color: heroB, location: 0.55),
            .init(color: heroC, location: 1),
        ],
        startPoint: UnitPoint(x: 0.25, y: 0),
        endPoint: UnitPoint(x: 0.75, y: 1)
    )
}

enum Radius {
    static let field: CGFloat = 12
    static let button: CGFloat = 14
    static let card: CGFloat = 20
}

extension Font {
    static let largeTitleBold = Font.system(size: 34, weight: .bold)
    static let eyebrow = Font.system(size: 12, weight: .semibold)
    static let fieldLabel = Font.system(size: 13, weight: .medium)
    static let buttonLabel = Font.system(size: 17, weight: .semibold)
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
    /// Soft brand-tinted shadow (`--shadow` token).
    func brandShadow() -> some View {
        modifier(BrandShadow())
    }
}

private struct BrandShadow: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content.shadow(
            color: scheme == .dark ? .black.opacity(0.5) : Color(hex: 0x7F1D1D, alpha: 0.12),
            radius: 15, x: 0, y: 10
        )
    }
}
