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
        case .completed: Palette.sub
        case .cancelled, .unknown: Palette.ter
        }
    }

    var background: Color {
        switch self {
        case .active: Palette.greenSoft
        case .inProgress: Palette.amberSoft
        case .completed: Color(light: 0xF1E6DC, dark: 0x3A2A2A)
        case .cancelled, .unknown: Palette.sep
        }
    }
}

extension DrawType {
    func title(_ t: Strings) -> String {
        self == .dynamic ? t.typeInvite : t.typeManual
    }

    var icon: String { self == .dynamic ? "link" : "person.3.fill" }
    var iconForeground: Color { self == .dynamic ? Palette.brandText : Palette.greenText }
    var iconBackground: Color { self == .dynamic ? Palette.chip : Palette.greenSoft }
}

extension DrawListItem {
    /// Invite draws are named by their memorable invite code; manual draws get a fun,
    /// stable name in the draw's language (same word lists as the backend and web).
    var displayName: String {
        if let code = inviteCode, !code.isEmpty { return code }
        return FunDrawName.make(id: id, language: language)
    }
}

enum FunDrawName {
    private static let trAdjectives = [
        "neseli", "sakar", "uykucu", "obur", "tombik", "haylaz", "geveze", "telasli",
        "pofuduk", "zipzip", "miskin", "sasirmis", "kikirdayan", "havali", "utangac",
        "cilgin", "dalgin", "sirin", "afacan", "mizmiz", "keyifli",
    ]
    private static let trNouns = [
        "rengeyigi", "kardanadam", "noelbaba", "kurabiye", "mandalina", "kestane",
        "salep", "kizak", "yilbasiagaci", "penguen", "hindi", "corap", "zil",
        "yildiz", "hediye", "cuce", "kartopu", "simit", "boza", "pamuk",
    ]
    private static let enAdjectives = [
        "jolly", "merry", "festive", "bright", "shiny", "sparkly", "cheerful", "happy", "cozy",
        "magical", "snowy", "frosty", "gleaming", "twinkling", "radiant", "dazzling", "glowing", "beaming",
    ]
    private static let enNouns = [
        "reindeer", "snowman", "gift", "star", "bell", "tree", "santa", "elf", "candy",
        "sleigh", "angel", "wreath", "snowflake", "gingerbread", "stocking", "ornament", "mistletoe", "carol",
    ]

    static func make(id: Int, language: String) -> String {
        let tr = language.uppercased() == "TR"
        let adjectives = tr ? trAdjectives : enAdjectives
        let nouns = tr ? trNouns : enNouns
        let n = abs(id)
        return "\(adjectives[(n * 7 + 3) % adjectives.count])-\(nouns[(n * 13 + 5) % nouns.count])-\(100 + (n * 37) % 900)"
    }
}

enum DrawDateFormat {
    /// "24 Aralık 2026 20:00" / "Dec 24, 2026 at 20:00"
    static func long(_ date: Date, language: AppLanguage) -> String {
        date.formatted(
            .dateTime.day().month(.wide).year().hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)
                .locale(language.locale)
        )
    }

    static func short(_ date: Date, language: AppLanguage) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(language.locale))
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
                .frame(width: 46, height: 46)
                .background(draw.drawType.iconBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(draw.displayName)
                    .font(AppFont.display(17))
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                Text("\(draw.drawType.title(t)) · \(t.participantCount(draw.participantCount))")
                    .font(AppFont.body(13, .semibold))
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
        .padding(14)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Palette.cardBorder, lineWidth: 2))
    }
}
