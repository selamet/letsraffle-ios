import XCTest
@testable import Lets_Raffle

final class APIClientTests: XCTestCase {
    private let baseURL = URL(string: "https://api.test/api/v1")!
    private var store: InMemoryTokenStore!
    private var client: APIClient!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
        store = InMemoryTokenStore()
        client = APIClient(baseURL: baseURL, session: MockURLProtocol.makeSession(), tokenStore: store)
    }

    // MARK: Decoding real response shapes

    func testLoginDecodesSnakeCaseTokenResponse() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/auth/login")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
            return .init(status: 200, body: Fixtures.tokenResponse(access: "a1", refresh: "r1"))
        }

        let response = try await client.send(API.login(email: "test.user@example.com", password: "secret1"))

        XCTAssertEqual(response.accessToken, "a1")
        XCTAssertEqual(response.user.email, "test.user@example.com")
        let body = try XCTUnwrap(MockURLProtocol.requests.first?.httpBody)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: String]
        XCTAssertEqual(json, ["email": "test.user@example.com", "password": "secret1"])
    }

    func testDrawListDecodesCamelCaseAndStatuses() async throws {
        store.tokens = AuthTokens(accessToken: "a1", refreshToken: "r1")
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer a1")
            return .init(status: 200, body: Fixtures.drawList)
        }

        let draws = try await client.send(API.draws())

        XCTAssertEqual(draws.count, 2)
        XCTAssertEqual(draws[0].drawType, .dynamic)
        XCTAssertEqual(draws[0].status, .inProgress)
        XCTAssertEqual(draws[0].inviteCode, "jolly-reindeer-742")
        XCTAssertNotNil(draws[0].drawDate)
        XCTAssertEqual(draws[1].status, .unknown)
        XCTAssertNil(draws[1].inviteCode)
    }

    func testDynamicDrawRequestEncodesCamelCaseWithOffsetDate() async throws {
        store.tokens = AuthTokens(accessToken: "a1", refreshToken: "r1")
        MockURLProtocol.handler = { _ in
            .init(status: 201, body: #"{"success":true,"message":"ok","drawId":7,"inviteCode":"merry-elf-100"}"#)
        }
        let date = Date(timeIntervalSince1970: 1_798_142_400) // 2026-12-24T20:00:00Z
        let request = DynamicDrawRequest(
            addressRequired: true,
            phoneNumberRequired: false,
            language: "TR",
            drawDate: date,
            participants: [ParticipantInput(firstName: "Ayşe", lastName: "Demir", email: "ayse@example.com", address: "Kadıköy")]
        )

        let response = try await client.send(API.createDynamicDraw(request))

        XCTAssertEqual(response.inviteCode, "merry-elf-100")
        XCTAssertNil(response.participantToken)
        let body = try XCTUnwrap(MockURLProtocol.requests.first?.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["addressRequired"] as? Bool, true)
        XCTAssertEqual(json["drawDate"] as? String, "2026-12-24T20:00:00Z")
        let participant = try XCTUnwrap((json["participants"] as? [[String: Any]])?.first)
        XCTAssertEqual(participant["firstName"] as? String, "Ayşe")
        XCTAssertNil(participant["phone"], "nil optionals must be omitted")
        XCTAssertNil(participant["id"], "local identifier must not be sent")
    }

    func testDeleteReturnsEmptyResponseFor204() async throws {
        store.tokens = AuthTokens(accessToken: "a1", refreshToken: "r1")
        MockURLProtocol.handler = { _ in .init(status: 204, body: "") }

        let result = try await client.send(API.deleteParticipant(drawId: 1, participantId: 2))

        XCTAssertEqual(result, EmptyResponse())
        XCTAssertEqual(MockURLProtocol.requests.first?.httpMethod, "DELETE")
    }

    // MARK: Errors

    func testServerErrorExposesFastAPIDetail() async {
        MockURLProtocol.handler = { _ in .init(status: 409, body: #"{"detail":"This email is already registered for this draw"}"#) }

        do {
            _ = try await client.send(API.joinDraw(inviteCode: "x", participant: .init(firstName: "a", lastName: "b", email: "c@d.com")))
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error as? APIError, .server(status: 409, detail: "This email is already registered for this draw"))
        }
    }

    func testValidationErrorListIsFlattened() {
        let body = #"{"detail":[{"loc":["body"],"msg":"Value error, address is required","type":"value_error"},{"loc":["body","email"],"msg":"value is not a valid email address","type":"value_error"}]}"#
        XCTAssertEqual(
            APIError.detailMessage(from: Data(body.utf8)),
            "address is required\nvalue is not a valid email address"
        )
    }

    func testRequiredAuthWithoutTokenFailsFast() async {
        do {
            _ = try await client.send(API.draws())
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error as? APIError, .unauthorized)
            XCTAssertTrue(MockURLProtocol.requests.isEmpty)
        }
    }

    // MARK: Token refresh

    func testExpiredAccessTokenIsRefreshedAndRequestRetried() async throws {
        store.tokens = AuthTokens(accessToken: "old", refreshToken: "r1")
        MockURLProtocol.handler = { request in
            switch (request.url!.path, request.value(forHTTPHeaderField: "Authorization")) {
            case ("/api/v1/draws", "Bearer old"): .init(status: 401, body: #"{"detail":"Could not validate credentials"}"#)
            case ("/api/v1/auth/refresh", nil): .init(status: 200, body: Fixtures.tokenResponse(access: "new", refresh: "r2"))
            case ("/api/v1/draws", "Bearer new"): .init(status: 200, body: "[]")
            default: .init(status: 500, body: "{}")
            }
        }

        let draws = try await client.send(API.draws())

        XCTAssertTrue(draws.isEmpty)
        XCTAssertEqual(store.tokens, AuthTokens(accessToken: "new", refreshToken: "r2"))
        XCTAssertEqual(MockURLProtocol.requests.map(\.url!.path), ["/api/v1/draws", "/api/v1/auth/refresh", "/api/v1/draws"])
    }

    func testRejectedRefreshTokenClearsSessionAndNotifies() async {
        store.tokens = AuthTokens(accessToken: "old", refreshToken: "bad")
        MockURLProtocol.handler = { _ in .init(status: 401, body: #"{"detail":"Invalid refresh token"}"#) }
        let expired = expectation(description: "session expired")
        await client.setSessionExpiredHandler { expired.fulfill() }

        do {
            _ = try await client.send(API.draws())
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error as? APIError, .unauthorized)
        }

        await fulfillment(of: [expired], timeout: 1)
        XCTAssertNil(store.tokens)
    }
}

final class APIDateTests: XCTestCase {
    func testParsesBackendFormats() throws {
        let expected = Date(timeIntervalSince1970: 1_798_142_400)
        XCTAssertEqual(APIDate.parse("2026-12-24T20:00:00Z"), expected)
        XCTAssertEqual(APIDate.parse("2026-12-24T20:00:00+00:00"), expected)
        XCTAssertEqual(APIDate.parse("2026-12-24T23:00:00+03:00"), expected)
        XCTAssertEqual(APIDate.parse("2026-12-24T20:00:00"), expected, "naive dates are UTC")
        let micro = try XCTUnwrap(APIDate.parse("2026-12-24T20:00:00.123456+00:00"))
        XCTAssertEqual(micro.timeIntervalSince1970, expected.timeIntervalSince1970 + 0.123, accuracy: 0.001)
        XCTAssertNil(APIDate.parse("not a date"))
    }
}

enum Fixtures {
    static func tokenResponse(access: String, refresh: String) -> String {
        """
        {"access_token":"\(access)","refresh_token":"\(refresh)","token_type":"bearer",
         "user":{"id":1,"email":"test.user@example.com","created_at":"2026-11-01T10:00:00.123456Z","updated_at":"2026-11-01T10:00:00.123456Z"}}
        """
    }

    static let drawList = """
    [
      {"id":2,"drawType":"dynamic","status":"in_progress","inviteCode":"jolly-reindeer-742","participantCount":3,
       "createdAt":"2026-11-02T09:15:00.5+00:00","drawDate":"2026-12-24T17:00:00Z","language":"TR"},
      {"id":1,"drawType":"manual","status":"archived","inviteCode":null,"participantCount":5,
       "createdAt":"2026-11-01T09:15:00Z","drawDate":null,"language":"EN"}
    ]
    """
}
