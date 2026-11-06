import SwiftUI

struct OnboardingView: View {
    @Binding var path: [AuthRoute]
    @Environment(\.strings) private var t
    @Environment(SessionStore.self) private var session
    @State private var appleError: String?

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.height < 700
            ZStack {
                Palette.heroGradient
                RadialGradient(
                    colors: [.white.opacity(0.16), .clear],
                    center: UnitPoint(x: 0.7, y: 0.2),
                    startRadius: 0,
                    endRadius: geo.size.width * 0.8
                )
                SnowDots()
                ChristmasTree(variant: .large)
                    .opacity(0.28)
                    .position(x: 40, y: geo.size.height - 230 - 175)
                ChristmasTree(variant: .small)
                    .opacity(0.22)
                    .position(x: geo.size.width + 40 - 75, y: geo.size.height - 250 - 140)

                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    VStack(spacing: 12) {
                        SantaAvatar(size: compact ? 110 : 160)
                        Text(t.brandEyebrow)
                            .font(.eyebrow)
                            .tracking(3.6)
                            .textCase(.uppercase)
                            .foregroundStyle(.white.opacity(0.75))
                        Text("Santa's Draw")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.25), radius: 7, y: 4)
                        Text(t.onbSub)
                            .font(.system(size: 15))
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 300)
                    }
                    .padding(.horizontal, 24)
                    Spacer(minLength: 0)

                    VStack(spacing: 10) {
                        if let appleError {
                            Banner(text: appleError, style: .error)
                        }
                        AppleSignInButton(title: t.apple, style: .black) { appleError = $0 }

                        Button(t.emailContinue) { path.append(.login) }
                            .buttonStyle(PrimaryButtonStyle(background: .white, foreground: Palette.heroB))
                            .accessibilityIdentifier("onboarding.email")

                        Button {
                            session.continueAsGuest()
                        } label: {
                            Text("\(t.guestStart) →")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.white.opacity(0.85))
                                .frame(height: 44)
                        }
                        .accessibilityIdentifier("onboarding.guest")
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, compact ? 16 : 32)
                }
            }
            .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
