import Foundation
import Observation

/// Owns the authentication state of the app.
@MainActor
@Observable
final class SessionStore {
    enum State: Equatable {
        /// Restoring a persisted session on launch.
        case restoring
        /// No account; onboarding is shown.
        case signedOut
        /// Using the app without an account (manual draw + join only).
        case guest
        case signedIn(User)
    }

    private(set) var state: State = .restoring
    private(set) var expiredMessageVisible = false

    let api: APIClient
    private let defaults: UserDefaults

    init(api: APIClient, defaults: UserDefaults = .standard) {
        self.api = api
        self.defaults = defaults
    }

    var user: User? {
        if case let .signedIn(user) = state { return user }
        return nil
    }

    var isSignedIn: Bool { user != nil }

    /// Restores the session on launch. Refreshing doubles as token validation and
    /// returns the current user; when offline the cached user is used instead.
    func restore() async {
        await api.setSessionExpiredHandler { [weak self] in
            Task { @MainActor in self?.handleExpiredSession() }
        }

        guard await api.isAuthenticated else {
            state = defaults.bool(forKey: Keys.guest) ? .guest : .signedOut
            return
        }

        if let cached = cachedUser {
            state = .signedIn(cached)
        }

        do {
            try await refreshUser()
        } catch APIError.network {
            if cachedUser == nil { state = .signedOut }
        } catch {
            await signOut()
        }
    }

    func login(email: String, password: String) async throws {
        let response = try await api.send(API.login(email: normalized(email), password: password))
        await complete(response)
    }

    func register(email: String, password: String) async throws {
        let response = try await api.send(API.register(email: normalized(email), password: password))
        await complete(response)
    }

    func requestPasswordReset(email: String, language: AppLanguage) async throws {
        _ = try await api.send(API.forgotPassword(email: normalized(email), language: language))
    }

    func continueAsGuest() {
        defaults.set(true, forKey: Keys.guest)
        state = .guest
    }

    /// Leaves guest mode and shows onboarding again.
    func exitGuestMode() {
        defaults.set(false, forKey: Keys.guest)
        state = .signedOut
    }

    func signOut() async {
        await api.storeTokens(nil)
        cachedUser = nil
        defaults.set(false, forKey: Keys.guest)
        state = .signedOut
    }

    /// Permanently deletes the account (App Store guideline 5.1.1(v)).
    func deleteAccount() async throws {
        _ = try await api.send(API.deleteAccount())
        await signOut()
    }

    func dismissExpiredMessage() {
        expiredMessageVisible = false
    }

    // MARK: - Private

    private func refreshUser() async throws {
        guard let refresh = await api.refreshToken else { return }
        let response = try await api.send(API.refresh(token: refresh))
        await complete(response)
    }

    private func complete(_ response: AuthResponse) async {
        await api.storeTokens(response.tokens)
        cachedUser = response.user
        defaults.set(false, forKey: Keys.guest)
        state = .signedIn(response.user)
    }

    private func handleExpiredSession() {
        guard isSignedIn else { return }
        cachedUser = nil
        state = .signedOut
        expiredMessageVisible = true
    }

    private func normalized(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var cachedUser: User? {
        get {
            defaults.data(forKey: Keys.user).flatMap { try? JSONCoding.decoder.decode(User.self, from: $0) }
        }
        set {
            defaults.set(newValue.flatMap { try? JSONCoding.encoder.encode($0) }, forKey: Keys.user)
        }
    }

    private enum Keys {
        static let user = "session.user"
        static let guest = "session.guest"
    }
}
