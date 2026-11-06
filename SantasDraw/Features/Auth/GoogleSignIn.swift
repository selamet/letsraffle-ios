import SwiftUI

/// "Continue with Google" button. The API does not expose a Google OAuth
/// endpoint yet, so tapping it explains that the option is coming soon.
/// Wire `action` to GoogleSignIn-iOS once the backend supports it.
struct GoogleSignInButton: View {
    var onError: (String) -> Void = { _ in }
    @Environment(\.strings) private var t

    var body: some View {
        Button {
            onError(t.googleSoon)
        } label: {
            HStack(spacing: 10) {
                Image("google-g")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text(t.google)
            }
        }
        .buttonStyle(.outlinedWhite)
        .accessibilityIdentifier("auth.google")
    }
}
