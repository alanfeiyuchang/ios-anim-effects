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
            "On a near-black ink backdrop, ~260 particles trace an invisible vector field whose direction is a sum of three slowly evolving sine terms, so the current bends into broad, ever-changing swirls. Each particle leaves a 14-point trail drawn with round caps in one of four spectrum hues (indigo, violet, sky, mint) with additive blending, so dense lanes glow brighter; particles live 2.5–6 s, fading in and out so the image never pops. Touching the stage turns the finger into a vortex: within ≈ 120 pt, particles gain a tangential swirl plus a slight outward push, drawing a luminous whirlpool that dissolves back into the current on release. Generative, meditative and quietly premium.",
            "近乎纯黑的墨色背景上，约 260 个粒子沿一张看不见的向量场漂流：方向由三组缓慢演变的正弦项叠加而成，洋流因此弯成宽阔且不断变化的漩涡。每个粒子拖出 14 个点的圆头轨迹，颜色取自四种光谱色（靛蓝、紫、天蓝、薄荷），以叠加混合绘制，密集的流道自然更亮；粒子寿命 2.5–6 秒，出生与消亡都有淡入淡出，画面从不闪跳。按住舞台，手指化身漩涡中心：约 120pt 内的粒子获得切向旋转与轻微外推，绘出一个发光的涡流，松手后又融回洋流。生成式、冥想感，安静而高级。"
        ),
        implementation: L(
            "A reference-type particle system advanced inside a TimelineView Canvas integrates each head along the field and a touch vortex; trails are binned by hue and fade level into twelve Paths stroked with .plusLighter.",
            "在 TimelineView 驱动的 Canvas 中推进引用类型粒子系统：每个粒子头沿向量场与触点漩涡积分；轨迹按色相与淡入淡出程度分入十二条 Path，以 .plusLighter 描边。"
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
    var trail: [CGPoint]
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
        guard let head = p.trail.last else {
            p = spawn(hue: p.hue, age: 0)
            return
        }
        let x = Double(head.x)
        let y = Double(head.y)
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
        p.trail.append(next)
        if p.trail.count > FlowModel.trailLength { p.trail.removeFirst(p.trail.count - FlowModel.trailLength) }
        p.age += dt
        let outside = next.x < -12 || next.y < -12 || next.x > size.width + 12 || next.y > size.height + 12
        if outside || p.age > p.life {
            p = spawn(hue: p.hue, age: 0)
        }
    }

    private func spawn(hue: Int, age: Double) -> FlowParticle {
        let point = CGPoint(x: CGFloat.random(in: 0...max(size.width, 1)), y: CGFloat.random(in: 0...max(size.height, 1)))
        return FlowParticle(trail: [point], age: age, life: Double.random(in: 2.5...6), hue: hue)
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
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in model.touch = value.location }
                .onEnded { _ in model.touch = nil }
        )
        .backgroundsHint(L("Drag to stir a vortex", "拖动以搅出漩涡"), ctx)
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
            var bins = [Path](repeating: Path(), count: 12)
            for particle in model.particles where particle.trail.count > 1 {
                let fade = min(particle.age / 0.6, (particle.life - particle.age) / 0.8, 1)
                guard fade > 0.02 else { continue }
                let level = min(Int(fade * 3), 2)
                var path = Path()
                path.addLines(particle.trail)
                bins[particle.hue % 4 * 3 + level].addPath(path)
            }
            context.blendMode = .plusLighter
            for hue in 0..<4 {
                for level in 0..<3 {
                    context.stroke(
                        bins[hue * 3 + level],
                        with: .color(FlowCanvas.hues[hue].opacity(0.22 + 0.26 * Double(level))),
                        style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round)
                    )
                }
            }
        }
    }
}
