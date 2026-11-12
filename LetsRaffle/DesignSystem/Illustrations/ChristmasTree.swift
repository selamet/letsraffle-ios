import SwiftUI

/// Christmas tree illustration ported from the web SVG.
struct ChristmasTree: View {
    enum Variant { case large, small }

    var variant: Variant = .large

    private var canvasSize: CGSize {
        variant == .large ? CGSize(width: 200, height: 350) : CGSize(width: 150, height: 280)
    }

    var body: some View {
        Canvas { ctx, _ in
            switch variant {
            case .large: drawLarge(&ctx)
            case .small: drawSmall(&ctx)
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .accessibilityHidden(true)
    }

    private func drawLarge(_ ctx: inout GraphicsContext) {
        ctx.fill(polygon([(100, 50), (40, 130), (60, 130), (20, 200), (50, 200), (10, 280), (100, 280),
                          (100, 330), (80, 330), (80, 350), (120, 350), (120, 330), (100, 330)]),
                 with: .color(Color(hex: 0x065F46)))
        ctx.fill(polygon([(100, 50), (160, 130), (140, 130), (180, 200), (150, 200), (190, 280), (100, 280)]),
                 with: .color(Color(hex: 0x047857)))
        ctx.fill(polygon([(100, 20), (105, 40), (125, 45), (108, 55), (112, 75), (100, 65), (88, 75),
                          (92, 55), (75, 45), (95, 40)]),
                 with: .color(Color(hex: 0xFCD34D)))
        let ornaments: [(Double, Double, UInt32)] = [
            (80, 150, 0xEF4444), (120, 160, 0x3B82F6), (70, 220, 0xFCD34D), (130, 230, 0xEF4444), (90, 260, 0x10B981),
        ]
        for (x, y, hex) in ornaments {
            ctx.fill(Path(ellipseIn: CGRect(x: x - 5, y: y - 5, width: 10, height: 10)), with: .color(Color(hex: hex)))
        }
    }

    private func drawSmall(_ ctx: inout GraphicsContext) {
        ctx.fill(polygon([(75, 40), (30, 110), (45, 110), (15, 170), (40, 170), (10, 240), (75, 240),
                          (75, 260), (60, 260), (60, 280), (90, 280), (90, 260), (75, 260)]),
                 with: .color(Color(hex: 0x065F46)))
        ctx.fill(polygon([(75, 40), (120, 110), (105, 110), (135, 170), (110, 170), (140, 240), (75, 240)]),
                 with: .color(Color(hex: 0x047857)))
        ctx.fill(polygon([(75, 20), (78, 35), (93, 38), (81, 46), (84, 61), (75, 53), (66, 61), (69, 46),
                          (57, 38), (72, 35)]),
                 with: .color(Color(hex: 0xFCD34D)))
    }

    private func polygon(_ points: [(Double, Double)]) -> Path {
        var p = Path()
        p.addLines(points.map { CGPoint(x: $0.0, y: $0.1) })
        p.closeSubpath()
        return p
    }
}

#Preview {
    HStack(alignment: .bottom) {
        ChristmasTree()
        ChristmasTree(variant: .small)
    }
}
