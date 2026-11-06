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
            ZStack(alignment: .top) {
                ChristmasBackdrop()

                VStack(spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("Mutlu")
                        Text("Yıllar").offset(y: 18)
                    }
                    .font(AppFont.script(compact ? 54 : 64))
                    .foregroundStyle(Palette.goldLight)
                    .shadow(color: Color(hex: 0x5A0A0F, alpha: 0.45), radius: 0, y: 4)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(t.happyNewYear)
                    .padding(.top, compact ? 70 : 92)

                    SantaAvatar(size: compact ? 230 : 280, mood: .draw)
                        .padding(.top, compact ? 6 : 16)
                        .opacity(appeared ? 1 : 0)

                    Spacer(minLength: 0)
                }

                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    sheet(compact: compact)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { withAnimation(.easeOut(duration: 0.6)) { appeared = true } }
    }

    private func sheet(compact: Bool) -> some View {
        VStack(spacing: 0) {
            brandPill.offset(y: -18).padding(.bottom, -8)

            Text(t.onbTitle)
                .font(AppFont.display(28))
                .foregroundStyle(Palette.brandText)
                .multilineTextAlignment(.center)
            Text(t.onbBody)
                .font(AppFont.body(15, .medium))
                .foregroundStyle(Palette.sub)
                .multilineTextAlignment(.center)
                .padding(.top, 6)
                .padding(.bottom, 16)

            VStack(spacing: 6) {
                if let authError {
                    Banner(text: authError, style: .error).padding(.bottom, 6)
                }
                AppleSignInButton(title: t.appleContinue, style: .black) { authError = $0 }
                GoogleSignInButton { authError = $0 }
            }

            HStack {
                Button {
                    path.append(.login)
                } label: {
                    Label(t.emailShort, systemImage: "envelope")
                }
                .accessibilityIdentifier("onboarding.email")
                Spacer()
                Button {
                    path.append(.joinCode)
                } label: {
                    HStack(spacing: 6) {
                        Text(t.joinWithCode)
                        Image(systemName: "arrow.right")
                    }
                }
                .foregroundStyle(Palette.greenText)
                .accessibilityIdentifier("onboarding.join")
            }
            .font(AppFont.body(15, .bold))
            .foregroundStyle(Palette.brandText)
            .frame(minHeight: 44)
            .padding(.top, 10)

            Button {
                session.continueAsGuest()
            } label: {
                Text("\(t.guestStart) →")
                    .font(AppFont.body(14, .semibold))
                    .foregroundStyle(Palette.sub)
                    .frame(minHeight: 36)
            }
            .accessibilityIdentifier("onboarding.guest")
        }
        .padding(.horizontal, 24)
        .padding(.bottom, compact ? 8 : 16)
        .frame(maxWidth: .infinity)
        .background(alignment: .top) {
            VStack(spacing: 0) {
                SnowWave().fill(Palette.page).frame(height: 60)
                Palette.page
            }
            .padding(.top, -50)
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private var brandPill: some View {
        HStack(spacing: 7) {
            Image(systemName: "gift.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Palette.cranberryDark)
                .frame(width: 24, height: 24)
                .background(Palette.goldGradient, in: Circle())
            Text("Lets Raffle").font(AppFont.display(14))
        }
        .foregroundStyle(Palette.snow)
        .padding(.leading, 5)
        .padding(.trailing, 13)
        .padding(.vertical, 5)
        .background(Palette.cranberry, in: Capsule())
        .overlay(Capsule().strokeBorder(Palette.gold, lineWidth: 2))
    }
}
