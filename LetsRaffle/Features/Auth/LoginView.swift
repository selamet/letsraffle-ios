import SwiftUI

struct LoginView: View {
    @Binding var path: [AuthRoute]
    @Environment(\.strings) private var t
    @Environment(SessionStore.self) private var session

    @State private var email = ""
    @State private var password = ""
    @State private var showErrors = false
    @State private var isLoading = false
    @State private var serverError: String?
    @State private var passwordFocused = false

    var body: some View {
        AuthScaffold(
            mood: passwordFocused ? .cover : .list,
            script: t.welcome,
            subtitle: t.welcomeSub,
            bubble: passwordFocused ? t.notLooking : nil
        ) {
            VStack(alignment: .leading, spacing: 14) {
                AuthSegment(selected: .login) { _ in path = [.register] }

                ScreenHeader(title: t.loginTitle, titleSize: 27)
                    .padding(.top, 6)

                if session.expiredMessageVisible {
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
                        error: showErrors ? Validation.passwordError(password, t) : nil,
                        onFocusChange: { focused in withAnimation { passwordFocused = focused } }
                    )
                    Button(t.forgot) { path.append(.forgotPassword) }
                        .font(AppFont.body(14, .bold))
                        .foregroundStyle(Palette.brandText)
                        .frame(minHeight: 36)
                }

                Button {
                    submit()
                } label: {
                    HStack(spacing: 8) {
                        Text(t.loginBtn)
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(.festive(loading: isLoading))
                .disabled(isLoading)
                .accessibilityIdentifier("login.submit")

                OrDivider(title: t.or)

                VStack(spacing: 4) {
                    AppleSignInButton(title: t.appleContinue) { serverError = $0 }
                    GoogleSignInButton { serverError = $0 }
                }

                HStack(spacing: 4) {
                    Text(t.tryWithoutAccount).foregroundStyle(Palette.sub)
                    Button(t.manualDraw) { session.continueAsGuest() }
                        .fontWeight(.heavy)
                        .foregroundStyle(Palette.greenText)
                }
                .font(AppFont.body(14, .semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
            }
        }
        .onDisappear { session.dismissExpiredMessage() }
    }

    private func submit() {
        showErrors = true
        serverError = nil
        guard Validation.emailError(email, t) == nil, Validation.passwordError(password, t) == nil else { return }
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                try await session.login(email: email, password: password)
            } catch {
                serverError = error.userMessage(t)
            }
        }
    }
}
