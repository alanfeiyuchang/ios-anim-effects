import SwiftUI

extension Effect {
    static let backgroundsSnowfall = Effect(
        id: "backgrounds.snowfall",
        category: .backgrounds,
        interaction: .gesture,
        name: L("Snowfall", "飘雪"),
        summary: L(
            "Soft flakes drift down in depth — drag sideways to blow a gust of wind.",
            "雪花分层景深飘落，左右拖动即可吹起一阵风。"
        ),
        prompt: L(
            "A twilight winter sky — deep indigo at the top warming to a dusty lavender near a soft, glowing snowbank along the bottom edge. Snowflakes fall in continuous depth: each flake's size (1.5–6 pt), fall speed (roughly 20–70 pt/s), opacity and sway amplitude scale with a random depth, near flakes rendered slightly defocused. Every flake sways on its own slow sine (3–8 s period) as it descends. Dragging horizontally raises a gust: wind eases toward the drag velocity with an exponential response (~250 ms) and carries near flakes further than distant ones for true parallax, then calms smoothly on release. A large temperature readout sits above. Quiet, cosy and hushed.",
            "黄昏冬日的天空——顶部深靛蓝，向下渐暖为灰调薰衣草色，底部是一道柔和发光的雪堆。雪花以连续景深飘落：每片雪花的大小（1.5–6pt）、下落速度（约 20–70pt/秒）、透明度与摆动幅度都随随机景深变化，近处雪花略带虚焦。每片雪花在下落时沿各自缓慢的正弦曲线（周期 3–8 秒）左右摇摆。水平拖动会吹起一阵风：风速以约 250 毫秒的指数响应趋近拖动力度，近处雪花被吹得比远处更远，形成真实视差；松手后风平缓止息。上方是一枚大号温度读数。安静、温馨、万籁俱寂。"
        ),
        implementation: L(
            "Snow is two batched Paths (far crisp, near blurred in a drawLayer) computed from index and time; a small model integrates wind offset so gusts never cause jumps.",
            "雪花由索引与时间计算，合并为两条 Path（远景清晰、近景在 drawLayer 中模糊）；小型模型对风的偏移做积分，确保阵风不会导致跳变。"
        ),
        apis: ["Canvas", "TimelineView(.animation)", "DragGesture(minimumDistance:)", "GraphicsContext.drawLayer"],
        tags: ["snow", "winter", "weather", "particles", "下雪", "冬天", "天气", "粒子"],
        params: [
            .slider("count", L("Flakes", "雪花数量"), 40...240, default: 130, step: 10, decimals: 0),
            .slider("speed", L("Fall speed", "下落速度"), 0.3...2.0, default: 1.0, unit: "×"),
            .slider("size", L("Flake size", "雪花大小"), 0.5...2.0, default: 1.0, unit: "×"),
        ]
    ) { ctx in
        SnowfallDemo(ctx: ctx)
    }
}

private final class SnowModel {
    let clock = BackgroundClock()
    var targetWind: Double = 0
    /// x where the current horizontal drag was first reported.
    var dragStartX: CGFloat?
    private(set) var wind: Double = 0
    private(set) var windOffset: Double = 0

    func step(now: Double, speed: Double, simulate: Bool) -> Double {
        let t = clock.advance(to: now, speed: speed)
        let target = simulate ? 70 * sin(now * 0.45) : targetWind
        wind += (target - wind) * clock.follow(rate: 4)
        windOffset += wind * clock.delta
        return t
    }
}

private struct SnowfallDemo: View {
    let ctx: DemoContext
    @State private var model = SnowModel()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x141B3A), Color(hex: 0x2E3566), Color(hex: 0x6C6A9E)], startPoint: .top, endPoint: .bottom)
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let t = model.step(now: timeline.date.timeIntervalSinceReferenceDate, speed: ctx["speed"], simulate: ctx.isPreview)
                SnowCanvas(t: t, windOffset: model.windOffset, count: ctx.int("count"), scale: ctx.cg("size"))
            }
            BackgroundSampleTitle(
                title: L("−3°", "−3°"),
                subtitle: L("Light snow · Stay cosy", "小雪 · 注意保暖"),
                language: ctx.language,
                size: 46
            )
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 36)
        }
        // Horizontal-first drag: a vertical swipe on the stage still scrolls the page.
        .backgroundsTouch { location in
            let start = model.dragStartX ?? location.x
            model.dragStartX = start
            model.targetWind = Double((location.x - start) * 1.4).clamped(to: -260...260)
        } onEnded: {
            model.dragStartX = nil
            model.targetWind = 0
        }
        .overlay(alignment: .bottom) {
            // The hint sits on the pale snowbank, so it uses dark (light-scheme) secondary text for contrast.
            DemoHint(text: L("Drag sideways to blow wind", "左右拖动吹起风"), ctx: ctx)
                .padding(.bottom, 14)
                .environment(\.colorScheme, .light)
                .allowsHitTesting(false)
        }
    }
}

private struct SnowCanvas: View {
    let t: Double
    let windOffset: Double
    let count: Int
    let scale: CGFloat

    var body: some View {
        Canvas { context, size in
            SnowCanvas.drawDrift(&context, size: size)
            let flakes = SnowCanvas.flakePaths(size: size, t: t, windOffset: windOffset, count: count, scale: scale)
            context.fill(flakes.far, with: .color(.white.opacity(0.55)))
            context.drawLayer { layer in
                layer.addFilter(.blur(radius: 1.2))
                layer.fill(flakes.near, with: .color(.white.opacity(0.92)))
            }
        }
    }

    private static func flakePaths(size: CGSize, t: Double, windOffset: Double, count: Int, scale: CGFloat) -> (far: Path, near: Path) {
        var far = Path()
        var near = Path()
        let wrapWidth = Double(size.width) + 24
        let wrapHeight = Double(size.height) + 24
        for i in 0..<max(count, 0) {
            let depth = BackgroundMath.rand(i, 1)
            let radius = CGFloat(0.75 + 2.25 * depth) * scale
            let fall = 20 + 50 * depth
            let sway = (6 + 14 * depth) * sin(t * (0.8 + BackgroundMath.rand(i, 2) * 1.2) + BackgroundMath.rand(i, 3) * BackgroundMath.tau)
            let rawX = BackgroundMath.rand(i, 4) * wrapWidth + windOffset * (0.4 + depth) + sway
            let x = BackgroundMath.fract(rawX / wrapWidth) * wrapWidth - 12
            let y = BackgroundMath.fract(BackgroundMath.rand(i, 5) + t * fall / wrapHeight) * wrapHeight - 12
            let rect = CGRect(x: CGFloat(x) - radius, y: CGFloat(y) - radius, width: radius * 2, height: radius * 2)
            if depth > 0.6 {
                near.addEllipse(in: rect)
            } else {
                far.addEllipse(in: rect)
            }
        }
        return (far, near)
    }

    private static func drawDrift(_ context: inout GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        var path = Path()
        path.move(to: CGPoint(x: 0, y: h * 0.9))
        path.addQuadCurve(to: CGPoint(x: w * 0.55, y: h * 0.88), control: CGPoint(x: w * 0.28, y: h * 0.8))
        path.addQuadCurve(to: CGPoint(x: w, y: h * 0.86), control: CGPoint(x: w * 0.8, y: h * 0.95))
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        let gradient = Gradient(colors: [Color(hex: 0xEEF0FF), Color(hex: 0xB9BCE6)])
        context.fill(path, with: .linearGradient(gradient, startPoint: CGPoint(x: 0, y: h * 0.8), endPoint: CGPoint(x: 0, y: h)))
    }
}
