import SwiftUI

enum JoinRoute: Hashable {
    case form(inviteCode: String)
    case reveal(inviteCode: String)
}

/// Pending invite code coming from a deep link or universal link.
@MainActor
@Observable
final class DeepLinkRouter {
    var pendingInviteCode: String?
    /// Destination from a tapped push notification.
    var pendingDestination: PushDestination?

    func handle(_ url: URL) {
        // Widget links: letsraffle://reveal/<code>, letsraffle://draw/<code>
        if url.scheme == InviteLink.scheme, let code = url.pathComponents.dropFirst().first {
            switch url.host {
            case "reveal": pendingDestination = .reveal(inviteCode: code); return
            case "draw": pendingDestination = .drawDetail(inviteCode: code); return
            default: break
            }
        }
        if let code = InviteLink.code(from: url) {
            pendingInviteCode = code
        }
    }
}

/// Tab 2: enter an invite code or scan a QR, then fill the join form.
struct JoinTabView: View {
    @Environment(\.strings) private var t
    @Environment(DeepLinkRouter.self) private var router
    @Environment(ParticipationStore.self) private var participations
    @Environment(TabBarVisibility.self) private var tabBar
    @Environment(AppSettings.self) private var settings
    @Environment(SessionStore.self) private var session

    @State private var path: [JoinRoute] = []
    @State private var code = ""
    @State private var codeError: String?
    @State private var scanning = false
    @FocusState private var codeFocused: Bool

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 0) {
                    hero
                    codeCard
                    joined
                }
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .floatingTabBarInset()
            .background(alignment: .top) {
                ChristmasBackdrop(garland: true, pines: false).frame(height: 420)
            }
            .background(Palette.page.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .statusBarStyle(.lightContent)
            .navigationDestination(for: JoinRoute.self) { route in
                switch route {
                case let .form(inviteCode):
                    JoinFormView(inviteCode: inviteCode) { path.removeAll() }
                case let .reveal(inviteCode):
                    RevealView(inviteCode: inviteCode, api: session.api, participations: participations, isSignedIn: session.isSignedIn)
                }
            }
        }
        .fullScreenCover(isPresented: $scanning) {
            QRScannerSheet { scanned in open(scanned) }
        }
        .onChange(of: path, initial: true) { _, newPath in tabBar.isHidden = !newPath.isEmpty }
        .onChange(of: router.pendingInviteCode, initial: true) { _, pending in
            guard let pending else { return }
            router.pendingInviteCode = nil
            path = [.form(inviteCode: pending)]
        }
        .onChange(of: router.pendingDestination, initial: true) { _, destination in
            guard case let .reveal(code)? = destination else { return }
            router.pendingDestination = nil
            path = [.reveal(inviteCode: code)]
        }
    }

    private var hero: some View {
        HStack(alignment: .bottom, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(t.haveInvite)
                    .font(AppFont.script(42))
                    .foregroundStyle(Palette.goldLight)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(t.haveInviteSub)
                    .font(AppFont.body(14, .bold))
                    .foregroundStyle(Palette.snow.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, 34)
            Spacer(minLength: 4)
            SantaAvatar(size: 150, mood: .invite)
        }
        .padding(.leading, 22)
        .padding(.trailing, 6)
        .padding(.top, 70)
        .frame(height: 270, alignment: .bottom)
    }

    private var codeCard: some View {
        JoinCodeCard(code: $code, error: codeError, focused: $codeFocused, onSubmit: { open(code) }, onScan: { scanning = true })
            .padding(.horizontal, 24)
            .padding(.top, 26)
            .padding(.bottom, 20)
            .background(
                UnevenRoundedRectangle(topLeadingRadius: 34, topTrailingRadius: 34, style: .continuous)
                    .fill(Palette.page)
                    .shadow(color: Color(hex: 0x320000, alpha: 0.3), radius: 22, y: -8)
            )
    }

    @ViewBuilder
    private var joined: some View {
        if !participations.items.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(t.myJoinedDraws)
                    .font(AppFont.display(19))
                    .foregroundStyle(Palette.text)
                    .padding(.horizontal, 4)
                ForEach(participations.items) { item in
                    NavigationLink(value: JoinRoute.reveal(inviteCode: item.inviteCode)) {
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.open.fill")
                            .foregroundStyle(Palette.brandText)
                            .frame(width: 46, height: 46)
                            .background(Palette.chip, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.inviteCode).font(AppFont.display(17)).foregroundStyle(Palette.text).lineLimit(1)
                            Text(item.drawDate.map { DrawDateFormat.long($0, language: settings.language) } ?? t.noDrawDate)
                                .font(AppFont.body(13, .semibold)).foregroundStyle(Palette.sub)
                        }
                        Spacer()
                        Image(systemName: item.result == nil ? "gift" : "gift.fill")
                            .foregroundStyle(Palette.brandText)
                        Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.ter)
                    }
                    .padding(14)
                    .background(Palette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Palette.cardBorder, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .background(Palette.page)
        }
    }

    private func open(_ raw: String) {
        guard let inviteCode = InviteLink.code(from: raw) else {
            codeError = t.fieldRequired
            return
        }
        codeError = nil
        code = ""
        codeFocused = false
        path = [.form(inviteCode: inviteCode)]
    }
}

