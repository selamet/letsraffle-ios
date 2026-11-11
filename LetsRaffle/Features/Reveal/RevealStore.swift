import Foundation
import Observation

/// Loads the current user's match for a draw.
///
/// Uses the participant token stored when joining/creating on this device and
/// falls back to the organizer endpoint for draws created on another device.
@MainActor
@Observable
final class RevealStore {
    enum Phase: Equatable {
        case loading
        /// Draw has not been executed yet (409).
        case waiting
        case revealed(MatchResult)
        case failed(String)
    }

    let inviteCode: String
    private(set) var phase: Phase = .loading

    private let api: APIClient
    private let participations: ParticipationStore
    private let isSignedIn: Bool

    init(inviteCode: String, api: APIClient, participations: ParticipationStore, isSignedIn: Bool) {
        self.inviteCode = inviteCode
        self.api = api
        self.participations = participations
        self.isSignedIn = isSignedIn
    }

    var drawDate: Date? { participations.participation(for: inviteCode)?.drawDate }

    /// First name of the person looking at the reveal (from the join form), when known.
    var firstName: String? {
        guard let name = participations.participation(for: inviteCode)?.displayName
            .split(separator: " ").first.map(String.init), !name.isEmpty else { return nil }
        return name
    }

    func load(_ t: Strings) async {
        #if DEBUG
        // Visual QA without a backend: `-revealDemo YES`
        if UserDefaults.standard.bool(forKey: "revealDemo") {
            phase = .revealed(MatchResult(
                drawId: 7, inviteCode: inviteCode,
                receiver: .init(firstName: "Mehmet", lastName: "Kaya", address: "Bağdat Cad. No:12 D:5, Kadıköy / İstanbul", phone: "+90 532 123 45 67")
            ))
            return
        }
        #endif
        let participation = participations.participation(for: inviteCode)
        if let cached = participation?.result {
            phase = .revealed(cached)
        }

        do {
            let result: MatchResult
            if let token = participation?.participantToken {
                result = try await api.send(API.participantResult(token: token))
            } else if isSignedIn {
                result = try await api.send(API.organizerResult(inviteCode: inviteCode))
            } else {
                phase = .failed(t.genericError)
                return
            }
            participations.storeResult(result, for: inviteCode)
            phase = .revealed(result)
        } catch APIError.server(status: 409, _) {
            phase = .waiting
        } catch is CancellationError {
        } catch {
            // Keep a cached result visible when offline.
            if case .revealed = phase { return }
            phase = .failed(error.userMessage(t))
        }
    }
}
