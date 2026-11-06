import SwiftUI

/// Organizer view of an invite draw: share link/QR, participants, schedule, run.
struct DrawDetailView: View {
    @State private var store: DrawDetailStore
    @Environment(\.strings) private var t
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings

    @State private var copied = false
    @State private var showSchedule = false
    @State private var confirmExecute = false
    @State private var executed = false
    @State private var showDrawing = false

    private let onReveal: () -> Void

    init(inviteCode: String, api: APIClient, onReveal: @escaping () -> Void = {}) {
        _store = State(initialValue: DrawDetailStore(inviteCode: inviteCode, api: api))
        self.onReveal = onReveal
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            content
        }
        .background(Palette.page.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .statusBarStyle(.darkContent)
        .task { await store.load(t) }
        .fullScreenCover(isPresented: $showDrawing) {
            ManualSuccessView { showDrawing = false }
                .statusBarStyle(.lightContent)
                .onDisappear { StatusBar.set(.darkContent) }
        }
        .sheet(isPresented: $showSchedule) {
            ScheduleSheet(store: store)
                .presentationDetents([.medium])
        }
        .confirmationDialog(t.runDraw, isPresented: $confirmExecute, titleVisibility: .visible) {
            Button(t.runDraw) {
                Task {
                    executed = await store.execute(t)
                    if executed { showDrawing = true }
                }
            }
            Button(t.cancel, role: .cancel) {}
        } message: {
            Text(t.minHint)
        }
        .alert(t.genericError, isPresented: Binding(get: { store.actionError != nil }, set: { if !$0 { store.actionError = nil } })) {
            Button(t.ok) {}
        } message: {
            Text(store.actionError ?? "")
        }
    }

