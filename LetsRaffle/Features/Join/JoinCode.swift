import SwiftUI

/// Code entry card shared by the Join tab and the signed-out "Join with code" screen.
struct JoinCodeCard: View {
    @Binding var code: String
    var error: String?
    var focused: FocusState<Bool>.Binding
    var onSubmit: () -> Void
    var onScan: (() -> Void)?
    /// true while the code is being checked with the server
    var isChecking = false
    /// bump to shake the field (wrong code)
    var shake = 0

    @Environment(\.strings) private var t

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(t.enterCode)
                .font(AppFont.display(25))
                .foregroundStyle(Palette.brandText)
            CandyStripe(width: 80)
            Text(t.enterCodeSub)
                .font(AppFont.body(15, .medium))
                .foregroundStyle(Palette.sub)
                .fixedSize(horizontal: false, vertical: true)

            Text(t.inviteCodeLabel)
                .font(.fieldLabel)
                .foregroundStyle(Color(light: 0x5B3A3A, dark: 0xE8D2C8))
                .padding(.top, 4)
            TextField("", text: $code, prompt: Text(t.codePlaceholder).foregroundStyle(Palette.ter))
                .font(AppFont.display(22, black: false))
                .multilineTextAlignment(.center)
                .foregroundStyle(Palette.brandText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .submitLabel(.go)
                .focused(focused)
                .onSubmit(onSubmit)
                .frame(height: 60)
                .background(code.isEmpty ? Palette.field : Palette.card2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(error != nil || focused.wrappedValue ? Palette.brand : (code.isEmpty ? Palette.fieldBorder : Palette.gold), lineWidth: 2))
                .accessibilityIdentifier("join.code")
                .modifier(ShakeEffect(shakes: CGFloat(shake)))
                .animation(.easeInOut(duration: 0.45), value: shake)
                .sensoryFeedback(.error, trigger: shake)
            if let error {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill").font(.system(size: 15, weight: .bold))
                    Text(error).font(AppFont.body(13, .bold)).fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(Palette.brandText)
                .padding(.horizontal, 12).padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.chip, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                .accessibilityIdentifier("join.codeError")
            } else {
                Text(t.deepLinkHint).font(AppFont.body(12, .semibold)).foregroundStyle(Palette.ter)
            }

            Button {
                onSubmit()
            } label: {
                HStack(spacing: 8) {
                    Text(t.continueLabel)
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(.primary(loading: isChecking))
            .disabled(code.trimmed.isEmpty || isChecking)
            .padding(.top, 6)

            if let onScan {
                OrDivider(title: t.or)
                Button(action: onScan) {
                    Label(t.scanQr, systemImage: "qrcode.viewfinder")
                }
                .buttonStyle(PrimaryButtonStyle(background: Palette.card, foreground: Palette.brandText, edge: Color(hex: 0xE2CDB8), rim: Palette.fieldBorder))
            }
        }
    }
}

/// Horizontal shake used when a wrong invite code is entered.
struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat
    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 9 * sin(shakes * .pi * 4), y: 0))
    }
}

/// Checks an invite code with the server before leaving the code screen, so a
/// wrong code is reported right on the card instead of on a new page.
enum InviteCodeCheck {
    enum Outcome { case ok(String), failed(String) }

    static func run(_ raw: String, api: APIClient, t: Strings) async -> Outcome {
        guard let inviteCode = InviteLink.code(from: raw) else { return .failed(t.fieldRequired) }
        do {
            let _: DrawPublicInfo = try await api.send(API.publicDraw(inviteCode: inviteCode))
            return .ok(inviteCode)
        } catch APIError.server(status: 404, _) {
            return .failed(t.codeNotFound)
        } catch {
            return .failed(error.userMessage(t))
        }
    }
}

/// Red scene header shared by both code-entry screens: title, hint and Santa
/// (who looks sad, with a little speech bubble, when the code was wrong).
struct JoinCodeHero: View {
    var failed: Bool
    @Environment(\.strings) private var t

    var body: some View {
        VStack(spacing: 6) {
            Text(t.haveInvite)
                .font(AppFont.script(48))
                .foregroundStyle(Palette.goldLight)
                .shadow(color: Color(hex: 0x3C0000, alpha: 0.3), radius: 0, y: 3)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(t.haveInviteSub)
                .font(AppFont.body(15, .bold))
                .foregroundStyle(Palette.snow.opacity(0.95))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 40)
            SantaAvatar(size: 132, mood: failed ? .sad : .invite)
                .id(failed)
                .transition(.opacity)
                .overlay(alignment: .topTrailing) {
                    if failed {
                        Text(t.codeNotFoundBubble)
                            .font(AppFont.display(13))
                            .foregroundStyle(Palette.brandText)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Palette.snow, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Palette.gold, lineWidth: 2))
                            .fixedSize()
                            .offset(x: 86, y: 6)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                // The artwork has empty space above the hat; pull him up under the text.
                .padding(.top, -18)
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(duration: 0.35), value: failed)
    }
}

/// Signed-out entry point from onboarding ("Kodla katıl").
struct JoinCodeScreen: View {
    @Binding var path: [AuthRoute]
    @Environment(\.strings) private var t
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var session
    @State private var code = ""
    @State private var error: String?
    @State private var scanning = false
    @State private var isChecking = false
    @State private var shake = 0
    @FocusState private var focused: Bool

    var body: some View {
        ZStack(alignment: .top) {
            ChristmasBackdrop(garland: true, pines: false)
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                SnowFriends(fill: Palette.page, height: 84)
            }
            .ignoresSafeArea(.container, edges: .bottom)
            .ignoresSafeArea(.keyboard)
            VStack(spacing: 0) {
                HStack {
                    OrnamentBackButton(stringLength: 50) { dismiss() }
                    Spacer()
                }
                .padding(.leading, 12)
                .padding(.top, -46)
                JoinCodeHero(failed: error != nil)
                    .padding(.top, -22)
                ScrollView {
                    JoinCodeCard(code: $code, error: error, focused: $focused, onSubmit: submit, onScan: { scanning = true }, isChecking: isChecking, shake: shake)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 22)
                        .foilCard(radius: 30)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .statusBarStyle(.lightContent)
        .onChange(of: code) { _, _ in if error != nil { withAnimation { error = nil } } }
        .fullScreenCover(isPresented: $scanning) {
            QRScannerSheet { scanned in
                code = scanned
                submit()
            }
        }
    }

    private func submit() {
        guard !isChecking else { return }
        isChecking = true
        Task {
            let outcome = await InviteCodeCheck.run(code, api: session.api, t: t)
            isChecking = false
            switch outcome {
            case let .ok(inviteCode):
                error = nil
                focused = false
                path.append(.joinForm(inviteCode))
            case let .failed(message):
                withAnimation { error = message }
                shake += 1
            }
        }
    }
}
