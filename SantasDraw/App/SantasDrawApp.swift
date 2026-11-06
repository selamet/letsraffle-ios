import SwiftUI

@main
struct SantasDrawApp: App {
    @State private var settings = AppSettings()
    @State private var session = SessionStore(api: APIClient(tokenStore: KeychainTokenStore()))
    @State private var participations = ParticipationStore()
    @State private var router = DeepLinkRouter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(session)
                .environment(participations)
                .environment(router)
                .onOpenURL { router.handle($0) }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    if let url = activity.webpageURL { router.handle(url) }
                }
                .environment(\.strings, settings.strings)
                .environment(\.locale, settings.language.locale)
                .preferredColorScheme(settings.appearance.colorScheme)
                .tint(Palette.brand)
        }
    }
}
