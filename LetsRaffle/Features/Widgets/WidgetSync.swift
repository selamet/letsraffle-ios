import Foundation
import WidgetKit

/// Keeps the App Group widget snapshot in sync with app state.
@MainActor
final class WidgetSync {
    /// Under unit tests the shared instance is inert so tests never touch the real App Group.
    static let shared: WidgetSync = NSClassFromString("XCTestCase") == nil
        ? WidgetSync()
        : WidgetSync(defaults: nil, reload: {})

    private var draws: [DrawListItem] = []
    private var participations: [Participation] = []
    private var language: AppLanguage = .tr
    private let defaults: UserDefaults?
    private let reload: () -> Void

    init(defaults: UserDefaults? = UserDefaults(suiteName: WidgetSnapshot.appGroup),
         reload: @escaping () -> Void = { WidgetCenter.shared.reloadAllTimelines() }) {
        self.defaults = defaults
        self.reload = reload
    }

    func update(draws: [DrawListItem]) {
        self.draws = draws
        publish()
    }

    func update(participations: [Participation]) {
        self.participations = participations
        publish()
    }

    func update(language: AppLanguage) {
        self.language = language
        publish()
    }

    /// Builds the snapshot from the current inputs.
    func makeSnapshot(now: Date = .now) -> WidgetSnapshot {
        let organizerDates = draws
            .filter { $0.status == .active }
            .compactMap { draw in draw.drawDate.map { (draw.inviteCode ?? draw.displayName, $0) } }
        let participantDates = participations
            .filter { $0.result == nil }
            .compactMap { p in p.drawDate.map { (p.inviteCode, $0) } }
        let next = (organizerDates + participantDates)
            .filter { $0.1 > now }
            .min { $0.1 < $1.1 }

        let revealed = participations.first { $0.result != nil }
        let match = revealed.flatMap { p in
            p.result.map { WidgetSnapshot.Match(inviteCode: p.inviteCode, initials: Participant.initials($0.receiver.firstName, $0.receiver.lastName)) }
        }

        return WidgetSnapshot(
            language: language.rawValue,
            nextDraw: next.map { WidgetSnapshot.NextDraw(inviteCode: $0.0, date: $0.1) },
            match: match,
            activeDraws: draws.prefix(3).map {
                WidgetSnapshot.Draw(name: $0.displayName, isInvite: $0.drawType == .dynamic,
                                    participantCount: $0.participantCount, status: $0.status.rawValue)
            }
        )
    }

    private func publish() {
        let snapshot = makeSnapshot()
        guard snapshot != WidgetSnapshot.load(from: defaults) else { return }
        snapshot.save(to: defaults)
        reload()
    }
}
