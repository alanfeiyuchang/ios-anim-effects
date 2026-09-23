import SwiftUI

extension Effect {
    static let backgroundsFlowField = Effect(
        id: "backgrounds.flow-field",
        category: .backgrounds,
        interaction: .gesture,
        name: L("Flow Field Currents", "流场游丝"),
        summary: L(
            "Hundreds of luminous threads ride an invisible, slowly shifting current; your finger stirs a vortex.",
            "数百缕发光游丝沿无形且缓慢变化的洋流漂动，手指可搅出漩涡。"
        ),
        prompt: L(
            "On a near-black ink backdrop, ~260 particles trace an invisible vector field whose direction is a sum of three slowly evolving sine terms, so the current bends into broad, ever-changing swirls. Each particle leaves a trail sampled every 1/30 s of simulated time (14 samples, ≈ 0.45 s of path), so its length depends on speed, never on frame rate; the trail is drawn in three segments that taper from a faint, thin tail to a bright, thicker head, in one of four spectrum hues (indigo, violet, sky, mint) with additive blending, so dense lanes glow brighter; particles live 2.5–6 s, fading in and out so the image never pops. Dragging on the stage (horizontal-first, so the page still scrolls vertically) turns the finger into a vortex: within ≈ 120 pt, particles gain a tangential swirl plus a slight outward push, drawing a luminous whirlpool that dissolves back into the current on release. Generative, meditative and quietly premium.",
            "近乎纯黑的墨色背景上，约 260 个粒子沿一张看不见的向量场漂流：方向由三组缓慢演变的正弦项叠加而成，洋流因此弯成宽阔且不断变化的漩涡。每个粒子的轨迹按模拟时间每 1/30 秒采样一次（14 个采样点，约 0.45 秒的路径），长度只取决于速度而与帧率无关；轨迹分三段绘制，从暗淡纤细的尾部渐变到明亮稍粗的头部，颜色取自四种光谱色（靛蓝、紫、天蓝、薄荷），以叠加混合绘制，密集的流道自然更亮；粒子寿命 2.5–6 秒，出生与消亡都有淡入淡出，画面从不闪跳。在舞台上拖动（水平方向优先识别，页面仍可竖向滚动），手指化身漩涡中心：约 120pt 内的粒子获得切向旋转与轻微外推，绘出一个发光的涡流，松手后又融回洋流。生成式、冥想感，安静而高级。"
        ),
        implementation: L(
            "A reference-type particle system advanced inside a TimelineView Canvas integrates each head along the field and a touch vortex and records trail samples on a fixed simulated-time interval; trails are split into tail/mid/head segments and binned by hue, fade level and segment into 36 Paths stroked with .plusLighter.",
            "在 TimelineView 驱动的 Canvas 中推进引用类型粒子系统：每个粒子头沿向量场与触点漩涡积分，并按固定的模拟时间间隔记录轨迹采样；轨迹切分为尾、中、头三段，按色相、淡入淡出程度与分段归入 36 条 Path，以 .plusLighter 描边。"
        ),
        apis: ["Canvas", "TimelineView(.animation)", "Path", ".plusLighter", "DragGesture"],
        tags: ["flow field", "particles", "generative", "vortex", "currents", "流场", "粒子", "生成艺术", "漩涡", "洋流"],
        params: [
            .slider("count", L("Particles", "粒子数量"), 80...480, default: 260, step: 10, decimals: 0),
            .slider("speed", L("Current speed", "流速"), 0.3...2.5, default: 1.0, unit: "×"),
            .slider("scale", L("Turbulence", "湍流尺度"), 0.4...2.0, default: 1.0, unit: "×"),
        ]
    ) { ctx in
        FlowFieldDemo(ctx: ctx)
    }
}

private struct FlowParticle {
    /// The live head, advanced every frame.
    var head: CGPoint
    /// Samples recorded every `FlowModel.sampleInterval` of simulated time (oldest first).
    var trail: [CGPoint]
    var sinceSample: Double = 0
    var age: Double
    var life: Double
    let hue: Int
}

private final class FlowModel {
    let clock = BackgroundClock()
    var touch: CGPoint?
    private(set) var particles: [FlowParticle] = []
    private var size: CGSize = .zero

    static let trailLength = 14
    /// Trail sampling step in simulated seconds: independent of the display's frame rate.
    static let sampleInterval = 1.0 / 30.0

    func step(now: Double, speed: Double, count: Int, scale: Double, size newSize: CGSize, simulated: CGPoint?) -> Double {
        let t = clock.advance(to: now, speed: speed)
        if newSize != size || particles.count != count {
            size = newSize
            particles = (0..<max(count, 0)).map { index in spawn(hue: index % 4, age: Double.random(in: 0...3)) }
        }
        let dt = clock.delta * speed
        guard dt > 0, size.width > 1, size.height > 1 else { return t }
        let vortex = touch ?? simulated
        let f = 0.011 / max(scale, 0.1)
        for index in particles.indices {
            advance(&particles[index], t: t, dt: dt, f: f, vortex: vortex)
        }
        return t
    }

