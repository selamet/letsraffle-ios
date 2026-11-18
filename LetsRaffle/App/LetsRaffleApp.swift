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
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .scrollIndicators(.hidden)
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
                .onChange(of: session.state, initial: true) { _, state in
                    // Each account only sees the draws it joined on this device; wait for the
                    // stored session to be restored before deciding whose draws to show.
                    if state != .restoring { participations.setOwner(session.user?.id) }
                    Task { await push.sync() }
                }
                .onChange(of: settings.notificationsEnabled) { _, enabled in Task { await push.setEnabled(enabled) } }
                .onChange(of: settings.language, initial: true) { _, language in
                    WidgetSync.shared.update(language: language)
                    Task { await push.sync() }
                }
                // The New Year countdown follows the switches, the language and the permission.
                .task(id: countdownKey) {
                    await SeasonCountdown.reschedule(enabled: settings.notificationsEnabled && settings.countdownEnabled, t: settings.strings)
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

    private var countdownKey: String {
        "\(settings.notificationsEnabled)-\(settings.countdownEnabled)-\(settings.language.rawValue)-\(push.authorization.rawValue)-\(scenePhase == .active)"
    }

    @MainActor
    private func setUpPush() async {
        push.attach(session: session, participations: participations, settings: settings)
        appDelegate.onDeviceToken = { [push] token in push.didRegister(deviceToken: token) }
        appDelegate.onOpen = { [router] destination in router.pendingDestination = destination }
        await push.refreshAuthorization()
    }
}
