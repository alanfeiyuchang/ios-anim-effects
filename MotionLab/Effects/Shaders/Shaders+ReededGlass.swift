import SwiftUI

extension Effect {
    static let shaderReededGlass = Effect(
        id: "shader.reeded-glass",
        category: .shaders,
        interaction: .gesture,
        name: L("Reeded Glass", "长虹玻璃"),
        summary: L(
            "Slide a fluted-glass panel across the artwork; it snaps to detents with a click.",
            "拖动一块长虹（凹凸条纹）玻璃划过画面，松手后吸附到档位并伴随一声轻“咔”。"
        ),
        prompt: L(
            "A 150 pt wide panel of reeded (fluted) glass stands over colorful artwork while a warm light orb drifts behind it. Every 14 pt flute behaves like a small cylindrical lens: the image across it is squeezed and mirrored, so shapes behind the glass break into repeating vertical slivers, softened by a light vertical frost. Each flute is shaded darker at its sides and carries a thin specular line, and both panel edges catch a bright bevel. Dragging the panel follows the finger 1:1; on release its throw is projected from the gesture's predicted end and it springs (response 0.5 s, damping 0.72) to the nearest of three detents with a selection haptic. Architectural, tactile and refined.",
            "一块 150pt 宽的长虹（凹凸条纹）玻璃立在彩色画面前方，一团暖色光球在其后缓缓游动。每条 14pt 宽的竖向条纹都像一枚小柱面透镜：其后的图像被压缩并镜像，于是玻璃后的形状碎成重复的竖向细条，再经轻微的竖向磨砂柔化。每条条纹两侧略暗，并带一道细细的高光线，面板两侧边缘还有明亮的倒角反光。拖动面板时它 1:1 跟随手指；松手后根据手势的预测终点推算惯性，以弹簧（响应 0.5 秒、阻尼 0.72）吸附到最近的三个档位之一，并伴随选择触感。建筑感、可触、精致。"
        ),
        implementation: L(
            "A [[stitchable]] layer shader offsets each sample by u·rib·strength inside the panel (u = position across the flute), averages five vertical taps for frost and adds flute shading, a specular line and edge bevels; the panel x is an Animatable modifier value snapped with predictedEndLocation.",
            "[[stitchable]] layerEffect 着色器在面板范围内按 u·条纹宽·强度 偏移采样（u 为条纹内的横向位置），取五个竖向采样做磨砂平均，并叠加条纹明暗、高光线与边缘倒角；面板 x 坐标是 Animatable 修饰器数值，并依据 predictedEndLocation 吸附。"
        ),
        apis: ["layerEffect", "Animatable", "DragGesture.predictedEndLocation", "spring(response:dampingFraction:)", "Metal"],
        tags: ["reeded glass", "fluted", "refraction", "glass", "长虹玻璃", "条纹玻璃", "折射", "玻璃"],
        params: [
            .slider("rib", L("Flute width", "条纹宽度"), 6...30, default: 14, decimals: 0, unit: "pt"),
            .slider("strength", L("Refraction", "折射强度"), 0...1.6, default: 0.9),
            .slider("frost", L("Frost", "磨砂"), 0...3, default: 1.2, decimals: 1),
        ]
    ) { ctx in
        ReededGlassDemo(ctx: ctx)
    }
}

private enum ReededLayout {
    static let size = CGSize(width: 260, height: 300)
    static let panelWidth: CGFloat = 150
    static let detents: [CGFloat] = [85, 130, 175]
    static let space = "reededGlassStage"
}

private struct ReededGlassDemo: View {
    let ctx: DemoContext
    @State private var panelX: CGFloat = 130
    /// Finger-to-panel-center offset captured when a drag starts.
    @State private var grab: CGFloat?
    /// True once the current touch has moved mostly sideways; vertical swipes are left to the page.
    @State private var engaged = false
    /// Resets itself when the touch ends or the system cancels it, so the panel always lands on a detent.
    @GestureState private var touching = false
    @State private var detentIndex = 1

