import XCTest
@testable import Lets_Raffle

@MainActor
final class ManualDrawModelTests: XCTestCase {
    private func person(_ name: String, address: String? = nil) -> ParticipantInput {
        ParticipantInput(firstName: name, lastName: "Test", email: "\(name.lowercased())@example.com", address: address)
    }

    func testRequiresThreeParticipants() {
        let model = ManualDrawModel()
        model.upsert(person("Ayse"))
        model.upsert(person("Mert"))
        XCTAssertFalse(model.canRun)
        model.upsert(person("Elif"))
        XCTAssertTrue(model.canRun)
    }

    func testRejectsDuplicateEmailCaseInsensitively() {
        let model = ManualDrawModel()
        model.upsert(person("Ayse"))
        let dup = ParticipantInput(firstName: "Other", lastName: "X", email: " AYSE@example.com ")
        XCTAssertEqual(model.error(for: dup, editing: nil, .en)[.email], Strings.en.duplicateEmail)
    }

    func testEditingKeepsOwnEmailValid() {
        let model = ManualDrawModel()
        model.upsert(person("Ayse"))
        var edited = model.participants[0]
        edited.lastName = "Demir"
        XCTAssertTrue(model.error(for: edited, editing: edited.id, .en).isEmpty)
        model.upsert(edited)
        XCTAssertEqual(model.participants.count, 1)
        XCTAssertEqual(model.participants[0].lastName, "Demir")
    }

    func testRequiringAddressLaterBlocksIncompleteParticipants() {
        let model = ManualDrawModel()
        ["Ayse", "Mert"].forEach { model.upsert(person($0, address: "Kadıköy")) }
        model.upsert(person("Elif"))
        model.requireAddress = true
        XCTAssertTrue(model.isIncomplete(model.participants[2]))
        XCTAssertFalse(model.canRun)
    }

    func testSubmitPostsManualDrawWithoutAuth() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.handler = { _ in .init(status: 201, body: #"{"success":true,"message":"ok","drawId":42}"#) }
        let api = APIClient(baseURL: URL(string: "https://api.test/api/v1")!, session: MockURLProtocol.makeSession(), tokenStore: InMemoryTokenStore())
        let model = ManualDrawModel()
        ["Ayse", "Mert", "Elif"].forEach { model.upsert(person($0)) }

        await model.submit(api: api, language: .tr, .tr)

        XCTAssertEqual(model.completedDrawId, 42)
        let request = try XCTUnwrap(MockURLProtocol.requests.first)
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: request.httpBody!) as? [String: Any])
        XCTAssertEqual((json["participants"] as? [Any])?.count, 3)
        XCTAssertEqual(json["language"] as? String, "TR")
    }
}
