import SwiftUI
import WidgetKit

@main
struct SantasDrawWidgetBundle: WidgetBundle {
    var body: some Widget {
        NextDrawWidget()
        MatchWidget()
        ActiveDrawsWidget()
    }
}

// MARK: - Timeline

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot

    var strings: WidgetStrings { .forLanguage(snapshot.language) }
}

struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: .now, snapshot: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        let snapshot = WidgetSnapshot.load()
        completion(SnapshotEntry(date: .now, snapshot: context.isPreview && snapshot.nextDraw == nil ? .preview : snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        // Refresh after midnight so the day counter stays correct; the app reloads on changes.
        let entry = SnapshotEntry(date: .now, snapshot: WidgetSnapshot.load())
        let tomorrow = Calendar.current.startOfDay(for: .now.addingTimeInterval(86_400))
        completion(Timeline(entries: [entry], policy: .after(tomorrow)))
    }
}

extension WidgetSnapshot {
    static let preview = WidgetSnapshot(
        language: "TR",
        nextDraw: .init(inviteCode: "jolly-reindeer-742", date: .now.addingTimeInterval(12 * 86_400)),
        match: .init(inviteCode: "jolly-reindeer-742", initials: "EY"),
        activeDraws: [
            .init(name: "jolly-reindeer-742", isInvite: true, participantCount: 8, status: "active"),
            .init(name: "#12", isInvite: false, participantCount: 5, status: "completed"),
        ]
    )
}

// MARK: - Next draw

struct NextDrawWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NextDrawWidget", provider: SnapshotProvider()) { entry in
            NextDrawView(entry: entry)
        }
        .configurationDisplayName("Santa's Draw")
        .description("Sonraki çekilişe kalan gün · Days until your next draw")
        .supportedFamilies([.systemSmall, .accessoryRectangular, .accessoryCircular])
    }
}

struct NextDrawView: View {
    let entry: SnapshotEntry
    @Environment(\.widgetFamily) private var family

    private var days: Int? { entry.snapshot.nextDraw.map { WidgetSnapshot.daysLeft(until: $0.date, from: entry.date) } }

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                Gauge(value: Double(max(0, 30 - (days ?? 30))), in: 0...30) {
                    Text("🎅")
                } currentValueLabel: {
                    Text(days.map(String.init) ?? "–")
                }
                .gaugeStyle(.accessoryCircularCapacity)
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 1) {
                    Text("🎅 \(entry.strings.nextDraw)").font(.caption2.weight(.semibold))
                    Text(days.map { $0 == 0 ? entry.strings.today : "\($0) \(entry.strings.daysLeft)" } ?? entry.strings.noDraws)
                        .font(.headline)
                    if let code = entry.snapshot.nextDraw?.inviteCode {
                        Text(code).font(.caption2).lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            default:
                small
            }
        }
        .widgetURL(entry.snapshot.nextDraw.map { WidgetLink.draw($0.inviteCode) } ?? WidgetLink.home)
        .containerBackground(for: .widget) {
            if family == .systemSmall {
                LinearGradient(colors: [Color(hex: 0xE7000B), Color(hex: 0x9F0712)], startPoint: .topLeading, endPoint: .bottomTrailing)
            } else {
                Color.clear
            }
        }
    }

    private var small: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(entry.strings.nextDraw)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.5)
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 4)
                Text("🎅").font(.system(size: 12)).frame(width: 22, height: 22).background(.white, in: Circle())
            }
            Spacer(minLength: 0)
            if let days {
                Text(days == 0 ? "🎄" : "\(days)")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.white)
                Text(days == 0 ? entry.strings.today : entry.strings.daysLeft)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(entry.snapshot.nextDraw?.inviteCode ?? "")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
            } else {
                Text(entry.strings.noDraws).font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
            }
        }
        .background(alignment: .bottomTrailing) {
            ChristmasTree(variant: .small).scaleEffect(0.45).opacity(0.3).offset(x: 60, y: 90)
        }
    }
}

