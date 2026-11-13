import AuthenticationServices
import SwiftUI

/// Result of a successful Apple authorization.
struct AppleCredential: Equatable {
    let identityToken: String
    /// One-time code the backend exchanges for the refresh token it revokes
    /// when the account is deleted (App Store guideline 5.1.1(v)).
    var authorizationCode: String? = nil
    let firstName: String?
    let lastName: String?
}

/// Runs `ASAuthorizationController` with async/await.
@MainActor
final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<AppleCredential?, Error>?

    /// Returns `nil` when the user cancels.
    func signIn() async throws -> AppleCredential? {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            controller.performRequests()
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        let credential = authorization.credential as? ASAuthorizationAppleIDCredential
        let token = credential?.identityToken.flatMap { String(data: $0, encoding: .utf8) }
        let code = credential?.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
        let result = token.map {
            AppleCredential(
                identityToken: $0,
                authorizationCode: code,
                firstName: credential?.fullName?.givenName,
                lastName: credential?.fullName?.familyName
            )
        }
        Task { @MainActor in
            if let result {
                self.finish(.success(result))
            } else {
                self.finish(.failure(APIError.invalidResponse))
            }
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let canceled = (error as? ASAuthorizationError)?.code == .canceled
        Task { @MainActor in
            self.finish(canceled ? .success(nil) : .failure(error))
        }
    }

    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                .first ?? ASPresentationAnchor()
        }
    }

    private func finish(_ result: Result<AppleCredential?, Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }
}

/// Apple sign-in button matching the design; shows a spinner while working
/// and reports errors (cancellation is silent).
struct AppleSignInButton: View {
    enum Style { case black, inverted }

    let title: String
    var style: Style = .inverted
    var onError: (String) -> Void = { _ in }

    @Environment(\.strings) private var t
    @Environment(SessionStore.self) private var session
    @State private var coordinator = AppleSignInCoordinator()
    @State private var isLoading = false

    var body: some View {
        Button {
            Task { await run() }
        } label: {
            AppleLabel(title: title)
        }
        // Apple's guidelines: always a black (or white) button with the Apple logo.
        .buttonStyle(PrimaryButtonStyle(background: .black, foreground: .white, edge: .black, rim: .clear, isLoading: isLoading, height: 54))
        .disabled(isLoading)
        .accessibilityIdentifier("auth.apple")
    }

    private func run() async {
        isLoading = true
        defer { isLoading = false }
        do {
            guard let credential = try await coordinator.signIn() else { return }
            try await session.signInWithApple(credential)
        } catch {
            onError(error.userMessage(t))
        }
    }
}
