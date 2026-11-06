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
        ScrollView {
            VStack(spacing: 0) {
                AuthTopBar()

                VStack(spacing: 12) {
                    SantaAvatar(size: 150, thinking: true)
                    Text(t.forgotFun)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Palette.brandText)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Palette.card, in: Capsule())
                        .brandShadow()
                }
                .padding(.top, 12)

                VStack(spacing: 6) {
                    Text(t.forgotTitle)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Palette.text)
                    Text(t.forgotSub)
                        .font(.system(size: 15))
                        .foregroundStyle(Palette.sub)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 20)

                VStack(spacing: 14) {
                    FormField(
                        label: t.email, text: $email, placeholder: t.emailPh, kind: .email,
                        error: showErrors ? Validation.emailError(email, t) : nil
                    )
                    Button(t.sendReset, action: submit)
                        .buttonStyle(.primary(loading: isLoading))
                        .disabled(isLoading)

                    if sent {
                        Text(t.resetSent)
                            .font(.system(size: 14))
                            .foregroundStyle(Palette.greenText)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .background(Palette.greenSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .transition(.opacity)
                    }
                    if let serverError {
                        Banner(text: serverError, style: .error)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                Button(t.backToLogin) { dismiss() }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.brandText)
                    .padding(.top, 32)
                    .padding(.bottom, 24)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Palette.page.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
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
