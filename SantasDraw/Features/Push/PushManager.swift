import Foundation
import Observation
import UIKit
import UserNotifications

/// Push payload `type` values sent by letsraffle-api.
enum PushKind: String {
    case matchRevealed = "match_revealed"
    case participantJoined = "participant_joined"
    case drawReminder = "draw_reminder"
}

/// Owns notification permission, APNs registration and backend device sync.
@MainActor
@Observable
final class PushManager {
    private(set) var authorization: UNAuthorizationStatus = .notDetermined
    /// Presents the pre-permission screen.
    var isPromptPresented = false

    private let defaults: UserDefaults
    private var deviceToken: String?
    private weak var session: SessionStore?
    private weak var participations: ParticipationStore?
    private weak var settings: AppSettings?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func attach(session: SessionStore, participations: ParticipationStore, settings: AppSettings) {
        self.session = session
        self.participations = participations
        self.settings = settings
    }

    // MARK: Permission

    func refreshAuthorization() async {
        authorization = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        if authorization == .authorized || authorization == .provisional, settings?.notificationsEnabled == true {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    /// Shows our pre-permission screen once, at a meaningful moment (after creating or joining a draw).
    func promptIfAppropriate() {
        guard authorization == .notDetermined, !defaults.bool(forKey: Keys.promptDismissed),
              settings?.notificationsEnabled == true else { return }
        isPromptPresented = true
    }

    func allow() async {
        isPromptPresented = false
        defaults.set(true, forKey: Keys.promptDismissed)
        let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        await refreshAuthorization()
        if granted { UIApplication.shared.registerForRemoteNotifications() }
    }

    func later() {
        isPromptPresented = false
        defaults.set(true, forKey: Keys.promptDismissed)
    }

    /// Reacts to the Profile switch.
    func setEnabled(_ enabled: Bool) async {
        if enabled {
            if authorization == .notDetermined {
                await allow()
            } else {
                await refreshAuthorization()
            }
        } else {
            await unregister()
        }
    }

    // MARK: Registration

    func didRegister(deviceToken data: Data) {
        deviceToken = data.map { String(format: "%02x", $0) }.joined()
        Task { await sync() }
    }

    /// Sends the token + participant tokens to the backend. Called after login/logout and joins too.
    func sync() async {
        guard let deviceToken, let session, settings?.notificationsEnabled == true else { return }
        let tokens = participations?.items.filter(\.wantsNotification).compactMap(\.participantToken) ?? []
        let request = DeviceRegistration(
            token: deviceToken,
            language: settings?.language.rawValue ?? AppLanguage.tr.rawValue,
            participantTokens: tokens
        )
        _ = try? await session.api.send(API.registerDevice(request))
    }

    func unregister() async {
        guard let deviceToken, let session else { return }
        _ = try? await session.api.send(API.unregisterDevice(token: deviceToken))
    }

    // MARK: Routing

    /// Maps a notification payload to an in-app destination.
    static func destination(for userInfo: [AnyHashable: Any]) -> PushDestination? {
        guard let raw = userInfo["type"] as? String, let kind = PushKind(rawValue: raw),
              let code = userInfo["inviteCode"] as? String else { return nil }
        switch kind {
        case .matchRevealed: return .reveal(inviteCode: code)
        case .participantJoined, .drawReminder: return .drawDetail(inviteCode: code)
        }
    }

    private enum Keys {
        static let promptDismissed = "push.promptDismissed"
    }
}

enum PushDestination: Equatable {
    case reveal(inviteCode: String)
    case drawDetail(inviteCode: String)
}

struct DeviceRegistration: Encodable {
    let token: String
    var platform = "ios"
    let language: String
    let participantTokens: [String]
}

struct DeviceRegistrationResponse: Decodable, Equatable {
    let userLinked: Bool
    let participantCount: Int
}

/// Bridges UIKit push callbacks into SwiftUI.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var onDeviceToken: ((Data) -> Void)?
    var onOpen: ((PushDestination) -> Void)?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        onDeviceToken?(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Simulator / missing entitlement; nothing to do.
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        if let destination = PushManager.destination(for: response.notification.request.content.userInfo) {
            await MainActor.run { onOpen?(destination) }
        }
    }
}
