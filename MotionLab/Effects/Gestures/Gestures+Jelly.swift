import SwiftUI

extension Effect {
    static let gesturesJelly = Effect(
        id: "gestures.jelly-stretch",
        category: .gestures,
        interaction: .gesture,
        name: L("Jelly Stretch", "果冻拉伸"),
        summary: L("A gel blob that stretches with drag velocity and wobbles back into shape.", "随拖拽速度拉长的果冻球，松手后摇晃回弹。"),
        prompt: L(
            "A 110 pt glossy gel sphere (violet-to-pink gradient, white specular highlight at the upper left, a soft contact shadow on the floor that does not deform) follows the finger. Its shape is driven by velocity, not position: speed maps to a strain of up to 45%, stretching the blob along the direction of travel and thinning it perpendicular, with direction and magnitude smoothed by a fast 150 ms spring so it never jitters. On release it flies back to center on an under-damped spring (response ≈ 0.5 s, damping ≈ 0.4); because strain is stored as a signed tensor, the overshoot turns into a squash, so the blob jiggles stretch → squash → stretch before coming to rest. Playful, squishy and alive.",
            "一个 110pt 的光泽果冻球（紫到粉渐变、左上角白色高光、地面上不参与形变的柔和接触阴影）跟随手指移动。形变由速度而非位置驱动：速度映射为最高 45% 的应变，沿运动方向拉长、垂直方向变细，方向和幅度经 150ms 的快速弹簧平滑，绝不抖动。松手后以欠阻尼弹簧（响应约 0.5 秒、阻尼约 0.4）飞回中心；由于应变以带符号的张量存储，过冲会自然变成挤压，于是果冻经历“拉长 → 压扁 → 拉长”的晃动后才静止。俏皮、软糯、充满生命力。"
        ),
        implementation: L(
            "Velocity is converted to a traceless strain tensor (s·cos2θ, s·sin2θ) animated through a custom GeometryEffect that builds an affine stretch around the view center; negative strain naturally becomes a squash.",
            "将速度转换为无迹应变张量 (s·cos2θ, s·sin2θ)，通过自定义 GeometryEffect 以视图中心为原点构建仿射拉伸；负应变自然表现为挤压。"
        ),
        apis: ["GeometryEffect", "ProjectionTransform", "DragGesture.Value.velocity", "interactiveSpring"],
        tags: ["jelly", "squash", "stretch", "wobble", "velocity", "果冻", "拉伸", "挤压", "形变"],
        params: [
            .slider("intensity", L("Stretch intensity", "拉伸强度"), 0.3...1.6, default: 1),
            .slider("damping", L("Wobble damping", "晃动阻尼"), 0.15...0.9, default: 0.4),
            .slider("response", L("Spring response", "弹簧响应"), 0.25...1.0, default: 0.5, unit: "s"),
        ]
    ) { ctx in
        JellyDemo(ctx: ctx)
    }
}

/// Symmetric, traceless stretch: (e1, e2) = s·(cos 2θ, sin 2θ).
private struct JellyStrain: GeometryEffect {
    var e1: CGFloat
    var e2: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(e1, e2) }
        set {
            e1 = newValue.first
            e2 = newValue.second
        }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let cx = size.width / 2
        let cy = size.height / 2
        let a = 1 + e1
        let d = 1 - e1
        let b = e2
        let transform = CGAffineTransform(
            a: a, b: b, c: b, d: d,
            tx: cx - (a * cx + b * cy),
            ty: cy - (b * cx + d * cy)
        )
        return ProjectionTransform(transform)
    }
}

private struct JellyDemo: View {
    let ctx: DemoContext
    @State private var offset: CGSize = .zero
    @State private var strain: CGSize = .zero
    @State private var isDragging = false

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Palette.violet.opacity(0.22))
                .frame(width: 110, height: 22)
                .blur(radius: 10)
                .offset(x: offset.width, y: 76 + max(offset.height, 0) * 0.2)
                .scaleEffect(isDragging ? 0.85 : 1)

            blob
                .modifier(JellyStrain(e1: strain.width, e2: strain.height))
                .offset(offset)
                .gesture(dragGesture)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Drag and flick the jelly", "拖动并甩动果冻"), ctx: ctx)
                .padding(.bottom, 14)
        }
        .autoplay(ctx.isPreview, every: 1.9) { simulate() }
    }

    private var blob: some View {
        Circle()
            .fill(LinearGradient(colors: [Palette.violet, Palette.pink], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                Ellipse()
                    .fill(.white.opacity(0.55))
                    .frame(width: 34, height: 20)
                    .rotationEffect(.degrees(-35))
                    .offset(x: -22, y: -26)
                    .blur(radius: 1.5)
            }
            .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 1))
            .frame(width: 110, height: 110)
            .shadow(color: Palette.pink.opacity(0.35), radius: 18, y: 10)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !isDragging {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isDragging = true }
                }
                offset = value.translation
                withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.86)) {
                    strain = strainFor(velocity: value.velocity)
                }
            }
            .onEnded { _ in release() }
    }

    private func strainFor(velocity: CGSize) -> CGSize {
        let speed = (velocity.width * velocity.width + velocity.height * velocity.height).squareRoot()
        guard speed > 1 else { return .zero }
        let s = min(speed / 2000 * ctx.cg("intensity"), 0.45)
        let theta = atan2(velocity.height, velocity.width)
        return CGSize(width: s * cos(2 * theta), height: s * sin(2 * theta))
    }

    private func release() {
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            offset = .zero
            strain = .zero
            isDragging = false
        }
    }

    private func simulate() {
        let angle = Double.random(in: 0..<(2 * Double.pi))
        let target = CGSize(width: cos(angle) * 90, height: sin(angle) * 70)
        let velocity = CGSize(width: cos(angle) * 1600, height: sin(angle) * 1600)
        withAnimation(.easeOut(duration: 0.35)) {
            offset = target
            strain = strainFor(velocity: velocity)
            isDragging = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.45))
            // Flip the strain on release so the wobble reads clearly in the thumbnail.
            withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
                offset = .zero
                strain = CGSize(width: -strain.width * 0.6, height: -strain.height * 0.6)
                isDragging = false
            }
            try? await Task.sleep(for: .seconds(0.12))
            withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
                strain = .zero
            }
        }
    }
}
