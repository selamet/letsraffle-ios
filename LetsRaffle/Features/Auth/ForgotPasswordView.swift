import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.strings) private var t
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings
    @Environment(SessionStore.self) private var session

    @State private var email = ""
    @State private var showErrors = false
    @State private var isLoading = false
    @State private var sent = false
    @State private var serverError: String?

    var body: some View {
        AuthScaffold(mood: .thinking, script: t.forgotTitle, subtitle: t.forgotFun) {
            VStack(alignment: .leading, spacing: 14) {
                ScreenHeader(title: t.forgotTitle, subtitle: t.forgotSub, titleSize: 27)

                FormField(
                    label: t.email, text: $email, placeholder: t.emailPh, kind: .email,
                    error: showErrors ? Validation.emailError(email, t) : nil
                )
                Button(t.sendReset, action: submit)
                    .buttonStyle(.festive(loading: isLoading))
                    .disabled(isLoading)
                    .padding(.top, 4)

                if sent {
                    Banner(text: t.resetSent, style: .success)
                        .transition(.opacity)
                }
                if let serverError {
                    Banner(text: serverError, style: .error)
                }

                Button(t.backToLogin) { dismiss() }
                    .font(AppFont.body(15, .bold))
                    .foregroundStyle(Palette.brandText)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
        }
        .animation(.default, value: sent)
    }

    private func submit() {
        showErrors = true
        serverError = nil
        guard Validation.emailError(email, t) == nil else { return }
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                try await session.requestPasswordReset(email: email, language: settings.language)
                sent = true
            } catch {
                serverError = error.userMessage(t)
            }
        }
    }
}
