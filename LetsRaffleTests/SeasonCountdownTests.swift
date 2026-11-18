import XCTest
@testable import Lets_Raffle

final class SeasonCountdownTests: XCTestCase {
    private var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        return c
    }()

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12, _ min: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    func testEveryOtherEveningUntilNewYearsEve() {
        let items = SeasonCountdown.schedule(now: date(2026, 11, 18), calendar: calendar)

        XCTAssertEqual(items.first?.date, date(2026, 11, 19, 19, 30))
        XCTAssertEqual(items.first?.daysLeft, 43)
        let gaps = zip(items.dropLast(), items.dropLast().dropFirst()).map { calendar.dateComponents([.day], from: $0.date, to: $1.date).day }
        XCTAssertTrue(gaps.allSatisfy { $0 == 2 })
        XCTAssertEqual(items.last, .init(date: date(2026, 12, 31, 20, 0), daysLeft: 1, isNewYearsEve: true))
        XCTAssertLessThan(items.count, 40, "iOS keeps at most 64 pending local notifications")
    }

    func testRescheduleDoesNotShiftTheDates() {
        let monday = SeasonCountdown.schedule(now: date(2026, 11, 18), calendar: calendar).map(\.date)
        let tuesday = SeasonCountdown.schedule(now: date(2026, 11, 19, 8), calendar: calendar).map(\.date)
        XCTAssertEqual(Array(monday.drop { $0 < tuesday[0] }), tuesday)
        // already past this evening's time: starts with the next one
        let lateEvening = SeasonCountdown.schedule(now: date(2026, 11, 19, 21), calendar: calendar)
        XCTAssertEqual(lateEvening.first?.date, date(2026, 11, 21, 19, 30))
    }

    func testNothingOutsideTheSeason() {
        XCTAssertTrue(SeasonCountdown.schedule(now: date(2026, 10, 20), calendar: calendar).isEmpty)
        XCTAssertTrue(SeasonCountdown.schedule(now: date(2027, 1, 2), calendar: calendar).isEmpty)
        XCTAssertTrue(SeasonCountdown.schedule(now: date(2026, 12, 31, 21), calendar: calendar).isEmpty)
    }

    func testMessagesFillInTheDaysAndRotate() {
        let items = SeasonCountdown.schedule(now: date(2026, 11, 18), calendar: calendar)
        let first = SeasonCountdown.message(for: items[0], index: 0, t: .tr)
        let second = SeasonCountdown.message(for: items[1], index: 1, t: .tr)
        XCTAssertEqual(first.title, "Yılbaşına 43 gün kaldı 🎄")
        XCTAssertNotEqual(first.title, second.title)
        for (index, item) in items.enumerated() {
            for t in [Strings.tr, Strings.en] {
                let text = SeasonCountdown.message(for: item, index: index, t: t)
                XCTAssertFalse(text.title.contains("{d}") || text.body.contains("{d}"))
            }
        }
        XCTAssertEqual(SeasonCountdown.message(for: items.last!, index: 0, t: .en).title, "Happy New Year! 🎆")
    }

    func testTheSoundShipsWithTheApp() {
        XCTAssertNotNil(Bundle.main.url(forResource: "jingle", withExtension: "caf"))
    }
}
