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
                MainPlaceholderView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: session.state)
        .task { await session.restore() }
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

/// Temporary signed-in screen; replaced by the tab bar in #4.
private struct MainPlaceholderView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.strings) private var t

    var body: some View {
        VStack(spacing: 16) {
            SantaAvatar(size: 100)
            Text(session.user?.email ?? t.guest).font(.headline)
            Button(t.logout) { Task { await session.signOut() } }
                .buttonStyle(.primary)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.page)
    }
}
