import XCTest
@testable import Lets_Raffle

@MainActor
final class WidgetSyncTests: XCTestCase {
    private func draw(_ id: Int, code: String?, status: DrawStatus, date: Date?) -> DrawListItem {
        DrawListItem(id: id, drawType: code == nil ? .manual : .dynamic, status: status, inviteCode: code,
                     participantCount: 4, createdAt: .now, drawDate: date, language: "TR")
    }

    func testSnapshotPicksSoonestFutureDrawAndHidesMatchName() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        var reloads = 0
        let sync = WidgetSync(defaults: defaults) { reloads += 1 }
        let now = Date(timeIntervalSince1970: 1_790_000_000)

        sync.update(draws: [
            draw(1, code: "far-away-1", status: .active, date: now.addingTimeInterval(10 * 86_400)),
            draw(2, code: "past-draw-2", status: .active, date: now.addingTimeInterval(-3600)),
            draw(3, code: nil, status: .completed, date: nil),
        ])
        sync.update(participations: [
            Participation(inviteCode: "soon-star-3", participantId: 9, drawId: 4, displayName: "Mert",
                          drawDate: now.addingTimeInterval(2 * 86_400), participantToken: "t", wantsNotification: true, joinedAt: now),
            Participation(inviteCode: "done-bell-4", participantId: 8, drawId: 5, displayName: "Mert", drawDate: nil,
                          participantToken: "t", wantsNotification: true, joinedAt: now,
                          result: MatchResult(drawId: 5, inviteCode: "done-bell-4",
                                              receiver: .init(firstName: "Elif", lastName: "Yılmaz", address: nil, phone: nil))),
        ])
        let snapshot = sync.makeSnapshot(now: now)

        XCTAssertEqual(snapshot.nextDraw?.inviteCode, "soon-star-3")
        XCTAssertEqual(snapshot.match, .init(inviteCode: "done-bell-4", initials: "EY"))
        XCTAssertEqual(snapshot.activeDraws.map(\.name), ["far-away-1", "past-draw-2", "#3"])
        XCTAssertGreaterThan(reloads, 0)
        XCTAssertFalse(String(data: try! JSONEncoder().encode(snapshot), encoding: .utf8)!.contains("Elif"), "full name must not leave the app")
    }

    func testDaysLeft() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        let now = calendar.date(from: DateComponents(year: 2026, month: 12, day: 12, hour: 23))!
        let eve = calendar.date(from: DateComponents(year: 2026, month: 12, day: 24, hour: 20))!
        XCTAssertEqual(WidgetSnapshot.daysLeft(until: eve, from: now, calendar: calendar), 12)
        XCTAssertEqual(WidgetSnapshot.daysLeft(until: now, from: eve, calendar: calendar), 0)
    }

    func testRouterHandlesWidgetLinks() {
        let router = DeepLinkRouter()
        router.handle(WidgetLink.reveal("merry-elf-100"))
        XCTAssertEqual(router.pendingDestination, .reveal(inviteCode: "merry-elf-100"))
        router.handle(WidgetLink.draw("merry-elf-100"))
        XCTAssertEqual(router.pendingDestination, .drawDetail(inviteCode: "merry-elf-100"))
        XCTAssertNil(router.pendingInviteCode)
    }
}
