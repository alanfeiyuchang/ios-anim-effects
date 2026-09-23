import SwiftUI

extension Effect {
    static let backgroundsGrainGradient = Effect(
        id: "backgrounds.grain-gradient",
        category: .backgrounds,
        interaction: .gesture,
        name: L("Grain Gradient", "颗粒质感渐变"),
        summary: L(
            "Silky colour fields drift beneath fine film grain; one glow follows your finger.",
            "丝滑色域在细腻胶片颗粒下缓缓流动，其中一团光晕追随手指。"
        ),
        prompt: L(
            "A full-bleed editorial gradient: a deep base colour with three soft Gaussian colour fields (e.g. pink, indigo, peach) that drift on slow Lissajous paths (≈ 18–33 s periods). The coordinates are domain-warped by two octaves of fractal noise, so the edges between fields bend and breathe like silk instead of sliding. A static, per-pixel film grain (±8% luminance) sits on top, giving the matte, printed texture of premium landing pages. The third field is the “focus”: it orbits on its own, and while you drag it eases toward your finger (exponential follow ≈ 160 ms) and drifts back to its orbit on release. Calm, tactile and expensive-looking.",
            "一张满版的杂志感渐变：深色底上叠加三团柔和的高斯色域（如粉、靛蓝、蜜桃），各自沿缓慢的李萨如轨迹漂移（周期约 18–33 秒）。坐标先经两层分形噪声做域扭曲，色域之间的边界因此像丝绸一样弯折、呼吸，而不是生硬平移。最上层是静态的逐像素胶片颗粒（亮度 ±8%），带来高端落地页那种哑光、印刷般的质感。第三团色域是“焦点”：平时自行环绕，拖动时以约 160ms 的指数跟随缓缓靠向手指，松手后再漂回原轨道。安静、可触，且质感高级。"
        ),
        implementation: L(
            "A [[stitchable]] Metal colorEffect evaluates domain-warped fBm, mixes three exp(−d²) colour fields over the base colour and adds hashed grain; a small model accumulates speed-scaled time and eases the focus point toward the touch.",
            "[[stitchable]] Metal colorEffect 计算域扭曲的 fBm 噪声，在底色上以 exp(−d²) 权重混合三团色域并叠加哈希颗粒；小型模型累积按速度缩放的时间，并让焦点平滑跟随触点。"
        ),
        apis: ["colorEffect", "visualEffect", "TimelineView(.animation)", "ShaderLibrary", "DragGesture"],
        tags: ["grain", "noise", "gradient", "film grain", "editorial", "颗粒", "噪点", "渐变", "质感", "胶片"],
        params: [
            .choice("palette", L("Palette", "配色"), [L("Dusk", "暮色"), L("Citrus", "柑橘"), L("Lagoon", "泻湖")]),
            .slider("speed", L("Drift speed", "漂移速度"), 0.2...3.0, default: 1.0, unit: "×"),
            .slider("grain", L("Grain", "颗粒强度"), 0...1, default: 0.5),
        ]
    ) { ctx in
        GrainGradientDemo(ctx: ctx)
    }
}

private struct GrainPalette {
    let base: Color
    let first: Color
    let second: Color
    let focus: Color

    static let all: [GrainPalette] = [
        GrainPalette(base: Color(hex: 0x1B1036), first: Color(hex: 0xFF5FA2), second: Color(hex: 0x6E7BFF), focus: Color(hex: 0xFFB36B)),
        GrainPalette(base: Color(hex: 0xFF7A45), first: Color(hex: 0xFFC247), second: Color(hex: 0xFF4D7A), focus: Color(hex: 0xFFE7C2)),
        GrainPalette(base: Color(hex: 0x03182B), first: Color(hex: 0x21D4A8), second: Color(hex: 0x3AC4FF), focus: Color(hex: 0xA46BFF)),
    ]
}

private final class GrainModel {
    let clock = BackgroundClock()
    /// Touch in unit coordinates (0...1), nil when idle.
    var touch: CGPoint?
    private(set) var focus = CGPoint(x: 0.5, y: 0.5)

    func step(now: Double, speed: Double) -> Double {
        let t = clock.advance(to: now, speed: speed)
        let orbit = CGPoint(x: 0.5 + 0.28 * cos(t * 0.37), y: 0.55 + 0.22 * sin(t * 0.53))
        let target = touch ?? orbit
        let k = CGFloat(clock.follow(rate: touch == nil ? 1.4 : 6))
        focus.x += (target.x - focus.x) * k
        focus.y += (target.y - focus.y) * k
        return t
    }
}

private struct GrainGradientDemo: View {
    let ctx: DemoContext
    @State private var model = GrainModel()
    @State private var size = CGSize(width: 340, height: 340)

    var body: some View {
        let palette = GrainPalette.all[ctx.int("palette").clamped(to: 0...(GrainPalette.all.count - 1))]
        let speed = ctx["speed"]
        let grain = ctx["grain"]
        ZStack {
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let t = model.step(now: timeline.date.timeIntervalSinceReferenceDate, speed: speed)
                GrainSurface(time: t, grain: grain, palette: palette, focus: model.focus)
            }
            BackgroundSampleTitle(
                title: L("Made to feel", "为感受而生"),
                subtitle: L("Spring collection · 2026", "春季系列 · 2026"),
                language: ctx.language,
                size: 28
            )
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    model.touch = CGPoint(
                        x: (value.location.x / max(size.width, 1)).clamped(to: 0...1),
                        y: (value.location.y / max(size.height, 1)).clamped(to: 0...1)
                    )
                }
                .onEnded { _ in model.touch = nil }
        )
        .backgroundsHint(L("Drag to steer the glow", "拖动以引导光晕"), ctx)
    }
}

private struct GrainSurface: View {
    let time: Double
    let grain: Double
    let palette: GrainPalette
    let focus: CGPoint

    var body: some View {
        let t = time
        let g = grain
        let f = focus
        let c0 = palette.base
        let c1 = palette.first
        let c2 = palette.second
        let c3 = palette.focus
        Rectangle()
            .visualEffect { content, proxy in
                content.colorEffect(
                    ShaderLibrary.mlGrainGradient(
                        .float2(proxy.size),
                        .float(t),
                        .float(g),
                        .color(c0),
                        .color(c1),
                        .color(c2),
                        .color(c3),
                        .float2(f)
                    )
                )
            }
    }
}