    var body: some View {
        let rib = ctx["rib"]
        let strength = ctx["strength"]
        let frost = ctx["frost"]
        VStack(spacing: 14) {
            ShaderClock(preview: ctx.isPreview) { time in
                ReededSource(time: time)
                    .modifier(ReededModifier(panelX: panelX, rib: rib, strength: strength, frost: frost))
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            }
            .frame(width: ReededLayout.size.width, height: ReededLayout.size.height)
            .overlay { handle }
            .coordinateSpace(.named(ReededLayout.space))
            DemoHint(text: L("Drag the glass panel", "拖动玻璃面板"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.6, delay: 0.4) { glideToNext() }
    }

    /// Only the panel itself is draggable, and only horizontally, so vertical swipes still scroll the page.
    private var handle: some View {
        Color.clear
            .frame(width: ReededLayout.panelWidth, height: ReededLayout.size.height)
            .contentShape(Rectangle())
            .position(x: panelX, y: ReededLayout.size.height / 2)
            // Simultaneous, so a vertical swipe that starts on the panel is still the page's scroll.
            .simultaneousGesture(
                DragGesture(minimumDistance: 10, coordinateSpace: .named(ReededLayout.space))
                    .updating($touching) { _, state, _ in state = true }
                    .onChanged { value in drag(value) }
                    .onEnded { value in end(value) }
            )
            .onChange(of: touching) { _, isTouching in
                if !isTouching && engaged { cancelDrag() }
            }
    }

    private func drag(_ value: DragGesture.Value) {
        if !engaged {
            guard abs(value.translation.width) > abs(value.translation.height) else { return }
            engaged = true
        }
        if grab == nil {
            grab = panelX - value.startLocation.x
            Haptics.tap(.soft)
        }
        let offset = grab ?? 0
        let halfPanel = ReededLayout.panelWidth / 2
        panelX = (value.location.x + offset).clamped(to: -halfPanel * 0.4...(ReededLayout.size.width + halfPanel * 0.4))
    }

    private func end(_ value: DragGesture.Value) {
        guard engaged else { return }
        engaged = false
        settle(value)
    }

    /// The system took the touch (e.g. the page scrolled): land on the nearest detent without a throw.
    private func cancelDrag() {
        engaged = false
        grab = nil
        let best = ReededLayout.detents.indices.min { abs(ReededLayout.detents[$0] - panelX) < abs(ReededLayout.detents[$1] - panelX) } ?? 1
        detentIndex = best
        withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) { panelX = ReededLayout.detents[best] }
    }

    private func settle(_ value: DragGesture.Value) {
        let projected = value.predictedEndLocation.x + (grab ?? 0)
        grab = nil
        var best = 0
        for index in ReededLayout.detents.indices {
            let distance = abs(ReededLayout.detents[index] - projected)
            if distance < abs(ReededLayout.detents[best] - projected) {
                best = index
            }
        }
        detentIndex = best
        Haptics.selection()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) { panelX = ReededLayout.detents[best] }
    }

    /// Preview loop: hop between the detents like a quick flick.
    private func glideToNext() {
        detentIndex = (detentIndex + 1) % ReededLayout.detents.count
        withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) { panelX = ReededLayout.detents[detentIndex] }
    }
}

/// Artwork plus a drifting warm orb, so the flutes always have something moving behind them.
private struct ReededSource: View {
    let time: Double

    var body: some View {
        ZStack {
            ShaderArtwork(variant: 4)
            Circle()
                .fill(RadialGradient(colors: [Palette.amber, Palette.amber.opacity(0)], center: .center, startRadius: 0, endRadius: 50))
                .frame(width: 100, height: 100)
                .offset(x: CGFloat(80 * cos(time * 0.9)), y: CGFloat(70 * sin(time * 0.7)))
        }
        .frame(width: ReededLayout.size.width, height: ReededLayout.size.height)
    }
}

private struct ReededModifier: ViewModifier, Animatable {
    var panelX: CGFloat
    var rib: Double
    var strength: Double
    var frost: Double

    var animatableData: CGFloat {
        get { panelX }
        set { panelX = newValue }
    }

    func body(content: Content) -> some View {
        let reachX = rib * strength * 0.5 + 2
        let reachY = frost * 4 + 2
        content
            .layerEffect(
                ShaderLibrary.mlReededGlass(
                    .float(panelX),
                    .float(ReededLayout.panelWidth),
                    .float(rib),
                    .float(strength),
                    .float(frost)
                ),
                maxSampleOffset: CGSize(width: reachX, height: reachY)
            )
            .overlay {
                Rectangle()
                    .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
                    .frame(width: ReededLayout.panelWidth, height: ReededLayout.size.height + 4)
                    .position(x: panelX, y: ReededLayout.size.height / 2)
                    .allowsHitTesting(false)
            }
    }
}
