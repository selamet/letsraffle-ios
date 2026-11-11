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
            // The winter scene stays put. The list scrolls underneath and disappears along the
            // snow line (not a straight edge); Santa stands in front of it.
            let heroHeight = 300 + geo.safeAreaInsets.top
            ZStack(alignment: .top) {
                    HomeHero(
                        topInset: geo.safeAreaInsets.top,
                        name: nil,
                        activeCount: store?.draws.filter { $0.status == .active || $0.status == .inProgress }.count ?? 0
                    )
                ScrollView {
                    VStack(spacing: 14) {
                        NewDrawPicker(onInvite: { open(.createInvite) }, onManual: { path.append(.manual) })
                        if let next = nextDraw {
                            NextDrawCard(draw: next).onTapGesture {
                                if let code = next.inviteCode { path.append(.detail(inviteCode: code)) }
                            }
                        }
                        draws
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 62)
                    .padding(.bottom, 24)
                }
                .floatingTabBarInset()
                .refreshable { await store?.load(t) }
                .mask {
                    // The cut sits a little below the snow line so there is a band of snow
                    // between the scene and the scrolling content, and it fades out softly.
                    SnowTopMask(offset: 16, waveHeight: 56)
                        .padding(.horizontal, -12)
                        .padding(.bottom, -12)
                        .blur(radius: 3)
                }
                .padding(.top, heroHeight - 56)

                SantaAvatar(size: 158, mood: .draw)
                    .padding(.bottom, 20)
                    .frame(height: heroHeight, alignment: .bottom)
                    .allowsHitTesting(false)
            }
            .background(Palette.page)
            .ignoresSafeArea(edges: .top)
            }
            .toolbar(.hidden, for: .navigationBar)
            .statusBarStyle(.lightContent)
            .navigationDestination(for: DrawsRoute.self, destination: destination)
        }
        .task(id: session.user?.id) {
            #if DEBUG
            if !session.isSignedIn, UserDefaults.standard.bool(forKey: "detailDemo") { applyDebugRoute() }
            #endif
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
                ChristmasLoader(label: t.loadingDraws).frame(maxWidth: .infinity).padding(.vertical, 20)
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

/// One continuous shape (no seam): everything below a snow-wave line that starts `offset` points down.
private struct SnowTopMask: Shape {
    var offset: CGFloat
    var waveHeight: CGFloat

    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = waveHeight, y0 = rect.minY + offset, x0 = rect.minX
        var p = Path()
        p.move(to: CGPoint(x: x0, y: y0 + h * 0.5))
        p.addCurve(to: CGPoint(x: x0 + w * 0.54, y: y0 + h * 0.4), control1: CGPoint(x: x0 + w * 0.18, y: y0 + h * 0.1), control2: CGPoint(x: x0 + w * 0.36, y: y0 + h * 0.75))
        p.addCurve(to: CGPoint(x: x0 + w, y: y0 + h * 0.36), control1: CGPoint(x: x0 + w * 0.72, y: y0 + h * 0.08), control2: CGPoint(x: x0 + w * 0.88, y: y0))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// Winter scene at the top of the home screen: greeting, Santa drawing from
/// his sack on the snow with his friends, as on the website's home page.
private struct HomeHero: View {
    var topInset: CGFloat = 0
    var name: String?
    var activeCount: Int
    @Environment(\.strings) private var t

    var body: some View {
        ZStack(alignment: .top) {
            Palette.heroGradient
            RadialGradient(colors: [.white.opacity(0.14), .clear], center: UnitPoint(x: 0.5, y: 0.3), startRadius: 0, endRadius: 280)
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                MountainRange().frame(height: 150).padding(.bottom, 36)
            }
            SnowDots()
            Garland().padding(.top, topInset - 16)

            HStack(alignment: .center) {
                if let name {
                    Text("\(t.hello) \(name),")
                        .font(AppFont.script(34))
                        .foregroundStyle(Palette.goldLight)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                } else {
                    // The brand sits where the greeting would be: this is the most-seen screen.
                    Image("lockup")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 44)
                        .shadow(color: Color(hex: 0x3C0000, alpha: 0.25), radius: 6, y: 3)
                        .accessibilityLabel("Lets Raffle")
                }
                Spacer(minLength: 8)
                HStack(spacing: 6) {
                    Circle().fill(Color(hex: 0x7BE0A0)).frame(width: 8, height: 8)
                    Text(String(format: t.activeCount, activeCount))
                }
                .font(AppFont.body(13, .black))
                .foregroundStyle(Palette.snow)
                .padding(.horizontal, 14)
                .frame(height: 36)
                .background(Color.white.opacity(0.16), in: Capsule())
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.4), lineWidth: 1.5))
            }
            .padding(.horizontal, 20)
            .padding(.top, topInset + 36)

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                ZStack(alignment: .bottom) {
                    HStack(alignment: .bottom, spacing: 0) {
                        FriendImage(friend: .hug, width: 78).padding(.leading, 6)
                        Spacer(minLength: 0)
                        ZStack(alignment: .bottomTrailing) {
                            FriendImage(friend: .tree, width: 32).saturation(0.75).brightness(-0.08).opacity(0.85).padding(.bottom, 6)
                            FriendImage(friend: .tree, width: 46).padding(.trailing, 28)
                        }
                        .padding(.trailing, 6)
                    }
                    .padding(.bottom, 24)
                    SnowWave().fill(Palette.page).frame(height: 56)
                }
            }
        }
        .frame(height: 300 + topInset)
        .accessibilityElement(children: .combine)
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
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(t.nextDraw)
                        .font(AppFont.body(10.5, .black))
                        .tracking(1.5)
                        .textCase(.uppercase)
                        .foregroundStyle(Palette.brandText)
                    Text(draw.displayName)
                        .font(AppFont.display(16))
                        .foregroundStyle(Palette.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if let date = draw.drawDate {
                        Text(DrawDateFormat.short(date, language: settings.language))
                            .font(AppFont.body(12.5, .semibold))
                            .foregroundStyle(Palette.sub)
                    }
                }
                Spacer(minLength: 0)
                if days > 0 { box(days, t.daysUnit) }
                box(hours, t.hoursUnit)
                if days == 0 { box(minutes, t.minutesUnit) }
            }
            .padding(.vertical, 12)
            .padding(.leading, 16)
            .padding(.trailing, 12)
            .background(Palette.card2, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Palette.cardBorder, lineWidth: 2))
        }
        .accessibilityElement(children: .combine)
    }

    private func box(_ value: Int, _ unit: String) -> some View {
        VStack(spacing: 0) {
            Text(String(format: "%02d", value)).font(AppFont.display(20))
            Text(unit).font(AppFont.body(10, .bold)).opacity(0.9)
        }
        .foregroundStyle(Palette.goldLight)
        .frame(width: 50, height: 50)
        .background(Palette.cranberryDark, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentTransition(.numericText())
    }
}

