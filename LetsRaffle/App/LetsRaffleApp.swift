import GoogleSignIn
import SwiftUI

@main
struct LetsRaffleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var settings = AppSettings()
    @State private var session = SessionStore(api: APIClient(tokenStore: KeychainTokenStore()))
    @State private var participations = ParticipationStore()
    @State private var router = DeepLinkRouter()
    @State private var push = PushManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(session)
                .environment(participations)
                .environment(router)
                .environment(push)
                .onOpenURL { url in
                    // Google's OAuth redirect comes back through the reversed client ID scheme.
                    if GIDSignIn.sharedInstance.handle(url) { return }
                    router.handle(url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    if let url = activity.webpageURL { router.handle(url) }
                }
                .environment(\.strings, settings.strings)
                .environment(\.locale, settings.language.locale)
                .preferredColorScheme(settings.appearance.colorScheme)
                .tint(Palette.brand)
                .task { await setUpPush() }
                .onChange(of: session.state) { _, _ in Task { await push.sync() } }
                .onChange(of: settings.notificationsEnabled) { _, enabled in Task { await push.setEnabled(enabled) } }
                .onChange(of: settings.language, initial: true) { _, language in
                    WidgetSync.shared.update(language: language)
                    Task { await push.sync() }
                }
                .onChange(of: session.isSignedIn) { _, signedIn in
                    if !signedIn { WidgetSync.shared.update(draws: []) }
                }
                .fullScreenCover(isPresented: $push.isPromptPresented) {
                    PushPromptView(push: push)
                        .environment(\.strings, settings.strings)
                }
        }
    }

    @MainActor
    private func setUpPush() async {
        push.attach(session: session, participations: participations, settings: settings)
        appDelegate.onDeviceToken = { [push] token in push.didRegister(deviceToken: token) }
        appDelegate.onOpen = { [router] destination in router.pendingDestination = destination }
        await push.refreshAuthorization()
    }
}
