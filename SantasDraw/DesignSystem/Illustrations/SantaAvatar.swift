import SwiftUI

/// Santa illustration ported from the web SVG (viewBox 400×500).
struct SantaAvatar: View {
    var size: CGFloat = 160
    var thinking = false

    var body: some View {
        Canvas { ctx, canvasSize in
            let s = canvasSize.width / 400
            ctx.scaleBy(x: s, y: s)
            draw(in: &ctx)
        }
        .frame(width: size, height: size * 1.25)
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 12)
        .accessibilityHidden(true)
    }

    private func draw(in ctx: inout GraphicsContext) {
        let red = Color(hex: 0xDC2626)
        let white = Color.white
        let skin = Color(hex: 0xFBBF77)
        let dark = Color(hex: 0x1F2937)

        // Hat
        var hat = Path()
        hat.move(to: CGPoint(x: 200, y: 50))
        hat.addLine(to: CGPoint(x: 120, y: 180))
        hat.addLine(to: CGPoint(x: 280, y: 180))
        hat.closeSubpath()
        ctx.fill(hat, with: .color(red))
        ctx.stroke(hat, with: .color(Color(hex: 0x991B1B)), lineWidth: 3)
        ctx.fill(ellipse(200, 45, 30, 15), with: .color(white))
        ctx.fill(ellipse(200, 50, 20, 20), with: .color(white))

        // Face and beard
        ctx.fill(ellipse(200, 250, 120, 140), with: .color(skin))
        ctx.fill(ellipse(200, 320, 130, 100), with: .color(white))
        ctx.fill(beardSide(left: true), with: .color(white))
        ctx.fill(beardSide(left: false), with: .color(white))
        ctx.fill(ellipse(200, 180, 140, 25), with: .color(white))
        ctx.fill(ellipse(160, 200, 35, 40), with: .color(white))
        ctx.fill(ellipse(240, 200, 35, 40), with: .color(white))

        // Eyes
        if thinking {
            ctx.fill(ellipse(165, 195, 20, 25), with: .color(dark))
            ctx.fill(ellipse(168, 190, 6, 6), with: .color(white))
            ctx.fill(ellipse(245, 195, 20, 25), with: .color(dark))
            ctx.fill(ellipse(248, 190, 6, 6), with: .color(white))
            let brown = Color(hex: 0x8B4513)
            ctx.stroke(quad(135, 175, 155, 170, 175, 175), with: .color(brown), style: roundStroke)
            ctx.stroke(quad(215, 175, 235, 168, 255, 175), with: .color(brown), style: roundStroke)
        } else {
            ctx.fill(ellipse(160, 200, 18, 18), with: .color(dark))
            ctx.fill(ellipse(165, 195, 6, 6), with: .color(white))
            ctx.fill(ellipse(240, 200, 18, 18), with: .color(dark))
            ctx.fill(ellipse(245, 195, 6, 6), with: .color(white))
        }

        // Nose and mouth
        ctx.fill(ellipse(200, 240, 20, 25), with: .color(Color(hex: 0xEF4444)))
        ctx.fill(ellipse(205, 235, 6, 8), with: .color(Color(hex: 0xFCA5A5).opacity(0.6)))
        let mouth = thinking ? quad(170, 280, 200, 275, 230, 280) : quad(170, 280, 200, 295, 230, 280)
        ctx.stroke(mouth, with: .color(red), style: roundStroke)

        // Body
        ctx.fill(ellipse(200, 430, 100, 80), with: .color(red))
        ctx.fill(ellipse(200, 400, 90, 30), with: .color(dark))
        for y in [420.0, 450.0] {
            let button = ellipse(200, y, 10, 10)
            ctx.fill(button, with: .color(Color(hex: 0xFCD34D)))
            ctx.stroke(button, with: .color(Color(hex: 0xB45309)), lineWidth: 2)
        }

        if thinking {
            var hand = ctx
            hand.translateBy(x: 260, y: 280)
            hand.rotate(by: .degrees(-20))
            hand.fill(ellipse(0, 0, 25, 30), with: .color(skin))
        }
    }

    private var roundStroke: StrokeStyle { StrokeStyle(lineWidth: 4, lineCap: .round) }

    private func ellipse(_ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double) -> Path {
        Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
    }

    private func quad(_ x0: Double, _ y0: Double, _ cx: Double, _ cy: Double, _ x1: Double, _ y1: Double) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: x0, y: y0))
        p.addQuadCurve(to: CGPoint(x: x1, y: y1), control: CGPoint(x: cx, y: cy))
        return p
    }

    private func beardSide(left: Bool) -> Path {
        // Mirrors "M 70 250 Q 60 300 80 350 Q 100 380 140 390" around x = 200.
        func x(_ v: Double) -> Double { left ? v : 400 - v }
        var p = Path()
        p.move(to: CGPoint(x: x(70), y: 250))
        p.addQuadCurve(to: CGPoint(x: x(80), y: 350), control: CGPoint(x: x(60), y: 300))
        p.addQuadCurve(to: CGPoint(x: x(140), y: 390), control: CGPoint(x: x(100), y: 380))
        p.closeSubpath()
        return p
    }
}

#Preview {
    HStack {
        SantaAvatar()
        SantaAvatar(size: 120, thinking: true)
    }
}
