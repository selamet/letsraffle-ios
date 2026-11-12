import GoogleSignIn
import SwiftUI

/// "Continue with Google" button.
///
/// Runs the GoogleSignIn-iOS flow (client ID from `GIDClientID` in Info.plist) and
/// exchanges the Google ID token for a Lets Raffle session at `POST /auth/google`.
struct GoogleSignInButton: View {
    var onError: (String) -> Void = { _ in }
    @Environment(SessionStore.self) private var session
    @Environment(\.strings) private var t
    @State private var isLoading = false

    var body: some View {
        Button {
            Task { await run() }
        } label: {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                } else {
                    Image("google-g")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                }
                Text(t.google)
            }
        }
        .buttonStyle(.outlinedWhite)
        .disabled(isLoading)
        .accessibilityIdentifier("auth.google")
    }

    @MainActor
    private func run() async {
        guard let presenter = Self.topViewController() else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
            guard let idToken = result.user.idToken?.tokenString else {
                onError(t.googleFailed)
                return
            }
            try await session.signInWithGoogle(idToken: idToken)
        } catch let error as GIDSignInError where error.code == .canceled {
            // The user closed the Google sheet; nothing to report.
        } catch {
            onError(error.userMessage(t))
        }
    }

    /// The view controller GoogleSignIn presents its sheet from.
    @MainActor
    private static func topViewController() -> UIViewController? {
        let window = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first
        var controller = window?.rootViewController
        while let presented = controller?.presentedViewController {
            controller = presented
        }
        return controller
    }
}
