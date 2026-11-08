import XCTest
@testable import Lets_Raffle

@MainActor
final class DrawsStoreTests: XCTestCase {
    func testLoadOrdersActiveDrawsFirst() async {
        MockURLProtocol.reset()
        MockURLProtocol.handler = { _ in
            .init(status: 200, body: """
            [
              {"id":3,"drawType":"manual","status":"completed","inviteCode":null,"participantCount":5,"createdAt":"2026-11-03T09:00:00Z","drawDate":null,"language":"TR"},
              {"id":2,"drawType":"dynamic","status":"active","inviteCode":"merry-star-200","participantCount":2,"createdAt":"2026-11-02T09:00:00Z","drawDate":null,"language":"TR"}
            ]
            """)
        }
        let api = APIClient(
            baseURL: URL(string: "https://api.test/api/v1")!,
            session: MockURLProtocol.makeSession(),
            tokenStore: InMemoryTokenStore(tokens: AuthTokens(accessToken: "a", refreshToken: "r"))
        )
        let store = DrawsStore(api: api)

        await store.load(.en)

        XCTAssertEqual(store.phase, .loaded)
        XCTAssertEqual(store.activeFirst.map(\.id), [2, 3])
        XCTAssertEqual(store.activeFirst.first?.displayName, "merry-star-200")
        XCTAssertEqual(store.activeFirst.last?.displayName, "#3")
    }

    func testLoadFailureExposesMessage() async {
        MockURLProtocol.reset()
        MockURLProtocol.handler = { _ in .init(status: 500, body: #"{"detail":"boom"}"#) }
        let api = APIClient(
            baseURL: URL(string: "https://api.test/api/v1")!,
            session: MockURLProtocol.makeSession(),
            tokenStore: InMemoryTokenStore(tokens: AuthTokens(accessToken: "a", refreshToken: "r"))
        )
        let store = DrawsStore(api: api)

        await store.load(.en)

        XCTAssertEqual(store.phase, .failed("boom"))
    }
}
