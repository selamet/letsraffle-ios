import Foundation
import Observation

/// Loads and caches the organizer's draw list.
@MainActor
@Observable
final class DrawsStore {
    enum Phase: Equatable {
        case idle, loading, loaded, failed(String)
    }

    private(set) var draws: [DrawListItem] = []
    private(set) var phase: Phase = .idle

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    /// Draws still waiting to be executed come first, newest first (backend order).
    var activeFirst: [DrawListItem] {
        draws.filter { $0.status == .active || $0.status == .inProgress }
            + draws.filter { $0.status != .active && $0.status != .inProgress }
    }

    func load(_ t: Strings) async {
        if draws.isEmpty { phase = .loading }
        do {
            draws = try await api.send(API.draws())
            phase = .loaded
        } catch is CancellationError {
            // View went away; keep the current state.
        } catch {
            phase = .failed(error.userMessage(t))
        }
    }

    func reset() {
        draws = []
        phase = .idle
    }
}
