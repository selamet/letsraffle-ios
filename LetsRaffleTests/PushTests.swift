import XCTest
@testable import Lets_Raffle

@MainActor
final class PushTests: XCTestCase {
    func testPayloadRouting() {
        XCTAssertEqual(PushManager.destination(for: ["type": "match_revealed", "inviteCode": "merry-elf-100"]), .reveal(inviteCode: "merry-elf-100"))
        XCTAssertEqual(PushManager.destination(for: ["type": "participant_joined", "inviteCode": "a"]), .drawDetail(inviteCode: "a"))
        XCTAssertEqual(PushManager.destination(for: ["type": "draw_reminder", "inviteCode": "b"]), .drawDetail(inviteCode: "b"))
        XCTAssertEqual(PushManager.destination(for: ["type": "draw_not_run", "inviteCode": "c"]), .drawDetail(inviteCode: "c"))
        XCTAssertEqual(PushManager.destination(for: ["type": "gift_reminder", "inviteCode": "d"]), .reveal(inviteCode: "d"))
        XCTAssertNil(PushManager.destination(for: ["type": "unknown", "inviteCode": "a"]))
        XCTAssertNil(PushManager.destination(for: ["type": "match_revealed"]))
    }

    func testGiftReminderFiresOnDecember28InSeason() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Europe/Istanbul"))
        func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
            calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
        }

        XCTAssertEqual(GiftReminder.fireDate(now: date(2026, 12, 20), calendar: calendar), date(2026, 12, 28, 10))
        XCTAssertEqual(GiftReminder.fireDate(now: date(2026, 10, 1), calendar: calendar), date(2026, 12, 28, 10))
        // too late, or out of season
        XCTAssertNil(GiftReminder.fireDate(now: date(2026, 12, 28, 11), calendar: calendar))
        XCTAssertNil(GiftReminder.fireDate(now: date(2026, 12, 30), calendar: calendar))
        XCTAssertNil(GiftReminder.fireDate(now: date(2027, 1, 2), calendar: calendar))
        XCTAssertNil(GiftReminder.fireDate(now: date(2026, 6, 1), calendar: calendar))
    }

    func testGiftReminderNeverNamesTheReceiver() {
        let content = GiftReminder.content(inviteCode: "merry-elf-100", t: .tr)
        XCTAssertEqual(content.userInfo["type"] as? String, "gift_reminder")
        XCTAssertEqual(content.userInfo["inviteCode"] as? String, "merry-elf-100")
        XCTAssertEqual(PushManager.destination(for: content.userInfo), .reveal(inviteCode: "merry-elf-100"))
        XCTAssertFalse(content.body.isEmpty)
        XCTAssertEqual(GiftReminder.identifier(for: "merry-elf-100"), "gift-reminder-merry-elf-100")
    }

    func testDeviceRegistrationEncoding() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.handler = { _ in .init(status: 200, body: #"{"userLinked":false,"participantCount":1}"#) }
        let api = APIClient(baseURL: URL(string: "https://api.test/api/v1")!, session: MockURLProtocol.makeSession(), tokenStore: InMemoryTokenStore())

        let response = try await api.send(API.registerDevice(DeviceRegistration(token: "abcd", language: "EN", participantTokens: ["pt"])))

        XCTAssertEqual(response.participantCount, 1)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: MockURLProtocol.requests[0].httpBody!) as? [String: Any])
        XCTAssertEqual(json["platform"] as? String, "ios")
        XCTAssertEqual(json["participantTokens"] as? [String], ["pt"])
        XCTAssertNil(MockURLProtocol.requests[0].value(forHTTPHeaderField: "Authorization"))
    }
}
