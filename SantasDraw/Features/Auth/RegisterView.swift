import SwiftUI

struct RegisterView: View {
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
                AuthTopBar()

                ScreenHeader(eyebrow: t.brandEyebrow, title: t.registerTitle, subtitle: t.registerSub)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                VStack(spacing: 14) {
                    if let serverError {
                        Banner(text: serverError, style: .error)
                    }
                    FormField(
                        label: t.email, text: $email, placeholder: t.emailPh, kind: .email,
                        error: showErrors ? Validation.emailError(email, t) : nil
                    )
                    FormField(
                        label: t.password, text: $password, placeholder: t.passwordPh, kind: .password,
                        hint: t.passwordRule,
                        error: showErrors ? Validation.passwordError(password, t) : nil
                    )

                    Button(t.registerBtn, action: submit)
                        .buttonStyle(.primary(loading: isLoading))
                        .disabled(isLoading)
                        .padding(.top, 6)
                        .accessibilityIdentifier("register.submit")

                    OrDivider(title: t.or)

                    AppleSignInButton(title: t.appleSignup) { serverError = $0 }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                HStack(spacing: 4) {
                    Text(t.haveAccount).foregroundStyle(Palette.sub)
                    Button(t.loginLink) { path = [.login] }
                        .fontWeight(.semibold)
                        .foregroundStyle(Palette.brandText)
                }
                .font(.system(size: 15))
                .padding(.top, 32)
                .padding(.bottom, 24)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Palette.page.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func submit() {
        showErrors = true
        serverError = nil
        guard Validation.emailError(email, t) == nil, Validation.passwordError(password, t) == nil else { return }
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                try await session.register(email: email, password: password)
            } catch {
                serverError = error.userMessage(t)
            }
        }
    }
}
