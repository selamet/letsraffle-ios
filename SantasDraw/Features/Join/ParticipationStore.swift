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
}

/// Persists joined draws in the Keychain (they contain participant tokens).
@MainActor
@Observable
final class ParticipationStore {
    private(set) var items: [Participation] = []
    private let service: String
    private let account = "participations"

    init(service: String = "com.letsraffle.ios.participations") {
        self.service = service
        load()
    }

    func add(_ participation: Participation) {
        items.removeAll { $0.inviteCode == participation.inviteCode }
        items.insert(participation, at: 0)
        save()
    }

    func participation(for inviteCode: String) -> Participation? {
        items.first { $0.inviteCode == inviteCode }
    }

    func storeResult(_ result: MatchResult, for inviteCode: String) {
        guard let index = items.firstIndex(where: { $0.inviteCode == inviteCode }) else { return }
        items[index].result = result
        save()
    }

    func remove(_ inviteCode: String) {
        items.removeAll { $0.inviteCode == inviteCode }
        save()
    }

    func removeAll() {
        items = []
        save()
    }

    private func load() {
        guard let data = Keychain.read(service: service, account: account),
              let decoded = try? JSONCoding.decoder.decode([Participation].self, from: data) else { return }
        items = decoded
        WidgetSync.shared.update(participations: items)
    }

    private func save() {
        WidgetSync.shared.update(participations: items)
        if let data = try? JSONCoding.encoder.encode(items) {
            Keychain.write(data, service: service, account: account)
        }
    }
}