    private func advance(_ p: inout FlowParticle, t: Double, dt: Double, f: Double, vortex: CGPoint?) {
        let x = Double(p.head.x)
        let y = Double(p.head.y)
        let angle = (sin(x * f + t * 0.21) + cos(y * f * 1.3 - t * 0.17) + sin((x + y) * f * 0.7 + t * 0.11)) * 1.5
        var vx = cos(angle) * 55
        var vy = sin(angle) * 55
        if let vortex {
            let dx = x - Double(vortex.x)
            let dy = y - Double(vortex.y)
            let d = max((dx * dx + dy * dy).squareRoot(), 1)
            if d < 120 {
                let w = 1 - d / 120
                vx += (-dy / d * 190 + dx / d * 45) * w
                vy += (dx / d * 190 + dy / d * 45) * w
            }
        }
        let next = CGPoint(x: x + vx * dt, y: y + vy * dt)
        p.head = next
        p.sinceSample += dt
        if p.sinceSample >= FlowModel.sampleInterval {
            p.sinceSample = p.sinceSample.truncatingRemainder(dividingBy: FlowModel.sampleInterval)
            p.trail.append(next)
            if p.trail.count > FlowModel.trailLength { p.trail.removeFirst(p.trail.count - FlowModel.trailLength) }
        }
        p.age += dt
        let outside = next.x < -12 || next.y < -12 || next.x > size.width + 12 || next.y > size.height + 12
        if outside || p.age > p.life {
            p = spawn(hue: p.hue, age: 0)
        }
    }

    private func spawn(hue: Int, age: Double) -> FlowParticle {
        let point = CGPoint(x: CGFloat.random(in: 0...max(size.width, 1)), y: CGFloat.random(in: 0...max(size.height, 1)))
        return FlowParticle(head: point, trail: [point], age: age, life: Double.random(in: 2.5...6), hue: hue)
    }
}

private struct FlowFieldDemo: View {
    let ctx: DemoContext
    @State private var model = FlowModel()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x05060D), Color(hex: 0x0B0C1C)], startPoint: .top, endPoint: .bottom)
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                FlowCanvas(
                    model: model,
                    now: timeline.date.timeIntervalSinceReferenceDate,
                    count: ctx.int("count"),
                    speed: ctx["speed"],
                    scale: ctx["scale"],
                    simulate: ctx.isPreview
                )
            }
            BackgroundSampleTitle(
                title: L("Deep Focus", "深度专注"),
                subtitle: L("Flow state · 25:00", "心流模式 · 25:00"),
                language: ctx.language,
                size: 26
            )
        }
        // Horizontal-first with a 10 pt slop (plus tap-to-poke), so vertical swipes still scroll the page.
        .backgroundsTouch { location in model.touch = location } onEnded: { model.touch = nil }
        .backgroundsHint(L("Tap or drag sideways to stir a vortex", "点击或横向拖动以搅出漩涡"), ctx)
    }
}

private struct FlowCanvas: View {
    let model: FlowModel
    let now: Double
    let count: Int
    let speed: Double
    let scale: Double
    let simulate: Bool

    private static let hues: [Color] = [Palette.indigo, Palette.violet, Palette.sky, Palette.mint]

    var body: some View {
        Canvas { context, size in
            let simulated: CGPoint? = simulate
                ? CGPoint(x: size.width * (0.5 + 0.28 * cos(now * 0.5)), y: size.height * (0.5 + 0.24 * sin(now * 0.8)))
                : nil
            _ = model.step(now: now, speed: speed, count: count, scale: scale, size: size, simulated: simulated)
            // Bins: hue (4) × life fade (3) × trail segment (3: tail, mid, head).
            var bins = [Path](repeating: Path(), count: 36)
            for particle in model.particles {
                let fade = min(particle.age / 0.6, (particle.life - particle.age) / 0.8, 1)
                guard fade > 0.02 else { continue }
                let level = min(Int(fade * 3), 2)
                let points = particle.trail + [particle.head]
                guard points.count > 1 else { continue }
                let last = points.count - 1
                for segment in 0..<3 {
                    let from = last * segment / 3
                    let to = last * (segment + 1) / 3
                    guard to > from else { continue }
                    var path = Path()
                    path.addLines(Array(points[from...to]))
                    bins[(particle.hue % 4 * 3 + level) * 3 + segment].addPath(path)
                }
            }
            context.blendMode = .plusLighter
            let segmentAlpha: [Double] = [0.3, 0.62, 1]
            let segmentWidth: [CGFloat] = [0.9, 1.25, 1.6]
            for hue in 0..<4 {
                for level in 0..<3 {
                    for segment in 0..<3 {
                        context.stroke(
                            bins[(hue * 3 + level) * 3 + segment],
                            with: .color(FlowCanvas.hues[hue].opacity((0.22 + 0.26 * Double(level)) * segmentAlpha[segment])),
                            style: StrokeStyle(lineWidth: segmentWidth[segment], lineCap: .round, lineJoin: .round)
                        )
                    }
                }
            }
        }
    }
}
