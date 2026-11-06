import SwiftUI

/// Pre-permission screen shown before the system notification prompt.
struct PushPromptView: View {
    let push: PushManager
    @Environment(\.strings) private var t

    var body: some View {
        ZStack(alignment: .bottom) {
            ChristmasBackdrop(garland: true, pines: false).ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    SantaAvatar(size: 150, mood: .watch)
                    Image(systemName: "bell.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Palette.cranberryDark)
                        .frame(width: 52, height: 52)
                        .background(Palette.goldGradient, in: Circle())
                        .overlay(Circle().strokeBorder(Palette.snow, lineWidth: 3))
                        .shadow(color: Color(hex: 0x6E0D12, alpha: 0.35), radius: 10, y: 8)
                        .offset(x: 10, y: 20)
                }
                .padding(.top, 40)
                Spacer(minLength: 0)
            }

            SnowSheet {
                VStack(spacing: 14) {
                    Text(t.pushTitle)
                        .font(AppFont.display(26))
                        .foregroundStyle(Palette.brandText)
                    CandyStripe(width: 80, height: 8)
                    Text(t.pushSub)
                        .font(AppFont.body(15, .semibold))
                        .foregroundStyle(Palette.sub)
                        .frame(maxWidth: 320)

                    CardSection {
                        item("gift.fill", Palette.brand, t.pushItem1, separator: true)
                        item("person.2.fill", Palette.pine, t.pushItem2, separator: true)
                        item("alarm.fill", Palette.goldDark, t.pushItem3)
                    }
                    .padding(.top, 4)

                    Button(t.pushAllow) { Task { await push.allow() } }
                        .buttonStyle(.primary)
                        .accessibilityIdentifier("push.allow")
                        .padding(.top, 6)
                    Button(t.pushLater) { push.later() }
                        .font(AppFont.body(15, .bold))
                        .foregroundStyle(Palette.sub)
                        .frame(minHeight: 44)
                }
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            }
        }
        .interactiveDismissDisabled()
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
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            if separator { Rectangle().fill(Palette.sep).frame(height: 1).padding(.leading, 60) }
        }
    }
}
