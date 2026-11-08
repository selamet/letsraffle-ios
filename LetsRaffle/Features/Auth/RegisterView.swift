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
    @State private var passwordFocused = false

    var body: some View {
        AuthScaffold(
            mood: passwordFocused ? .cover : .list,
            script: t.welcome,
            subtitle: t.welcomeSub,
            bubble: passwordFocused ? t.notLooking : nil
        ) {
            VStack(alignment: .leading, spacing: 14) {
                AuthSegment(selected: .register) { _ in path = [.login] }

                ScreenHeader(title: t.registerTitle, subtitle: t.registerSub, titleSize: 27)
                    .padding(.top, 6)

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
                    error: showErrors ? Validation.passwordError(password, t) : nil,
                    onFocusChange: { focused in withAnimation { passwordFocused = focused } }
                )

                Button(t.registerBtn, action: submit)
                    .buttonStyle(.primary(loading: isLoading))
                    .disabled(isLoading)
                    .padding(.top, 4)
                    .accessibilityIdentifier("register.submit")

                OrDivider(title: t.or)

                VStack(spacing: 4) {
                    AppleSignInButton(title: t.appleSignup) { serverError = $0 }
                    GoogleSignInButton { serverError = $0 }
                    LegalNotice().padding(.top, 4)
                }

                HStack(spacing: 4) {
                    Text(t.haveAccount).foregroundStyle(Palette.sub)
                    Button(t.loginLink) { path = [.login] }
                        .fontWeight(.heavy)
                        .foregroundStyle(Palette.brandText)
                }
                .font(AppFont.body(15, .semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
            }
        }
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
