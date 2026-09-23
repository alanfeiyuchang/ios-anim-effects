import SwiftUI

extension Effect {
    static let gesturesGooeyBlobs = Effect(
        id: "gestures.gooey-blobs",
        category: .gestures,
        interaction: .gesture,
        name: L("Gooey Drag", "黏液拖拽"),
        summary: L("Pull a droplet out of a blob and watch the liquid bridge stretch, snap and re-merge.", "从团块中拉出液滴，液桥拉伸、断开再融合。"),
        prompt: L(
            "A 112 pt liquid blob sits at the centre with a 72 pt droplet fused to its right side and a 34 pt satellite drop hidden inside that droplet, all rendered as one aurora-gradient surface (mint → sky → violet) with a soft glow. The surface uses a metaball look: shapes are blurred about 14 pt and alpha-thresholded at 50%, so whenever they come close a smooth, necking liquid bridge forms between them. Dragging pulls the droplet toward the finger on a simulated spring (response 0.5 s, damping 0.45); the bridge thins and snaps as it leaves, and the satellite peels out and trails behind on a softer, laggier spring. Releasing flings the droplet home, where it overshoots, merges and wobbles before settling. Viscous, tactile and delightfully liquid.",
            "中央是一个 112 pt 的液态团块，右侧融着一颗 72 pt 的液滴，液滴里还藏着一颗 34 pt 的小卫星滴，三者渲染成同一块带柔光的极光渐变表面（薄荷绿、天蓝、紫）。表面用“元球”手法：图形先模糊约 14 pt，再按 50% 透明度阈值裁切，只要彼此靠近就会长出平滑、带颈缩的液桥。拖动时液滴由模拟弹簧（响应 0.5 秒、阻尼 0.45）拉向手指，液桥越拉越细直至断开，小卫星也脱离出来，以更软、更滞后的弹簧拖在后面。松手后液滴被弹回原位，过冲、融合、晃几下才稳住。黏稠可触，充满液体的趣味。"
        ),
        implementation: L(
            "A TimelineView(.animation) steps a small spring integrator stored in a reference-type model and pauses once it settles; a Canvas blurs and alpha-thresholds the circles into metaballs that mask an aurora gradient, while a second blurred Canvas draws the glow, all flattened with drawingGroup() instead of a costly view shadow.",
            "TimelineView(.animation) 每帧推进存放在引用类型模型中的弹簧积分器，静止后自动暂停；Canvas 对圆形进行模糊与透明度阈值处理形成元球并遮罩极光渐变，另一个模糊 Canvas 绘制光晕，整体用 drawingGroup() 合成，取代昂贵的视图阴影。"
        ),
        apis: ["Canvas", "GraphicsContext.Filter.alphaThreshold", "GraphicsContext.Filter.blur", "TimelineView", "mask"],
        tags: ["gooey", "metaball", "liquid", "blob", "merge", "黏液", "元球", "液态", "融合"],
        params: [
            .slider("goo", L("Gooeyness", "黏稠度"), 6...24, default: 14, step: 1, decimals: 0, unit: "pt"),
            .slider("response", L("Spring response", "弹簧响应"), 0.25...1.0, default: 0.5, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.2...1.0, default: 0.45),
        ]
    ) { ctx in
        GooeyDemo(ctx: ctx)
    }
}

/// Critically/under-damped spring integrated per frame. Reference type so the Canvas can advance it.
private final class GooModel {
    var droplet: CGPoint
    var dropletVelocity: CGVector = .zero
    var satellite: CGPoint
    var satelliteVelocity: CGVector = .zero
    var target: CGPoint
    let home: CGPoint
    private var lastDate: Date?

    /// Everything is home and still, so the timeline can pause.
    var isSettled: Bool {
        func still(_ p: CGPoint, _ v: CGVector, _ goal: CGPoint) -> Bool {
            abs(p.x - goal.x) < 0.3 && abs(p.y - goal.y) < 0.3 && abs(v.dx) < 0.5 && abs(v.dy) < 0.5
        }
        return target == home && still(droplet, dropletVelocity, home) && still(satellite, satelliteVelocity, home)
    }

    init(home: CGPoint) {
        self.home = home
        droplet = home
        satellite = home
        target = home
    }

