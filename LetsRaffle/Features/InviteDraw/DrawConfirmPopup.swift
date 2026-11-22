import SwiftUI

/// Themed confirmation shown before the organizer runs the draw.
struct DrawConfirmPopup: View {
    let draw: DrawDetail
    let onConfirm: () -> Void
    let onCancel: () -> Void
    @Environment(\.strings) private var t
    @State private var shown = false

    private var count: Int { draw.participants.count }

    var body: some View {
        ZStack {
            Color.black.opacity(shown ? 0.5 : 0)
                .ignoresSafeArea()
                .onTapGesture { close(onCancel) }
                .accessibilityHidden(true)

            card
                .padding(.horizontal, 22)
                .scaleEffect(shown ? 1 : 0.88)
                .opacity(shown ? 1 : 0)
                .offset(y: shown ? 0 : 30)
        }
        .onAppear { withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) { shown = true } }
    }

    private var card: some View {
        VStack(spacing: 0) {
            header
            VStack(spacing: 14) {
                Text(t.runDrawConfirmTitle)
                    .font(AppFont.display(23))
                    .foregroundStyle(Palette.brandText)
                    .multilineTextAlignment(.center)
                CandyStripe(width: 70, height: 7)
                people

                VStack(alignment: .leading, spacing: 10) {
                    row("bell.badge.fill", Palette.brand, t.runConfirmNotify)
                    row("lock.fill", Palette.pine, t.runConfirmFinal)
                    if draw.drawDate != nil { row("calendar", Palette.goldDark, t.runConfirmScheduled) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if count == 3 {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lightbulb.fill").foregroundStyle(Palette.amberText)
                        Text(t.runConfirmThree)
                            .font(AppFont.body(13, .semibold))
                            .foregroundStyle(Palette.amberText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.amberSoft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Button { close(onConfirm) } label: {
                    Label(t.runDraw, systemImage: "gift.fill")
                }
                .buttonStyle(.primary)
                .accessibilityIdentifier("confirm.run")
                .padding(.top, 4)
                Button(t.runConfirmCancel) { close(onCancel) }
                    .font(AppFont.body(15, .bold))
                    .foregroundStyle(Palette.sub)
                    .frame(minHeight: 40)
                    .accessibilityIdentifier("confirm.cancel")
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
        }
        .background(Palette.page, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Palette.goldLight.opacity(0.9), lineWidth: 2))
        .shadow(color: Color(hex: 0x3D0609, alpha: 0.45), radius: 30, y: 16)
        .frame(maxWidth: 420)
    }

    /// Red band with falling snow and Santa reaching into his sack.
    private var header: some View {
        ZStack(alignment: .bottom) {
            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous)
                .fill(Palette.heroGradient)
                .frame(height: 96)
                .overlay {
                    Canvas { ctx, size in
                        var rng = SystemRandomNumberGeneratorSeeded(seed: 11)
                        for _ in 0..<26 {
                            let x = CGFloat(rng.next() % 1000) / 1000 * size.width
                            let y = CGFloat(rng.next() % 1000) / 1000 * size.height
                            let r = 1 + CGFloat(rng.next() % 30) / 10
                            ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)), with: .color(.white.opacity(0.7)))
                        }
                    }
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous))
                }
            SnowWave().fill(Palette.page).frame(height: 26)
            SantaAvatar(size: 120, mood: .draw)
                .frame(height: 130)
                .offset(y: -6)
                .accessibilityHidden(true)
        }
        .padding(.top, -40)
    }

    private var people: some View {
        HStack(spacing: 10) {
            HStack(spacing: -6) {
                ForEach(draw.participants.prefix(count > 5 ? 4 : 5)) { p in
                    Avatar(initials: p.initials)
                        .overlay(Circle().strokeBorder(Palette.page, lineWidth: 3))
                }
                if count > 5 {
                    Text("+\(count - 4)")
                        .font(AppFont.body(13, .black))
                        .foregroundStyle(Palette.brandText)
                        .frame(width: 40, height: 40)
                        .background(Palette.chip, in: Circle())
                        .overlay(Circle().strokeBorder(Palette.page, lineWidth: 3))
                }
            }
            Text(t.runConfirmPeople(count))
                .font(AppFont.body(15, .bold))
                .foregroundStyle(Palette.text)
        }
    }

    private func row(_ symbol: String, _ color: Color, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(color, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            Text(text)
                .font(AppFont.body(14, .semibold))
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func close(_ action: @escaping () -> Void) {
        withAnimation(.easeIn(duration: 0.18)) { shown = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { action() }
    }
}

/// Tiny deterministic generator so the header snow doesn't jump between renders.
private struct SystemRandomNumberGeneratorSeeded: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed &* 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
