import SwiftUI
import UIKit

/// One-tap sharing of the invite link (same targets as the website):
/// WhatsApp, Telegram, Instagram, X, Messages and Mail. The system share
/// sheet stays available through the "Paylaş" button below this row.
struct InviteShareRow: View {
    let url: URL
    @State private var notice: String?
    @Environment(\.strings) private var t
    @Environment(\.openURL) private var openURL

    private var message: String { "\(t.shareMessage) \(url.absoluteString)" }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 0) {
                target("WhatsApp", image: "share-whatsapp") { open("https://wa.me/?text=\(enc(message))") }
                target("Telegram", image: "share-telegram") { open("https://t.me/share/url?url=\(enc(url.absoluteString))&text=\(enc(t.shareMessage))") }
                target("Instagram", image: "share-instagram", action: shareInstagram)
                target("X", image: "share-x") { open("https://twitter.com/intent/tweet?text=\(enc(message))") }
                target(t.shareMessages, symbol: "message.fill", tint: Color(hex: 0x1F5C3E)) { open("sms:&body=\(enc(message))") }
                target(t.shareMail, symbol: "envelope.fill", tint: Palette.cranberry) { open("mailto:?subject=\(enc(t.shareSubject))&body=\(enc(message))") }
            }
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

    /// Instagram's share sheet takes text only when the app is installed; otherwise
    /// the invite is copied so it can be pasted into a chat or story.
    private func shareInstagram() {
        UIPasteboard.general.string = message
        guard let target = URL(string: "instagram://sharesheet?text=\(enc(message))") else { return }
        UIApplication.shared.open(target) { opened in
            show(opened ? t.shareInstagramCopied : t.shareInstagramMissing)
        }
    }

    private func show(_ text: String) {
        notice = text
        Task {
            try? await Task.sleep(for: .seconds(4))
            if notice == text { notice = nil }
        }
    }

    private func target(_ label: String, image: String? = nil, symbol: String? = nil, tint: Color = .clear, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Group {
                    if let image {
                        Image(image).resizable().scaledToFit()
                    } else if let symbol {
                        Image(systemName: symbol)
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(tint, in: Circle())
                    }
                }
                .frame(width: 42, height: 42)
                .overlay(Circle().strokeBorder(.white.opacity(0.7), lineWidth: 1.5))
                Text(label)
                    .font(AppFont.body(10, .bold))
                    .foregroundStyle(Palette.snow.opacity(0.95))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityIdentifier("share.\(label.lowercased())")
    }
}
