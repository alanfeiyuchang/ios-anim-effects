import SwiftUI

extension Effect {
    static let gesturesJelly = Effect(
        id: "gestures.jelly-stretch",
        category: .gestures,
        interaction: .gesture,
        name: L("Jelly Stretch", "果冻拉伸"),
        summary: L("A gel blob that stretches with drag velocity and wobbles back into shape.", "随拖拽速度拉长的果冻球，松手后摇晃回弹。"),
        prompt: L(
            "A 110 pt glossy gel sphere (violet-to-pink gradient, white specular highlight at the upper left, an undeformed contact shadow on the floor) follows the finger. Its shape is driven by velocity rather than position: speed maps to up to 45% strain, stretching the blob along its travel and thinning it across, smoothed by a fast 150 ms spring so it never jitters, and if the finger rests for 80 ms the strain relaxes back to round (response 0.3 s). On release it flies home on an under-damped spring (response 0.5 s, damping 0.4), and because strain is stored as a signed tensor the overshoot becomes a squash, so it jiggles stretch → squash → stretch before resting. Playful, squishy and alive.",
            "一个110 pt的光泽果冻球（紫到粉渐变，左上角白色高光，地面接触阴影不参与形变）跟着手指走。形变由速度而非位置驱动：速度映射为最高45%的应变，沿运动方向拉长、横向变细，并经150毫秒的快速弹簧平滑，绝不抖动；手指停住80毫秒，应变就以弹簧（响应0.3秒）松弛回圆形。松手后它以欠阻尼弹簧（响应0.5秒、阻尼0.4）飞回中心，由于应变以带符号的张量存储，过冲会自然变成挤压，于是“拉长、压扁、再拉长”地晃几下才停住。俏皮、软糯、充满生命力。"
        ),
        implementation: L(
            "Velocity is converted to a signed strain tensor (s·cos2θ, s·sin2θ) animated through a custom GeometryEffect that builds an area-preserving affine stretch (1 + s along, 1/(1 + s) across) around the view center; negative strain naturally becomes a squash.",
            "将速度转换为带符号的应变张量 (s·cos2θ, s·sin2θ)，通过自定义 GeometryEffect 以视图中心为原点构建保持面积的仿射拉伸（沿向 1 + s、横向 1/(1 + s)）；负应变自然表现为挤压。"
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

/// Area-preserving stretch along θ, with the strain stored as (e1, e2) = s·(cos 2θ, sin 2θ): the blob grows by
/// 1 + s along θ and shrinks by 1 / (1 + s) across it, so its area never changes. (−e1, −e2) points 90° away,
/// which reads as a squash along θ.
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
        let s = (e1 * e1 + e2 * e2).squareRoot()
        guard s > 0.0001 else { return ProjectionTransform(CGAffineTransform.identity) }
        let along = 1 + s
        let across = 1 / along
        let mean = (along + across) / 2
        let half = (along - across) / 2
        // R(θ)·diag(along, across)·R(−θ), written with cos 2θ = e1 / s and sin 2θ = e2 / s.
        let a = mean + half * e1 / s
        let d = mean - half * e1 / s
        let b = half * e2 / s
        let cx = size.width / 2
        let cy = size.height / 2
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
    /// The one pending relax; each drag change cancels and replaces it.
    @State private var relaxTask: Task<Void, Never>?
    /// True while a real finger holds the jelly.
    @State private var held = false
    /// The scripted flick, cancelled on the first real touch.
    @State private var script: Task<Void, Never>?
    /// Resets on system cancellation too, so a stolen touch never leaves the blob offset.
    @GestureState private var pressing = false

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
        .onDisappear {
            relaxTask?.cancel()
            script?.cancel()
        }
        .onChange(of: pressing) { _, isPressing in
            if !isPressing { endHold() }
        }
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
            .updating($pressing) { _, state, _ in state = true }
            .onChanged { value in
                if !held {
                    held = true
                    script?.cancel()
                    script = nil
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isDragging = true }
                }
                offset = value.translation
                withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.86)) {
                    strain = strainFor(velocity: value.velocity)
                }
                relaxWhenStill()
            }
            .onEnded { _ in endHold() }
    }

    /// Release or system cancellation: the blob wobbles home.
    private func endHold() {
        guard held else { return }
        held = false
        relaxTask?.cancel()
        release()
    }

    /// DragGesture stops reporting when the finger holds still, so the last velocity would freeze the stretch.
    private func relaxWhenStill() {
        relaxTask?.cancel()
        relaxTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.08))
            guard !Task.isCancelled, isDragging else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) { strain = .zero }
        }
    }

    private func strainFor(velocity: CGSize) -> CGSize {
        let speed = (velocity.width * velocity.width + velocity.height * velocity.height).squareRoot()
        guard speed > 1 else { return .zero }
        let s = min(speed / 2000 * ctx.cg("intensity"), 0.45)
        let theta = atan2(velocity.height, velocity.width)
        return CGSize(width: s * cos(2 * theta), height: s * sin(2 * theta))
    }

    private func release() {
        let distance = (offset.width * offset.width + offset.height * offset.height).squareRoot()
        let current = (strain.width * strain.width + strain.height * strain.height).squareRoot()
        // A finger that rested before lifting has already relaxed the strain: give the fly-home a short stretch
        // along its path (toward the centre) so it still jiggles.
        if current < 0.05 && distance > 24 {
            let s = min(distance / 90 * 0.16 * ctx.cg("intensity"), 0.24)
            let theta = atan2(-offset.height, -offset.width)
            withAnimation(.easeOut(duration: 0.07)) {
                strain = CGSize(width: s * cos(2 * theta), height: s * sin(2 * theta))
            }
            relaxTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.07))
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) { strain = .zero }
            }
            withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
                offset = .zero
                isDragging = false
            }
            return
        }
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            offset = .zero
            strain = .zero
            isDragging = false
        }
    }

    private func simulate() {
        guard !held else { return }
        let angle = Double.random(in: 0..<(2 * Double.pi))
        let target = CGSize(width: cos(angle) * 90, height: sin(angle) * 70)
        let velocity = CGSize(width: cos(angle) * 1600, height: sin(angle) * 1600)
        withAnimation(.easeOut(duration: 0.35)) {
            offset = target
            strain = strainFor(velocity: velocity)
            isDragging = true
        }
        script?.cancel()
        script = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.45))
            guard !Task.isCancelled else { return }
            // Flip the strain on release so the wobble reads clearly in the thumbnail.
            withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
                offset = .zero
                strain = CGSize(width: -strain.width * 0.6, height: -strain.height * 0.6)
                isDragging = false
            }
            try? await Task.sleep(for: .seconds(0.12))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
                strain = .zero
            }
        }
    }
}