/// Public join form for an invite code (`GET` + `POST /draws/join/{code}`).
struct JoinFormView: View {
    let inviteCode: String
    var onFinish: () -> Void

    @Environment(\.strings) private var t
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings
    @Environment(SessionStore.self) private var session
    @Environment(ParticipationStore.self) private var participations
    @Environment(PushManager.self) private var push

    @State private var info: DrawPublicInfo?
    @State private var loadError: String?
    @State private var participant = ParticipantInput(firstName: "", lastName: "", email: "")
    @State private var notify = true
    @State private var showErrors = false
    @State private var isSubmitting = false
    @State private var submitError: String?
    @State private var success = false

    var body: some View {
        ZStack(alignment: .top) {
            ChristmasBackdrop(garland: true, pines: false)
            VStack(spacing: 0) {
                header
                Group {
                    if let info {
                        form(info)
                    } else if let loadError {
                        VStack(spacing: 12) {
                            Banner(text: loadError, style: .error)
                            Button(t.retry) { Task { await load() } }
                                .font(AppFont.body(15, .bold))
                                .foregroundStyle(Palette.brandText)
                        }
                        .padding(24)
                        .frame(maxHeight: .infinity, alignment: .top)
                    } else {
                        ProgressView().tint(Palette.brand).frame(maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
                .background(
                    UnevenRoundedRectangle(topLeadingRadius: 34, topTrailingRadius: 34, style: .continuous)
                        .fill(Palette.page)
                        .shadow(color: Color(hex: 0x320000, alpha: 0.3), radius: 22, y: -8)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .statusBarStyle(.lightContent)
        .task { await load() }
        .overlay {
            if success, let info {
                JoinSuccessOverlay(drawDate: info.drawDate) {
                    onFinish()
                    if notify { push.promptIfAppropriate() }
                }
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: success)
        .onAppear {
            if participant.email.isEmpty, let email = session.user?.email { participant.email = email }
        }
    }

    private var header: some View {
        HStack(alignment: .bottom, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                CircleIconButton(onDark: true) { dismiss() }
                    .padding(.leading, -10)
                    .padding(.bottom, 6)
                Text(t.youreInvited)
                    .font(AppFont.script(40))
                    .foregroundStyle(Palette.goldLight)
                Text(t.joinHeading)
                    .font(AppFont.display(28))
                    .foregroundStyle(Palette.snow)
                if let info {
                    HStack(spacing: 6) {
                        if let date = info.drawDate {
                            chip(icon: "calendar", DrawDateFormat.long(date, language: settings.language))
                        }
                        chip(icon: "person.2.fill", t.participantCount(info.participantCount))
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.bottom, 26)
            Spacer(minLength: 0)
            SantaAvatar(size: 128, mood: .invite)
        }
        .padding(.leading, 22)
        .padding(.trailing, 4)
        .padding(.top, 50)
    }

    private func chip(icon: String, _ text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 11, weight: .bold))
            Text(text).lineLimit(1)
        }
        .font(AppFont.body(12, .bold))
        .foregroundStyle(Palette.snow)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.16), in: Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.35), lineWidth: 1.5))
    }

    private func form(_ info: DrawPublicInfo) -> some View {
        let errors = showErrors ? validation(info) : [:]
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                drawCard(info)

                ScreenHeader(title: t.joinHeading, subtitle: t.joinSubheading, titleSize: 24)

                if info.status != .active {
                    Banner(text: t.drawNotActive, style: .error)
                }
                if let submitError {
                    Banner(text: submitError, style: .error)
                }

                VStack(spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        FormField(label: t.firstName, text: $participant.firstName, placeholder: t.firstNamePh, kind: .name, error: errors[.firstName])
                        FormField(label: t.lastName, text: $participant.lastName, placeholder: t.lastNamePh, kind: .name, error: errors[.lastName])
                    }
                    FormField(label: t.email, text: $participant.email, placeholder: t.emailPh, kind: .email, isRequired: true, error: errors[.email])
                    if info.requireAddress {
                        FormField(label: t.address, text: optional(\.address), placeholder: t.addressPh, isRequired: true, error: errors[.address], icon: "mappin.and.ellipse")
                    }
                    if info.requirePhone {
                        FormField(label: t.phone, text: optional(\.phone), placeholder: t.phonePh, kind: .phone, isRequired: true, error: errors[.phone])
                    }
                    Toggle(isOn: $notify) {
                        Text(t.notifyMe).font(AppFont.body(14, .bold)).foregroundStyle(Palette.text)
                    }
                    .toggleStyle(CheckboxToggleStyle())
                    .padding(.vertical, 6)
                    .padding(.horizontal, 2)

                    Button {
                        Task { await submit(info) }
                    } label: {
                        Label(t.joinSubmit, systemImage: "gift.fill")
                    }
                    .buttonStyle(.primary(loading: isSubmitting))
                    .disabled(isSubmitting || info.status != .active)
                    .accessibilityIdentifier("join.submit")
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func drawCard(_ info: DrawPublicInfo) -> some View {
        let initials = info.organizerName.map { name in
            name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
        } ?? "🎁"
        let details = [
            info.organizerName.map { "\(t.hostedBy) \($0)" },
            t.participantCount(info.participantCount),
        ].compactMap { $0 }.joined(separator: " · ")
        return HStack(spacing: 12) {
            Text(initials)
                .font(AppFont.display(15))
                .foregroundStyle(Palette.cranberryDark)
                .frame(width: 42, height: 42)
                .background(Palette.goldGradient, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(inviteCode).font(AppFont.display(16)).foregroundStyle(Palette.text)
                Text(details).font(AppFont.body(13, .semibold)).foregroundStyle(Palette.sub)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Palette.card2, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.gold.opacity(0.6), lineWidth: 1.5))
    }

    private func optional(_ keyPath: WritableKeyPath<ParticipantInput, String?>) -> Binding<String> {
        Binding(get: { participant[keyPath: keyPath] ?? "" }, set: { participant[keyPath: keyPath] = $0 })
    }

    private func validation(_ info: DrawPublicInfo) -> [ParticipantField: String] {
        var errors: [ParticipantField: String] = [:]
        if let e = Validation.requiredError(participant.firstName, t) { errors[.firstName] = e }
        if let e = Validation.requiredError(participant.lastName, t) { errors[.lastName] = e }
        if let e = Validation.emailError(participant.email, t) { errors[.email] = e }
        if info.requireAddress, let e = Validation.requiredError(participant.address, t) { errors[.address] = e }
        if info.requirePhone, let e = Validation.requiredError(participant.phone, t) { errors[.phone] = e }
        return errors
    }

    private func load() async {
        loadError = nil
        do {
            info = try await session.api.send(API.publicDraw(inviteCode: inviteCode))
        } catch APIError.server(status: 404, _) {
            loadError = t.joinNotFound
        } catch is CancellationError {
        } catch {
            loadError = error.userMessage(t)
        }
    }

    private func submit(_ info: DrawPublicInfo) async {
        showErrors = true
        submitError = nil
        guard validation(info).isEmpty else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        var payload = participant
        payload.firstName = participant.firstName.trimmed
        payload.lastName = participant.lastName.trimmed
        payload.email = participant.email.trimmed.lowercased()
        payload.address = info.requireAddress ? participant.address?.trimmed : nil
        payload.phone = info.requirePhone ? participant.phone?.trimmed : nil

        do {
            let response = try await session.api.send(API.joinDraw(inviteCode: inviteCode, participant: payload))
            participations.add(Participation(
                inviteCode: inviteCode,
                participantId: response.participantId,
                drawId: response.drawId,
                displayName: payload.fullName,
                drawDate: info.drawDate,
                participantToken: response.participantToken,
                wantsNotification: notify,
                joinedAt: .now
            ))
            success = true
            await push.sync()
        } catch {
            submitError = error.userMessage(t)
        }
    }
}

/// Rounded brand checkbox toggle.
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(configuration.isOn ? Palette.brand : Palette.field)
                    .strokeBorder(configuration.isOn ? Palette.gold : Palette.fieldBorder, lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .overlay {
                        if configuration.isOn {
                            Image(systemName: "checkmark").font(.system(size: 12, weight: .heavy)).foregroundStyle(.white)
                        }
                    }
                configuration.label
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
    }
}

/// Celebration modal shown after joining.
struct JoinSuccessOverlay: View {
    let drawDate: Date?
    var onDone: () -> Void
    @Environment(\.strings) private var t
    @Environment(AppSettings.self) private var settings
    @State private var shown = false

