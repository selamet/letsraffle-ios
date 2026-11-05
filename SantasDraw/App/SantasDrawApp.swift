import SwiftUI

@main
struct SantasDrawApp: App {
    @State private var settings = AppSettings()
    @State private var session = SessionStore(api: APIClient(tokenStore: KeychainTokenStore()))

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(session)
                .environment(\.strings, settings.strings)
                .environment(\.locale, settings.language.locale)
                .preferredColorScheme(settings.appearance.colorScheme)
                .tint(Palette.brand)
        }
    }
}
