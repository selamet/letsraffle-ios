import SwiftUI

enum DrawsRoute: Hashable {
    case allDraws
    case createInvite
    case inviteDetails
    case manual
    case detail(inviteCode: String)
    case reveal(inviteCode: String)
}

/// Tab 1: hero header, draw mode cards and the organizer's draws.
struct DrawsHomeView: View {
    @Environment(\.strings) private var t
    @Environment(SessionStore.self) private var session
    @State private var store: DrawsStore?
    @State private var path: [DrawsRoute] = []
    @State private var inviteDraft: InviteDraft?
    @Environment(TabBarVisibility.self) private var tabBar
    @Environment(DeepLinkRouter.self) private var router
    @Environment(PushManager.self) private var push
    @Environment(ParticipationStore.self) private var participations

    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {
                    HomeHero(
                        topInset: geo.safeAreaInsets.top,
                        name: nil,
                        activeCount: store?.draws.filter { $0.status == .active || $0.status == .inProgress }.count ?? 0,
                        onJoin: { tabBar.requestedTab = .join }
                    )
                    VStack(spacing: 12) {
                        if let next = nextDraw {
                            NextDrawCard(draw: next).onTapGesture {
                                if let code = next.inviteCode { path.append(.detail(inviteCode: code)) }
                            }
                        }
                        NewDrawPicker(onInvite: { open(.createInvite) }, onManual: { path.append(.manual) })
                            .padding(.top, nextDraw == nil ? 0 : 8)
                        draws
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, nextDraw == nil ? 16 : -30)
                    .padding(.bottom, 24)
                }
            }
            .background(Palette.page)
            .ignoresSafeArea(edges: .top)
            .floatingTabBarInset()
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
        .onChange(of: path, initial: true) { _, newPath in
            tabBar.isHidden = !newPath.isEmpty
            // Refresh after returning from create / detail / manual flows.
            if newPath.isEmpty { Task { await store?.load(t) } }
        }
        .onChange(of: router.pendingDestination, initial: true) { _, destination in
            guard case let .drawDetail(code)? = destination, session.isSignedIn else { return }
            router.pendingDestination = nil
            path = [.detail(inviteCode: code)]
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

    /// Closest upcoming scheduled invite draw (drives the countdown card).
    private var nextDraw: DrawListItem? {
        store?.draws
            .filter { $0.status == .active && ($0.drawDate ?? .distantPast) > .now }
            .min { ($0.drawDate ?? .distantFuture) < ($1.drawDate ?? .distantFuture) }
    }

    @ViewBuilder
    private var draws: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(t.allEvents)
                .font(AppFont.display(19))
                .foregroundStyle(Palette.text)
            Spacer()
            if let store, store.draws.count > 3 {
                Button(t.seeAll) { path.append(.allDraws) }
                    .font(AppFont.body(15, .bold))
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
                    // The organizer takes part too; keep their token for the in-app result.
                    participations.add(Participation(
                        inviteCode: response.inviteCode,
                        participantId: nil,
                        drawId: response.drawId,
                        displayName: inviteDraft.firstName,
                        drawDate: inviteDraft.scheduleEnabled ? InviteDraft.exactHour(inviteDraft.drawDate) : nil,
                        participantToken: response.participantToken,
                        wantsNotification: true,
                        joinedAt: .now
                    ))
                    self.inviteDraft = nil
                    path = [.detail(inviteCode: response.inviteCode)]
                    push.promptIfAppropriate()
                }
            }
        case let .detail(inviteCode):
            DrawDetailView(inviteCode: inviteCode, api: session.api) { path.append(.reveal(inviteCode: inviteCode)) }
        case let .reveal(inviteCode):
            RevealView(inviteCode: inviteCode, api: session.api, participations: participations, isSignedIn: session.isSignedIn)
        case .manual:
            ManualDrawView { path.removeAll() }
        }
    }
}

private struct HomeHero: View {
    var topInset: CGFloat = 0
    var name: String?
    var activeCount: Int
    var onJoin: () -> Void
    @Environment(\.strings) private var t

