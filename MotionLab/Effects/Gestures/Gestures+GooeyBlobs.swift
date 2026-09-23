import SwiftUI

extension Effect {
    static let gesturesGooeyBlobs = Effect(
        id: "gestures.gooey-blobs",
        category: .gestures,
        interaction: .gesture,
        name: L("Gooey Drag", "黏液拖拽"),
        summary: L("Pull a droplet out of a blob and watch the liquid bridge stretch, snap and re-merge.", "从团块中拉出液滴，液桥拉伸、断开再融合。"),
        prompt: L(
            "A 112 pt liquid blob sits at the center with a 72 pt droplet fused to its right side and a 34 pt satellite drop hidden inside that droplet, all rendered as one aurora-gradient surface (mint → sky → violet) with a soft glow. The surface uses a metaball look: shapes are blurred ~14 pt and alpha-thresholded at 50%, so whenever they come close a smooth, necking liquid bridge forms between them. Dragging pulls the droplet toward the finger on a physically simulated spring (≈ 0.5 s response, damping ≈ 0.45); the bridge thins and snaps as it leaves, and the satellite peels out and trails behind on a softer, laggier spring. Releasing flings the droplet home, where it overshoots, merges and wobbles before settling. Viscous, tactile, delightfully liquid.",
            "中央是一个 112pt 的液态团块，右侧融合着一颗 72pt 的液滴，液滴内还藏着一颗 34pt 的小卫星滴，三者作为同一块极光渐变表面（薄荷绿 → 天蓝 → 紫）渲染，并带柔和光晕。表面采用“元球”效果：图形先模糊约 14pt，再以 50% 透明度阈值裁切，因此只要彼此靠近就会自然生出平滑、带颈缩的液桥。拖动时，液滴通过物理模拟的弹簧（响应约 0.5 秒、阻尼约 0.45）被拉向手指，液桥逐渐变细直至断开，小卫星则从液滴中分离，以更软、更滞后的弹簧拖在其后。松手后液滴被弹回原位，过冲、融合并晃动后才稳定。黏稠、可触，充满液体的趣味。"
        ),
        implementation: L(
            "A TimelineView(.animation) steps a small spring integrator stored in a reference-type model; a Canvas blurs and alpha-thresholds the circles into metaballs, and the result masks an aurora gradient.",
            "TimelineView(.animation) 每帧推进存放在引用类型模型中的弹簧积分器；Canvas 对圆形进行模糊与透明度阈值处理形成元球，再用结果遮罩极光渐变。"
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

    private let area: CGFloat = 300

    var body: some View {
        let goo = ctx.cg("goo")
        let response = ctx["response"]
        let damping = ctx["damping"]
        let isPreview = ctx.isPreview

        LinearGradient(colors: [Palette.mint, Palette.sky, Palette.violet], startPoint: .topLeading, endPoint: .bottomTrailing)
            .mask {
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        if isPreview {
                            let t = timeline.date.timeIntervalSinceReferenceDate
                            let pull = max(0, sin(t * 1.4))
                            model.target = CGPoint(
                                x: model.home.x + CGFloat(pull * 44 + 6 * cos(t * 2.3)),
                                y: CGFloat(sin(t * 0.9) * 70 * pull)
                            )
                        }
                        model.step(to: timeline.date, response: response, damping: damping)
                        draw(in: context, size: size, goo: goo)
                    }
                }
            }
            .frame(width: area, height: area)
            .shadow(color: Palette.sky.opacity(0.35), radius: 18, y: 8)
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                DemoHint(text: L("Pull the droplet away", "把液滴拉出来"), ctx: ctx)
                    .padding(.bottom, 14)
            }
    }

    private func draw(in context: GraphicsContext, size: CGSize, goo: CGFloat) {
        var context = context
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        context.addFilter(.alphaThreshold(min: 0.5, color: .white))
        context.addFilter(.blur(radius: goo))
        context.drawLayer { layer in
            let blobs: [(CGPoint, CGFloat)] = [
                (.zero, 56),
                (model.droplet, 36),
                (model.satellite, 17),
            ]
            for (offset, radius) in blobs {
                let rect = CGRect(
                    x: center.x + offset.x - radius,
                    y: center.y + offset.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )
                layer.fill(Path(ellipseIn: rect), with: .color(.white))
            }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
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
}
