import SwiftUI

/// Temporary root that showcases the design system until the auth flow (#3) lands.
struct RootView: View {
    @Environment(\.strings) private var t
    @Environment(AppSettings.self) private var settings
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        @Bindable var settings = settings
        ScrollView {
            VStack(spacing: 20) {
                SantaAvatar(size: 120)
                ScreenHeader(eyebrow: t.brandEyebrow, title: t.loginTitle, subtitle: t.loginSub)
                FormField(label: t.email, text: $email, placeholder: t.emailPh, kind: .email)
                FormField(label: t.password, text: $password, placeholder: t.passwordPh, kind: .password, hint: t.passwordRule)
                Button(t.loginBtn) {}.buttonStyle(.primary)
                OrDivider(title: t.or)
                Button {} label: { AppleLabel(title: t.apple) }.buttonStyle(.inverted)
                HStack {
                    StatusChip(title: t.statusActive, foreground: Palette.greenText, background: Palette.greenSoft)
                    StatusChip(title: t.statusInProgress, foreground: Palette.amberText, background: Palette.amberSoft)
                    StatusChip(title: t.statusCompleted, foreground: Palette.blueText, background: Palette.blueSoft)
                }
                Picker(t.language, selection: $settings.language) {
                    ForEach(AppLanguage.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                Picker(t.appearance, selection: $settings.appearance) {
                    ForEach(AppearancePreference.allCases) { Text($0.title(t)).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            .padding(20)
        }
        .background(Palette.page)
    }
}

#Preview {
    RootView().environment(AppSettings())
}
