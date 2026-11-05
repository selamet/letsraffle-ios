import SwiftUI

enum DrawsRoute: Hashable {
    case allDraws
    case createInvite
    case inviteDetails
    case manual
    case detail(inviteCode: String)
}

/// Tab 1: hero header, draw mode cards and the organizer's draws.
struct DrawsHomeView: View {
    @Environment(\.strings) private var t
    @Environment(SessionStore.self) private var session
    @State private var store: DrawsStore?
    @State private var path: [DrawsRoute] = []
    @State private var inviteDraft: InviteDraft?
    @Environment(TabBarVisibility.self) private var tabBar

    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {
                    HomeHero(topInset: geo.safeAreaInsets.top)
                    VStack(spacing: 12) {
                        InviteModeCard { open(.createInvite) }
                        ManualModeCard { path.append(.manual) }
                        draws
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, -52)
                    .padding(.bottom, 24)
                }
            }
            .background(Palette.page)
            .ignoresSafeArea(edges: .top)
            .refreshable { await store?.load(t) }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: DrawsRoute.self, destination: destination)
        }
        .task(id: session.user?.id) {
            guard session.isSignedIn else { store = nil; return }
            if store == nil { store = DrawsStore(api: session.api) }
            #if DEBUG
            applyDebugRoute()
            #endif
            await store?.load(t)
        }
    }

    #if DEBUG
    private func applyDebugRoute() {
        guard path.isEmpty, let route = DebugRoute.current else { return }
        if route == "invite" { open(.createInvite) }
        if route == "invite2" { open(.createInvite); path.append(.inviteDetails) }
        if route == "manual" { open(.manual) }
        if route.hasPrefix("detail:") { path = [.detail(inviteCode: String(route.dropFirst(7)))] }
        tabBar.isHidden = !path.isEmpty
    }
    #endif

    private func open(_ route: DrawsRoute) {
        if session.isSignedIn {
            if route == .createInvite {
                inviteDraft = InviteDraft(email: session.user?.email ?? "")
            }
            path.append(route)
        } else {
            session.exitGuestMode()
        }
    }

    @ViewBuilder
    private var draws: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(t.activeDraws)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Palette.text)
            Spacer()
            if let store, store.draws.count > 3 {
                Button(t.seeAll) { path.append(.allDraws) }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Palette.brandText)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)

        if let store {
            switch store.phase {
            case .idle, .loading:
                ProgressView().frame(maxWidth: .infinity).padding(.vertical, 24)
            case let .failed(message):
                VStack(spacing: 12) {
                    Banner(text: message, style: .error)
                    Button(t.retry) { Task { await store.load(t) } }
                        .foregroundStyle(Palette.brandText)
                }
            case .loaded where store.draws.isEmpty:
                EmptyHint(text: t.noDraws)
            case .loaded:
                ForEach(store.activeFirst.prefix(3)) { draw in
                    drawLink(draw)
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
    func drawLink(_ draw: DrawListItem) -> some View {
        if let code = draw.inviteCode, draw.drawType == .dynamic {
            NavigationLink(value: DrawsRoute.detail(inviteCode: code)) { DrawRow(draw: draw) }
                .buttonStyle(.plain)
        } else {
            DrawRow(draw: draw)
        }
    }

    @ViewBuilder
    private func destination(_ route: DrawsRoute) -> some View {
        switch route {
        case .allDraws:
            AllDrawsView(store: store, rowLink: drawLink)
        case .createInvite:
            if let inviteDraft { InviteSettingsView(path: $path, draft: inviteDraft) }
        case .inviteDetails:
            if let inviteDraft {
                InviteOrganizerView(path: $path, draft: inviteDraft) { response in
                    self.inviteDraft = nil
                    path = [.detail(inviteCode: response.inviteCode)]
                }
            }
        case let .detail(inviteCode):
            DrawDetailView(inviteCode: inviteCode, api: session.api)
        case .manual:
            ManualDrawView { path.removeAll() }
        }
    }
}

private struct HomeHero: View {
    var topInset: CGFloat = 0
    @Environment(\.strings) private var t

    var body: some View {
        ZStack(alignment: .topLeading) {
            Palette.heroGradient
            RadialGradient(colors: [.white.opacity(0.18), .clear], center: UnitPoint(x: 0.8, y: 0.1), startRadius: 0, endRadius: 260)
            ChristmasTree(variant: .small)
                .scaleEffect(0.8)
                .opacity(0.3)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .offset(x: 30, y: 40)
            SnowDots(dots: [
                .init(x: 0.4, y: 0.3, size: 5, opacity: 0.7),
                .init(x: 0.82, y: 0.5, size: 4, opacity: 0.6),
            ])

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(t.homeTag)
                        .font(.eyebrow)
                        .tracking(3)
                        .textCase(.uppercase)
                        .foregroundStyle(.white.opacity(0.75))
                    Text(t.homeTitle)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                    Text(t.homeHello)
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, topInset + 16)
        }
        .frame(height: 180 + topInset)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 32, bottomTrailingRadius: 32, style: .continuous))
    }
}

private struct InviteModeCard: View {
    let action: () -> Void
    @Environment(\.strings) private var t

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(t.inviteMode).font(.system(size: 20, weight: .bold)).foregroundStyle(.white)
                    Text(t.inviteModeDesc)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.92))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("★ \(t.inviteModeFooter)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: 0xFFD230))
                        .padding(.top, 2)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.right")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Palette.brandText)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.95), in: Circle())
            }
            .padding(16)
            .background {
                LinearGradient(
                    stops: [.init(color: Color(hex: 0xFE9A00), location: 0), .init(color: Color(hex: 0xE7000B), location: 0.55), .init(color: Color(hex: 0xC10007), location: 1)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            }
            .overlay(alignment: .top) {
                LinearGradient(colors: [.clear, .white, .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(height: 3).opacity(0.7)
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Color(hex: 0xFFD230), lineWidth: 2))
            .overlay(alignment: .topTrailing) {
                Text("\(t.special) ★")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(LinearGradient(colors: [Color(hex: 0xFFB900), Color(hex: 0xE17100)], startPoint: .leading, endPoint: .trailing), in: Capsule())
                    .shadow(color: .black.opacity(0.2), radius: 5, y: 4)
                    .rotationEffect(.degrees(8))
                    .offset(x: 6, y: -8)
            }
            .shadow(color: Color(hex: 0x7F1D1D, alpha: 0.35), radius: 15, y: 12)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.invite")
    }
}

private struct ManualModeCard: View {
    let action: () -> Void
    @Environment(\.strings) private var t

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(t.manualMode).font(.system(size: 20, weight: .bold)).foregroundStyle(Palette.brandText)
                    Text(t.manualModeDesc)
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.sub)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Text(t.start)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .frame(height: 40)
                    .background(Palette.brand, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(16)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.sep, lineWidth: 1))
            .shadow(color: .black.opacity(0.05), radius: 7, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.manual")
    }
}

struct EmptyHint: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 15))
            .foregroundStyle(Palette.sub)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// Full list behind "See all".
struct AllDrawsView<Row: View>: View {
    let store: DrawsStore?
    let rowLink: (DrawListItem) -> Row
    @Environment(\.strings) private var t

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(store?.draws ?? []) { rowLink($0) }
            }
            .padding(16)
        }
        .background(Palette.page)
        .navigationTitle(t.homeTitle)
        .refreshable { await store?.load(t) }
    }
}
