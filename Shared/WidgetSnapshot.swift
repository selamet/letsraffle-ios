import Foundation

/// Data the app shares with its widgets through the App Group.
///
/// Compiled into both the app and the widget extension.
struct WidgetSnapshot: Codable, Equatable {
    struct NextDraw: Codable, Equatable {
        let inviteCode: String
        let date: Date
    }

    /// Only initials are shared; the widget never shows the full match.
    struct Match: Codable, Equatable {
        let inviteCode: String
        let initials: String
    }

    struct Draw: Codable, Equatable, Identifiable {
        var id: String { name }
        let name: String
        let isInvite: Bool
        let participantCount: Int
        /// Backend status raw value (`active`, `in_progress`, `completed`, `cancelled`).
        let status: String
    }

    var language: String = "TR"
    var nextDraw: NextDraw?
    var match: Match?
    var activeDraws: [Draw] = []

    static let appGroup = "group.com.letsraffle.ios"
    private static let key = "widget.snapshot"

    static func load(from defaults: UserDefaults? = UserDefaults(suiteName: appGroup)) -> WidgetSnapshot {
        guard let data = defaults?.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else { return WidgetSnapshot() }
        return snapshot
    }

    func save(to defaults: UserDefaults? = UserDefaults(suiteName: appGroup)) {
        if let data = try? JSONEncoder().encode(self) {
            defaults?.set(data, forKey: Self.key)
        }
    }

    /// Whole days until the draw (0 on the day itself).
    static func daysLeft(until date: Date, from now: Date = .now, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: now)
        let end = calendar.startOfDay(for: date)
        return max(0, calendar.dateComponents([.day], from: start, to: end).day ?? 0)
    }
}

/// Deep links used by widgets.
enum WidgetLink {
    static func reveal(_ code: String) -> URL { URL(string: "letsraffle://reveal/\(code)")! }
    static func draw(_ code: String) -> URL { URL(string: "letsraffle://draw/\(code)")! }
    static let home = URL(string: "letsraffle://home")!
}

/// Minimal TR/EN copy for widgets (the app's `Strings` is not linked into the extension).
struct WidgetStrings {
    let nextDraw: String
    let daysLeft: String
    let today: String
    let match: String
    let tapToReveal: String
    let activeDraws: String
    let noDraws: String
    let invite: String
    let manual: String
    let statuses: [String: String]

    static func forLanguage(_ code: String) -> WidgetStrings {
        code == "EN"
            ? WidgetStrings(nextDraw: "Next draw", daysLeft: "days left", today: "Today!", match: "Your match",
                            tapToReveal: "Tap to reveal", activeDraws: "My Active Draws", noDraws: "No draws yet",
                            invite: "Invite Link", manual: "Manual",
                            statuses: ["active": "Active", "in_progress": "In Progress", "completed": "Completed", "cancelled": "Cancelled"])
            : WidgetStrings(nextDraw: "Sonraki çekiliş", daysLeft: "gün kaldı", today: "Bugün!", match: "Eşleşmen",
                            tapToReveal: "Göstermek için dokun", activeDraws: "Aktif Etkinliklerim", noDraws: "Henüz çekiliş yok",
                            invite: "Davet Linki", manual: "Manuel",
                            statuses: ["active": "Aktif", "in_progress": "Devam Ediyor", "completed": "Tamamlandı", "cancelled": "İptal"])
    }
}
