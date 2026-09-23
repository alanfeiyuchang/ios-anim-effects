import SwiftUI

extension Effect {
    static let backgroundsHalftoneFlow = Effect(
        id: "backgrounds.halftone-flow",
        category: .backgrounds,
        interaction: .loop,
        name: L("Halftone Flow", "半调点阵流"),
        summary: L(
            "A dot matrix swells and shrinks with flowing interference waves — a clean, noise-free texture.",
            "点阵随流动的干涉波起伏缩放，干净无噪点的动态肌理。"
        ),
        prompt: L(
            "A dark graphite canvas covered edge to edge by a regular halftone dot matrix. Each dot's radius is driven by a smooth interference field — the sum of two diagonal travelling sine waves, one horizontal-drifting wave and one ripple radiating from the centre, each moving at a different speed (4–10 s periods) — so bands of large dots glide, cross and dissolve like light under water, while quiet areas shrink to pinpoints. The whole matrix is tinted by a single diagonal gradient (indigo → violet → pink → amber) so colour stays still while form moves. It replaces film grain with something crisp and intentional: technical, calm and quietly premium, in the spirit of Stripe and Vercel hero art.",
            "深石墨色画布被规则的半调点阵完整铺满。每个点的半径由一个平滑的干涉场驱动——两道斜向行进的正弦波、一道水平漂移的波，以及一道从中心向外扩散的涟漪相加而成，各自速度不同（周期 4–10 秒）——于是大点组成的光带如水下光影般滑动、交错又消散，平静区域则收缩成针尖大小。整片点阵由一条对角渐变（靛蓝 → 紫 → 粉 → 琥珀）统一着色，色彩静止、形态流动。它以清晰而有意图的方式替代胶片噪点：理性、沉静、低调高级，颇具 Stripe 与 Vercel 首屏美术的气质。"
        ),
        implementation: L(
            "Per frame, every dot's radius is sampled from a sum of sines and appended to a single Path, which is filled once with a linear gradient shading — one draw call for the whole field.",
            "每帧根据正弦叠加场计算每个点的半径并追加到同一条 Path，最后以线性渐变一次性填充——整片点阵只需一次绘制调用。"
        ),
        apis: ["Canvas", "TimelineView(.animation)", "Path.addEllipse(in:)", "GraphicsContext.Shading.linearGradient"],
        tags: ["halftone", "dots", "pattern", "texture", "半调", "点阵", "纹理", "图案"],
        params: [
            .slider("spacing", L("Dot spacing", "点间距"), 9...24, default: 13, decimals: 0, unit: "pt"),
            .slider("speed", L("Flow speed", "流动速度"), 0.2...2.5, default: 1.0, unit: "×"),
            .choice("palette", L("Palette", "配色"), [L("Spectrum", "光谱"), L("Mint", "薄荷"), L("Mono", "单色")]),
        ]
    ) { ctx in
        HalftoneFlowDemo(ctx: ctx)
    }
}

private struct HalftoneFlowDemo: View {
    let ctx: DemoContext
    @State private var clock = BackgroundClock()

    var body: some View {
        ZStack {
            Color(hex: 0x0A0A12)
            TimelineView(.animation) { timeline in
                let t = clock.advance(to: timeline.date.timeIntervalSinceReferenceDate, speed: ctx["speed"])
                HalftoneCanvas(t: t, spacing: max(ctx.cg("spacing"), 6), colors: HalftoneCanvas.paletteColors(ctx.int("palette")))
            }
            BackgroundSampleTitle(
                title: L("Ship faster", "更快交付"),
                subtitle: L("Infrastructure that scales with you", "随你成长的基础设施"),
                language: ctx.language
            )
        }
    }
}

private struct HalftoneCanvas: View {
    let t: Double
    let spacing: CGFloat
    let colors: [Color]

    static func paletteColors(_ index: Int) -> [Color] {
        switch index {
        case 1:
            return [Palette.mint, Palette.sky, Palette.blue]
        case 2:
            return [.white.opacity(0.95), .white.opacity(0.45)]
        default:
            return [Palette.indigo, Palette.violet, Palette.pink, Palette.amber]
        }
    }

    var body: some View {
        Canvas { context, size in
            let path = HalftoneCanvas.dots(size: size, t: t, spacing: spacing)
            context.fill(
                path,
                with: .linearGradient(Gradient(colors: colors), startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height))
            )
        }
    }

    private static func dots(size: CGSize, t: Double, spacing: CGFloat) -> Path {
        var path = Path()
        let cx = Double(size.width / 2)
        let cy = Double(size.height / 2)
        let maxRadius = spacing * 0.46
        var y = spacing / 2
        while y < size.height {
            var x = spacing / 2
            while x < size.width {
                let dx = Double(x)
                let dy = Double(y)
                let distance = ((dx - cx) * (dx - cx) + (dy - cy) * (dy - cy)).squareRoot()
                var field = sin((dx + dy) * 0.016 + t * 1.1)
                field += sin((dx - dy) * 0.021 - t * 0.8)
                field += sin(dx * 0.012 + t * 0.6)
                field += sin(distance * 0.035 - t * 1.5)
                let n = ((field / 3 + 1) / 2).clamped(to: 0...1)
                let radius = maxRadius * CGFloat(0.1 + 0.9 * n * n)
                if radius > 0.3 {
                    path.addEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
                }
                x += spacing
            }
            y += spacing
        }
        return path
    }
}
