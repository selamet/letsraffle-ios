import SwiftUI

enum AppearancePreference: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    func title(_ t: Strings) -> String {
        switch self {
        case .system: t.appearanceSystem
        case .light: t.appearanceLight
        case .dark: t.appearanceDark
        }
    }
}

/// User preferences persisted in `UserDefaults`.
@Observable
final class AppSettings {
    private let defaults: UserDefaults

    var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: Keys.language) }
    }

    var appearance: AppearancePreference {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    /// User-level switch for push notifications (registration happens in #10).
    var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notifications) }
    }

    var strings: Strings { language.strings }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        language = defaults.string(forKey: Keys.language).flatMap(AppLanguage.init) ?? .deviceDefault
        appearance = defaults.string(forKey: Keys.appearance).flatMap(AppearancePreference.init) ?? .system
        notificationsEnabled = defaults.object(forKey: Keys.notifications) as? Bool ?? true
    }

    private enum Keys {
        static let language = "settings.language"
        static let appearance = "settings.appearance"
        static let notifications = "settings.notifications"
    }
}
