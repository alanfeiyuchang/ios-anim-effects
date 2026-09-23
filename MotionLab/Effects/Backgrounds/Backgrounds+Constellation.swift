import SwiftUI

extension Effect {
    static let backgroundsConstellation = Effect(
        id: "backgrounds.constellation",
        category: .backgrounds,
        interaction: .gesture,
        name: L("Constellation Network", "星座连线网络"),
        summary: L(
            "Drifting nodes link up whenever they come close; your finger becomes a hub that gathers them.",
            "漂浮的节点彼此靠近便自动连线，手指化身枢纽将它们聚拢。"
        ),
        prompt: L(
            "A deep navy-to-indigo backdrop holds ~42 small star nodes (1.2–2.6 pt, gently twinkling) that drift on slow, independent sine paths. Every pair closer than the link distance (≈ 95 pt) is joined by a hairline whose opacity and weight rise with proximity ((1 − d / link)², four brightness tiers), so the web constantly knits and unknits as nodes wander. Touching the stage adds a glowing mint hub under the finger: nodes within ≈ 130 pt are drawn toward it with a quadratic falloff and connect to it with brighter mint lines, and on release the hub fades out over ~300 ms while the nodes relax back to their paths. Quiet, intelligent and quietly alive — ideal behind AI, network or onboarding screens.",
            "深海军蓝到靛蓝的背景中，约 42 个细小的星点节点（1.2–2.6pt，轻微闪烁）各自沿缓慢的正弦路径漂移。任意两个节点距离小于连线阈值（约 95pt）时，便以一根发丝细线相连，线的透明度与粗细随距离接近而增强（(1 − d / 阈值)²，分四档亮度），节点游走时网络随之不断编织、拆解。按住舞台，指尖下出现一个发光的薄荷绿枢纽：约 130pt 内的节点按二次衰减被吸向它，并以更亮的薄荷绿线条与之相连；松手后枢纽在约 300ms 内淡出，节点缓缓回到原本的轨迹。安静、智慧、暗含生命力，适合作为 AI、网络或引导页的背景。"
        ),
        implementation: L(
            "A Canvas inside TimelineView computes node positions as pure functions of index and time, bins every close pair into four Paths by strength (four strokes per frame), and eases a hub point and its presence in a small reference-type model.",
            "TimelineView 中的 Canvas 以索引与时间的纯函数计算节点位置，把所有近距离节点对按强度分入四条 Path（每帧仅四次描边），并在小型引用类型模型中平滑枢纽位置与出现程度。"
        ),
        apis: ["Canvas", "TimelineView(.animation)", "Path", "GraphicsContext.Shading.radialGradient", "DragGesture"],
        tags: ["plexus", "network", "constellation", "nodes", "lines", "连线", "网络", "星座", "节点", "粒子"],
        params: [
            .slider("count", L("Nodes", "节点数量"), 16...80, default: 42, step: 1, decimals: 0),
            .slider("link", L("Link distance", "连线距离"), 50...150, default: 95, decimals: 0, unit: "pt"),
            .slider("speed", L("Drift speed", "漂移速度"), 0.2...2.5, default: 1.0, unit: "×"),
        ]
    ) { ctx in
        ConstellationDemo(ctx: ctx)
    }
}

private final class ConstellationModel {
    let clock = BackgroundClock()
    var touch: CGPoint?
    private(set) var hub: CGPoint?
    private(set) var presence: Double = 0

    func step(now: Double, speed: Double, simulated: CGPoint?) -> Double {
        let t = clock.advance(to: now, speed: speed)
        if let target = touch ?? simulated {
            if let current = hub {
                let k = CGFloat(clock.follow(rate: 12))
                hub = CGPoint(x: current.x + (target.x - current.x) * k, y: current.y + (target.y - current.y) * k)
            } else {
                hub = target
            }
            presence += (1 - presence) * clock.follow(rate: 6)
        } else {
            presence += (0 - presence) * clock.follow(rate: 10)
            if presence < 0.01 { hub = nil }
        }
        return t
    }
}

private struct ConstellationDemo: View {
    let ctx: DemoContext
    @State private var model = ConstellationModel()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x050816), Color(hex: 0x0D1233), Color(hex: 0x1A1446)],
                startPoint: .top,
                endPoint: .bottom
            )
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                ConstellationCanvas(
                    model: model,
                    now: timeline.date.timeIntervalSinceReferenceDate,
                    count: ctx.int("count"),
                    link: ctx.cg("link"),
                    speed: ctx["speed"],
                    simulate: ctx.isPreview
                )
            }
            BackgroundSampleTitle(
                title: L("Everything, connected", "万物互联"),
                subtitle: L("Your team graph · live", "团队关系图 · 实时"),
                language: ctx.language,
                size: 26
            )
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 36)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in model.touch = value.location }
                .onEnded { _ in model.touch = nil }
        )
        .backgroundsHint(L("Touch and drag to gather nodes", "按住拖动以聚拢节点"), ctx)
    }
}