    var body: some View {
        ZStack(alignment: .topLeading) {
            Palette.heroGradient
            RadialGradient(colors: [.white.opacity(0.14), .clear], center: UnitPoint(x: 0.85, y: 0.15), startRadius: 0, endRadius: 280)
            Garland().padding(.top, topInset - 6)
            SnowDots(dots: [
                .init(x: 0.58, y: 0.66, size: 5, opacity: 0.7),
                .init(x: 0.36, y: 0.3, size: 3, opacity: 0.6),
                .init(x: 0.12, y: 0.8, size: 4, opacity: 0.5),
            ])

            HStack(alignment: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name.map { "\(t.hello) \($0)," } ?? "\(t.hello),")
                        .font(AppFont.script(34))
                        .foregroundStyle(Palette.goldLight)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(t.myDraws)
                        .font(AppFont.display(32))
                        .foregroundStyle(Palette.snow)
                    HStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Circle().fill(Color(hex: 0x4FB87E)).frame(width: 8, height: 8)
                            Text(String(format: t.activeCount, activeCount))
                        }
                        .font(AppFont.body(13, .bold))
                        .foregroundStyle(Palette.snow)
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .background(Color.white.opacity(0.16), in: Capsule())
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.35), lineWidth: 1.5))

                        Button(action: onJoin) {
                            HStack(spacing: 6) {
                                Image(systemName: "ticket.fill").font(.system(size: 12, weight: .bold))
                                Text(t.joinWithCode)
                            }
                            .font(AppFont.body(13, .black))
                            .foregroundStyle(Palette.goldText)
                            .padding(.horizontal, 13)
                            .frame(height: 32)
                            .background(Palette.goldGradient, in: Capsule())
                            .background(Palette.goldDark, in: Capsule().offset(y: 3))
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("home.joinCode")
                    }
                    .padding(.top, 6)
                }
                .padding(.bottom, 44)
                Spacer(minLength: 0)
                SantaAvatar(size: 136, mood: .watch)
                    .padding(.bottom, 30)
            }
            .padding(.leading, 20)
            .padding(.trailing, 4)
            .padding(.top, topInset + 30)
        }
        .frame(height: 252 + topInset)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 34, bottomTrailingRadius: 34, style: .continuous))
    }
}

/// Foil card with a countdown to the next scheduled draw.
private struct NextDrawCard: View {
    let draw: DrawListItem
    @Environment(\.strings) private var t
    @Environment(AppSettings.self) private var settings

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            let remaining = max(0, (draw.drawDate ?? context.date).timeIntervalSince(context.date))
            let days = Int(remaining) / 86_400
            let hours = Int(remaining) % 86_400 / 3_600
            let minutes = Int(remaining) % 3_600 / 60
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(t.nextDraw)
                        .font(AppFont.body(12, .black))
                        .tracking(1.6)
                        .textCase(.uppercase)
                        .foregroundStyle(Palette.brandText)
                    Spacer()
                    StatusChip(title: draw.status.title(t), foreground: draw.status.foreground, background: draw.status.background)
                }
                Text(draw.drawDate.map { "\(draw.displayName) · \(DrawDateFormat.short($0, language: settings.language))" } ?? draw.displayName)
                    .font(AppFont.display(20))
                    .foregroundStyle(Palette.brandText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                HStack(spacing: 8) {
                    box(days, t.daysUnit)
                    box(hours, t.hoursUnit)
                    box(minutes, t.minutesUnit)
                }
            }
            .padding(18)
            .foilCard(radius: 24)
        }
        .accessibilityElement(children: .combine)
    }

    private func box(_ value: Int, _ unit: String) -> some View {
        VStack(spacing: 0) {
            Text(String(format: "%02d", value)).font(AppFont.display(24))
            Text(unit).font(AppFont.body(11, .bold)).opacity(0.9)
        }
        .foregroundStyle(Palette.snow)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Palette.cranberry, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentTransition(.numericText())
    }
}

