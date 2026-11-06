import XCTest
@testable import Santa_s_Draw

@MainActor
final class PushTests: XCTestCase {
    func testPayloadRouting() {
        XCTAssertEqual(PushManager.destination(for: ["type": "match_revealed", "inviteCode": "merry-elf-100"]), .reveal(inviteCode: "merry-elf-100"))
        XCTAssertEqual(PushManager.destination(for: ["type": "participant_joined", "inviteCode": "a"]), .drawDetail(inviteCode: "a"))
        XCTAssertEqual(PushManager.destination(for: ["type": "draw_reminder", "inviteCode": "b"]), .drawDetail(inviteCode: "b"))
        XCTAssertNil(PushManager.destination(for: ["type": "unknown", "inviteCode": "a"]))
        XCTAssertNil(PushManager.destination(for: ["type": "match_revealed"]))
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
