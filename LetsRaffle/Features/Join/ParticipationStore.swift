import Foundation
import Observation

/// A draw this device joined as a participant.
struct Participation: Codable, Identifiable, Equatable, Hashable {
    var id: String { inviteCode }
    let inviteCode: String
    /// Unknown for the organizer's own entry (create response has no participant id).
    let participantId: Int?
    let drawId: Int
    let displayName: String
    var drawDate: Date?
    /// Secret token from letsraffle-api#60, used for the in-app result and push registration.
    var participantToken: String?
    var wantsNotification: Bool
    let joinedAt: Date
    /// Cached once revealed so the result (and widget) work offline.
    var result: MatchResult?
    /// The account that joined on this device; `nil` for a join made without an account.
    var ownerId: Int?
}

/// Persists joined draws in the Keychain (they contain participant tokens).
///
/// One device can be used with several accounts, so every entry remembers the account that
/// joined, and only the signed-in account's entries are visible (`items`). Joins made without an
/// account belong to whoever signs in next on this device.
@MainActor
@Observable
final class ParticipationStore {
    /// Every entry on this device, for all accounts.
    private var all: [Participation] = []
    /// The signed-in account, or `nil` when using the app without one.
    private(set) var ownerId: Int?
    private let service: String
    private let account = "participations"

    init(service: String = "com.letsraffle.ios.participations") {
        self.service = service
        load()
    }

    /// The current account's draws (or, without an account, the draws joined without one).
    var items: [Participation] { all.filter { $0.ownerId == ownerId } }

    /// Switches to another account. Entries without an owner (joined without an account, or saved
    /// before entries had owners) are handed to the account that signs in.
    func setOwner(_ id: Int?) {
        var changed = false
        if let id {
            for index in all.indices where all[index].ownerId == nil {
                if all.contains(where: { $0.ownerId == id && $0.inviteCode == all[index].inviteCode }) { continue }
                all[index].ownerId = id
                changed = true
            }
        }
        guard changed || ownerId != id else { return }
        ownerId = id
        changed ? save() : WidgetSync.shared.update(participations: items)
    }

    func add(_ participation: Participation) {
        var participation = participation
        participation.ownerId = ownerId
        all.removeAll { $0.inviteCode == participation.inviteCode && $0.ownerId == ownerId }
        all.insert(participation, at: 0)
        save()
    }

    func participation(for inviteCode: String) -> Participation? {
        items.first { $0.inviteCode == inviteCode }
    }

    func storeResult(_ result: MatchResult, for inviteCode: String) {
        guard let index = all.firstIndex(where: { $0.inviteCode == inviteCode && $0.ownerId == ownerId }) else { return }
        all[index].result = result
        save()
    }

    func remove(_ inviteCode: String) {
        all.removeAll { $0.inviteCode == inviteCode && $0.ownerId == ownerId }
        save()
    }

    /// Removes the current account's entries; other accounts on this device keep theirs.
    func removeAll() {
        all.removeAll { $0.ownerId == ownerId }
        save()
    }

    private func load() {
        guard let data = Keychain.read(service: service, account: account),
              let decoded = try? JSONCoding.decoder.decode([Participation].self, from: data) else { return }
        all = decoded
        WidgetSync.shared.update(participations: items)
    }

    private func save() {
        WidgetSync.shared.update(participations: items)
        if let data = try? JSONCoding.encoder.encode(all) {
            Keychain.write(data, service: service, account: account)
        }
    }
}
