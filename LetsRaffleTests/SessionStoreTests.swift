import XCTest
@testable import Lets_Raffle

@MainActor
final class SessionStoreTests: XCTestCase {
    private var store: InMemoryTokenStore!
    private var defaults: UserDefaults!
    private var session: SessionStore!

    override func setUp() async throws {
        MockURLProtocol.reset()
        store = InMemoryTokenStore()
        defaults = UserDefaults(suiteName: "SessionStoreTests")!
        defaults.removePersistentDomain(forName: "SessionStoreTests")
        let api = APIClient(baseURL: URL(string: "https://api.test/api/v1")!, session: MockURLProtocol.makeSession(), tokenStore: store)
        session = SessionStore(api: api, defaults: defaults)
    }

    func testRestoreWithoutTokensShowsOnboarding() async {
        await session.restore()
        XCTAssertEqual(session.state, .signedOut)
    }

    func testLoginNormalizesEmailAndStoresTokens() async throws {
        MockURLProtocol.handler = { _ in .init(status: 200, body: Fixtures.tokenResponse(access: "a", refresh: "r")) }

        try await session.login(email: "  Test.User@Example.com ", password: "secret1")

        XCTAssertEqual(session.user?.email, "test.user@example.com")
        XCTAssertEqual(store.tokens, AuthTokens(accessToken: "a", refreshToken: "r"))
        let body = try XCTUnwrap(MockURLProtocol.requests.first?.httpBody)
        XCTAssertEqual((try JSONSerialization.jsonObject(with: body) as? [String: String])?["email"], "test.user@example.com")
    }

    func testRestoreRefreshesExistingSession() async {
        store.tokens = AuthTokens(accessToken: "a", refreshToken: "r")
        MockURLProtocol.handler = { _ in .init(status: 200, body: Fixtures.tokenResponse(access: "a2", refresh: "r2")) }

        await session.restore()

        XCTAssertTrue(session.isSignedIn)
        XCTAssertEqual(store.tokens?.refreshToken, "r2")
    }

    func testRestoreWithRejectedTokenSignsOut() async {
        store.tokens = AuthTokens(accessToken: "a", refreshToken: "expired")
        MockURLProtocol.handler = { _ in .init(status: 401, body: #"{"detail":"Invalid refresh token"}"#) }

        await session.restore()

        XCTAssertEqual(session.state, .signedOut)
        XCTAssertNil(store.tokens)
    }

    /// Without an account the app always opens on the welcome screen, even after browsing as a guest.
    func testGuestModeIsNotRememberedAcrossLaunches() async {
        session.continueAsGuest()
        let api = APIClient(baseURL: URL(string: "https://api.test")!, session: MockURLProtocol.makeSession(), tokenStore: InMemoryTokenStore())
        let restored = SessionStore(api: api, defaults: defaults)

        await restored.restore()

        XCTAssertEqual(restored.state, .signedOut)
    }

    func testValidation() {
        let t = Strings.en
        XCTAssertNil(Validation.emailError("a@b.co", t))
        XCTAssertEqual(Validation.emailError("", t), t.fieldRequired)
        XCTAssertEqual(Validation.emailError("not-an-email", t), t.invalidEmail)
        XCTAssertEqual(Validation.passwordError("12345", t), t.passwordTooShort)
        XCTAssertNil(Validation.passwordError("123456", t))
    }
}

@MainActor
final class AppleSignInSessionTests: XCTestCase {
    func testAppleSignInPostsSnakeCaseBodyAndSignsIn() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.handler = { _ in .init(status: 200, body: Fixtures.tokenResponse(access: "a", refresh: "r")) }
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let store = InMemoryTokenStore()
        let api = APIClient(baseURL: URL(string: "https://api.test/api/v1")!, session: MockURLProtocol.makeSession(), tokenStore: store)
        let session = SessionStore(api: api, defaults: defaults)

        try await session.signInWithApple(AppleCredential(identityToken: "jwt", firstName: "Ayşe", lastName: nil))

        XCTAssertTrue(session.isSignedIn)
        let request = try XCTUnwrap(MockURLProtocol.requests.first)
        XCTAssertEqual(request.url?.path, "/api/v1/auth/apple")
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: request.httpBody!) as? [String: Any])
        XCTAssertEqual(json["identity_token"] as? String, "jwt")
        XCTAssertEqual(json["first_name"] as? String, "Ayşe")
        XCTAssertNil(json["last_name"])
        XCTAssertNil(json["authorization_code"], "omitted when Apple returns no code")
    }

    /// The backend needs the code to revoke the user's Apple tokens on account deletion.
    func testAppleSignInSendsAuthorizationCode() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.handler = { _ in .init(status: 200, body: Fixtures.tokenResponse(access: "a", refresh: "r")) }
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let api = APIClient(baseURL: URL(string: "https://api.test/api/v1")!, session: MockURLProtocol.makeSession(), tokenStore: InMemoryTokenStore())
        let session = SessionStore(api: api, defaults: defaults)

        try await session.signInWithApple(AppleCredential(identityToken: "jwt", authorizationCode: "one-time-code", firstName: nil, lastName: nil))

        let request = try XCTUnwrap(MockURLProtocol.requests.first)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: request.httpBody!) as? [String: Any])
        XCTAssertEqual(json["identity_token"] as? String, "jwt")
        XCTAssertEqual(json["authorization_code"] as? String, "one-time-code")
    }
}
