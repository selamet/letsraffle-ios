import SwiftUI

enum EventsRoute: Hashable {
    case detail(inviteCode: String)
    case reveal(inviteCode: String)
}

/// Tab 3, "Etkinliklerim": every draw the person created and every draw they joined,
/// in two lists. Created draws open their detail (invite, participants, run the draw);
/// joined ones open the result, or the waiting screen until the draw has run.
struct EventsView: View {
    private enum Segment { case created, joined }

    @Environment(\.strings) private var t
    @Environment(SessionStore.self) private var session
    @Environment(ParticipationStore.self) private var participations
    @Environment(TabBarVisibility.self) private var tabBar
    @Environment(AppSettings.self) private var settings

    @State private var store: DrawsStore?
    @State private var path: [EventsRoute] = []
    @State private var segment: Segment = DebugRoute.current == "tab:events:joined" ? .joined : .created
    @State private var pickedDefault = false

    var body: some View {
        NavigationStack(path: $path) {
            // The red header stays put; the lists scroll in the cream sheet.
            VStack(spacing: 0) {
                header
                VStack(spacing: 0) {
                    segments
                        .padding(.horizontal, 16)
                        .padding(.top, 18)
                        .padding(.bottom, 4)
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            switch segment {
                            case .created: created
                            case .joined: joined
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        .padding(.bottom, 24)
                    }
                    .floatingTabBarInset()
                    .refreshable { await store?.load(t) }
                }
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 34, topTrailingRadius: 34, style: .continuous))
                .background(
                    UnevenRoundedRectangle(topLeadingRadius: 34, topTrailingRadius: 34, style: .continuous)
                        .fill(Palette.page)
                        .shadow(color: Color(hex: 0x320000, alpha: 0.3), radius: 18, y: -8)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
            .background(alignment: .top) {
                ChristmasBackdrop(garland: true, pines: false).frame(height: 420)
            }
            .background(Palette.page.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .statusBarStyle(.lightContent)
            .navigationDestination(for: EventsRoute.self) { route in
                switch route {
                case let .detail(inviteCode):
                    DrawDetailView(inviteCode: inviteCode, api: session.api) { path.append(.reveal(inviteCode: inviteCode)) }
                case let .reveal(inviteCode):
                    RevealView(inviteCode: inviteCode, api: session.api, participations: participations, isSignedIn: session.isSignedIn)
                }
            }
        }
        .task(id: session.user?.id) {
            guard session.isSignedIn else {
                store = nil
                pickDefaultSegment()
                return
            }
            if store == nil { store = DrawsStore(api: session.api) }
            await store?.load(t)
            pickDefaultSegment()
        }
        .onAppear { Task { await store?.load(t) } }
        .onChange(of: path) { _, newPath in
            tabBar.isHidden = !newPath.isEmpty
            // Refresh after coming back from a detail screen.
            if newPath.isEmpty { Task { await store?.load(t) } }
        }
    }

    /// Opens on "joined" the first time when that is the only list with anything in it.
    private func pickDefaultSegment() {
        guard !pickedDefault else { return }
        pickedDefault = true
        if (store?.draws.isEmpty ?? true) && !participations.items.isEmpty { segment = .joined }
    }

    private var header: some View {
        HStack(alignment: .bottom, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(t.tabEvents)
                    .font(AppFont.script(44))
                    .foregroundStyle(Palette.goldLight)
                    .shadow(color: Color(hex: 0x5A0A0F, alpha: 0.4), radius: 0, y: 2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(t.eventsSub)
                    .font(AppFont.body(14, .bold))
                    .foregroundStyle(Palette.snow.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, 16)
            Spacer(minLength: 0)
            SantaAvatar(size: 92, mood: .list)
        }
        .padding(.leading, 22)
        .padding(.trailing, 6)
        .padding(.top, 46)
    }

    private var segments: some View {
        HStack(spacing: 4) {
            segmentButton(.created, t.eventsCreated, count: store?.draws.count ?? 0)
            segmentButton(.joined, t.eventsJoined, count: participations.items.count)
        }
        .padding(4)
        .background(Color(light: 0xF3E6D6, dark: 0x3A2224), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func segmentButton(_ value: Segment, _ title: String, count: Int) -> some View {
        let on = segment == value
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { segment = value }
        } label: {
            HStack(spacing: 6) {
                Text(title)
                    .font(AppFont.body(14, .black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if count > 0 {
                    Text("\(count)")
                        .font(AppFont.body(11, .black))
                        .foregroundStyle(on ? Palette.goldText : Palette.sub)
                        .padding(.horizontal, 6)
                        .frame(minWidth: 20, minHeight: 20)
                        .background(on ? AnyShapeStyle(Palette.goldGradient) : AnyShapeStyle(Palette.card), in: Capsule())
                }
            }
            .foregroundStyle(on ? Palette.snow : Palette.sub)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
            .background {
                if on {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LinearGradient(colors: [Color(hex: 0xD0282F), Palette.cranberry], startPoint: .top, endPoint: .bottom))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Palette.goldLight, lineWidth: 1.5))
                        .shadow(color: Color(hex: 0x6E0D12, alpha: 0.25), radius: 5, y: 3)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    // MARK: Lists

    @ViewBuilder
    private var created: some View {
        if let store {
            switch store.phase {
            case .idle, .loading:
                ChristmasLoader(label: t.loadingDraws).frame(maxWidth: .infinity).padding(.vertical, 20)
            case let .failed(message):
                VStack(spacing: 12) {
                    Banner(text: message, style: .error)
                    Button(t.retry) { Task { await store.load(t) } }
                        .font(AppFont.body(15, .bold))
                        .foregroundStyle(Palette.brandText)
                }
            case .loaded where store.draws.isEmpty:
                EmptyHint(text: t.eventsEmptyCreated)
            case .loaded:
                ForEach(store.activeFirst) { draw in
                    if let code = draw.inviteCode, draw.drawType == .dynamic {
                        NavigationLink(value: EventsRoute.detail(inviteCode: code)) { DrawRow(draw: draw) }
                            .buttonStyle(.plain)
                    } else {
                        DrawRow(draw: draw)
                    }
                }
            }
        } else {
            VStack(spacing: 12) {
                EmptyHint(text: t.guestDrawsHint)
                Button(t.loginBtn) { session.exitGuestMode() }
                    .buttonStyle(.primary)
            }
        }
    }

    @ViewBuilder
    private var joined: some View {
        if participations.items.isEmpty {
            EmptyHint(text: t.eventsEmptyJoined)
        } else {
            ForEach(participations.items) { item in
                NavigationLink(value: EventsRoute.reveal(inviteCode: item.inviteCode)) {
                    HStack(spacing: 12) {
                        Image(systemName: item.result == nil ? "envelope.fill" : "envelope.open.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Palette.brandText)
                            .frame(width: 46, height: 46)
                            .background(Palette.chip, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.inviteCode).font(AppFont.display(17)).foregroundStyle(Palette.text).lineLimit(1)
                            Text(item.drawDate.map { DrawDateFormat.long($0, language: settings.language) } ?? t.noDrawDate)
                                .font(AppFont.body(13, .semibold)).foregroundStyle(Palette.sub)
                        }
                        Spacer(minLength: 8)
                        if item.result != nil {
                            Text(t.eventsSeeResult)
                                .font(AppFont.body(12, .black))
                                .foregroundStyle(Palette.goldText)
                                .padding(.horizontal, 10)
                                .frame(height: 28)
                                .background(Palette.goldGradient, in: Capsule())
                        } else {
                            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.ter)
                        }
                    }
                    .padding(14)
                    .background(Palette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Palette.cardBorder, lineWidth: 2))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
