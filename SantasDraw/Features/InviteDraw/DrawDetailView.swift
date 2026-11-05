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

    init(inviteCode: String, api: APIClient) {
        _store = State(initialValue: DrawDetailStore(inviteCode: inviteCode, api: api))
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            content
        }
        .background(Palette.page.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await store.load(t) }
        .sheet(isPresented: $showSchedule) {
            ScheduleSheet(store: store)
                .presentationDetents([.medium])
        }
        .confirmationDialog(t.runDraw, isPresented: $confirmExecute, titleVisibility: .visible) {
            Button(t.runDraw) {
                Task { executed = await store.execute(t) }
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
                        .font(.system(size: 12))
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
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(draw.inviteCode ?? "#\(draw.id)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                StatusChip(title: draw.status.title(t), foreground: draw.status.foreground, background: draw.status.background)
            }
            Text("\(t.inviteMode) · \(t.drawOn) \(draw.drawDate.map { DrawDateFormat.long($0, language: settings.language) } ?? t.noDrawDate)")
                .font(.system(size: 14))
                .foregroundStyle(Palette.sub)
        }
        .padding(.horizontal, 8)
    }

    private var shareCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                QRCodeView(content: store.inviteURL.absoluteString)
                    .padding(4)
                    .frame(width: 72, height: 72)
                    .background(.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Color(hex: 0xE2E8F0)))
                VStack(alignment: .leading, spacing: 3) {
                    Text(t.shareTitle).font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.text)
                    Text(store.inviteURL.absoluteString.replacingOccurrences(of: "https://", with: ""))
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.sub)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text(t.qrHint).font(.system(size: 12)).foregroundStyle(Palette.ter)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 8) {
                ShareLink(item: store.inviteURL) {
                    Label(t.share, systemImage: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(.white)
                        .background(Palette.brand, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                Button {
                    UIPasteboard.general.url = store.inviteURL
                    copied = true
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        copied = false
                    }
                } label: {
                    Label(copied ? t.copied : t.copy, systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(Palette.brandText)
                        .background(Palette.chip, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.success, trigger: copied) { _, new in new }
            }
        }
        .padding(16)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.sep))
    }

    private func participantsHeader(_ draw: DrawDetail) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(t.participants).font(.system(size: 20, weight: .bold)).foregroundStyle(Palette.text)
                + Text(" · \(draw.participants.count)").font(.system(size: 20, weight: .medium)).foregroundStyle(Palette.sub)
            Spacer()
            Button {
                Task { await store.load(t) }
            } label: {
                Label(t.refresh, systemImage: "arrow.clockwise").font(.system(size: 15, weight: .medium))
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
                Banner(text: t.statusCompleted, style: .success)
            } else {
                Button(store.canExecute ? t.readyForDraw : t.runDraw) { confirmExecute = true }
                    .buttonStyle(PrimaryButtonStyle(background: Palette.green, isLoading: store.isWorking))
                    .disabled(!store.canExecute || store.isWorking)
                    .accessibilityIdentifier("detail.execute")
                Text(store.canExecute ? (draw.drawDate != nil ? t.readyForDrawMsg : "") : t.minHint)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.sub)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Palette.page)
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
                    Text(participant.fullName).font(.system(size: 16, weight: .semibold)).foregroundStyle(Palette.text)
                    if isOrganizer {
                        Image(systemName: "crown.fill").font(.system(size: 11)).foregroundStyle(Palette.amber)
                    }
                }
                Text(participant.email).font(.system(size: 13)).foregroundStyle(Palette.sub).lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

struct Avatar: View {
    let initials: String

    var body: some View {
        Text(initials)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 40, height: 40)
            .background(LinearGradient(colors: [Color(hex: 0xFF6467), Color(hex: 0xE7000B)], startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
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
