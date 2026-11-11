import SwiftUI
import UIKit

/// A4 invitation to print and hang on the office wall: the story invitation scaled up to a
/// page, with a large QR code on the ticket. Laid out in points (595×842 = A4).
struct InvitePosterCard: View {
    let inviteCode: String
    let url: URL
    let t: Strings

    static let size = CGSize(width: 595, height: 842)

    private var words: [Substring] { inviteCode.split(separator: "-") }
    private var name: String {
        let parts = words.filter { Int($0) == nil }
        return parts.isEmpty ? inviteCode : parts.map { $0.capitalized }.joined(separator: " ")
    }
    private var number: String? { words.last.flatMap { Int($0) == nil ? nil : String($0) } }

    private let topHeight: CGFloat = 268

    var body: some View {
        ZStack(alignment: .top) {
            Palette.heroGradient
            RadialGradient(colors: [Palette.goldLight.opacity(0.26), .clear], center: UnitPoint(x: 0.5, y: 0.34), startRadius: 0, endRadius: 380)
            snow
            // The garland is drawn for phone widths; scale it up to span the page.
            Garland()
                .frame(width: 397, height: 56)
                .scaleEffect(1.5, anchor: .top)
                .padding(.top, 14)
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                MountainRange().frame(height: 230).padding(.bottom, 20)
            }
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                SnowWave().fill(Palette.snow).frame(height: 30)
            }

            VStack(spacing: 0) {
                Text(t.storyEyebrow)
                    .font(AppFont.body(16, .black)).tracking(5)
                    .foregroundStyle(Palette.goldLight)
                Text(t.youreInvited)
                    .font(AppFont.script(80))
                    .foregroundStyle(Palette.goldLight)
                    .shadow(color: Color(hex: 0x5A0A0F, alpha: 0.45), radius: 0, y: 4)
                    .fixedSize()
                    .padding(.top, -2)
                Image("santa-invite-still")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 106)
                    .padding(.top, -30)
                    .zIndex(1)
                ticket
                    .padding(.top, -12)
                VStack(spacing: 2) {
                    Image("lockup").resizable().scaledToFit().frame(width: 160, height: 54)
                    Text("letsraffle.co")
                        .font(AppFont.body(17, .black))
                        .foregroundStyle(Palette.snow)
                }
                .fixedSize()
                .padding(.top, 48)
                Spacer(minLength: 0)
            }
            .padding(.top, 88)
            .padding(.horizontal, 54)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .clipped()
    }

    private var ticket: some View {
        let shape = StoryTicketShape(split: topHeight, radius: 30, notch: 15)
        return VStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 12) {
                    Text(name)
                        .font(AppFont.display(40))
                        .foregroundStyle(Palette.cranberryDark)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    if let number {
                        Text("No. \(number)")
                            .font(AppFont.body(14, .black)).tracking(1.4)
                            .foregroundStyle(Palette.goldText)
                            .padding(.horizontal, 12)
                            .frame(height: 28)
                            .background(Palette.goldGradient, in: Capsule())
                    }
                }
                Text(t.storyBody)
                    .font(AppFont.body(14, .bold))
                    .foregroundStyle(Color(hex: 0x5B3A3A))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.top, 2)
                HStack(alignment: .center, spacing: 30) {
                    QRCodeView(content: url.absoluteString)
                        .frame(width: 136, height: 136)
                        .padding(12)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Palette.gold, lineWidth: 4))
                    VStack(alignment: .leading, spacing: 14) {
                        step(1, t.posterStep1)
                        step(2, t.posterStep2)
                        step(3, t.posterStep3)
                    }
                }
                .padding(.top, 14)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .frame(height: topHeight)

            Dashes()
                .stroke(Palette.cranberryDark.opacity(0.4), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [7, 8]))
                .frame(height: 2.5)
                .padding(.horizontal, 30)

            VStack(spacing: 6) {
                Text(t.storyCodeLabel)
                    .font(AppFont.body(13, .black)).tracking(3)
                    .foregroundStyle(Palette.cranberryDark)
                Text(inviteCode)
                    .font(AppFont.display(27))
                    .foregroundStyle(Palette.snow)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 26)
                    .frame(height: 52)
                    .background(
                        LinearGradient(colors: [Color(hex: 0xD0282F), Palette.cranberry, Palette.cranberryDark], startPoint: .top, endPoint: .bottom),
                        in: Capsule()
                    )
                    .overlay(Capsule().strokeBorder(Palette.goldLight, lineWidth: 3))
                Text(t.storyHow)
                    .font(AppFont.body(14, .bold))
                    .foregroundStyle(Color(hex: 0x5B3A3A))
            }
            .padding(.top, 14)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity)
            .background(Palette.goldGradient)
        }
        .background(LinearGradient(colors: [Color(hex: 0xFFFBF5), Color(hex: 0xFFF3DC)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(shape)
        .overlay(shape.stroke(Palette.goldLight, lineWidth: 3.5))
        .background(shape.fill(Color(hex: 0x4A080C)).offset(y: 8))
        .shadow(color: Color(hex: 0x3C0000, alpha: 0.35), radius: 16, y: 12)
    }

    private var snow: some View {
        Canvas { ctx, size in
            let dots: [(CGFloat, CGFloat, CGFloat)] = [
                (0.06, 0.14, 6), (0.94, 0.12, 5), (0.12, 0.26, 5), (0.90, 0.24, 7), (0.04, 0.44, 5),
                (0.96, 0.42, 5), (0.05, 0.62, 6), (0.95, 0.64, 5), (0.04, 0.80, 5), (0.96, 0.82, 6),
                (0.24, 0.17, 4), (0.78, 0.16, 4),
            ]
            for (x, y, d) in dots {
                ctx.fill(Path(ellipseIn: CGRect(x: x * size.width, y: y * size.height, width: d, height: d)), with: .color(Palette.snow.opacity(0.8)))
            }
        }
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(AppFont.display(19))
                .foregroundStyle(Palette.goldText)
                .frame(width: 38, height: 38)
                .background(Palette.goldGradient, in: Circle())
                .overlay(Circle().strokeBorder(Palette.goldDark.opacity(0.5), lineWidth: 1.5))
            Text(text)
                .font(AppFont.body(17, .black))
                .foregroundStyle(Color(hex: 0x3A2626))
                .fixedSize()
        }
    }

    private struct Dashes: Shape {
        func path(in rect: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: rect.minX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            return p
        }
    }
}

@MainActor
enum InvitePoster {
    /// The poster as one high-resolution picture (about 290 dpi on A4), so it can be saved
    /// to Photos as well as printed from the share sheet.
    static func image(inviteCode: String, url: URL, t: Strings) -> UIImage? {
        let renderer = ImageRenderer(content: InvitePosterCard(inviteCode: inviteCode, url: url, t: t))
        renderer.scale = 4
        renderer.isOpaque = true
        return renderer.uiImage
    }

    #if DEBUG
    /// `-storyDemo YES`: also writes the poster to the app's tmp folder for visual QA.
    static func debugDump() {
        guard UserDefaults.standard.bool(forKey: "storyDemo") else { return }
        let code = "miskin-penguen-768"
        let picture = image(inviteCode: code, url: AppConfig.inviteURL(for: code), t: AppLanguage.tr.strings)
        try? picture?.pngData()?.write(to: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("poster.png"))
    }
    #endif
}
