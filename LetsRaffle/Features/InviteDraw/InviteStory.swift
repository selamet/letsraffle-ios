import SwiftUI
import UIKit

/// The 9:16 picture shared to Instagram / WhatsApp stories: the invitation as a
/// raffle ticket, with the brand at the bottom. Laid out at 360×640 and rendered at 3x.
struct InviteStoryCard: View {
    let inviteCode: String
    let t: Strings

    static let size = CGSize(width: 360, height: 640)

    private var words: [Substring] { inviteCode.split(separator: "-") }
    private var name: String {
        let parts = words.filter { Int($0) == nil }
        return parts.isEmpty ? inviteCode : parts.map { $0.capitalized }.joined(separator: " ")
    }
    private var number: String? { words.last.flatMap { Int($0) == nil ? nil : String($0) } }

    var body: some View {
        ZStack {
            Palette.heroGradient
            RadialGradient(colors: [Palette.goldLight.opacity(0.28), .clear], center: UnitPoint(x: 0.5, y: 0.36), startRadius: 0, endRadius: 260)
            snow
            VStack(spacing: 0) {
                Garland().frame(height: 60).padding(.top, 34)
                Spacer(minLength: 0)
            }
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                MountainRange().frame(height: 170).padding(.bottom, 70)
            }
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                SnowWave().fill(Palette.snow).frame(height: 52)
            }

            VStack(spacing: 0) {
                Text(t.storyEyebrow)
                    .font(AppFont.body(11, .black)).tracking(3)
                    .foregroundStyle(Palette.goldLight)
                Text(t.youreInvited)
                    .font(AppFont.script(54))
                    .foregroundStyle(Palette.goldLight)
                    .shadow(color: Color(hex: 0x5A0A0F, alpha: 0.45), radius: 0, y: 3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.top, 2)
                Image("santa-invite-still")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 118)
                    .padding(.top, -16)
                    .zIndex(1)
                ticket
                    .padding(.top, -10)
                brand
                    .padding(.top, 14)
                Spacer(minLength: 0)
            }
            .padding(.top, 94)
            .padding(.horizontal, 30)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .clipped()
    }

    private var ticket: some View {
        let shape = StoryTicketShape(split: 104)
        return VStack(spacing: 0) {
            VStack(spacing: 5) {
                HStack(alignment: .center, spacing: 8) {
                    Text(name)
                        .font(AppFont.display(25))
                        .foregroundStyle(Palette.cranberryDark)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    if let number {
                        Text("No. \(number)")
                            .font(AppFont.body(10, .black)).tracking(1)
                            .foregroundStyle(Palette.goldText)
                            .padding(.horizontal, 8)
                            .frame(height: 20)
                            .background(Palette.goldGradient, in: Capsule())
                    }
                }
                Text(t.storyBody)
                    .font(AppFont.body(13, .bold))
                    .foregroundStyle(Color(hex: 0x5B3A3A))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .frame(height: 104)

            Line()
                .stroke(Palette.cranberryDark.opacity(0.4), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 6]))
                .frame(height: 2)
                .padding(.horizontal, 22)

            VStack(spacing: 5) {
                Text(t.storyCodeLabel)
                    .font(AppFont.body(10, .black)).tracking(2.4)
                    .foregroundStyle(Palette.cranberryDark)
                Text(inviteCode)
                    .font(AppFont.display(19))
                    .foregroundStyle(Palette.snow)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 16)
                    .frame(height: 38)
                    .background(
                        LinearGradient(colors: [Color(hex: 0xD0282F), Palette.cranberry, Palette.cranberryDark], startPoint: .top, endPoint: .bottom),
                        in: Capsule()
                    )
                    .overlay(Capsule().strokeBorder(Palette.goldLight, lineWidth: 2))
                Text(t.storyHow)
                    .font(AppFont.body(11, .bold))
                    .foregroundStyle(Color(hex: 0x5B3A3A))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 14)
            .frame(maxWidth: .infinity)
            .background(Palette.goldGradient)
        }
        .background(LinearGradient(colors: [Color(hex: 0xFFFBF5), Color(hex: 0xFFF3DC)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(shape)
        .overlay(shape.stroke(Palette.goldLight, lineWidth: 2.5))
        .background(shape.fill(Color(hex: 0x4A080C)).offset(y: 6))
        .shadow(color: Color(hex: 0x3C0000, alpha: 0.35), radius: 12, y: 10)
    }

    private var brand: some View {
        VStack(spacing: 0) {
            Image("lockup")
                .resizable()
                .scaledToFit()
                .frame(width: 138)
            Text("letsraffle.co")
                .font(AppFont.body(14, .black))
                .foregroundStyle(Palette.snow)
        }
    }

    /// A fixed sprinkle of snow (the app's animated snow cannot be rendered into a picture).
    private var snow: some View {
        let dots: [(CGFloat, CGFloat, CGFloat)] = [
            (0.08, 0.20, 4), (0.90, 0.17, 3), (0.16, 0.36, 3), (0.86, 0.33, 5), (0.05, 0.52, 3),
            (0.95, 0.50, 3), (0.12, 0.68, 4), (0.90, 0.66, 3), (0.50, 0.14, 3), (0.72, 0.24, 2.5),
            (0.28, 0.25, 2.5), (0.06, 0.82, 3), (0.94, 0.80, 4),
        ]
        return Canvas { ctx, size in
            for (x, y, d) in dots {
                let rect = CGRect(x: x * size.width, y: y * size.height, width: d, height: d)
                ctx.fill(Path(ellipseIn: rect), with: .color(Palette.snow.opacity(0.8)))
            }
        }
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: rect.minX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            return p
        }
    }
}

