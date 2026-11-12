import XCTest
@testable import Lets_Raffle

@MainActor
final class InviteDrawTests: XCTestCase {
    private var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        return c
    }()

    func testDefaultDateIsChristmasEveWhenAhead() {
        let now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 5, hour: 10))!
        let date = InviteDraft.defaultDrawDate(now: now, calendar: calendar)
        XCTAssertEqual(calendar.dateComponents([.month, .day, .hour, .minute], from: date), DateComponents(month: 12, day: 24, hour: 20, minute: 0))
    }

    func testDefaultDateFallsBackToTomorrowEvening() {
        let now = calendar.date(from: DateComponents(year: 2026, month: 12, day: 25, hour: 10))!
        let date = InviteDraft.defaultDrawDate(now: now, calendar: calendar)
        XCTAssertEqual(calendar.dateComponents([.month, .day, .hour], from: date), DateComponents(month: 12, day: 26, hour: 20))
    }

    func testRequestNormalizesOrganizerAndRoundsToHour() {
        let draft = InviteDraft(email: " Ayse@Example.com ")
        draft.firstName = " Ayşe "
        draft.lastName = "Demir"
        draft.requirePhone = true
        draft.phone = "555"
        draft.address = "ignored because not required"
        draft.scheduleEnabled = true // off by default
        draft.drawDate = Date(timeIntervalSince1970: 1_798_142_400 + 25 * 60) // 20:25Z

        let request = draft.makeRequest(language: .en)

        XCTAssertEqual(request.language, "EN")
        XCTAssertEqual(request.drawDate, Date(timeIntervalSince1970: 1_798_142_400))
        XCTAssertEqual(request.participants.count, 1)
        XCTAssertEqual(request.participants[0].firstName, "Ayşe")
        XCTAssertEqual(request.participants[0].email, "ayse@example.com")
        XCTAssertEqual(request.participants[0].phone, "555")
        XCTAssertNil(request.participants[0].address)
    }

    func testScheduleDisabledSendsNoDate() {
        let draft = InviteDraft()
        draft.scheduleEnabled = false
        XCTAssertNil(draft.makeRequest(language: .tr).drawDate)
    }

    func testValidationRequiresConditionalFields() {
        let draft = InviteDraft(email: "a@b.co")
        draft.firstName = "A"
        draft.lastName = "B"
        XCTAssertTrue(draft.validationErrors(.en).isEmpty)
        draft.requireAddress = true
        XCTAssertEqual(draft.validationErrors(.en)[.address], Strings.en.fieldRequired)
    }

    func testDetailStoreProtectsOrganizerAndGatesExecution() async {
        MockURLProtocol.reset()
        MockURLProtocol.handler = { _ in
            .init(status: 200, body: """
            {"id":1,"drawType":"dynamic","status":"active","inviteCode":"merry-star-200","requireAddress":false,"requirePhone":false,
             "drawDate":null,"createdAt":"2026-11-01T10:00:00Z","language":"TR","participants":[
               {"id":7,"firstName":"Mert","lastName":"Kaya","email":"m@example.com","address":null,"phone":null,"createdAt":"2026-11-02T10:00:00Z"},
               {"id":5,"firstName":"Ayşe","lastName":"Demir","email":"a@example.com","address":null,"phone":null,"createdAt":"2026-11-01T10:00:00Z"}
             ]}
            """)
        }
        let api = APIClient(baseURL: URL(string: "https://api.test/api/v1")!, session: MockURLProtocol.makeSession(),
                            tokenStore: InMemoryTokenStore(tokens: AuthTokens(accessToken: "a", refreshToken: "r")))
        let store = DrawDetailStore(inviteCode: "merry-star-200", api: api)

        await store.load(.en)

        XCTAssertEqual(store.organizerId, 5)
        XCTAssertFalse(store.canExecute, "needs 3 participants")
        XCTAssertEqual(store.inviteURL.absoluteString, "https://letsraffle.co/draw/join/merry-star-200")

        await store.remove(store.draw!.participants.first { $0.id == 5 }!, .en)
        XCTAssertEqual(store.draw?.participants.count, 2, "organizer must not be removed")
        XCTAssertFalse(MockURLProtocol.requests.contains { $0.httpMethod == "DELETE" })
    }
}