// MARK: - Match (hidden until tapped in the app)

struct MatchWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MatchWidget", provider: SnapshotProvider()) { entry in
            MatchView(entry: entry)
        }
        .configurationDisplayName("Santa's Draw")
        .description("Eşleşmen · Your match")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

struct MatchView: View {
    let entry: SnapshotEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if family == .accessoryRectangular {
                VStack(alignment: .leading, spacing: 1) {
                    Text("🎁 \(entry.strings.match)").font(.caption2.weight(.semibold))
                    Text(entry.snapshot.match == nil ? entry.strings.noDraws : entry.strings.tapToReveal).font(.headline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading) {
                    HStack {
                        Text(entry.strings.match)
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1.5)
                            .textCase(.uppercase)
                            .foregroundStyle(Palette.brandText)
                        Spacer()
                        Text("🎁").font(.system(size: 14))
                    }
                    Spacer(minLength: 0)
                    // Initials are blurred: the match stays secret on the Home Screen.
                    Text(entry.snapshot.match?.initials ?? "?")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(LinearGradient(colors: [Color(hex: 0xFF6467), Color(hex: 0xE7000B)], startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
                        .blur(radius: entry.snapshot.match == nil ? 0 : 4)
                    Text("••••••")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Palette.text)
                    Text(entry.snapshot.match == nil ? entry.strings.noDraws : entry.strings.tapToReveal)
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.sub)
                }
            }
        }
        .widgetURL(entry.snapshot.match.map { WidgetLink.reveal($0.inviteCode) } ?? WidgetLink.home)
        .containerBackground(Palette.card, for: .widget)
    }
}

// MARK: - Active draws (organizer)

struct ActiveDrawsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ActiveDrawsWidget", provider: SnapshotProvider()) { entry in
            ActiveDrawsView(entry: entry)
        }
        .configurationDisplayName("Santa's Draw")
        .description("Aktif Etkinliklerim · My Active Draws")
        .supportedFamilies([.systemMedium])
    }
}

struct ActiveDrawsView: View {
    let entry: SnapshotEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(entry.strings.activeDraws)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.5)
                    .textCase(.uppercase)
                    .foregroundStyle(Palette.brandText)
                Spacer()
                Text("Santa's Draw").font(.system(size: 11, weight: .semibold)).foregroundStyle(Palette.sub)
            }
            if entry.snapshot.activeDraws.isEmpty {
                Spacer()
                Text(entry.strings.noDraws).font(.subheadline).foregroundStyle(Palette.sub)
                Spacer()
            }
            ForEach(entry.snapshot.activeDraws.prefix(3)) { draw in
                HStack(spacing: 10) {
                    Text("\(draw.participantCount)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(draw.isInvite ? Palette.blueText : Palette.brandText)
                        .frame(width: 30, height: 30)
                        .background(draw.isInvite ? Palette.blueSoft : Palette.chip, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: 0) {
                        Text(draw.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(Palette.text).lineLimit(1)
                        Text(draw.isInvite ? entry.strings.invite : entry.strings.manual).font(.system(size: 11)).foregroundStyle(Palette.sub)
                    }
                    Spacer(minLength: 4)
                    Text(entry.strings.statuses[draw.status] ?? draw.status)
                        .font(.system(size: 9, weight: .bold))
                        .textCase(.uppercase)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .foregroundStyle(statusColors(draw.status).0)
                        .background(statusColors(draw.status).1, in: Capsule())
                }
            }
            Spacer(minLength: 0)
        }
        .widgetURL(WidgetLink.home)
        .containerBackground(Palette.card, for: .widget)
    }

    private func statusColors(_ status: String) -> (Color, Color) {
        switch status {
        case "active": (Palette.greenText, Palette.greenSoft)
        case "in_progress": (Palette.amberText, Palette.amberSoft)
        case "completed": (Palette.blueText, Palette.blueSoft)
        default: (Palette.sub, Palette.sep)
        }
    }
}

#Preview(as: .systemSmall) {
    NextDrawWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .preview)
}
