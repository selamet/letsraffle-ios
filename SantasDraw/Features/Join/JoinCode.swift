import SwiftUI

/// Code entry card shared by the Join tab and the signed-out "Join with code" screen.
struct JoinCodeCard: View {
    @Binding var code: String
    var error: String?
    var focused: FocusState<Bool>.Binding
    var onSubmit: () -> Void
    var onScan: (() -> Void)?

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
            TextField("", text: $code, prompt: Text("jolly-reindeer-742").foregroundStyle(Palette.ter))
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
            if let error {
                Text(error).font(AppFont.body(12, .bold)).foregroundStyle(Palette.brandText)
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
            .buttonStyle(.primary)
            .disabled(code.trimmed.isEmpty)
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

/// Signed-out entry point from onboarding ("Kodla katıl").
struct JoinCodeScreen: View {
    @Binding var path: [AuthRoute]
    @Environment(\.strings) private var t
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var error: String?
    @State private var scanning = false
    @FocusState private var focused: Bool

    var body: some View {
        ZStack(alignment: .top) {
            ChristmasBackdrop(garland: false, pines: false)
            VStack(spacing: 0) {
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
                    }
                    .padding(.bottom, 30)
                    Spacer(minLength: 4)
                    SantaAvatar(size: 140, mood: .invite)
                }
                .padding(.leading, 22)
                .padding(.trailing, 6)
                .overlay(alignment: .topLeading) {
                    CircleIconButton(onDark: true) { dismiss() }.padding(.leading, 12).offset(y: -40)
                }
                .padding(.top, 60)

                ScrollView {
                    JoinCodeCard(code: $code, error: error, focused: $focused, onSubmit: submit, onScan: { scanning = true })
                }
                .scrollDismissesKeyboard(.interactively)
                .padding(.horizontal, 24)
                .padding(.top, 26)
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
        .fullScreenCover(isPresented: $scanning) {
            QRScannerSheet { scanned in
                code = scanned
                submit()
            }
        }
    }

    private func submit() {
        guard let inviteCode = InviteLink.code(from: code) else {
            error = t.fieldRequired
            return
        }
        error = nil
        focused = false
        path.append(.joinForm(inviteCode))
    }
}
