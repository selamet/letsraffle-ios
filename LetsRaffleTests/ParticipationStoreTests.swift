import XCTest
@testable import Lets_Raffle

@MainActor
final class ParticipationStoreTests: XCTestCase {
    private func makeStore(_ service: String = "tests.\(UUID().uuidString)") -> ParticipationStore {
        ParticipationStore(service: service)
    }

    private func entry(_ code: String) -> Participation {
        Participation(inviteCode: code, participantId: 1, drawId: 1, displayName: "Mert",
                      drawDate: nil, participantToken: "pt-\(code)", wantsNotification: true, joinedAt: .now)
    }

    func testEachAccountOnlySeesItsOwnDraws() {
        let store = makeStore()
        store.setOwner(1)
        store.add(entry("merry-elf-100"))
        store.setOwner(2)
        XCTAssertTrue(store.items.isEmpty)
        store.add(entry("jolly-star-200"))

        XCTAssertEqual(store.items.map(\.inviteCode), ["jolly-star-200"])
        store.setOwner(1)
        XCTAssertEqual(store.items.map(\.inviteCode), ["merry-elf-100"])
        XCTAssertNil(store.participation(for: "jolly-star-200"))
    }

    func testDrawsJoinedWithoutAnAccountGoToTheNextAccount() {
        let store = makeStore()
        store.setOwner(nil)
        store.add(entry("merry-elf-100"))
        XCTAssertEqual(store.items.count, 1)

        store.setOwner(7)
        XCTAssertEqual(store.items.map(\.ownerId), [7])
        store.setOwner(nil)
        XCTAssertTrue(store.items.isEmpty)
        store.setOwner(8)
        XCTAssertTrue(store.items.isEmpty)
    }

    func testTheSameDrawCanBeJoinedByTwoAccounts() {
        let store = makeStore()
        store.setOwner(1)
        store.add(entry("merry-elf-100"))
        store.setOwner(2)
        store.add(entry("merry-elf-100"))
        store.remove("merry-elf-100")

        XCTAssertTrue(store.items.isEmpty)
        store.setOwner(1)
        XCTAssertEqual(store.items.count, 1)
    }

    /// The Keychain is not available to unsigned simulator tests, so check the stored format instead.
    func testOwnerIsStoredAndOlderEntriesStillDecode() throws {
        var stored = entry("merry-elf-100")
        stored.ownerId = 3
        let roundTrip = try JSONCoding.decoder.decode(Participation.self, from: JSONCoding.encoder.encode(stored))
        XCTAssertEqual(roundTrip.ownerId, 3)

        var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONCoding.encoder.encode(entry("jolly-star-200"))) as? [String: Any])
        legacy.removeValue(forKey: "ownerId")
        let decoded = try JSONCoding.decoder.decode(Participation.self, from: JSONSerialization.data(withJSONObject: legacy))
        XCTAssertNil(decoded.ownerId)
        XCTAssertEqual(decoded.inviteCode, "jolly-star-200")
    }
}
