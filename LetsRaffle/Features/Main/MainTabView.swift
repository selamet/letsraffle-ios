import SwiftUI

enum MainTab: Hashable, CaseIterable {
    /// Home (start a draw), join with a code, and everything the person created or joined.
    /// The profile lives behind the button in the home header.
    case draws, join, events

    var icon: String {
        switch self {
        case .draws: "house.fill"
        case .join: "ticket.fill"
        case .events: "gift.fill"
        }
    }

    func title(_ t: Strings) -> String {
        switch self {
        case .draws: t.tabHome
        case .join: t.tabJoin
        case .events: t.tabEvents
        }
    }
}

/// Lets pushed screens hide the floating tab bar.
@Observable
final class TabBarVisibility {
    var isHidden = false
    /// Lets a screen switch tabs (e.g. "Kodla katıl" on the home header).
    var requestedTab: MainTab?
}

/// Root of the signed-in / guest experience with the floating capsule tab bar.
struct MainTabView: View {
    @State private var selection: MainTab = DebugRoute.current == "tab:join" ? .join : ((DebugRoute.current ?? "").hasPrefix("tab:events") ? .events : .draws)
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
            EventsView()
                .tag(MainTab.events)
                .toolbar(.hidden, for: .tabBar)
        }
        .overlay(alignment: .bottom) {
            if !tabBar.isHidden {
                FloatingTabBar(selection: $selection)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: tabBar.isHidden)
        .environment(tabBar)
        .onChange(of: tabBar.requestedTab) { _, tab in
            guard let tab else { return }
            selection = tab
            tabBar.requestedTab = nil
        }
        .onChange(of: router.pendingInviteCode, initial: true) { _, code in
            if code != nil { selection = .join }
        }
        .onChange(of: router.pendingDestination, initial: true) { _, destination in
            switch destination {
            case .drawDetail: selection = .draws
            case .reveal: selection = .join
            case nil: break
            }
        }
    }
}

extension View {
    /// Keeps scrollable tab-root content clear of the floating tab bar.
    func floatingTabBarInset() -> some View {
        safeAreaPadding(.bottom, FloatingTabBar.reservedHeight)
    }
}

struct FloatingTabBar: View {
    static let reservedHeight: CGFloat = 92

    @Binding var selection: MainTab
    @Environment(\.strings) private var t

    var body: some View {
        HStack(alignment: .center) {
            ForEach(MainTab.allCases, id: \.self) { tab in
                let selected = tab == selection
                Button {
                    selection = tab
                } label: {
                    // Every tab has the same icon slot and label line, so the three labels sit
                    // on one baseline; the join ornament just rises out of its slot.
                    VStack(spacing: 3) {
                        if tab == .join {
                            Color.clear
                                .frame(height: 24)
                                .overlay(alignment: .bottom) {
                                    Image(systemName: tab.icon)
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 58, height: 58)
                                        .background(selected ? Palette.brand : Palette.cranberryDark, in: Circle())
                                        .overlay(Circle().strokeBorder(Palette.goldLight, lineWidth: 3))
                                        .background(Circle().fill(Color(hex: 0x4A080C)).offset(y: 4))
                                        .shadow(color: Color(hex: 0x6E0D12, alpha: 0.3), radius: 8, y: 6)
                                        .offset(y: -3)
                                }
                        } else {
                            Image(systemName: tab.icon)
                                .font(.system(size: 21, weight: .semibold))
                                .frame(height: 24)
                        }
                        Text(tab.title(t)).font(AppFont.body(11, selected ? .black : .bold))
                    }
                    .foregroundStyle(selected ? Palette.brandText : Palette.sub)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
                .accessibilityIdentifier("tab.\(tab)")
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(
            Capsule(style: .continuous)
                .fill(Palette.tabBar)
                .overlay(Capsule(style: .continuous).strokeBorder(Palette.gold, lineWidth: 2))
                .shadow(color: Color(hex: 0x3C0000, alpha: 0.14), radius: 10, y: 5)
        )
        .padding(.horizontal, 18)
        .padding(.bottom, 2)
        .animation(.spring(duration: 0.3), value: selection)
    }
}
