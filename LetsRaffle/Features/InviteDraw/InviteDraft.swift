import Foundation
import Observation

/// State shared by the two invite-draw creation steps.
@MainActor
@Observable
final class InviteDraft {
    var requireAddress = false
    var requirePhone = false
    /// Off by default: the organizer starts the draw by hand unless they pick a date.
    var scheduleEnabled = false
    /// Always normalized to an exact hour in the future (backend requirement).
    var drawDate: Date

    var firstName = ""
    var lastName = ""
    var email = ""
    var address = ""
    var phone = ""

    init(now: Date = .now, calendar: Calendar = .current, email: String = "") {
        drawDate = Self.defaultDrawDate(now: now, calendar: calendar)
        self.email = email
    }

    /// Christmas Eve 20:00 if it is still ahead, otherwise tomorrow 20:00.
    static func defaultDrawDate(now: Date, calendar: Calendar) -> Date {
        let year = calendar.component(.year, from: now)
        if let eve = calendar.date(from: DateComponents(year: year, month: 12, day: 24, hour: 20)), eve > now {
            return eve
        }
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        return calendar.date(bySettingHour: 20, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }

    /// Rounds a picked date down to the hour.
    static func exactHour(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.dateInterval(of: .hour, for: date)?.start ?? date
    }

    func validationErrors(_ t: Strings) -> [Field: String] {
        var errors: [Field: String] = [:]
        if let e = Validation.requiredError(firstName, t) { errors[.firstName] = e }
        if let e = Validation.requiredError(lastName, t) { errors[.lastName] = e }
        if let e = Validation.emailError(email, t) { errors[.email] = e }
        if requireAddress, let e = Validation.requiredError(address, t) { errors[.address] = e }
        if requirePhone, let e = Validation.requiredError(phone, t) { errors[.phone] = e }
        return errors
    }

    func makeRequest(language: AppLanguage) -> DynamicDrawRequest {
        DynamicDrawRequest(
            addressRequired: requireAddress,
            phoneNumberRequired: requirePhone,
            language: language.rawValue,
            drawDate: scheduleEnabled ? Self.exactHour(drawDate) : nil,
            participants: [
                ParticipantInput(
                    firstName: firstName.trimmed,
                    lastName: lastName.trimmed,
                    email: email.trimmed.lowercased(),
                    address: requireAddress ? address.trimmed : nil,
                    phone: requirePhone ? phone.trimmed : nil
                ),
            ]
        )
    }

    enum Field: Hashable {
        case firstName, lastName, email, address, phone
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