private struct ConstellationCanvas: View {
    let model: ConstellationModel
    let now: Double
    let count: Int
    let link: CGFloat
    let speed: Double
    let simulate: Bool

    var body: some View {
        Canvas { context, size in
            let simulated: CGPoint? = simulate
                ? CGPoint(x: size.width * (0.5 + 0.3 * cos(now * 0.55)), y: size.height * (0.56 + 0.2 * sin(now * 0.9)))
                : nil
            let t = model.step(now: now, speed: speed, simulated: simulated)
            let points = ConstellationCanvas.nodes(count: max(count, 2), size: size, t: t, hub: model.hub, presence: model.presence)
            ConstellationCanvas.drawLinks(&context, points: points, link: max(link, 1))
            ConstellationCanvas.drawHub(&context, points: points, hub: model.hub, presence: model.presence, link: max(link, 1))
            ConstellationCanvas.drawNodes(&context, points: points, t: t)
        }
    }

    private static func nodes(count: Int, size: CGSize, t: Double, hub: CGPoint?, presence: Double) -> [CGPoint] {
        (0..<count).map { i in
            let r = { (salt: Int) -> Double in BackgroundMath.rand(i, salt) }
            let dx = 22 * sin(t * (0.18 + 0.25 * r(3)) + r(4) * BackgroundMath.tau)
            let dy = 18 * cos(t * (0.15 + 0.22 * r(5)) + r(6) * BackgroundMath.tau)
            var p = CGPoint(
                x: (0.04 + 0.92 * BackgroundMath.unit(i, 1)) * size.width + CGFloat(dx),
                y: (0.04 + 0.92 * BackgroundMath.unit(i, 2)) * size.height + CGFloat(dy)
            )
            if let hub, presence > 0.001 {
                let ox = hub.x - p.x
                let oy = hub.y - p.y
                let d = (ox * ox + oy * oy).squareRoot()
                let reach: CGFloat = 130
                if d < reach {
                    let falloff = (1 - d / reach) * (1 - d / reach)
                    let pull = 0.35 * falloff * CGFloat(presence)
                    p.x += ox * pull
                    p.y += oy * pull
                }
            }
            return p
        }
    }

    private static func drawLinks(_ context: inout GraphicsContext, points: [CGPoint], link: CGFloat) {
        var tiers = [Path](repeating: Path(), count: 4)
        for i in 0..<points.count {
            for j in (i + 1)..<points.count {
                let dx = points[i].x - points[j].x
                let dy = points[i].y - points[j].y
                let d = (dx * dx + dy * dy).squareRoot()
                guard d < link else { continue }
                let q = (1 - d / link) * (1 - d / link)
                let tier = min(Int(q * 4), 3)
                tiers[tier].move(to: points[i])
                tiers[tier].addLine(to: points[j])
            }
        }
        let lineColor = Color(hex: 0x8FA8FF)
        for tier in 0..<4 {
            context.stroke(
                tiers[tier],
                with: .color(lineColor.opacity(0.12 + 0.2 * Double(tier))),
                lineWidth: 0.5 + 0.3 * CGFloat(tier)
            )
        }
    }

    private static func drawHub(_ context: inout GraphicsContext, points: [CGPoint], hub: CGPoint?, presence: Double, link: CGFloat) {
        guard let hub, presence > 0.01 else { return }
        let reach = link * 1.5
        var path = Path()
        for p in points {
            let dx = p.x - hub.x
            let dy = p.y - hub.y
            if (dx * dx + dy * dy).squareRoot() < reach {
                path.move(to: hub)
                path.addLine(to: p)
            }
        }
        context.stroke(path, with: .color(Palette.mint.opacity(0.55 * presence)), lineWidth: 0.9)
        let glow: CGFloat = 46
        let halo = Gradient(colors: [Palette.mint.opacity(0.45 * presence), Palette.mint.opacity(0)])
        context.fill(
            Path(ellipseIn: CGRect(x: hub.x - glow, y: hub.y - glow, width: glow * 2, height: glow * 2)),
            with: .radialGradient(halo, center: hub, startRadius: 0, endRadius: glow)
        )
        let core: CGFloat = 4
        context.fill(
            Path(ellipseIn: CGRect(x: hub.x - core, y: hub.y - core, width: core * 2, height: core * 2)),
            with: .color(.white.opacity(presence))
        )
    }

    private static func drawNodes(_ context: inout GraphicsContext, points: [CGPoint], t: Double) {
        for (i, p) in points.enumerated() {
            let radius = 1.2 + 1.4 * BackgroundMath.unit(i, 7)
            let twinkle = 0.55 + 0.45 * sin(t * (1.2 + BackgroundMath.rand(i, 8) * 1.6) + Double(i))
            let rect = CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2)
            context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.45 + 0.5 * twinkle)))
        }
    }
}