    private var topBar: some View {
        HStack {
            CircleIconButton { dismiss() }
            Spacer()
            if let draw = store.draw {
                StatusChip(title: draw.status.title(t), foreground: draw.status.foreground, background: draw.status.background)
            }
            if store.isEditable {
                CircleIconButton(systemName: "calendar.badge.clock") { showSchedule = true }
                    .accessibilityLabel(t.editDate)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var content: some View {
        switch store.phase {
        case .loading:
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .failed(message):
            VStack(spacing: 12) {
                Banner(text: message, style: .error)
                Button(t.retry) { Task { await store.load(t) } }.foregroundStyle(Palette.brandText)
            }
            .padding(20)
            .frame(maxHeight: .infinity, alignment: .top)
        case .loaded:
            if let draw = store.draw {
                loaded(draw)
            }
        }
    }

    private func loaded(_ draw: DrawDetail) -> some View {
        List {
            Section {
                header(draw)
                shareCard
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            .listRowSeparator(.hidden)

            Section {
                ForEach(draw.participants) { participant in
                    ParticipantRow(participant: participant, isOrganizer: participant.id == store.organizerId)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if store.isEditable && participant.id != store.organizerId {
                                Button(t.delete, role: .destructive) {
                                    Task { await store.remove(participant, t) }
                                }
                            }
                        }
                }
                .listRowBackground(Palette.card)
                .alignmentGuide(.listRowSeparatorLeading) { _ in 52 }
            } header: {
                participantsHeader(draw)
            } footer: {
                if store.isEditable && draw.participants.count > 1 {
                    Text("← \(t.swipeHint)")
                        .font(AppFont.body(12, .semibold))
                        .foregroundStyle(Palette.ter)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 4, for: .scrollContent)
        .refreshable { await store.load(t) }
        .safeAreaInset(edge: .bottom) { bottomAction(draw) }
    }

    private func header(_ draw: DrawDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(t.inviteModeTitle)
                    .font(AppFont.body(12, .black))
                    .tracking(1.6)
                    .textCase(.uppercase)
                    .foregroundStyle(Palette.brandText)
                Text(draw.inviteCode ?? "#\(draw.id)")
                    .font(AppFont.display(28))
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 4)
            countdown(draw)
        }
    }

    private func countdown(_ draw: DrawDetail) -> some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            let remaining = max(0, (draw.drawDate ?? context.date).timeIntervalSince(context.date))
            VStack(alignment: .leading, spacing: 4) {
                Text(draw.drawDate == nil ? t.noDrawDate : t.drawOn)
                    .font(AppFont.script(30))
                    .foregroundStyle(Palette.goldLight)
                Text(draw.drawDate.map { DrawDateFormat.long($0, language: settings.language) } ?? t.inviteModeDesc)
                    .font(AppFont.body(13, .bold))
                    .foregroundStyle(Palette.snow.opacity(0.88))
                    .padding(.bottom, 8)
                    .padding(.trailing, 110)
                if draw.drawDate != nil {
                    HStack(spacing: 8) {
                        countBox(Int(remaining) / 86_400, t.daysUnit)
                        countBox(Int(remaining) % 86_400 / 3_600, t.hoursUnit)
                        countBox(Int(remaining) % 3_600 / 60, t.minutesUnit)
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.heroGradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Palette.gold, lineWidth: 2))
            .overlay(alignment: .bottomTrailing) {
                SantaAvatar(size: 112, mood: .watch).padding(.trailing, 2).padding(.bottom, 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color(hex: 0x6E0D12, alpha: 0.26), radius: 15, y: 12)
        }
    }

    private func countBox(_ value: Int, _ unit: String) -> some View {
        VStack(spacing: 0) {
            Text(String(format: "%02d", value)).font(AppFont.display(24)).foregroundStyle(Palette.brandText)
            Text(unit).font(AppFont.body(11, .bold)).foregroundStyle(Palette.sub)
        }
        .frame(width: 64)
        .padding(.vertical, 8)
        .background(Palette.snow, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .background(Palette.goldDark, in: RoundedRectangle(cornerRadius: 14, style: .continuous).offset(y: 4))
    }

    private var shareCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(t.shareTitle).font(AppFont.script(28)).foregroundStyle(Palette.goldLight)
                    Text(t.qrHint).font(AppFont.body(13, .bold)).foregroundStyle(Palette.snow.opacity(0.9))
                }
                Spacer(minLength: 0)
                QRCodeView(content: store.inviteURL.absoluteString)
                    .padding(5)
                    .frame(width: 74, height: 74)
                    .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Palette.gold, lineWidth: 2))
            }
            HStack(spacing: 8) {
                Text(store.inviteURL.absoluteString.replacingOccurrences(of: "https://", with: ""))
                    .font(AppFont.body(14, .bold))
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 0)
                Button {
                    UIPasteboard.general.url = store.inviteURL
                    copied = true
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        copied = false
                    }
                } label: {
                    Label(copied ? t.copied : t.copy, systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(AppFont.body(13, .black))
                        .foregroundStyle(Palette.brandText)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 44)
                        .background(Palette.chip, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.success, trigger: copied) { _, new in new }
            }
            .padding(.leading, 14)
            .padding(.trailing, 6)
            .padding(.vertical, 6)
            .background(Palette.snow, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            ShareLink(item: store.inviteURL) {
                Label(t.share, systemImage: "square.and.arrow.up")
                    .font(.buttonLabel)
                    .foregroundStyle(Palette.goldText)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Palette.goldGradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .background(Palette.goldDark, in: RoundedRectangle(cornerRadius: 16, style: .continuous).offset(y: 4))
                    .padding(.bottom, 4)
            }
        }
        .padding(18)
        .background(alignment: .trailing) {
            ZStack {
                Palette.card2Brand
                Rectangle().fill(Palette.gold.opacity(0.85)).frame(width: 12)
                    .frame(maxWidth: .infinity, alignment: .trailing).padding(.trailing, 40)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Palette.gold, lineWidth: 2))
        .shadow(color: Color(hex: 0x6E0D12, alpha: 0.24), radius: 14, y: 10)
    }

    private func participantsHeader(_ draw: DrawDetail) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(t.participants).font(AppFont.display(19)).foregroundStyle(Palette.text)
                + Text(" · \(draw.participants.count)").font(AppFont.body(17, .bold)).foregroundStyle(Palette.sub)
            Spacer()
            Button {
                Task { await store.load(t) }
            } label: {
                Label(t.refresh, systemImage: "arrow.clockwise").font(AppFont.body(14, .bold))
            }
            .foregroundStyle(Palette.brandText)
        }
        .textCase(nil)
        .padding(.horizontal, -16)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func bottomAction(_ draw: DrawDetail) -> some View {
        VStack(spacing: 8) {
            if executed || draw.status == .inProgress {
                Banner(text: t.drawStarted, style: .success)
            } else if draw.status == .completed {
                Button {
                    onReveal()
                } label: {
                    Label(t.yourMatch, systemImage: "gift.fill")
                }
                .buttonStyle(.primary)
                .accessibilityIdentifier("detail.reveal")
            } else {
                Button {
                    confirmExecute = true
                } label: {
                    Label(store.canExecute ? t.readyForDraw : t.runDraw, systemImage: "gift.fill")
                }
                    .buttonStyle(PrimaryButtonStyle(isLoading: store.isWorking))
                    .disabled(!store.canExecute || store.isWorking)
                    .accessibilityIdentifier("detail.execute")
                Text(store.canExecute ? (draw.drawDate != nil ? t.readyForDrawMsg : "") : t.minHint)
                    .font(AppFont.body(12, .bold))
                    .foregroundStyle(Palette.sub)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 8)
        .background(
            Palette.card
                .shadow(color: Color(hex: 0x6E0D12, alpha: 0.08), radius: 15, y: -6)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

struct ParticipantRow: View {
    let participant: Participant
    var isOrganizer = false

    var body: some View {
        HStack(spacing: 12) {
            Avatar(initials: participant.initials)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(participant.fullName).font(AppFont.body(16, .bold)).foregroundStyle(Palette.text)
                    if isOrganizer {
                        Image(systemName: "crown.fill").font(.system(size: 11)).foregroundStyle(Palette.amber)
                    }
                }
                Text(participant.email).font(AppFont.body(13, .medium)).foregroundStyle(Palette.sub).lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

struct Avatar: View {
    let initials: String

    private static let colors: [Color] = [Palette.cranberry, Palette.pine, Palette.goldDark, Palette.cranberryDark, Color(hex: 0x2F7A55)]

    var body: some View {
        let index = initials.unicodeScalars.reduce(0) { $0 + Int($1.value) } % Self.colors.count
        Text(initials)
            .font(AppFont.display(15))
            .foregroundStyle(.white)
            .frame(width: 40, height: 40)
            .background(Self.colors[index], in: Circle())
    }
}

extension Participant {
    var initials: String { Self.initials(firstName, lastName) }

    static func initials(_ first: String, _ last: String) -> String {
        (String(first.prefix(1)) + String(last.prefix(1))).uppercased()
    }
}

/// Lets the organizer change or clear the scheduled date.
private struct ScheduleSheet: View {
    let store: DrawDetailStore
    @Environment(\.strings) private var t
    @Environment(\.dismiss) private var dismiss
    @State private var date: Date = InviteDraft.defaultDrawDate(now: .now, calendar: .current)

    var body: some View {
        NavigationStack {
            ScrollView {
                ScheduleEditor(date: $date).padding(16)
            }
            .background(Palette.page)
            .navigationTitle(t.editDate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(t.cancel) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(t.save) {
                        Task { if await store.updateSchedule(date, t) { dismiss() } }
                    }
                    .disabled(date <= .now || store.isWorking)
                }
            }
        }
        .onAppear {
            if let current = store.draw?.drawDate, current > .now { date = current }
        }
    }
}
