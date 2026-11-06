import SwiftUI

enum MainTab: Hashable, CaseIterable {
    case draws, join, profile

    var icon: String {
        switch self {
        case .draws: "gift.fill"
        case .join: "qrcode.viewfinder"
        case .profile: "person.crop.circle"
        }
    }

    func title(_ t: Strings) -> String {
        switch self {
        case .draws: t.tabDraws
        case .join: t.tabJoin
        case .profile: t.tabProfile
        }
    }
}

/// Lets pushed screens hide the floating tab bar.
@Observable
final class TabBarVisibility {
    var isHidden = false
}

/// Root of the signed-in / guest experience with the floating capsule tab bar.
struct MainTabView: View {
    @State private var selection: MainTab = DebugRoute.current == "tab:join" ? .join : (DebugRoute.current == "tab:profile" ? .profile : .draws)
    @State private var tabBar = TabBarVisibility()
    @Environment(DeepLinkRouter.self) private var router

    var body: some View {
        TabView(selection: $selection) {
            DrawsHomeView()
                .tag(MainTab.draws)
                .toolbar(.hidden, for: .tabBar)
            JoinTabView()
                .tag(MainTab.join)
                .toolbar(.hidden, for: .tabBar)
            ProfilePlaceholderView()
                .tag(MainTab.profile)
                .toolbar(.hidden, for: .tabBar)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !tabBar.isHidden {
                FloatingTabBar(selection: $selection)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: tabBar.isHidden)
        .environment(tabBar)
        .onChange(of: router.pendingInviteCode, initial: true) { _, code in
            if code != nil { selection = .join }
        }
    }
}

struct FloatingTabBar: View {
    @Binding var selection: MainTab
    @Environment(\.strings) private var t

    var body: some View {
        HStack {
            ForEach(MainTab.allCases, id: \.self) { tab in
                let selected = tab == selection
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.icon).font(.system(size: 20, weight: .semibold))
                        Text(tab.title(t)).font(.system(size: 10, weight: selected ? .semibold : .medium))
                    }
                    .foregroundStyle(selected ? Palette.brandText : Palette.sub)
                    .padding(.horizontal, 18)
                    .frame(height: 52)
                    .background {
                        if selected { Capsule().fill(Palette.chip) }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
                .accessibilityIdentifier("tab.\(tab)")
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 64)
        .background(.ultraThinMaterial, in: Capsule())
        .background(Palette.tabBar, in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.4), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.14), radius: 15, y: 8)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .animation(.spring(duration: 0.3), value: selection)
    }
}

/// Replaced by the Profile tab in #8.
private struct ProfilePlaceholderView: View {
    @Environment(\.strings) private var t
    @Environment(SessionStore.self) private var session

    var body: some View {
        VStack(spacing: 16) {
            ScreenHeader(title: t.tabProfile, subtitle: session.user?.email ?? t.guest)
            Button(t.logout) { Task { await session.signOut() } }
                .buttonStyle(.primary)
        }
        .padding(24)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Palette.page)
    }
}
