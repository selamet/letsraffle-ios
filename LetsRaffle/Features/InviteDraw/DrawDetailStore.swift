import Foundation
import Observation

/// Loads an invite draw and performs organizer actions on it.
@MainActor
@Observable
final class DrawDetailStore {
    enum Phase: Equatable { case loading, loaded, failed(String) }

    let inviteCode: String
    private(set) var draw: DrawDetail?
    private(set) var phase: Phase = .loading
    var actionError: String?
    var isWorking = false

    private let api: APIClient

    init(inviteCode: String, api: APIClient) {
        self.inviteCode = inviteCode
        self.api = api
    }

    static let minimumParticipants = 3

    var inviteURL: URL { AppConfig.inviteURL(for: inviteCode) }

    /// The backend treats the earliest participant as the organizer; it can't be removed.
    var organizerId: Int? {
        draw?.participants.min { $0.createdAt < $1.createdAt }?.id
    }

    var canExecute: Bool {
        guard let draw else { return false }
        return draw.status != .completed && draw.status != .inProgress && draw.participants.count >= Self.minimumParticipants
    }

    var isEditable: Bool {
        guard let draw else { return false }
        return draw.status == .active
    }

    func load(_ t: Strings) async {
        #if DEBUG
        // Visual QA without a backend: `-detailDemo YES`
        if UserDefaults.standard.bool(forKey: "detailDemo") {
            draw = DrawDetail(id: 7, drawType: .dynamic, status: .active, inviteCode: inviteCode, requireAddress: false,
                              requirePhone: false, drawDate: nil, createdAt: .now, language: "TR", participants: [])
            phase = .loaded
            return
        }
        #endif
        do {
            draw = try await api.send(API.drawDetail(inviteCode: inviteCode))
            phase = .loaded
        } catch is CancellationError {
        } catch {
            if draw == nil { phase = .failed(error.userMessage(t)) } else { actionError = error.userMessage(t) }
        }
    }

    func remove(_ participant: Participant, _ t: Strings) async {
        guard let draw, participant.id != organizerId else { return }
        // Optimistic removal; reload on failure.
        self.draw = draw.removing(participant.id)
        do {
            _ = try await api.send(API.deleteParticipant(drawId: draw.id, participantId: participant.id))
        } catch {
            actionError = error.userMessage(t)
            self.draw = draw
        }
    }

    func updateSchedule(_ date: Date?, _ t: Strings) async -> Bool {
        guard let draw else { return false }
        isWorking = true
        defer { isWorking = false }
        do {
            _ = try await api.send(API.updateSchedule(drawId: draw.id, date: date.map { InviteDraft.exactHour($0) }))
            await load(t)
            return true
        } catch {
            actionError = error.userMessage(t)
            return false
        }
    }

    func execute(_ t: Strings) async -> Bool {
        guard let draw, canExecute else { return false }
        isWorking = true
        defer { isWorking = false }
        do {
            _ = try await api.send(API.executeDraw(drawId: draw.id))
            await load(t)
            return true
        } catch {
            actionError = error.userMessage(t)
            return false
        }
    }
}

private extension DrawDetail {
    func removing(_ participantId: Int) -> DrawDetail {
        DrawDetail(
            id: id, drawType: drawType, status: status, inviteCode: inviteCode,
            requireAddress: requireAddress, requirePhone: requirePhone, drawDate: drawDate,
            createdAt: createdAt, language: language,
            participants: participants.filter { $0.id != participantId }
        )
    }
}
