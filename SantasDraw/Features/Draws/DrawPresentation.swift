import SwiftUI

extension DrawStatus {
    func title(_ t: Strings) -> String {
        switch self {
        case .active: t.statusActive
        case .inProgress: t.statusInProgress
        case .completed: t.statusCompleted
        case .cancelled: t.statusCancelled
        case .unknown: "—"
        }
    }

    var foreground: Color {
        switch self {
        case .active: Palette.greenText
        case .inProgress: Palette.amberText
        case .completed: Palette.blueText
        case .cancelled, .unknown: Palette.sub
        }
    }

    var background: Color {
        switch self {
        case .active: Palette.greenSoft
        case .inProgress: Palette.amberSoft
        case .completed: Palette.blueSoft
        case .cancelled, .unknown: Palette.sep
        }
    }
}

extension DrawType {
    func title(_ t: Strings) -> String {
        self == .dynamic ? t.typeInvite : t.typeManual
    }

    var icon: String { self == .dynamic ? "link" : "person.3.fill" }
    var iconForeground: Color { self == .dynamic ? Palette.blueText : Palette.brandText }
    var iconBackground: Color { self == .dynamic ? Palette.blueSoft : Palette.chip }
}

extension DrawListItem {
    /// Invite draws are named by their memorable invite code; manual draws by id.
    var displayName: String { inviteCode ?? "#\(id)" }
}

enum DrawDateFormat {
    /// "24 Aralık 2026 20:00" / "Dec 24, 2026 at 20:00"
    static func long(_ date: Date, language: AppLanguage) -> String {
        date.formatted(
            .dateTime.day().month(.wide).year().hour(.twoDigits(amPM: .omitted)).minute()
                .locale(language.locale)
        )
    }

    static func short(_ date: Date, language: AppLanguage) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).hour(.twoDigits(amPM: .omitted)).minute().locale(language.locale))
    }
}

struct DrawRow: View {
    let draw: DrawListItem
    @Environment(\.strings) private var t

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: draw.drawType.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(draw.drawType.iconForeground)
                .frame(width: 44, height: 44)
                .background(draw.drawType.iconBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(draw.displayName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                Text("\(draw.drawType.title(t)) · \(t.participantCount(draw.participantCount))")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.sub)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 6) {
                StatusChip(title: draw.status.title(t), foreground: draw.status.foreground, background: draw.status.background)
                if draw.drawType == .dynamic {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.ter)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.sep, lineWidth: 1))
    }
}
