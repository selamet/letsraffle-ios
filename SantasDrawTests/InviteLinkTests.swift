import XCTest
@testable import Santa_s_Draw

final class InviteLinkTests: XCTestCase {
    func testParsesRawCodes() {
        XCTAssertEqual(InviteLink.code(from: "  Jolly-Reindeer-742 "), "jolly-reindeer-742")
        XCTAssertNil(InviteLink.code(from: ""))
        XCTAssertNil(InviteLink.code(from: "drop table;"))
    }

    func testParsesWebInviteLinks() {
        XCTAssertEqual(InviteLink.code(from: "https://letsraffle.com/draw/join/merry-elf-100"), "merry-elf-100")
        XCTAssertEqual(InviteLink.code(from: "https://letsraffle.com/draw/join/merry-elf-100?utm=qr"), "merry-elf-100")
        XCTAssertNil(InviteLink.code(from: "https://letsraffle.com/draws/merry-elf-100"))
        XCTAssertNil(InviteLink.code(from: "https://letsraffle.com/draw/join/"))
    }

    func testParsesCustomScheme() {
        XCTAssertEqual(InviteLink.code(from: URL(string: "letsraffle://join/merry-elf-100")!), "merry-elf-100")
        XCTAssertNil(InviteLink.code(from: URL(string: "letsraffle://profile")!))
        XCTAssertNil(InviteLink.code(from: URL(string: "ftp://x/draw/join/abc")!))
    }

    func testDeepLinkRoundTrip() {
        let url = InviteLink.deepLink(for: "snowy-bell-321")
        XCTAssertEqual(InviteLink.code(from: url), "snowy-bell-321")
    }

    func testInviteURLMatchesWebRoute() {
        XCTAssertEqual(InviteLink.code(from: AppConfig.inviteURL(for: "snowy-bell-321")), "snowy-bell-321")
    }

    @MainActor
    func testRouterIgnoresUnrelatedURLs() {
        let router = DeepLinkRouter()
        router.handle(URL(string: "https://example.com/hello")!)
        XCTAssertNil(router.pendingInviteCode)
        router.handle(URL(string: "letsraffle://join/frosty-star-555")!)
        XCTAssertEqual(router.pendingInviteCode, "frosty-star-555")
    }
}
