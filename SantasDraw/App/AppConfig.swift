import Foundation

/// Build-time configuration injected from `Config/*.xcconfig` via Info.plist.
enum AppConfig {
    static let apiBaseURL: URL = url(forKey: "API_BASE_URL", fallback: "http://localhost:8000/api/v1")
    static let webBaseURL: URL = url(forKey: "WEB_BASE_URL", fallback: "https://letsraffle.com")

    /// Public invite link that opens the join form (web route `/draw/join/:inviteCode`).
    static func inviteURL(for code: String) -> URL {
        webBaseURL.appending(path: "draw/join/\(code)")
    }

    private static func url(forKey key: String, fallback: String) -> URL {
        let raw = (Bundle.main.object(forInfoDictionaryKey: key) as? String) ?? fallback
        return URL(string: raw) ?? URL(string: fallback)!
    }
}