/// "Yeni bir çekiliş başlat": the invite mode is the star (it is what makes
/// the app special), the manual mode a smaller second option.
private struct NewDrawPicker: View {
    var onInvite: () -> Void
    var onManual: () -> Void
    @Environment(\.strings) private var t

    var body: some View {
        VStack(spacing: 12) {
            Text(t.newDrawTitle)
                .font(AppFont.display(26))
                .foregroundStyle(Palette.brandText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 2)

            Button(action: onInvite) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 5) {
                            Image(systemName: "star.fill").font(.system(size: 9, weight: .bold))
                            Text(t.favTag).font(AppFont.body(10.5, .black)).tracking(1.2)
                        }
                        .foregroundStyle(Palette.goldText)
                        .padding(.horizontal, 10)
                        .frame(height: 22)
                        .background(Palette.goldGradient, in: Capsule())
                        Text(t.inviteHeroTitle)
                            .font(AppFont.display(27))
                            .foregroundStyle(Palette.goldLight)
                            .shadow(color: Color(hex: 0x3C0000, alpha: 0.35), radius: 0, y: 2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(t.inviteHeroDesc)
                            .font(AppFont.body(13.5, .bold))
                            .foregroundStyle(Palette.snow.opacity(0.96))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(t.inviteHeroFeatures)
                            .font(AppFont.body(11.5, .black))
                            .foregroundStyle(Palette.goldLight)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.top, 1)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(Palette.goldText)
                        .frame(width: 52, height: 52)
                        .background(Palette.goldGradient, in: Circle())
                        .overlay(Circle().strokeBorder(.white.opacity(0.55), lineWidth: 2))
                        .background(Circle().fill(Palette.goldDark).offset(y: 3))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity, minHeight: 134, alignment: .leading)
                .background(giftBackground([Color(hex: 0xD0282F), Palette.cranberry, Palette.cranberryDark], edge: Color(hex: 0x4A080C), halo: true))
                .padding(.bottom, 6)
            }
            .buttonStyle(ModeCardStyle())
            .accessibilityIdentifier("home.invite")

            Button(action: onManual) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(t.manualHeroTitle)
                            .font(AppFont.display(19))
                            .foregroundStyle(Palette.goldLight)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(t.manualHeroDesc)
                            .font(AppFont.body(13, .bold))
                            .foregroundStyle(Palette.snow.opacity(0.96))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(Palette.pine)
                        .frame(width: 38, height: 38)
                        .background(Palette.snow, in: Circle())
                        .background(Circle().fill(.black.opacity(0.3)).offset(y: 3))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
                .background(giftBackground([Color(hex: 0x2F8A5A), Palette.pine, Palette.pineEdge], edge: Color(hex: 0x0C2A1C), halo: false))
                .padding(.bottom, 6)
            }
            .buttonStyle(ModeCardStyle())
            .accessibilityIdentifier("home.manual")
        }
    }

    /// Glossy gift-wrap fill: gradient, double gold foil border, thick bottom edge.
    private func giftBackground(_ colors: [Color], edge: Color, halo: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 26, style: .continuous)
        return ZStack {
            shape.fill(edge).offset(y: 6)
            shape.fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            shape.fill(LinearGradient(colors: [.white.opacity(0.16), .clear], startPoint: .topLeading, endPoint: .center))
            shape.strokeBorder(Palette.goldLight, lineWidth: 2.5)
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Palette.goldLight.opacity(0.35), lineWidth: 1)
                .padding(6)
        }
        .background(shape.stroke(Palette.goldLight.opacity(halo ? 0.3 : 0), lineWidth: 8))
        .shadow(color: edge.opacity(0.35), radius: 12, y: 12)
    }
}

/// Whole-card button: presses down slightly.
private struct ModeCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .brightness(configuration.isPressed ? -0.03 : 0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

struct EmptyHint: View {
    let text: String

    var body: some View {
        VStack(spacing: 8) {
            FriendImage(friend: .snowman, width: 84)
            Text(text)
                .font(AppFont.body(15, .semibold))
                .foregroundStyle(Palette.sub)
                .multilineTextAlignment(.center)
        }
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
