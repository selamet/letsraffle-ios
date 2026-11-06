import SwiftUI

/// All user-facing copy. Values come from the design's i18n dictionaries
/// (which mirror letsraffle-web). Using a struct with a memberwise init means
/// the compiler guarantees TR and EN stay in sync, and the language can be
/// switched at runtime without restarting the app.
struct Strings {
    // Onboarding & auth
    let brandEyebrow: String
    let onbSub: String
    let apple: String
    let appleSignup: String
    let emailContinue: String
    let guestStart: String
    let register: String
    let loginTitle: String
    let loginSub: String
    let email: String
    let password: String
    let emailPh: String
    let passwordPh: String
    let passwordRule: String
    let forgot: String
    let loginBtn: String
    let or: String
    let celebration: String
    let registerTitle: String
    let registerSub: String
    let registerBtn: String
    let haveAccount: String
    let loginLink: String
    let forgotFun: String
    let forgotTitle: String
    let forgotSub: String
    let sendReset: String
    let resetSent: String
    let backToLogin: String

    // Home
    let homeTag: String
    let homeTitle: String
    let homeHello: String
    let special: String
    let inviteMode: String
    let inviteModeDesc: String
    let inviteModeFooter: String
    let manualMode: String
    let manualModeDesc: String
    let start: String
    let activeDraws: String
    let seeAll: String
    let noDraws: String
    let guestDrawsHint: String
    let tabDraws: String
    let tabJoin: String
    let tabProfile: String

    // Invite draw
    let step1of2: String
    let step2of2: String
    let settingsTitle: String
    let settingsOptional: String
    let requireAddress: String
    let requireAddressDesc: String
    let requirePhone: String
    let requirePhoneDesc: String
    let enableDrawDate: String
    let drawDateEnabledDesc: String
    let dateTime: String
    let dateLabel: String
    let timeLabel: String
    let drawDateTimeInfo: String // %@ = formatted date
    let continueTitle: String
    let yourDetails: String
    let yourDetailsSub: String
    let firstName: String
    let lastName: String
    let firstNamePh: String
    let lastNamePh: String
    let address: String
    let addressPh: String
    let phone: String
    let phonePh: String
    let saveDetails: String
    let active: String
    let drawOn: String
    let noDrawDate: String
    let shareTitle: String
    let qrHint: String
    let share: String
    let copy: String
    let copied: String
    let participants: String
    let participantsCount: String // %d
    let refresh: String
    let delete: String
    let swipeHint: String
    let readyForDraw: String
    let readyForDrawMsg: String
    let editDate: String
    let save: String
    let drawStarted: String

    // Manual draw
    let addParticipant: String
    let manageTitle: String
    let addressReq: String
    let phoneReq: String
    let treeTitle: String
    let runDraw: String
    let minHint: String
    let cancel: String
    let add: String
    let importContacts: String
    let duplicateEmail: String
    let manualSuccess: String

    // Join
    let joinTitle: String
    let joinSub: String
    let enterCode: String
    let enterCodeSub: String
    let scanQr: String
    let deepLinkHint: String
    let hostedBy: String
    let joinHeading: String
    let joinSubheading: String
    let notifyMe: String
    let joinSubmit: String
    let myJoinedDraws: String
    let cameraDenied: String

    // Success & reveal
    let successTitle: String
    let joinSuccessMsg: String
    let drawDateInfo: String // %@ = formatted date
    let successPush: String
    let happyHolidays: String
    let ok: String
    let yourMatch: String
    let revealTitle: String
    let revealSecret: String
    let tapToReveal: String
    let addReminder: String
    let reminderAdded: String
    let waitingForDraw: String
    let screenshotWarning: String
    let done: String

    // Push & widgets
    let pushTitle: String
    let pushSub: String
    let pushItem1: String
    let pushItem2: String
    let pushItem3: String
    let pushAllow: String
    let pushLater: String
    let widgetNext: String
    let daysLeft: String
    let widgetMatch: String
    let widgetTapReveal: String

    // Profile
    let preferences: String
    let language: String
    let appearance: String
    let appearanceSystem: String
    let appearanceLight: String
    let appearanceDark: String
    let notifications: String
    let widgets: String
    let about: String
    let version: String
    let logout: String
    let deleteAccount: String
    let deleteAccountConfirm: String
    let appleLinked: String
    let guest: String

    // Status & types
    let statusActive: String
    let statusInProgress: String
    let statusCompleted: String
    let statusCancelled: String
    let typeInvite: String
    let typeManual: String

    // Validation & errors
    let fieldRequired: String
    let invalidEmail: String
    let passwordTooShort: String
    let genericError: String
    let networkError: String
    let sessionExpired: String
    let retry: String
}

extension Strings {
    func participantCount(_ n: Int) -> String { String(format: participantsCount, n) }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case tr = "TR"
    case en = "EN"

    var id: String { rawValue }

    var strings: Strings { self == .tr ? .tr : .en }

    var locale: Locale { Locale(identifier: self == .tr ? "tr_TR" : "en_US") }

    /// Picks the device language on first launch.
    static var deviceDefault: AppLanguage {
        Locale.preferredLanguages.first?.lowercased().hasPrefix("tr") == true ? .tr : .en
    }
}

private struct StringsKey: EnvironmentKey {
    static let defaultValue: Strings = .tr
}

extension EnvironmentValues {
    var strings: Strings {
        get { self[StringsKey.self] }
        set { self[StringsKey.self] = newValue }
    }
}