    private let confetti: [(CGFloat, CGFloat, UInt32, Double)] = [
        (0.15, 0.10, 0xF6D98A, 20), (0.40, 0.06, 0x4FB87E, -30), (0.80, 0.14, 0xFFFFFF, 45), (0.62, 0.04, 0xF6D98A, 10),
        (0.27, 0.20, 0xFFFFFF, -15), (0.70, 0.22, 0x4FB87E, 60), (0.10, 0.30, 0xF6D98A, -50), (0.88, 0.30, 0x4FB87E, 25),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RadialGradient(colors: [Color(hex: 0xA3171C), Color(hex: 0x3D0609)], center: .center, startRadius: 0, endRadius: 520)
                    .opacity(0.96)
                    .ignoresSafeArea()
                ForEach(confetti.indices, id: \.self) { i in
                    let c = confetti[i]
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: c.2))
                        .frame(width: 9, height: 14)
                        .rotationEffect(.degrees(c.3 + (shown ? 180 : 0)))
                        .position(x: geo.size.width * c.0, y: geo.size.height * c.1 + (shown ? 60 : 0))
                }
                VStack(spacing: 10) {
                    Text(t.congrats).font(AppFont.script(54)).foregroundStyle(Color(hex: 0xB8892B))
                    Text(t.successTitle).font(AppFont.display(25)).foregroundStyle(Palette.brandText)
                    CandyStripe(width: 80)
                    Text(t.joinSuccessMsg).font(AppFont.body(15, .medium)).foregroundStyle(Palette.text)
                    if let drawDate {
                        Text(String(format: t.drawDateInfo, DrawDateFormat.long(drawDate, language: settings.language)))
                            .font(AppFont.body(14, .semibold)).foregroundStyle(Palette.sub)
                    }
                    Banner(text: t.successPush, style: .success)
                    Button(t.ok, action: onDone).buttonStyle(.primary).padding(.top, 4)
                    Text("★ \(t.happyHolidays) ★").font(AppFont.body(14, .bold)).foregroundStyle(Palette.greenText)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 104)
                .padding(.bottom, 22)
                .foilCard(radius: 32)
                .overlay(alignment: .top) {
                    SantaAvatar(size: 210, mood: .celebrate).offset(y: -158)
                }
                .padding(.horizontal, 22)
                .padding(.top, 120)
                .scaleEffect(shown ? 1 : 0.9)
                .opacity(shown ? 1 : 0)
            }
        }
        .onAppear { withAnimation(.spring(duration: 0.6, bounce: 0.35)) { shown = true } }
        .sensoryFeedback(.success, trigger: shown)
    }
}
