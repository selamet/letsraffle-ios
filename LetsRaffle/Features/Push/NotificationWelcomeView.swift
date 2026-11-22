import SwiftUI

/// First-launch screen that asks for notification permission with a warm New Year message.
/// The illustration (`notify-wishes`) is rendered in Blender: a sealed letter and a ringing bell.
struct NotificationWelcomeView: View {
    let push: PushManager
    @Environment(\.strings) private var t
    @State private var appeared = false
    @State private var floating = false

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.height < 760
            ZStack(alignment: .bottom) {
                ChristmasBackdrop(heavySnow: true).ignoresSafeArea()

              VStack(spacing: 0) {
                VStack(spacing: 0) {
                    Text(t.welcomeEyebrow)
                        .font(AppFont.script(compact ? 34 : 40))
                        .foregroundStyle(Palette.goldLight)
                        .shadow(color: Color(hex: 0x5A0A0F, alpha: 0.45), radius: 0, y: 3)
                        .padding(.top, compact ? 18 : 34)
                    Image("notify-wishes")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: compact ? 280 : 350, maxHeight: .infinity)
                        .padding(.horizontal, 16)
                        .offset(y: floating ? -6 : 6)
                        .scaleEffect(appeared ? 1 : 0.9)
                        .opacity(appeared ? 1 : 0)
                        .background {
                            RadialGradient(colors: [Palette.goldLight.opacity(0.35), .clear], center: .center, startRadius: 0, endRadius: 190)
                                .frame(width: 380, height: 380)
                                .allowsHitTesting(false)
                        }
                        .accessibilityHidden(true)
                        .padding(.bottom, 26)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                SnowSheet {
                    VStack(spacing: compact ? 8 : 12) {
                        Text(t.welcomeTitle)
                            .font(AppFont.display(compact ? 23 : 25))
                            .foregroundStyle(Palette.brandText)
                        CandyStripe(width: 80, height: 8)
                        Text(t.welcomeBody)
                            .font(AppFont.body(15, .semibold))
                            .foregroundStyle(Palette.sub)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: 330)

                        CardSection {
                            item("sparkles", Palette.cranberryDark, t.welcomeItem1, separator: true)
                            item("gift.fill", Palette.brand, t.welcomeItem2, separator: true)
                            item("alarm.fill", Palette.goldDark, t.welcomeItem3)
                        }
                        .padding(.top, 2)

                        Button(t.pushAllow) { Task { await push.allow() } }
                            .buttonStyle(.primary)
                            .accessibilityIdentifier("welcome.allow")
                            .padding(.top, 4)
                        Button(t.pushLater) { push.later() }
                            .font(AppFont.body(15, .bold))
                            .foregroundStyle(Palette.sub)
                            .frame(minHeight: 40)
                            .accessibilityIdentifier("welcome.later")
                        Text(t.welcomeFootnote)
                            .font(AppFont.body(12, .medium))
                            .foregroundStyle(Palette.ter)
                    }
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                }
                .layoutPriority(1)
              }
            }
        }
        .interactiveDismissDisabled()
        .statusBarStyle(.lightContent)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) { appeared = true }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { floating = true }
        }
    }

    private func item(_ symbol: String, _ background: Color, _ title: String, separator: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(title).font(AppFont.body(15, .semibold)).foregroundStyle(Palette.text).multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            if separator { Rectangle().fill(Palette.sep).frame(height: 1).padding(.leading, 60) }
        }
    }
}
