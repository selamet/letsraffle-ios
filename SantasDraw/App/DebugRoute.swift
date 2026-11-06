import Foundation

/// DEBUG-only deep entry used for visual QA: launch with `-route <name>`.
enum DebugRoute {
    static var current: String? {
        #if DEBUG
        UserDefaults.standard.string(forKey: "route")
        #else
        nil
        #endif
    }
}

#if DEBUG
extension SessionStore {
    /// Signs in with `-debugEmail` / `-debugPassword` launch arguments (visual QA only).
    func debugAutoLogin() async {
        let args = UserDefaults.standard
        guard let email = args.string(forKey: "debugEmail"), let password = args.string(forKey: "debugPassword") else { return }
        try? await login(email: email, password: password)
    }
}
#endif