/// "Yeni bir sürpriz?" – choose invite or manual mode, then one call to action.
private struct NewDrawPicker: View {
    enum Mode { case invite, manual }
    var onInvite: () -> Void
    var onManual: () -> Void
    @State private var mode: Mode = .invite
    @Environment(\.strings) private var t

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text(t.newSurprise).font(AppFont.script(30)).foregroundStyle(Color(hex: 0xB8892B))
                Text(t.howToDraw).font(AppFont.display(22)).foregroundStyle(Palette.brandText)
            }
            .padding(.horizontal, 2)

            inviteCard
            manualCard

            Button {
                mode == .invite ? onInvite() : onManual()
            } label: {
                HStack(spacing: 8) {
                    Text(mode == .invite ? t.inviteCta : t.manualCta)
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(ModeCTAStyle(gold: mode == .invite))
            .accessibilityIdentifier(mode == .invite ? "home.invite" : "home.manual")
        }
        .animation(.spring(duration: 0.35), value: mode)
    }

    private var inviteCard: some View {
        let on = mode == .invite
        return Button { mode = .invite } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    GiftTag(title: t.inviteModeTitle, size: 19)
                    Spacer()
                    radio(on: on, light: true)
                }
                Text(t.inviteModeDesc)
                    .font(AppFont.body(14, .semibold))
                    .foregroundStyle(Palette.snow.opacity(0.92))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                if on { steps(t.inviteSteps, light: true) }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(alignment: .trailing) {
                ZStack {
                    on ? Palette.card2Brand : Color(hex: 0xB8474B)
                    Rectangle().fill(Palette.gold.opacity(on ? 0.9 : 0.45)).frame(width: 12).frame(maxWidth: .infinity, alignment: .trailing).padding(.trailing, 58)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Palette.gold.opacity(on ? 1 : 0.5), lineWidth: 2))
            .shadow(color: Color(hex: 0x6E0D12, alpha: on ? 0.28 : 0), radius: 15, y: 12)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private var manualCard: some View {
        let on = mode == .manual
        return Button { mode = .manual } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Palette.greenText)
                        .frame(width: 38, height: 38)
                        .background(Palette.greenSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Text(t.manualModeTitle).font(AppFont.display(20)).foregroundStyle(Palette.brandText)
                    Spacer()
                    radio(on: on, light: false)
                }
                Text(t.manualModeDesc)
                    .font(AppFont.body(14, .medium))
                    .foregroundStyle(Palette.sub)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                if on { steps(t.manualSteps, light: false) }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(on ? Palette.pine : Palette.cardBorder, lineWidth: on ? 2.5 : 2))
            .shadow(color: Palette.pine.opacity(on ? 0.16 : 0), radius: 15, y: 12)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func radio(on: Bool, light: Bool) -> some View {
        ZStack {
            Circle().fill(on ? (light ? Palette.goldLight : Palette.pine) : .clear)
            Circle().strokeBorder(light ? Palette.gold : (on ? Palette.pine : Palette.fieldBorder), lineWidth: 2)
            if on {
                Image(systemName: "checkmark").font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(light ? Palette.cranberryDark : .white)
            }
        }
        .frame(width: 26, height: 26)
    }

    private func steps(_ items: [String], light: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(spacing: 8) {
                    Text("\(index + 1)")
                        .font(AppFont.body(12, .black))
                        .foregroundStyle(light ? Palette.cranberryDark : .white)
                        .frame(width: 22, height: 22)
                        .background(light ? Palette.goldLight : Palette.pine, in: Circle())
                    Text(item)
                        .font(AppFont.body(13, .bold))
                        .foregroundStyle(light ? Palette.snow : Palette.text)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(light ? Color.white.opacity(0.12) : Palette.card2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(light ? Palette.goldLight.opacity(0.45) : Palette.cardBorder, lineWidth: 1.5))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

private struct ModeCTAStyle: ButtonStyle {
    let gold: Bool

    func makeBody(configuration: Configuration) -> some View {
        Group {
            if gold {
                GoldButtonStyle().makeBody(configuration: configuration)
            } else {
                PrimaryButtonStyle().makeBody(configuration: configuration)
            }
        }
    }
}

struct EmptyHint: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AppFont.body(15, .semibold))
            .foregroundStyle(Palette.sub)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Palette.cardBorder, lineWidth: 2))
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
