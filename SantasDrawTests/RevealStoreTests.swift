import XCTest
@testable import Santa_s_Draw

@MainActor
final class RevealStoreTests: XCTestCase {
    private let resultJSON = #"{"drawId":1,"inviteCode":"merry-elf-100","receiver":{"firstName":"Elif","lastName":"Yılmaz","address":"Kadıköy","phone":null}}"#

    private func makeStore(token: String?, signedIn: Bool) -> (RevealStore, ParticipationStore) {
        let participations = ParticipationStore(service: "tests.\(UUID().uuidString)")
        if let token {
            participations.add(Participation(inviteCode: "merry-elf-100", participantId: 3, drawId: 1, displayName: "Mert",
                                             drawDate: nil, participantToken: token, wantsNotification: true, joinedAt: .now))
        }
        let api = APIClient(baseURL: URL(string: "https://api.test/api/v1")!, session: MockURLProtocol.makeSession(),
                            tokenStore: InMemoryTokenStore(tokens: signedIn ? AuthTokens(accessToken: "a", refreshToken: "r") : nil))
        return (RevealStore(inviteCode: "merry-elf-100", api: api, participations: participations, isSignedIn: signedIn), participations)
    }

    override func setUp() {
        MockURLProtocol.reset()
    }

    func testParticipantTokenRevealsAndCachesResult() async {
        MockURLProtocol.handler = { [resultJSON] request in
            XCTAssertEqual(request.url?.path, "/api/v1/participants/me/result")
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-Participant-Token"), "pt-1")
            return .init(status: 200, body: resultJSON)
        }
        let (store, participations) = makeStore(token: "pt-1", signedIn: false)

        await store.load(.tr)

        guard case let .revealed(result) = store.phase else { return XCTFail("expected revealed, got \(store.phase)") }
        XCTAssertEqual(result.receiver.fullName, "Elif Yılmaz")
        XCTAssertEqual(participations.participation(for: "merry-elf-100")?.result, result)
    }

    func testNotCompletedDrawIsWaiting() async {
        MockURLProtocol.handler = { _ in .init(status: 409, body: #"{"detail":"Draw not completed"}"#) }
        let (store, _) = makeStore(token: "pt-1", signedIn: false)

        await store.load(.tr)

        XCTAssertEqual(store.phase, .waiting)
    }

    func testOrganizerWithoutLocalTokenUsesMyResult() async {
        MockURLProtocol.handler = { [resultJSON] request in
            XCTAssertEqual(request.url?.path, "/api/v1/draws/merry-elf-100/my-result")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer a")
            return .init(status: 200, body: resultJSON)
        }
        let (store, _) = makeStore(token: nil, signedIn: true)

        await store.load(.tr)

        guard case .revealed = store.phase else { return XCTFail("expected revealed") }
    }

    func testCachedResultSurvivesOfflineReload() async {
        var online = true
        MockURLProtocol.handler = { [resultJSON] _ in online ? .init(status: 200, body: resultJSON) : .init(status: 503, body: "{}") }
        let (store, _) = makeStore(token: "pt-1", signedIn: false)
        await store.load(.tr)
        online = false

        await store.load(.tr)

        guard case .revealed = store.phase else { return XCTFail("cached result should stay visible") }
    }
}
