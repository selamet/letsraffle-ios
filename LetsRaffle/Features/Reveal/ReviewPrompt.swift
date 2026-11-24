import Foundation

/// When to ask for an App Store rating: right after someone sees their match (the happiest
/// moment in the app), at most once per app version. The system still decides whether the
/// prompt actually shows and caps it at three times a year.
struct ReviewPrompt {
    static let defaultsKey = "review.lastPromptedVersion"

    var defaults: UserDefaults = .standard
    var version: String = AppConfig.shortVersion

    var shouldAsk: Bool { defaults.string(forKey: Self.defaultsKey) != version }

    func markAsked() { defaults.set(version, forKey: Self.defaultsKey) }
}