/// Rounded card with a half-circle bitten out of the left and right edge at `split`.
private struct StoryTicketShape: Shape {
    var split: CGFloat
    var radius: CGFloat = 22
    var notch: CGFloat = 11

    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height, r = radius, n = notch
        let y = split + 1
        var p = Path()
        p.move(to: CGPoint(x: r, y: 0))
        p.addLine(to: CGPoint(x: w - r, y: 0))
        p.addArc(tangent1End: CGPoint(x: w, y: 0), tangent2End: CGPoint(x: w, y: r), radius: r)
        p.addLine(to: CGPoint(x: w, y: y - n))
        p.addArc(center: CGPoint(x: w, y: y), radius: n, startAngle: .degrees(270), endAngle: .degrees(90), clockwise: true)
        p.addLine(to: CGPoint(x: w, y: h - r))
        p.addArc(tangent1End: CGPoint(x: w, y: h), tangent2End: CGPoint(x: w - r, y: h), radius: r)
        p.addLine(to: CGPoint(x: r, y: h))
        p.addArc(tangent1End: CGPoint(x: 0, y: h), tangent2End: CGPoint(x: 0, y: h - r), radius: r)
        p.addLine(to: CGPoint(x: 0, y: y + n))
        p.addArc(center: CGPoint(x: 0, y: y), radius: n, startAngle: .degrees(90), endAngle: .degrees(270), clockwise: true)
        p.addLine(to: CGPoint(x: 0, y: r))
        p.addArc(tangent1End: CGPoint(x: 0, y: 0), tangent2End: CGPoint(x: r, y: 0), radius: r)
        p.closeSubpath()
        return p.offsetBy(dx: rect.minX, dy: rect.minY)
    }
}

@MainActor
enum InviteStory {
    /// 1080×1920 picture of the story card.
    static func image(inviteCode: String, t: Strings) -> UIImage? {
        let renderer = ImageRenderer(content: InviteStoryCard(inviteCode: inviteCode, t: t))
        renderer.scale = 3
        renderer.isOpaque = true
        return renderer.uiImage
    }

    /// Hands the picture straight to Instagram's story composer. Needs a Facebook App ID
    /// (Instagram refuses story shares without one); returns false when that is not possible.
    static func openInstagramStory(_ image: UIImage) async -> Bool {
        guard let appID = AppConfig.facebookAppID,
              let data = image.pngData(),
              let url = URL(string: "instagram-stories://share?source_application=\(appID)") else { return false }
        UIPasteboard.general.setItems(
            [["com.instagram.sharedSticker.backgroundImage": data]],
            options: [.expirationDate: Date().addingTimeInterval(300)]
        )
        return await UIApplication.shared.open(url)
    }

    /// System share sheet with the picture (WhatsApp → "My status", Instagram → "Story").
    static func presentShareSheet(_ image: UIImage) {
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first(where: { $0.activationState == .foregroundActive }),
              var top = scene.windows.first(where: \.isKeyWindow)?.rootViewController else { return }
        while let presented = top.presentedViewController { top = presented }
        let sheet = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        sheet.popoverPresentationController?.sourceView = top.view
        sheet.popoverPresentationController?.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.maxY - 80, width: 1, height: 1)
        top.present(sheet, animated: true)
    }

    #if DEBUG
    /// `-storyDemo YES`: writes the card to the app's tmp folder for visual QA.
    static func debugDump() {
        guard UserDefaults.standard.bool(forKey: "storyDemo") else { return }
        for (language, file) in [(AppLanguage.tr, "story-tr.png"), (.en, "story-en.png")] {
            let picture = image(inviteCode: "miskin-penguen-768", t: language.strings)
            try? picture?.pngData()?.write(to: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(file))
        }
    }
    #endif
}
