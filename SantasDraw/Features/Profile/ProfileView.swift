import SwiftUI

/// Tab 3: account, preferences, about, logout and account deletion.
struct ProfileView: View {
    @Environment(\.strings) private var t
    @Environment(SessionStore.self) private var session
    @Environment(AppSettings.self) private var settings

    @State private var confirmDelete = false
    @State private var isDeleting = false
    @State private var deleteError: String?
    @State private var showWidgetHelp = false

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(t.tabProfile)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Palette.text)
                        .padding(.horizontal, 8)

                    accountCard

                    section(t.preferences) {
                        row(icon: .text(settings.language.rawValue), tint: Color(hex: 0x155DFC), title: t.language, separator: true) {
                            Picker(t.language, selection: $settings.language) {
                                ForEach(AppLanguage.allCases) { Text($0.rawValue).tag($0) }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 110)
                        }
                        row(icon: .symbol("moon.fill"), tint: Color(hex: 0x1D293D), title: t.appearance, separator: true) {
                            Picker(t.appearance, selection: $settings.appearance) {
                                ForEach(AppearancePreference.allCases) { Text($0.title(t)).tag($0) }
                            }
                            .pickerStyle(.menu)
                            .tint(Palette.sub)
                        }
                        row(icon: .symbol("bell.fill"), tint: Color(hex: 0xFF3B30), title: t.notifications, separator: true) {
                            Toggle("", isOn: $settings.notificationsEnabled).labelsHidden().tint(Color(hex: 0x34C759))
                        }
                        Button { showWidgetHelp = true } label: {
                            row(icon: .symbol("square.grid.2x2.fill"), tint: Color(hex: 0xFE9A00), title: t.widgets) { chevron }
                        }
                        .buttonStyle(.plain)
                    }

                    section(t.about) {
                        Link(destination: AppConfig.sourceCodeURL) {
                            row(icon: .text("❤️"), tint: Color(hex: 0x1D293D), title: t.openSource, separator: true) {
                                HStack(spacing: 6) {
                                    Text("GitHub").font(.system(size: 15)).foregroundStyle(Palette.sub)
                                    chevron
                                }
                            }
                        }
                        row(icon: .symbol("info"), tint: Color(hex: 0x8E8E93), title: t.version) {
                            Text(AppConfig.version).font(.system(size: 15)).foregroundStyle(Palette.sub)
                        }
                    }

                    actions
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .floatingTabBarInset()
            .background(Palette.page)
            .toolbar(.hidden, for: .navigationBar)
        }
        .confirmationDialog(t.deleteAccount, isPresented: $confirmDelete, titleVisibility: .visible) {
            Button(t.deleteAccount, role: .destructive) { Task { await deleteAccount() } }
            Button(t.cancel, role: .cancel) {}
        } message: {
            Text(t.deleteAccountConfirm)
        }
        .alert(t.deleteAccountFailed, isPresented: Binding(get: { deleteError != nil }, set: { if !$0 { deleteError = nil } })) {
            Button(t.ok) {}
        } message: {
            Text(deleteError ?? "")
        }
        .alert(t.widgets, isPresented: $showWidgetHelp) {
            Button(t.ok) {}
        } message: {
            Text(t.widgetsHowTo)
        }
    }

    // MARK: Sections

    private var accountCard: some View {
        HStack(spacing: 14) {
            Text(initials)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(LinearGradient(colors: [Color(hex: 0xFF6467), Color(hex: 0xE7000B)], startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                if let user = session.user {
                    Text(user.email.components(separatedBy: "@").first ?? user.email)
                        .font(.system(size: 20, weight: .semibold)).foregroundStyle(Palette.text).lineLimit(1)
                    Text(user.email).font(.system(size: 14)).foregroundStyle(Palette.sub).lineLimit(1)
                    if user.hasApple == true {
                        Label(t.appleLinked, systemImage: "applelogo").font(.system(size: 12)).foregroundStyle(Palette.sub)
                    }
                } else {
                    Text(t.guest).font(.system(size: 20, weight: .semibold)).foregroundStyle(Palette.text)
                    Text(t.guestDrawsHint).font(.system(size: 13)).foregroundStyle(Palette.sub)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    @ViewBuilder
    private var actions: some View {
        if session.isSignedIn {
            Button { Task { await session.signOut() } } label: {
                Text(t.logout).actionLabel(color: Color(hex: 0xFF3B30))
            }
            .accessibilityIdentifier("profile.logout")
            Button { confirmDelete = true } label: {
                ZStack {
                    Text(t.deleteAccount).opacity(isDeleting ? 0 : 1)
                    if isDeleting { ProgressView() }
                }
                .actionLabel(color: Palette.sub, weight: .regular, size: 15)
            }
            .disabled(isDeleting)
        } else {
            Button(t.loginBtn) { session.exitGuestMode() }.buttonStyle(.primary)
        }
    }

    // MARK: Building blocks

    private enum RowIcon { case symbol(String), text(String) }

    private var initials: String {
        guard let email = session.user?.email else { return "🎅" }
        return String(email.prefix(2)).uppercased()
    }

    private var chevron: some View {
        Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.ter)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13))
                .textCase(.uppercase)
                .foregroundStyle(Palette.sub)
                .padding(.horizontal, 20)
            CardSection { content() }
        }
    }

    private func row<Trailing: View>(icon: RowIcon, tint: Color, title: String, separator: Bool = false, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: 12) {
            Group {
                switch icon {
                case let .symbol(name): Image(systemName: name).font(.system(size: 14, weight: .semibold))
                case let .text(text): Text(text).font(.system(size: 12, weight: .bold))
                }
            }
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(tint, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            Text(title).font(.system(size: 17)).foregroundStyle(Palette.text)
            Spacer(minLength: 8)
            trailing()
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            if separator { Rectangle().fill(Palette.sep).frame(height: 0.5).padding(.leading, 58) }
        }
    }

    private func deleteAccount() async {
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await session.deleteAccount()
        } catch {
            deleteError = error.userMessage(t)
        }
    }
}

private extension View {
    func actionLabel(color: Color, weight: Font.Weight = .medium, size: CGFloat = 17) -> some View {
        font(.system(size: size, weight: weight))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }
}
