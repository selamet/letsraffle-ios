import SwiftUI

/// Pre-permission screen shown before the system notification prompt.
struct PushPromptView: View {
    let push: PushManager
    @Environment(\.strings) private var t

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 18) {
                    ZStack(alignment: .topTrailing) {
                        SantaAvatar(size: 150)
                        Image(systemName: "bell.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                            .background(Palette.brand, in: Circle())
                            .overlay(Circle().strokeBorder(Palette.page, lineWidth: 3))
                            .shadow(color: Color(hex: 0xE7000B, alpha: 0.35), radius: 10, y: 8)
                            .offset(x: 10, y: 10)
                    }
                    Text(t.pushTitle)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Palette.text)
                    Text(t.pushSub)
                        .font(.system(size: 16))
                        .foregroundStyle(Palette.sub)
                        .frame(maxWidth: 300)

                    CardSection {
                        item("🎁", Palette.chip, t.pushItem1, separator: true)
                        item("👥", Palette.greenSoft, t.pushItem2, separator: true)
                        item("⏰", Palette.amberSoft, t.pushItem3)
                    }
                    .padding(.top, 8)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.top, 48)
            }

            VStack(spacing: 8) {
                Button(t.pushAllow) { Task { await push.allow() } }
                    .buttonStyle(.primary)
                    .accessibilityIdentifier("push.allow")
                Button(t.pushLater) { push.later() }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Palette.sub)
                    .frame(height: 44)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Palette.page.ignoresSafeArea())
        .interactiveDismissDisabled()
    }

    private func item(_ emoji: String, _ background: Color, _ title: String, separator: Bool = false) -> some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 16))
                .frame(width: 32, height: 32)
                .background(background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(title).font(.system(size: 15)).foregroundStyle(Palette.text).multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            if separator { Rectangle().fill(Palette.sep).frame(height: 0.5).padding(.leading, 60) }
        }
    }
}
