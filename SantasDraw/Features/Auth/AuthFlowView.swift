import SwiftUI

enum AuthRoute: Hashable {
    case login, register, forgotPassword
}

/// Onboarding + email authentication stack shown while signed out.
struct AuthFlowView: View {
    @State private var path: [AuthRoute] = Self.initialPath

    private static var initialPath: [AuthRoute] {
        switch DebugRoute.current {
        case "login": [.login]
        case "register": [.register]
        case "forgot": [.login, .forgotPassword]
        default: []
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            OnboardingView(path: $path)
                .navigationDestination(for: AuthRoute.self) { route in
                    switch route {
                    case .login: LoginView(path: $path)
                    case .register: RegisterView(path: $path)
                    case .forgotPassword: ForgotPasswordView()
                    }
                }
        }
    }
}

enum Validation {
    static func isValidEmail(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.range(of: #"^[^@\s]+@[^@\s]+\.[^@\s]{2,}$"#, options: .regularExpression) != nil
    }

    static func emailError(_ value: String, _ t: Strings) -> String? {
        if value.trimmingCharacters(in: .whitespaces).isEmpty { return t.fieldRequired }
        return isValidEmail(value) ? nil : t.invalidEmail
    }

    static func passwordError(_ value: String, _ t: Strings) -> String? {
        value.count >= 6 ? nil : t.passwordTooShort
    }

    static func requiredError(_ value: String?, _ t: Strings) -> String? {
        (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? t.fieldRequired : nil
    }
}

/// Top bar with a circular back button and an optional trailing view.
struct AuthTopBar<Trailing: View>: View {
    @Environment(\.dismiss) private var dismiss
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack {
            CircleIconButton { dismiss() }
            Spacer()
            trailing
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

extension AuthTopBar where Trailing == EmptyView {
    init() { self.init { EmptyView() } }
}
