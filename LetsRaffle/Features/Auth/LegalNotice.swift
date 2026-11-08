import SwiftUI

/// "By continuing you agree to the Terms of Use and Privacy Policy" with tappable links,
/// shown wherever an account can be created (App Store guideline 5.1.1).
struct LegalNotice: View {
    var onDark = false
    @Environment(\.strings) private var t

    var body: some View {
        Text(markdown)
            .font(AppFont.body(12, .semibold))
            .foregroundStyle(onDark ? Color.white.opacity(0.75) : Palette.sub)
            .tint(onDark ? .white : Palette.brandText)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("auth.legal")
    }

    private var markdown: AttributedString {
        let parts = [
            t.legalPrefix,
            "[\(t.termsOfUse)](\(AppConfig.termsURL.absoluteString))",
            t.legalAnd,
            "[\(t.privacyPolicy)](\(AppConfig.privacyURL.absoluteString))",
            t.legalSuffix,
        ].filter { !$0.isEmpty }
        let source = parts.joined(separator: " ") + (t.legalSuffix.isEmpty ? "." : "")
        return (try? AttributedString(markdown: source)) ?? AttributedString(source)
    }
}
