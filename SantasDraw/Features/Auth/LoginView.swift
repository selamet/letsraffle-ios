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

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                AuthTopBar {
                    PillButton(title: t.register) { path = [.register] }
                }

                ScreenHeader(eyebrow: t.brandEyebrow, title: t.loginTitle, subtitle: t.loginSub)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                VStack(spacing: 14) {
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
                    FormField(
                        label: t.password, text: $password, placeholder: t.passwordPh, kind: .password,
                        error: showErrors ? Validation.passwordError(password, t) : nil
                    )
                    HStack {
                        Spacer()
                        Button(t.forgot) { path.append(.forgotPassword) }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Palette.brandText)
                    }
                    .padding(.top, -4)

                    Button(t.loginBtn, action: submit)
                        .buttonStyle(.primary(loading: isLoading))
                        .disabled(isLoading)
                        .padding(.top, 6)
                        .accessibilityIdentifier("login.submit")

                    OrDivider(title: t.or)

                    AppleSignInButton(title: t.apple) { serverError = $0 }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                Text(t.celebration)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.sub)
                    .padding(.top, 32)
                    .padding(.bottom, 24)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Palette.page.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
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
