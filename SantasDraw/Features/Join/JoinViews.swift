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
                Palette.heroGradient.frame(height: 560).ignoresSafeArea()
            }
            .background(Palette.page)
            .toolbar(.hidden, for: .navigationBar)
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
        VStack(alignment: .leading, spacing: 4) {
            Text(t.joinTitle).font(.system(size: 34, weight: .bold)).foregroundStyle(.white)
            Text(t.joinSub).font(.system(size: 15)).foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .frame(height: 210)
        .background(alignment: .topLeading) {
            ZStack(alignment: .topLeading) {
                ChristmasTree(variant: .large).opacity(0.3).offset(x: -50, y: 90)
                ChristmasTree(variant: .small).opacity(0.25)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .offset(x: 30, y: 120)
            }
        }
        .overlay(alignment: .bottom) {
            SantaAvatar(size: 150).offset(y: 56)
        }
        .zIndex(0)
    }

    private var codeCard: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text(t.enterCode).font(.system(size: 22, weight: .bold)).foregroundStyle(Palette.text)
                Text(t.enterCodeSub).font(.system(size: 14)).foregroundStyle(Palette.sub).multilineTextAlignment(.center)
            }
            TextField("", text: $code, prompt: Text("jolly-reindeer-742").foregroundStyle(Palette.ter))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Palette.text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .submitLabel(.go)
                .focused($codeFocused)
                .onSubmit { open(code) }
                .frame(height: 54)
                .background(Palette.page, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(codeError != nil || codeFocused ? Palette.brand : Palette.fieldBorder, lineWidth: codeFocused ? 1.5 : 1))
                .accessibilityIdentifier("join.code")
            if let codeError {
                Text(codeError).font(.system(size: 12)).foregroundStyle(Palette.brandText)
            }
            Button(t.continueTitle) { open(code) }
                .buttonStyle(.primary)
                .disabled(code.trimmed.isEmpty)
            OrDivider(title: t.or)
            Button { scanning = true } label: {
                Label(t.scanQr, systemImage: "qrcode.viewfinder")
            }
            .buttonStyle(PrimaryButtonStyle(background: Palette.chip, foreground: Palette.brandText))
            Text(t.deepLinkHint).font(.system(size: 12)).foregroundStyle(Palette.ter).multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.top, 72)
        .padding(.bottom, 20)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 25, y: 20)
        .padding(.horizontal, 16)
        .zIndex(1)
    }

    @ViewBuilder
    private var joined: some View {
        if !participations.items.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(t.myJoinedDraws)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Palette.text)
                    .padding(.horizontal, 4)
                ForEach(participations.items) { item in
                    NavigationLink(value: JoinRoute.reveal(inviteCode: item.inviteCode)) {
                    HStack(spacing: 12) {
                        Image(systemName: "gift.fill")
                            .foregroundStyle(Palette.brandText)
                            .frame(width: 44, height: 44)
                            .background(Palette.chip, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.inviteCode).font(.system(size: 17, weight: .semibold)).foregroundStyle(Palette.text).lineLimit(1)
                            Text(item.drawDate.map { DrawDateFormat.long($0, language: settings.language) } ?? t.noDrawDate)
                                .font(.system(size: 13)).foregroundStyle(Palette.sub)
                        }
                        Spacer()
                        Image(systemName: item.result == nil ? "gift" : "gift.fill")
                            .foregroundStyle(Palette.brandText)
                        Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.ter)
                    }
                    .padding(14)
                    .background(Palette.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.sep))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
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
        VStack(spacing: 0) {
            HStack {
                CircleIconButton { dismiss() }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            if let info {
                form(info)
            } else if let loadError {
                VStack(spacing: 12) {
                    Banner(text: loadError, style: .error)
                    Button(t.retry) { Task { await load() } }.foregroundStyle(Palette.brandText)
                }
                .padding(20)
                Spacer()
            } else {
                ProgressView().frame(maxHeight: .infinity)
            }
        }
        .background(Palette.page.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
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

    private func form(_ info: DrawPublicInfo) -> some View {
        let errors = showErrors ? validation(info) : [:]
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                drawCard(info)

                ScreenHeader(title: t.joinHeading, subtitle: t.joinSubheading, titleSize: 30)
                    .padding(.horizontal, 8)

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
                        FormField(label: t.address, text: optional(\.address), placeholder: t.addressPh, isRequired: true, error: errors[.address])
                    }
                    if info.requirePhone {
                        FormField(label: t.phone, text: optional(\.phone), placeholder: t.phonePh, kind: .phone, isRequired: true, error: errors[.phone])
                    }
                    Toggle(isOn: $notify) {
                        Text(t.notifyMe).font(.system(size: 14)).foregroundStyle(Palette.text)
                    }
                    .toggleStyle(CheckboxToggleStyle())
                    .padding(.vertical, 6)
                    .padding(.horizontal, 4)

                    Button(t.joinSubmit) { Task { await submit(info) } }
                        .buttonStyle(.primary(loading: isSubmitting))
                        .disabled(isSubmitting || info.status != .active)
                        .accessibilityIdentifier("join.submit")
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
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
            info.drawDate.map { DrawDateFormat.long($0, language: settings.language) },
        ].compactMap { $0 }.joined(separator: " · ")
        return HStack(spacing: 12) {
            Text(initials)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(LinearGradient(colors: [Color(hex: 0xFF6467), Color(hex: 0xE7000B)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(inviteCode).font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.text)
                Text(details).font(.system(size: 13)).foregroundStyle(Palette.sub)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Palette.card2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                    .fill(configuration.isOn ? Palette.brand : .clear)
                    .strokeBorder(configuration.isOn ? Palette.brand : Palette.fieldBorder, lineWidth: 1.5)
                    .frame(width: 22, height: 22)
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

    private let confetti: [(CGFloat, CGFloat, UInt32, Double)] = [
        (0.15, 0.16, 0xEF4444, 20), (0.40, 0.13, 0x10B981, -30), (0.80, 0.20, 0x3B82F6, 45), (0.62, 0.10, 0xF59E0B, 10),
        (0.27, 0.25, 0x8B5CF6, -15), (0.60, 0.23, 0xEF4444, 60), (0.12, 0.75, 0xF59E0B, -50), (0.85, 0.78, 0x10B981, 25),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.opacity(0.55).ignoresSafeArea()
                ForEach(confetti.indices, id: \.self) { i in
                    let c = confetti[i]
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: c.2))
                        .frame(width: 8, height: 14)
                        .rotationEffect(.degrees(c.3))
                        .position(x: geo.size.width * c.0, y: geo.size.height * c.1)
                }
                VStack(spacing: 12) {
                    Text("🎉").font(.system(size: 64))
                    Text(t.successTitle).font(.system(size: 26, weight: .bold)).foregroundStyle(Palette.brandText)
                    Text(t.joinSuccessMsg).font(.system(size: 16)).foregroundStyle(Palette.text)
                    if let drawDate {
                        Text(String(format: t.drawDateInfo, DrawDateFormat.long(drawDate, language: settings.language)))
                            .font(.system(size: 14)).foregroundStyle(Palette.sub)
                    }
                    Banner(text: t.successPush)
                    Text(t.happyHolidays).font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.brandText)
                    Button(t.ok, action: onDone).buttonStyle(.primary).padding(.top, 6)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 24)
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .shadow(color: .black.opacity(0.4), radius: 40, y: 30)
                .padding(24)
            }
        }
        .sensoryFeedback(.success, trigger: true)
    }
}
