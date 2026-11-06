import SwiftUI

/// Switches between the restoring splash, the auth flow and the main app.
struct RootView: View {
    @Environment(SessionStore.self) private var session
    @Environment(DeepLinkRouter.self) private var router

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
        .sheet(item: signedOutInvite) { invite in
            // Joining works without an account, so deep links open over onboarding.
            NavigationStack {
                JoinFormView(inviteCode: invite.code) { router.pendingInviteCode = nil }
            }
        }
        .task {
            await session.restore()
            #if DEBUG
            if !session.isSignedIn { await session.debugAutoLogin() }
            if let route = DebugRoute.current, route.hasPrefix("join:") {
                router.handle(InviteLink.deepLink(for: String(route.dropFirst(5))))
            }
            #endif
        }
    }
}

private struct PendingInvite: Identifiable {
    let code: String
    var id: String { code }
}

private extension RootView {
    var signedOutInvite: Binding<PendingInvite?> {
        Binding(
            get: { session.state == .signedOut ? router.pendingInviteCode.map(PendingInvite.init) : nil },
            set: { if $0 == nil { router.pendingInviteCode = nil } }
        )
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
