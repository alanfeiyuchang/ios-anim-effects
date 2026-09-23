import SwiftUI

extension Effect {
    static let backgroundsBokeh = Effect(
        id: "backgrounds.bokeh",
        category: .backgrounds,
        interaction: .loop,
        name: L("Bokeh Lights", "散景光斑"),
        summary: L(
            "Out-of-focus city lights float upward in three layers of depth.",
            "失焦的城市灯光分三层景深缓缓上浮。"
        ),
        prompt: L(
            "A dim plum-to-wine gradient behind softly glowing out-of-focus light discs, like a fast lens shooting city lights at night. Discs live on three depth planes: far ones are small, faint and more blurred, near ones are large with brighter, slightly sharper rims — each disc uses a radial fill that is faint in the middle and brightest just inside the edge, mimicking real aperture bokeh. All discs rise slowly (a full crossing takes 12–30 s depending on depth) with a gentle sideways sway and a subtle 4–7 s brightness pulse, blending additively where they overlap. A frosted glass card sits on top to show the backdrop in context. Warm, festive, intimate.",
            "昏暗的梅子色到酒红色渐变背景上，漂浮着柔和发光的失焦光斑，宛如大光圈镜头拍摄的夜晚城市灯火。光斑分布在三个景深层：远景小而暗、更模糊；近景大且边缘更亮、略微清晰——每个光斑都采用中心淡、贴近边缘最亮的径向填充，模拟真实光圈散景。所有光斑缓慢上升（依景深不同，穿越画面需 12–30 秒），伴随轻微的左右摇摆与 4–7 秒的明暗呼吸，重叠处以叠加方式增亮。上方放置一张磨砂玻璃卡片，展示背景的实际使用语境。温暖、节日感、亲密。"
        ),
        implementation: L(
            "Canvas renders three drawLayers, each with its own blur filter and .plusLighter blending; every disc's position and pulse derive from its index and time, filled with a rim-weighted radial gradient.",
            "Canvas 绘制三个 drawLayer，各自带有不同模糊滤镜并使用 .plusLighter 混合；每个光斑的位置与呼吸由索引和时间推导，并以边缘加权的径向渐变填充。"
        ),
        apis: ["Canvas", "GraphicsContext.drawLayer", "GraphicsContext.Filter.blur", ".ultraThinMaterial"],
        tags: ["bokeh", "lights", "blur", "depth", "散景", "光斑", "景深", "灯光"],
        params: [
            .slider("count", L("Lights", "光斑数量"), 9...45, default: 27, step: 1, decimals: 0),
            .slider("blur", L("Defocus", "失焦程度"), 0...12, default: 4, decimals: 1, unit: "pt"),
            .choice("palette", L("Palette", "配色"), [L("Warm", "暖色"), L("Cool", "冷色"), L("Neon", "霓虹")]),
        ]
    ) { ctx in
        BokehDemo(ctx: ctx)
    }
}

private struct BokehDemo: View {
    let ctx: DemoContext
    @State private var clock = BackgroundClock()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x120A1C), Color(hex: 0x2A1330), Color(hex: 0x1A0B16)], startPoint: .top, endPoint: .bottom)
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let t = clock.advance(to: timeline.date.timeIntervalSinceReferenceDate, speed: 1)
                BokehCanvas(t: t, count: ctx.int("count"), blur: ctx.cg("blur"), palette: BokehCanvas.paletteColors(ctx.int("palette")))
            }
            card
        }
    }

    private var card: some View {
        HStack(spacing: 12) {
            Image(systemName: "party.popper.fill")
                .font(.title2)
                .foregroundStyle(Palette.amber)
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(L("Friday Night", "周五夜聚"), ctx.language)
                    .font(.headline)
                Text(L("8 guests · Rooftop bar", "8 位来宾 · 天台酒吧"), ctx.language)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(width: 250)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(.white.opacity(0.15)))
        .environment(\.colorScheme, .dark)
        .allowsHitTesting(false)
    }
}

private struct BokehCanvas: View {
    let t: Double
    let count: Int
    let blur: CGFloat
    let palette: [Color]

    static func paletteColors(_ index: Int) -> [Color] {
        switch index {
        case 1:
            return [Color(hex: 0x3AC4FF), Color(hex: 0x6E7BFF), Color(hex: 0x21D4A8), Color(hex: 0xA46BFF)]
        case 2:
            return [Color(hex: 0xFF3CAC), Color(hex: 0x2BD9FE), Color(hex: 0xA46BFF), Color(hex: 0xFFE45E)]
        default:
            return [Color(hex: 0xFFC247), Color(hex: 0xFF7A5C), Color(hex: 0xFF5FA2), Color(hex: 0xFFE0A3)]
        }
    }

    var body: some View {
        Canvas { context, size in
            let blurFactors: [CGFloat] = [1.8, 1.0, 0.5]
            for depth in 0..<3 {
                context.drawLayer { layer in
                    let layerBlur = blur * blurFactors[depth]
                    if layerBlur > 0.1 {
                        layer.addFilter(.blur(radius: layerBlur))
                    }
                    layer.blendMode = .plusLighter
                    for index in stride(from: depth, to: max(count, 0), by: 3) {
                        BokehCanvas.drawDisc(&layer, index: index, depth: depth, size: size, t: t, palette: palette)
                    }
                }
            }
        }
    }

    private static func drawDisc(_ context: inout GraphicsContext, index i: Int, depth: Int, size: CGSize, t: Double, palette: [Color]) {
        guard !palette.isEmpty else { return }
        let side = min(size.width, size.height)
        let radii: [CGFloat] = [0.035, 0.065, 0.11]
        let baseRadius = radii[depth]
        let radius = side * baseRadius * (0.7 + 0.6 * BackgroundMath.unit(i, 1))
        let rises: [Double] = [0.035, 0.05, 0.08]
        let strengths: [Double] = [0.45, 0.7, 1.0]
        let rise = rises[depth] * (0.8 + 0.4 * BackgroundMath.rand(i, 2))
        let span = size.height + radius * 2
        let y = size.height + radius - CGFloat(BackgroundMath.fract(BackgroundMath.rand(i, 3) + t * rise)) * span
        let x = BackgroundMath.unit(i, 4) * size.width + CGFloat(14 * sin(t * (0.25 + 0.2 * BackgroundMath.rand(i, 5)) + Double(i)))
        let pulse = 0.65 + 0.35 * sin(t * (0.9 + 0.6 * BackgroundMath.rand(i, 6)) + Double(i) * 1.7)
        let strength = strengths[depth] * pulse
        let color = palette[i % palette.count]

        let gradient = Gradient(stops: [
            .init(color: color.opacity(0.12 * strength), location: 0),
            .init(color: color.opacity(0.3 * strength), location: 0.8),
            .init(color: color.opacity(0.62 * strength), location: 0.94),
            .init(color: color.opacity(0), location: 1),
        ])
        let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: rect), with: .radialGradient(gradient, center: CGPoint(x: x, y: y), startRadius: 0, endRadius: radius))
    }
}
