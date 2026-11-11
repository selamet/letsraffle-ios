import SwiftUI
import UIKit

/// One-tap sharing of the invite: WhatsApp and Instagram (chat and story) and Mail.
/// The story targets share a 9:16 picture of the invitation (`InviteStoryCard`).
/// The system share sheet stays available through the "Paylaş" button below this row.
struct InviteShareRow: View {
    let url: URL
    @State private var notice: String?
    @Environment(\.strings) private var t
    @Environment(\.openURL) private var openURL

    private var message: String { "\(t.shareMessage) \(url.absoluteString)" }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 0) {
                target("WhatsApp", image: "glyph-whatsapp", style: 0) { open("https://wa.me/?text=\(enc(message))") }
                target(t.shareWhatsAppStatus, image: "glyph-whatsapp", style: 0, story: true) { shareStory(instagram: false) }
                target(t.shareInstagramStory, image: "glyph-instagram", style: 1, story: true) { shareStory(instagram: true) }
                target(t.shareMail, symbol: "envelope.fill", style: 2) { open("mailto:?subject=\(enc(t.shareSubject))&body=\(enc(message))") }
                target(t.sharePoster, symbol: "printer.fill", style: 1) {
                    // A4 invitation with the QR code, to print and hang up.
                    if let picture = InvitePoster.image(inviteCode: url.lastPathComponent, url: url, t: t) { InviteStory.presentShareSheet(picture) }
                }
            }
            .padding(.top, 8)
            if let notice {
                Text(notice)
                    .font(AppFont.body(12, .bold))
                    .foregroundStyle(Palette.greenText)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.greenSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: notice)
    }

    private func enc(_ value: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&=+?#")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }

    private func open(_ raw: String) {
        guard let target = URL(string: raw) else { return }
        openURL(target)
    }

    /// Renders the invitation picture and hands it to the story composer. Instagram gets it
    /// directly when a Facebook App ID is configured; otherwise (and always for WhatsApp, which
    /// has no status link) the share sheet opens with the picture.
    private func shareStory(instagram: Bool) {
        guard let picture = InviteStory.image(inviteCode: url.lastPathComponent, t: t) else { return }
        Task {
            if instagram, await InviteStory.openInstagramStory(picture) { return }
            UIPasteboard.general.string = url.absoluteString
            show(t.storyLinkCopied)
            InviteStory.presentShareSheet(picture)
        }
    }

    private func show(_ text: String) {
        notice = text
        Task {
            try? await Task.sleep(for: .seconds(4))
            if notice == text { notice = nil }
        }
    }

    /// Each target is a little Christmas bauble: cranberry, pine or gold with a gold cap.
    private func target(_ label: String, image: String? = nil, symbol: String? = nil, style: Int, story: Bool = false, action: @escaping () -> Void) -> some View {
        let palettes: [([Color], Color, Color)] = [
            ([Color(hex: 0xE0444A), Palette.cranberry, Palette.cranberryDark], Color(hex: 0x4A080C), Palette.snow),
            ([Color(hex: 0x3F9A63), Palette.pine, Palette.pineEdge], Color(hex: 0x0C2A1C), Palette.snow),
            ([Color(hex: 0xFDF0C4), Palette.gold, Palette.goldDark], Color(hex: 0x8A6A1E), Palette.goldText),
        ]
        let (colors, edge, foreground) = palettes[style % palettes.count]
        return Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle().fill(RadialGradient(colors: colors, center: UnitPoint(x: 0.34, y: 0.28), startRadius: 1, endRadius: 30))
                    Circle().strokeBorder(Palette.goldLight.opacity(0.85), lineWidth: 2)
                    if let image {
                        Image(image).renderingMode(.template).resizable().scaledToFit().frame(width: 22, height: 22)
                    } else if let symbol {
                        Image(systemName: symbol).font(.system(size: 17, weight: .semibold))
                    }
                }
                .foregroundStyle(foreground)
                .frame(width: 44, height: 44)
                .background(Circle().fill(edge).offset(y: 3))
                .overlay(alignment: .top) {
                    RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                        .fill(LinearGradient(colors: [Palette.goldLight, Palette.goldDark], startPoint: .top, endPoint: .bottom))
                        .frame(width: 12, height: 8)
                        .offset(y: -7)
                }
                .overlay(alignment: .bottomTrailing) {
                    // Story targets carry a little "+" like the story ring in those apps.
                    if story {
                        Image(systemName: "plus")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(Palette.cranberryDark)
                            .frame(width: 17, height: 17)
                            .background(Palette.snow, in: Circle())
                            .overlay(Circle().strokeBorder(Palette.gold, lineWidth: 1.5))
                            .offset(x: 3, y: 4)
                    }
                }
                Text(label)
                    .font(AppFont.body(10.5, .bold))
                    .foregroundStyle(Palette.text)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label.replacingOccurrences(of: "\n", with: " "))
        .accessibilityIdentifier("share.\(label.lowercased().replacingOccurrences(of: "\n", with: "-"))")
    }
}
