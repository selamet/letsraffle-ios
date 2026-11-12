import SwiftUI

/// E-mail login and registration on one screen. Switching between the two only swaps the
/// parts that differ; the scene, the card and whatever was typed stay where they are.
struct EmailAuthView: View {
    enum Mode { case login, register }

    @Binding var path: [AuthRoute]
    @State var mode: Mode
    @Environment(\.strings) private var t
    @Environment(SessionStore.self) private var session

    @State private var email = ""
    @State private var password = ""
    @State private var showErrors = false
    @State private var isLoading = false
    @State private var serverError: String?
    @State private var passwordFocused = false

    private var isLogin: Bool { mode == .login }

    var body: some View {
        AuthScaffold(
            mood: passwordFocused ? .cover : .list,
            script: t.welcome,
            subtitle: t.welcomeSub,
            bubble: passwordFocused ? t.notLooking : nil
        ) {
            VStack(alignment: .leading, spacing: 14) {
                AuthSegment(selected: isLogin ? .login : .register) { tab in
                    switchTo(tab == .login ? .login : .register)
                }

                ScreenHeader(
                    title: isLogin ? t.loginTitle : t.registerTitle,
                    subtitle: isLogin ? nil : t.registerSub,
                    titleSize: 27
                )
                .padding(.top, 6)

                if isLogin, session.expiredMessageVisible {
                    Banner(text: t.sessionExpired, style: .info)
                }
                if let serverError {
                    Banner(text: serverError, style: .error)
                }
                FormField(
                    label: t.email, text: $email, placeholder: t.emailPh, kind: .email,
                    error: showErrors ? Validation.emailError(email, t) : nil
                )
                VStack(alignment: .trailing, spacing: 2) {
                    FormField(
                        label: t.password, text: $password, placeholder: t.passwordPh, kind: .password,
                        hint: isLogin ? nil : t.passwordRule,
                        error: showErrors ? Validation.passwordError(password, t) : nil,
                        onFocusChange: { focused in withAnimation { passwordFocused = focused } }
                    )
                    if isLogin {
                        Button(t.forgot) { path.append(.forgotPassword) }
                            .font(AppFont.body(14, .bold))
                            .foregroundStyle(Palette.brandText)
                            .frame(minHeight: 36)
                    }
                }

                Button(action: submit) {
                    HStack(spacing: 8) {
                        Text(isLogin ? t.loginBtn : t.registerBtn)
                        if isLogin { Image(systemName: "arrow.right") }
                    }
                }
                .buttonStyle(.festive(loading: isLoading))
                .disabled(isLoading)
                .padding(.top, isLogin ? 0 : 4)
                .accessibilityIdentifier(isLogin ? "login.submit" : "register.submit")

                OrDivider(title: t.or)

                VStack(spacing: 4) {
                    AppleSignInButton(title: isLogin ? t.appleContinue : t.appleSignup) { serverError = $0 }
                    GoogleSignInButton { serverError = $0 }
                    if !isLogin { LegalNotice().padding(.top, 4) }
                }

                if isLogin {
                    HStack(spacing: 4) {
                        Text(t.tryWithoutAccount).foregroundStyle(Palette.sub)
                        Button(t.manualDraw) { session.continueAsGuest() }
                            .fontWeight(.heavy)
                            .foregroundStyle(Palette.greenText)
                    }
                    .font(AppFont.body(14, .semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
                } else {
                    HStack(spacing: 4) {
                        Text(t.haveAccount).foregroundStyle(Palette.sub)
                        Button(t.loginLink) { switchTo(.login) }
                            .fontWeight(.heavy)
                            .foregroundStyle(Palette.brandText)
                    }
                    .font(AppFont.body(15, .semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
            }
        }
        .onDisappear { session.dismissExpiredMessage() }
    }

    private func switchTo(_ newMode: Mode) {
        guard newMode != mode else { return }
        showErrors = false
        serverError = nil
        withAnimation(.easeInOut(duration: 0.2)) { mode = newMode }
    }

    private func submit() {
        showErrors = true
        serverError = nil
        guard Validation.emailError(email, t) == nil, Validation.passwordError(password, t) == nil else { return }
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                if isLogin {
                    try await session.login(email: email, password: password)
                } else {
                    try await session.register(email: email, password: password)
                }
            } catch {
                serverError = error.userMessage(t)
            }
        }
    }
}
