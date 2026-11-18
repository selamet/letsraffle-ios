import Foundation
import UserNotifications

/// Kind New Year wishes as local notifications, every evening from November until New Year's Eve.
/// They are words of hope and encouragement, not advertising for the app.
///
/// Scheduled on the device (no server involved) with the festive `jingle.caf` sound. The dates are
/// tied to the calendar, not to when the app was last opened, so rescheduling on every launch never
/// changes when they fire. Users turn them off in Profile.
enum SeasonCountdown {
    static let identifierPrefix = "countdown-"
    static let soundName = "jingle.caf"
    /// Evening, when people are off work.
    static let hour = 19, minute = 30

    struct Item: Equatable {
        let date: Date
        /// Days from that evening until 1 January.
        let daysLeft: Int
        /// The last one, on 31 December.
        let isNewYearsEve: Bool
    }

    /// iOS keeps at most 64 pending local notifications per app; leave room for the gift reminders.
    static let maxPending = 45

    /// Every evening from 1 November until 30 December at 19:30, plus 31 December at 20:00.
    /// Only moments still ahead of `now` are returned, at most `maxPending` evenings plus New Year's Eve
    /// (the rest are added when the app is opened again).
    static func schedule(now: Date = .now, calendar: Calendar = .current) -> [Item] {
        let year = calendar.component(.year, from: now)
        guard calendar.component(.month, from: now) >= 11,
              let seasonStart = calendar.date(from: DateComponents(year: year, month: 11, day: 1)),
              let newYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)),
              let eve = calendar.date(from: DateComponents(year: year, month: 12, day: 31, hour: 20)) else { return [] }

        var items: [Item] = []
        var day = seasonStart
        while let next = calendar.date(byAdding: .day, value: 1, to: day), day < eve {
            if let fire = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day),
               fire > now, calendar.component(.day, from: day) != 31 {
                let left = calendar.dateComponents([.day], from: calendar.startOfDay(for: day), to: newYear).day ?? 0
                items.append(Item(date: fire, daysLeft: left, isNewYearsEve: false))
            }
            day = next
        }
        items = Array(items.prefix(maxPending))
        if eve > now { items.append(Item(date: eve, daysLeft: 1, isNewYearsEve: true)) }
        return items
    }

    /// Title and body for one evening. The text rotates so two evenings in a row never repeat.
    static func message(for item: Item, index: Int, t: Strings) -> (title: String, body: String) {
        if item.isNewYearsEve { return (t.countdownEveTitle, t.countdownEveBody) }
        let pool = item.daysLeft <= 6 ? t.countdownFinal : t.countdownMessages
        let pick = pool[index % pool.count]
        let days = String(item.daysLeft)
        return (pick.title.replacingOccurrences(of: "{d}", with: days),
                pick.body.replacingOccurrences(of: "{d}", with: days))
    }

    /// Replaces the pending countdown with a fresh one in the current language, or just clears it.
    /// Never asks for permission.
    static func reschedule(enabled: Bool, t: Strings, now: Date = .now) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(identifierPrefix) })

        guard enabled else { return }
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }

        let calendar = Calendar.current
        for (index, item) in schedule(now: now, calendar: calendar).enumerated() {
            let text = message(for: item, index: index, t: t)
            let content = UNMutableNotificationContent()
            content.title = text.title
            content.body = text.body
            content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName))
            content.userInfo = ["type": "countdown"]
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: item.date),
                repeats: false
            )
            let id = identifierPrefix + ISO8601DateFormatter().string(from: item.date)
            try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }
}
