import Foundation
import UserNotifications

/// A local "have you bought the gift yet?" nudge a few days before New Year's Eve.
///
/// Scheduled on the device once the match has been revealed, so it needs no server. The receiver's
/// name is deliberately left out: a lock screen must never spoil the surprise.
enum GiftReminder {
    static func identifier(for inviteCode: String) -> String { "gift-reminder-\(inviteCode)" }

    /// 28 December, 10:00 local time. `nil` outside the season (before October) or once that moment has passed.
    static func fireDate(now: Date = .now, calendar: Calendar = .current) -> Date? {
        guard calendar.component(.month, from: now) >= 10 else { return nil }
        var components = DateComponents()
        components.year = calendar.component(.year, from: now)
        components.month = 12
        components.day = 28
        components.hour = 10
        guard let date = calendar.date(from: components), date > now else { return nil }
        return date
    }

    static func content(inviteCode: String, t: Strings) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = t.giftReminderTitle
        content.body = t.giftReminderBody
        content.sound = .default
        content.userInfo = ["type": PushKind.giftReminder.rawValue, "inviteCode": inviteCode]
        return content
    }

    /// Schedules (or replaces) the reminder for a draw. Does nothing without notification permission;
    /// it never asks for it.
    static func schedule(inviteCode: String, t: Strings, now: Date = .now, calendar: Calendar = .current) async {
        guard let date = fireDate(now: now, calendar: calendar) else { return }
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: identifier(for: inviteCode),
            content: content(inviteCode: inviteCode, t: t),
            trigger: trigger
        )
        try? await center.add(request)
    }

    static func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix("gift-reminder-") }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
}
