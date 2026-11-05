import SwiftUI

/// Switches between the restoring splash, the auth flow and the main app.
struct RootView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        Group {
            switch session.state {
            case .restoring:
                SplashView()
            case .signedOut:
                AuthFlowView()
                    .transition(.opacity)
            case .guest, .signedIn:
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: session.state)
        .task {
            await session.restore()
            #if DEBUG
            if !session.isSignedIn { await session.debugAutoLogin() }
            #endif
        }
    }
}

private struct SplashView: View {
    var body: some View {
        ZStack {
            Palette.heroGradient.ignoresSafeArea()
            SantaAvatar(size: 120)
        }
    }
}
