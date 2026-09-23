import SwiftUI

extension Effect {
    static let shaderJellyPress = Effect(
        id: "shader.jelly-press",
        category: .shaders,
        interaction: .gesture,
        name: L("Jelly Press", "果冻按压"),
        summary: L(
            "Press to raise a soft dome under your finger; let go and the surface wobbles like jelly.",
            "按下时指尖下隆起柔软的圆顶，松手后表面像果冻一样来回颤动。"
        ),
        prompt: L(
            "Pressing the card raises a soft glassy dome under the finger: within a 95 pt radius the content is magnified toward the touch with a (1 − t²)² falloff that has no visible edge, and the dome is lit from the top-left so it reads as a bulge. It springs up on press (response 0.28 s, damping 0.62) and rides the finger with an interactive spring, smearing its content up to 28 pt against the drag velocity like a viscous gel. On release the strength springs back to zero with a very underdamped spring (response 0.55 s, damping 0.3), overshooting into a dent and back several times before settling — the jelly wobble. Squishy, tactile and delightful.",
            "按住卡片时，指尖下方会隆起一个柔软的玻璃质圆顶：在 95pt 半径内，内容以 (1 − t²)² 的衰减向触点放大，边缘看不到任何接缝；圆顶受左上方光照，读起来就是一个凸起。按下时它以弹簧（响应 0.28 秒、阻尼 0.62）鼓起，并以交互弹簧跟随手指，同时像黏稠凝胶一样，沿拖动速度的反方向拖出最多 28pt 的拖影。松手后强度以强欠阻尼弹簧（响应 0.55 秒、阻尼 0.3）回到零，会越过零点变成凹陷、再弹回，反复数次才平息——这就是果冻般的颤动。软糯、可触、令人愉悦。"
        ),
        implementation: L(
            "A [[stitchable]] layer shader pulls samples toward the center by d·strength·(1 − t²)² and offsets them by the velocity smear, shading by the dome's slope; center, strength and smear live in an Animatable modifier so springs (including negative overshoot) drive the shader.",
            "[[stitchable]] layerEffect 着色器按 d·strength·(1 − t²)² 把采样点拉向中心，并叠加速度拖影偏移，再依据圆顶斜率打光；中心、强度与拖影放在 Animatable 修饰器中，由弹簧（包括越过零点的负向过冲）驱动着色器。"
        ),
        apis: ["layerEffect", "Animatable", "DragGesture.Value.velocity", "spring(response:dampingFraction:)", "Metal"],
        tags: ["jelly", "bulge", "wobble", "squishy", "果冻", "凸起", "颤动", "按压"],
        params: [
            .slider("radius", L("Dome radius", "圆顶半径"), 60...140, default: 95, decimals: 0, unit: "pt"),
            .slider("depth", L("Bulge", "隆起强度"), 0.2...0.9, default: 0.6),
            .slider("wobble", L("Release damping", "松手阻尼"), 0.15...0.8, default: 0.3),
        ]
    ) { ctx in
        JellyPressDemo(ctx: ctx)
    }
}

private struct JellyPressDemo: View {
    let ctx: DemoContext
    @State private var center = CGPoint(x: 130, y: 150)
    @State private var strength: Double = 0
    @State private var smear: CGSize = .zero
    @State private var pressing = false

    var body: some View {
        VStack(spacing: 14) {
            ShaderArtwork(variant: 1)
                .modifier(JellyModifier(center: center, strength: strength, smear: smear, radius: ctx["radius"]))
                .gesture(press)
            DemoHint(text: L("Press, hold and drag, then let go", "按住拖动，然后松手"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.2, delay: 0.3) { poke() }
    }

    private var press: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !pressing {
                    pressing = true
                    center = value.location
                    Haptics.tap(.soft)
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.62)) { strength = ctx["depth"] }
                }
                let sx = (value.velocity.width * 0.02).clamped(to: -28...28)
                let sy = (value.velocity.height * 0.02).clamped(to: -28...28)
                withAnimation(.interactiveSpring(response: 0.22, dampingFraction: 0.78)) {
                    center = value.location
                    smear = CGSize(width: sx, height: sy)
                }
            }
            .onEnded { _ in
                pressing = false
                release()
            }
    }

    private func release() {
        let damping = ctx["wobble"]
        withAnimation(.spring(response: 0.55, dampingFraction: damping)) {
            strength = 0
            smear = .zero
        }
    }

    /// Simulated press: pop a dome somewhere on the card, hold briefly, then let it wobble out.
    private func poke() {
        center = CGPoint(x: CGFloat.random(in: 70...190), y: CGFloat.random(in: 80...220))
        withAnimation(.spring(response: 0.28, dampingFraction: 0.62)) { strength = ctx["depth"] }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.55))
            guard !pressing else { return }
            release()
        }
    }
}

/// Animatable so springs (including overshoot through zero) reach the shader.
private struct JellyModifier: ViewModifier, Animatable {
    var center: CGPoint
    var strength: Double
    var smear: CGSize
    var radius: Double

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<Double, AnimatablePair<CGFloat, CGFloat>>> {
        get {
            AnimatablePair(
                AnimatablePair(center.x, center.y),
                AnimatablePair(strength, AnimatablePair(smear.width, smear.height))
            )
        }
        set {
            center = CGPoint(x: newValue.first.first, y: newValue.first.second)
            strength = newValue.second.first
            smear = CGSize(width: newValue.second.second.first, height: newValue.second.second.second)
        }
    }

    func body(content: Content) -> some View {
        let reach = radius * 0.5 + 30
        let active = abs(strength) > 0.001 || abs(smear.width) + abs(smear.height) > 0.01
        content.layerEffect(
            ShaderLibrary.mlJellyPress(.float2(center), .float(radius), .float(strength), .float2(smear)),
            maxSampleOffset: CGSize(width: reach, height: reach),
            isEnabled: active
        )
    }
}
