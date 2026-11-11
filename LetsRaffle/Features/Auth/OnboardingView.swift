import SwiftUI

/// Welcome screen: Santa drawing from his sack on a red scene, cream sheet with sign-in options.
struct OnboardingView: View {
    @Binding var path: [AuthRoute]
    @Environment(\.strings) private var t
    @Environment(SessionStore.self) private var session
    @Environment(DeepLinkRouter.self) private var router
    @State private var authError: String?
    @State private var appeared = false

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.height < 760
            ZStack {
                ChristmasBackdrop(heavySnow: true)

                VStack(spacing: 0) {
                    brandPill
                        .frame(height: compact ? 56 : 66)
                        .padding(.top, compact ? 26 : 38)
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("Mutlu")
                        Text("Yıllar").offset(y: 18)
                    }
                    .font(AppFont.script(compact ? 46 : 54))
                    .foregroundStyle(Palette.goldLight)
                    .shadow(color: Color(hex: 0x5A0A0F, alpha: 0.45), radius: 0, y: 4)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(t.happyNewYear)
                    .padding(.top, 2)

                    // Santa fills the space between the title and the sheet and
                    // stands on the snow wave instead of sinking behind it.
                    AnimatedSanta(mood: .draw)
                        .aspectRatio(0.8, contentMode: .fit)
                        .frame(maxWidth: compact ? 230 : 280, maxHeight: .infinity, alignment: .bottom)
                        .accessibilityHidden(true)
                        .padding(.top, 18)
                        .background {
                            RadialGradient(
                                colors: [Palette.goldLight.opacity(0.35), Palette.goldLight.opacity(0.1), .clear],
                                center: .center, startRadius: 0, endRadius: compact ? 150 : 180
                            )
                            .frame(width: compact ? 300 : 360, height: compact ? 300 : 360)
                            .offset(y: 20)
                            .allowsHitTesting(false)
                        }
                        .scaleEffect(appeared ? 1 : 0.92, anchor: .bottom)
                        .opacity(appeared ? 1 : 0)
                        .padding(.bottom, 50)
                        .frame(maxWidth: .infinity)
                        .overlay(alignment: .bottom) { friends(compact: compact) }
                        .zIndex(0)

                    sheet(compact: compact)
                        .zIndex(1)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .statusBarStyle(.lightContent)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appeared = true }
            #if DEBUG
            if path.isEmpty, DebugRoute.current == "login" { path.append(.login) }
            if path.isEmpty, DebugRoute.current == "register" { path.append(.register) }
            #endif
        }
    }

    private func sheet(compact: Bool) -> some View {
        VStack(spacing: 0) {
            Text(t.onbTitle)
                .font(AppFont.display(28))
                .foregroundStyle(Palette.brandText)
                .multilineTextAlignment(.center)
            Text(t.onbBody)
                .font(AppFont.body(15, .medium))
                .foregroundStyle(Palette.sub)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
                .padding(.bottom, 22)

            VStack(spacing: 6) {
                if let authError {
                    Banner(text: authError, style: .error).padding(.bottom, 6)
                }
                AppleSignInButton(title: t.appleContinue, style: .black) { authError = $0 }
                GoogleSignInButton { authError = $0 }
            }

            HStack(spacing: 8) {
                chip(t.emailChip, "envelope.fill", AnyShapeStyle(Palette.brand), Palette.brandEdge, Palette.snow, "onboarding.email") { path.append(.login) }
                chip(t.joinWithCode, "ticket.fill", AnyShapeStyle(Palette.pine), Palette.pineEdge, Palette.snow, "onboarding.join") { path.append(.joinCode) }
                chip(t.guestChip, "gift.fill", AnyShapeStyle(Palette.goldGradient), Palette.goldDark, Palette.goldText, "onboarding.guest") { session.continueAsGuest() }
            }
            .padding(.top, 14)
            LegalNotice().padding(.top, 10)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, compact ? -12 : -24)
        .frame(maxWidth: .infinity)
        .background(alignment: .top) {
            VStack(spacing: 0) {
                SnowWave().fill(Palette.page).frame(height: 84)
                Palette.page
            }
            .padding(.top, -74)
            .ignoresSafeArea(edges: .bottom)
        }
    }

    /// Snowman pair on Santa's left and a row of trees fading away on his right,
    /// standing where the snow wave of the sheet begins (as on the website).
    private func friends(compact: Bool) -> some View {
        HStack(alignment: .bottom) {
            FriendImage(friend: .hug, width: compact ? 70 : 84)
                .padding(.leading, 10)
            Spacer(minLength: 0)
            ZStack(alignment: .bottomTrailing) {
                FriendImage(friend: .tree, width: 30).saturation(0.6).brightness(-0.14).opacity(0.75).padding(.trailing, 80).padding(.bottom, 14)
                FriendImage(friend: .tree, width: 40).saturation(0.8).brightness(-0.07).opacity(0.9).padding(.trailing, 44).padding(.bottom, 8)
                FriendImage(friend: .tree, width: 52)
            }
            .padding(.trailing, 12)
        }
        .padding(.bottom, 34)
        .opacity(appeared ? 1 : 0)
        .allowsHitTesting(false)
    }

    /// Three small Christmas-coloured buttons: e-mail, join with a code, try without an account.
    private func chip(_ title: String, _ icon: String, _ fill: AnyShapeStyle, _ edge: Color, _ foreground: Color, _ id: String, action: @escaping () -> Void) -> some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        return Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 12, weight: .bold))
                Text(title).lineLimit(1).minimumScaleFactor(0.75)
            }
            .font(AppFont.body(13, .black))
            .foregroundStyle(foreground)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(fill, in: shape)
            .overlay(shape.strokeBorder(Palette.goldLight.opacity(0.7), lineWidth: 2))
            .background(edge, in: shape.offset(y: 4))
            .padding(.bottom, 4)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }

    private var brandPill: some View {
        Image("lockup")
            .resizable()
            .scaledToFit()
            .shadow(color: Color(hex: 0x6E0D12, alpha: 0.18), radius: 8, y: 4)
            .accessibilityLabel("Lets Raffle")
    }
}
