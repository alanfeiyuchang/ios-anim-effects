import SwiftUI

extension Effect {
    static let gesturesElasticTether = Effect(
        id: "gestures.elastic-tether",
        category: .gestures,
        interaction: .gesture,
        name: L("Elastic Tether", "弹力牵绳"),
        summary: L("A ball on a bungee cord that sags when slack, thins when stretched and slingshots home.", "系在弹力绳上的小球：松弛时下垂，拉紧时变细，松手弹射归位。"),
        prompt: L(
            "A 64 pt glossy ball hangs 130 pt below a small pin, joined by a bungee cord drawn as a quadratic curve with an indigo-to-pink gradient. Dragging the ball moves it with rubber-band resistance (limit 160 pt per axis). The cord reacts to its length: when shorter than its 130 pt rest length it sags downward by 70% of the slack; when stretched it pulls perfectly straight and thins from 6 pt to 2 pt, like real elastic under tension. On release the ball slingshots back on an under-damped spring (response 0.55 s, damping 0.32), overshooting past the pin line and oscillating two or three times, and a rigid haptic fires in proportion to the pull. Snappy, springy, playground-physical.",
            "一个 64pt 的光泽小球悬挂在小钉下方 130pt 处，二者由一根弹力绳相连，绳子用二次曲线绘制，带靛蓝到粉色渐变。拖动小球时带有橡皮筋阻力（每轴上限 160pt）。绳子随长度变化：短于 130pt 的自然长度时，会按松弛量的 70% 向下垂坠；被拉长时则绷得笔直，并从 6pt 逐渐变细到 2pt，如同真实弹力绳受力。松手后小球以欠阻尼弹簧（响应 0.55 秒、阻尼 0.32）弹射回位，冲过钉子所在位置并来回振荡两三次，同时按拉伸幅度触发一次硬朗的触感。干脆、有弹性，充满游乐场般的物理趣味。"
        ),
        implementation: L(
            "A Shape with an animatable end point builds the quad-curve cord and returns path.strokedPath with a width derived from the current length, so sag and thickness are recomputed on every spring frame.",
            "自定义 Shape 以可动画的端点构建二次曲线绳子，并根据当前长度计算线宽、返回 path.strokedPath，因此下垂与粗细会在弹簧的每一帧重新计算。"
        ),
        apis: ["Shape", "animatableData", "Path.strokedPath", "DragGesture", "rubberBand", "spring(response:dampingFraction:)"],
        tags: ["slingshot", "bungee", "elastic", "rope", "tether", "弹弓", "弹力绳", "牵绳", "回弹"],
        params: [
            .slider("damping", L("Damping", "阻尼"), 0.15...0.9, default: 0.32),
            .slider("response", L("Spring response", "弹簧响应"), 0.3...1.0, default: 0.55, unit: "s"),
            .slider("sag", L("Slack sag", "松弛下垂"), 0.2...1.2, default: 0.7),
        ]
    ) { ctx in
        ElasticTetherDemo(ctx: ctx)
    }
}

private let tetherPinY: CGFloat = -100
private let tetherRestY: CGFloat = 30

private struct TetherCord: Shape {
    var end: CGPoint
    let sag: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(end.x, end.y) }
        set { end = CGPoint(x: newValue.first, y: newValue.second) }
    }

    func path(in rect: CGRect) -> Path {
        let pin = CGPoint(x: rect.midX, y: rect.midY + tetherPinY)
        let tip = CGPoint(x: rect.midX + end.x, y: rect.midY + end.y)
        let dx: CGFloat = tip.x - pin.x
        let dy: CGFloat = tip.y - pin.y
        let length: CGFloat = (dx * dx + dy * dy).squareRoot()
        let rest: CGFloat = tetherRestY - tetherPinY
        let slack: CGFloat = max(rest - length, 0)
        let stretch: CGFloat = max(length - rest, 0)
        let control = CGPoint(x: (pin.x + tip.x) / 2, y: (pin.y + tip.y) / 2 + slack * sag)
        var cord = Path()
        cord.move(to: pin)
        cord.addQuadCurve(to: tip, control: control)
        let width: CGFloat = max(6 - stretch / 30, 2)
        return cord.strokedPath(StrokeStyle(lineWidth: width, lineCap: .round))
    }
}

private struct ElasticTetherDemo: View {
    let ctx: DemoContext
    @State private var drag: CGSize = .zero
    @State private var dragging = false

    var body: some View {
        let end = CGPoint(x: drag.width, y: tetherRestY + drag.height)
        ZStack {
            TetherCord(end: end, sag: ctx.cg("sag"))
                .fill(LinearGradient(colors: [Palette.indigo, Palette.pink], startPoint: .top, endPoint: .bottom))
            pin
            ball
                .offset(x: end.x, y: end.y)
                .gesture(dragGesture)
        }
        .frame(width: 320, height: 320)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Pull the ball and let go", "拉动小球后松手"), ctx: ctx)
                .padding(.bottom, 6)
        }
        .autoplay(ctx.isPreview, every: 2.2) { simulate() }
    }

    private var pin: some View {
        Circle()
            .fill(Palette.elevated)
            .overlay(Circle().strokeBorder(Palette.indigo, lineWidth: 3))
            .frame(width: 16, height: 16)
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            .offset(y: tetherPinY)
    }

    private var ball: some View {
        Circle()
            .fill(LinearGradient(colors: [Palette.pink, Palette.violet], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                Circle()
                    .fill(LinearGradient(colors: [.white.opacity(0.6), .clear], startPoint: .top, endPoint: .center))
                    .padding(6)
            }
            .frame(width: 64, height: 64)
            .scaleEffect(dragging ? 1.1 : 1)
            .shadow(color: Palette.pink.opacity(0.4), radius: dragging ? 18 : 10, y: dragging ? 12 : 6)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !dragging {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { dragging = true }
                }
                drag = CGSize(
                    width: rubberBand(value.translation.width, limit: 160),
                    height: rubberBand(value.translation.height, limit: 160)
                )
            }
            .onEnded { _ in release(haptic: true) }
    }

    private func release(haptic: Bool) {
        let pulled = (drag.width * drag.width + drag.height * drag.height).squareRoot()
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            drag = .zero
            dragging = false
        }
        if haptic && !ctx.isPreview && pulled > 30 {
            Haptics.tap(pulled > 100 ? .rigid : .light)
        }
    }

    private func simulate() {
        let angle = Double.random(in: 0.35...2.8)
        let reach = CGFloat.random(in: 110...150)
        withAnimation(.easeOut(duration: 0.55)) {
            drag = CGSize(width: CGFloat(cos(angle)) * reach, height: CGFloat(sin(angle)) * reach * 0.8)
            dragging = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.7))
            release(haptic: false)
        }
    }
}
