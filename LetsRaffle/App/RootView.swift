import SwiftUI

/// Switches between the restoring splash, the auth flow and the main app.
struct RootView: View {
    @Environment(SessionStore.self) private var session
    @Environment(DeepLinkRouter.self) private var router
    @Environment(PushManager.self) private var push
    /// The logo + fairy-light loader stays up for a short moment on every launch.
    @State private var splashDone = false

    var body: some View {
        Group {
            switch splashDone ? session.state : .restoring {
            case .restoring:
                SplashView()
                    .transition(.opacity)
            case .signedOut:
                AuthFlowView()
                    .transition(.opacity)
            case .guest, .signedIn:
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: session.state)
        .animation(.easeInOut(duration: 0.35), value: splashDone)
        .task {
            try? await Task.sleep(for: .seconds(1.6))
            splashDone = true
        }
        .onAppear {
            // No scroll bars anywhere in the app (also covers sheets and UIKit-backed lists).
            UIScrollView.appearance().showsVerticalScrollIndicator = false
            UIScrollView.appearance().showsHorizontalScrollIndicator = false
            DispatchQueue.main.async { KeyboardDismisser.install() }
        }
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
            if DebugRoute.current == "push" { push.isPromptPresented = true }
            InviteStory.debugDump()
            InvitePoster.debugDump()
            if let route = DebugRoute.current, route.hasPrefix("reveal:") {
                router.pendingDestination = .reveal(inviteCode: String(route.dropFirst(7)))
            }
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
            SnowDots()
            VStack(spacing: 22) {
                Image("lockup").resizable().scaledToFit().frame(width: 250)
                    .shadow(color: Color(hex: 0x280000, alpha: 0.35), radius: 8, y: 5)
                ChristmasLoader(onDark: true, width: 160)
            }
        }
    }
}
