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
            // The red header stays put; only the cream sheet scrolls.
            VStack(spacing: 0) {
                header
                ScrollView {
                VStack(alignment: .leading, spacing: 18) {

                    section(t.preferences) {
                        row(icon: .text(settings.language.rawValue), tint: Palette.pine, title: t.language, separator: true) {
                            Picker(t.language, selection: $settings.language) {
                                ForEach(AppLanguage.allCases) { Text($0.rawValue).tag($0) }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 110)
                        }
                        row(icon: .symbol("moon.fill"), tint: Palette.cranberryDark, title: t.appearance, separator: true) {
                            Picker(t.appearance, selection: $settings.appearance) {
                                ForEach(AppearancePreference.allCases) { Text($0.title(t)).tag($0) }
                            }
                            .pickerStyle(.menu)
                            .tint(Palette.sub)
                        }
                        row(icon: .symbol("bell.fill"), tint: Palette.goldDark, title: t.notifications, separator: true) {
                            Toggle(isOn: $settings.notificationsEnabled) { EmptyView() }.toggleStyle(CandyToggleStyle()).accessibilityLabel(t.notifications)
                        }
                        Button { showWidgetHelp = true } label: {
                            row(icon: .symbol("square.grid.2x2.fill"), tint: Palette.brand, title: t.widgets) { chevron }
                        }
                        .buttonStyle(.plain)
                    }

                    section(t.about) {
                        Link(destination: AppConfig.privacyURL) {
                            row(icon: .symbol("hand.raised.fill"), tint: Palette.pine, title: t.privacyPolicy, separator: true) { chevron }
                        }
                        Link(destination: AppConfig.termsURL) {
                            row(icon: .symbol("doc.text.fill"), tint: Palette.goldDark, title: t.termsOfUse, separator: true) { chevron }
                        }
                        Link(destination: AppConfig.sourceCodeURL) {
                            row(icon: .symbol("chevron.left.forwardslash.chevron.right"), tint: Palette.brand, title: t.openSource, separator: true) {
                                HStack(spacing: 6) {
                                    Text("GitHub").font(AppFont.body(14, .semibold)).foregroundStyle(Palette.sub)
                                    chevron
                                }
                            }
                        }
                        row(icon: .symbol("info"), tint: Palette.ter, title: t.version) {
                            Text(AppConfig.version).font(AppFont.body(14, .semibold)).foregroundStyle(Palette.sub)
                        }
                    }

                    actions
                }
                .padding(.horizontal, 16)
                .padding(.top, 22)
                .padding(.bottom, 24)
                }
                .floatingTabBarInset()
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 34, topTrailingRadius: 34, style: .continuous))
                .background(
                    UnevenRoundedRectangle(topLeadingRadius: 34, topTrailingRadius: 34, style: .continuous)
                        .fill(Palette.page)
                        .shadow(color: Color(hex: 0x320000, alpha: 0.3), radius: 18, y: -8)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
            .background(alignment: .top) {
                ChristmasBackdrop(garland: true, pines: false).frame(height: 420)
            }
            .background(Palette.page.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .statusBarStyle(.lightContent)
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

    /// Red scene header: gold initial badge, "Profil" in script, name / e-mail and Santa waving.
    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            Group {
                if session.user == nil {
                    // Guests have no initial: show the gift box instead.
                    Image("gift-closed").resizable().scaledToFit().padding(.horizontal, 7).padding(.top, 4)
                } else {
                    Text(initials)
                        .font(AppFont.display(26))
                        .foregroundStyle(Palette.cranberryDark)
                }
            }
                .frame(width: 68, height: 68)
                .background(Palette.goldGradient, in: Circle())
                .overlay(Circle().strokeBorder(Palette.snow, lineWidth: 3))
                .background(Circle().fill(Palette.goldDark).offset(y: 5))
            VStack(alignment: .leading, spacing: 2) {
                Text(t.tabProfile)
                    .font(AppFont.script(30))
                    .foregroundStyle(Palette.goldLight)
                if let user = session.user {
                    Text(user.email.components(separatedBy: "@").first ?? user.email)
                        .font(AppFont.display(24)).foregroundStyle(Palette.snow).lineLimit(1).minimumScaleFactor(0.7)
                    Text(user.email).font(AppFont.body(13.5, .bold)).foregroundStyle(Palette.snow.opacity(0.9)).lineLimit(1)
                    if user.hasApple == true {
                        Label(t.appleLinked, systemImage: "applelogo").font(AppFont.body(12, .bold)).foregroundStyle(Palette.goldLight)
                    }
                } else {
                    Text(t.guest).font(AppFont.display(24)).foregroundStyle(Palette.snow)
                    Text(t.guestDrawsHint).font(AppFont.body(13, .semibold)).foregroundStyle(Palette.snow.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            SantaAvatar(size: 76, mood: .wave)
        }
        .padding(.horizontal, 20)
        .padding(.top, 96)
        .padding(.bottom, 22)
    }

    @ViewBuilder
    private var actions: some View {
        if session.isSignedIn {
            Button { Task { await session.signOut() } } label: {
                Label(t.logout, systemImage: "rectangle.portrait.and.arrow.right").actionLabel(color: Palette.brandText)
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
        guard let email = session.user?.email else { return "LR" }
        return String(email.prefix(1)).uppercased()
    }

    private var chevron: some View {
        Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.ter)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.eyebrow)
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundStyle(Palette.sub)
                .padding(.horizontal, 6)
            CardSection { content() }
        }
    }

    private func row<Trailing: View>(icon: RowIcon, tint: Color, title: String, separator: Bool = false, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: 12) {
            Group {
                switch icon {
                case let .symbol(name): Image(systemName: name).font(.system(size: 14, weight: .semibold))
                case let .text(text): Text(text).font(AppFont.body(12, .black))
                }
            }
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(tint, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(title).font(AppFont.body(16, .bold)).foregroundStyle(Palette.text)
            Spacer(minLength: 8)
            trailing()
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            if separator { Rectangle().fill(Palette.sep).frame(height: 1).padding(.leading, 60) }
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
    func actionLabel(color: Color, weight: Font.Weight = .bold, size: CGFloat = 16) -> some View {
        font(AppFont.body(size, weight))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.cardBorder, lineWidth: 2))
    }
}
