import XCTest
@testable import Santa_s_Draw

final class StringsTests: XCTestCase {
    /// Every TR/EN pair must expose the same printf placeholders, otherwise
    /// `String(format:)` would crash or render garbage in one language.
    func testFormatPlaceholdersMatchAcrossLanguages() {
        let tr = Mirror(reflecting: Strings.tr).children
        let en = Dictionary(uniqueKeysWithValues: Mirror(reflecting: Strings.en).children.map { ($0.label!, $0.value as! String) })
        let pattern = try! NSRegularExpression(pattern: "%[@d]")

        for child in tr {
            let key = child.label!
            let trValue = child.value as! String
            let enValue = en[key]!
            XCTAssertFalse(trValue.isEmpty, "TR \(key) is empty")
            XCTAssertFalse(enValue.isEmpty, "EN \(key) is empty")
            XCTAssertEqual(placeholders(trValue, pattern), placeholders(enValue, pattern), "Placeholder mismatch for \(key)")
        }
    }

    func testParticipantCountFormatting() {
        XCTAssertEqual(Strings.tr.participantCount(3), "3 katılımcı")
        XCTAssertEqual(Strings.en.participantCount(8), "8 participants")
    }

    func testAppSettingsPersistLanguageAndAppearance() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let settings = AppSettings(defaults: defaults)
        settings.language = .en
        settings.appearance = .dark

        let reloaded = AppSettings(defaults: defaults)
        XCTAssertEqual(reloaded.language, .en)
        XCTAssertEqual(reloaded.appearance, .dark)
    }

    private func placeholders(_ s: String, _ re: NSRegularExpression) -> [String] {
        re.matches(in: s, range: NSRange(s.startIndex..., in: s)).map { (s as NSString).substring(with: $0.range) }
    }
}

final class AppConfigTests: XCTestCase {
    func testVersionIncludesBuildNumber() {
        XCTAssertTrue(AppConfig.version.contains("("))
    }

    func testNotificationsDefaultToEnabled() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        XCTAssertTrue(AppSettings(defaults: defaults).notificationsEnabled)
    }
}