    func step(to date: Date, response: Double, damping: Double) {
        let raw = lastDate.map { date.timeIntervalSince($0) } ?? 0
        lastDate = date
        let dt = CGFloat(min(max(raw, 0), 1.0 / 30))
        guard dt > 0 else { return }
        let omega = CGFloat(2 * Double.pi / max(response, 0.05))
        let stiffness = omega * omega
        let friction = 2 * CGFloat(damping) * omega
        let substeps = 4
        let h = dt / CGFloat(substeps)
        for _ in 0..<substeps {
            integrate(&droplet, &dropletVelocity, toward: target, stiffness: stiffness, friction: friction, h: h)
            integrate(&satellite, &satelliteVelocity, toward: droplet, stiffness: stiffness * 0.45, friction: friction * 0.7, h: h)
        }
    }

    private func integrate(_ p: inout CGPoint, _ v: inout CGVector, toward goal: CGPoint, stiffness: CGFloat, friction: CGFloat, h: CGFloat) {
        let ax = stiffness * (goal.x - p.x) - friction * v.dx
        let ay = stiffness * (goal.y - p.y) - friction * v.dy
        v.dx += ax * h
        v.dy += ay * h
        p.x += v.dx * h
        p.y += v.dy * h
    }
}

private struct GooeyDemo: View {
    let ctx: DemoContext
    @State private var model = GooModel(home: CGPoint(x: 62, y: 0))
    @State private var awake = true
    @State private var sleepWatcher: Task<Void, Never>?

    private let area: CGFloat = 300

    var body: some View {
        let goo = ctx.cg("goo")
        let response = ctx["response"]
        let damping = ctx["damping"]

        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview), paused: !awake)) { timeline in
            let _ = model.step(to: timeline.date, response: response, damping: damping)
            ZStack {
                // Bloom drawn in a Canvas and flattened with drawingGroup(): far cheaper than a view shadow
                // on a mask that changes every frame.
                Canvas { context, size in drawGlow(in: context, size: size) }
                LinearGradient(colors: [Palette.mint, Palette.sky, Palette.violet], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .mask {
                        Canvas { context, size in draw(in: context, size: size, goo: goo) }
                    }
            }
            .drawingGroup()
        }
        .frame(width: area, height: area)
        .contentShape(Rectangle())
        .gesture(dragGesture)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Pull the droplet away", "把液滴拉出来"), ctx: ctx)
                .padding(.bottom, 14)
        }
        .autoplay(ctx.isPreview, every: 2.2, delay: 0.3) { simulatePull() }
        .onAppear { wake() }
        .onDisappear { sleepWatcher?.cancel() }
    }

    private var blobs: [(CGPoint, CGFloat)] {
        [(.zero, 56), (model.droplet, 36), (model.satellite, 17)]
    }

    private func draw(in context: GraphicsContext, size: CGSize, goo: CGFloat) {
        var context = context
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        context.addFilter(.alphaThreshold(min: 0.5, color: .white))
        context.addFilter(.blur(radius: goo))
        context.drawLayer { layer in
            for (offset, radius) in blobs {
                let rect = CGRect(x: center.x + offset.x - radius, y: center.y + offset.y - radius, width: radius * 2, height: radius * 2)
                layer.fill(Path(ellipseIn: rect), with: .color(.white))
            }
        }
    }

    private func drawGlow(in context: GraphicsContext, size: CGSize) {
        var context = context
        let center = CGPoint(x: size.width / 2, y: size.height / 2 + 8)
        context.addFilter(.blur(radius: 18))
        for (offset, radius) in blobs {
            let r = radius + 4
            let rect = CGRect(x: center.x + offset.x - r, y: center.y + offset.y - r, width: r * 2, height: r * 2)
            context.fill(Path(ellipseIn: rect), with: .color(Palette.sky.opacity(0.35)))
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                // While awake the watcher is alive, and a pulled droplet never counts as settled.
                if !awake { wake() }
                let dx = value.location.x - area / 2
                let dy = value.location.y - area / 2
                let distance = (dx * dx + dy * dy).squareRoot()
                let limit: CGFloat = 100
                let scale = distance > limit ? limit / distance : 1
                model.target = CGPoint(x: dx * scale, y: dy * scale)
            }
            .onEnded { _ in
                model.target = model.home
                if !ctx.isPreview { Haptics.tap(.soft) }
            }
    }

    /// Simulated pull (previews and the arrival intro): tug the droplet out until the bridge snaps, then let go.
    private func simulatePull() {
        wake()
        let angle = Double.random(in: -0.8...0.8)
        model.target = CGPoint(x: CGFloat(cos(angle) * 100), y: CGFloat(sin(angle) * 100))
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.75))
            model.target = model.home
        }
    }

    /// Runs the timeline while anything moves; a watcher pauses it once the goo has settled.
    private func wake() {
        if !awake { awake = true }
        sleepWatcher?.cancel()
        sleepWatcher = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(0.3))
                if model.isSettled {
                    awake = false
                    return
                }
            }
        }
    }
}
