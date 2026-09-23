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
            "A dim plum-to-wine gradient behind softly glowing out-of-focus light discs, like a fast lens shooting city lights at night. Discs live on three depth planes: far ones are small, faint and more blurred, near ones are large with brighter, slightly sharper rims — each disc uses a radial fill that is faint in the middle and brightest just inside the edge, mimicking real aperture bokeh. All discs rise slowly (12–30 s per crossing depending on depth) with a gentle sideways sway and a subtle 4–7 s brightness pulse, blending additively. Dragging sideways racks focus: left pulls the far plane sharp, right the near one; each plane’s blur follows its distance from the focal plane, easing in about 0.3 s and drifting back to the near plane on release. A frosted glass card sits on top for context. Warm, festive, intimate.",
            "昏暗的梅子色到酒红色渐变背景上，漂浮着柔和发光的失焦光斑，宛如大光圈镜头拍下的夜晚城市灯火。光斑分布在三个景深层：远景小而暗、更模糊；近景大且边缘更亮、略微清晰。每个光斑采用中心淡、贴近边缘最亮的径向填充，模拟真实光圈散景。所有光斑缓慢上升（依景深不同，穿越画面需 12–30 秒），伴随轻微左右摇摆与 4–7 秒的明暗呼吸，重叠处叠加增亮。左右拖动即可移焦：向左让远景变清晰，向右让近景清晰；每层的模糊程度取决于它与焦平面的距离，约 0.3 秒内平滑过渡，松手后焦点慢慢回到近景。上方放一张磨砂玻璃卡片展示使用语境。温暖、节日感、亲密。"
        ),
        implementation: L(
            "Canvas renders three drawLayers, each with its own blur filter and .plusLighter blending; every disc's position and pulse derive from its index and time, filled with a rim-weighted radial gradient. A horizontal-first drag sets a smoothed focal plane, and each layer's blur scales with its distance from it.",
            "Canvas 绘制三个 drawLayer，各自带有不同模糊滤镜并使用 .plusLighter 混合；每个光斑的位置与呼吸由索引和时间推导，并以边缘加权的径向渐变填充。水平优先的拖动设定经平滑的焦平面，每层模糊按与焦平面的距离缩放。"
        ),
        apis: ["Canvas", "GraphicsContext.drawLayer", "GraphicsContext.Filter.blur", ".ultraThinMaterial"],
        tags: ["bokeh", "lights", "blur", "depth", "散景", "光斑", "景深", "灯光"],
        params: [
            .slider("count", L("Lights", "光斑数量"), 9...45, default: 27, step: 1, decimals: 0),
            .slider("blur", L("Defocus", "失焦程度"), 0...12, default: 4, decimals: 1, unit: "pt"),
            .choice("palette", L("Palette", "配色"), [L("Warm", "暖色"), L("Cool", "冷色"), L("Neon", "霓虹")]),
            .slider("speed", L("Drift speed", "上浮速度"), 0.2...2.5, default: 1.0, unit: "×"),
        ]
    ) { ctx in
        BokehDemo(ctx: ctx)
    }
}

private struct BokehDemo: View {
    let ctx: DemoContext
    @State private var clock = BackgroundClock()
    @State private var focus = BokehFocus()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x120A1C), Color(hex: 0x2A1330), Color(hex: 0x1A0B16)], startPoint: .top, endPoint: .bottom)
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let t = clock.advance(to: timeline.date.timeIntervalSinceReferenceDate, speed: ctx["speed"])
                BokehCanvas(
                    t: t,
                    count: ctx.int("count"),
                    blur: ctx.cg("blur"),
                    palette: BokehCanvas.paletteColors(ctx.int("palette")),
                    focus: focus.step(clock.follow(rate: 7))
                )
            }
            card
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            focus.width = width
        }
        .backgroundsTouch { location in focus.touchX = location.x } onEnded: { focus.touchX = nil }
        .backgroundsHint(L("Drag sideways to rack focus", "左右拖动移焦"), ctx)
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

/// Focal plane in depth units (0 far … 2 near), eased toward the finger's horizontal position.
private final class BokehFocus {
    var touchX: CGFloat?
    var width: CGFloat = 340
    private var plane: CGFloat = 2

    func step(_ k: Double) -> CGFloat {
        let target = touchX.map { 2 * ($0 / max(width, 1)).clamped(to: 0...1) } ?? 2
        plane += (target - plane) * CGFloat(k)
        return plane
    }
}

private struct BokehCanvas: View {
    let t: Double
    let count: Int
    let blur: CGFloat
    let palette: [Color]
    let focus: CGFloat

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
            for depth in 0..<3 {
                // 0.5× at the focal plane, +0.65× per plane away (focus 2 gives the resting 1.8 / 1.15 / 0.5).
                let defocus = abs(CGFloat(depth) - focus)
                context.drawLayer { layer in
                    let layerBlur = blur * (0.5 + 0.65 * defocus)
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
