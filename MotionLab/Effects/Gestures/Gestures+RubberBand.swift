import SwiftUI

extension Effect {
    static let gesturesRubberBand = Effect(
        id: "gestures.rubber-band",
        category: .gestures,
        interaction: .gesture,
        name: L("Rubber-Band Drag", "橡皮筋拖拽"),
        summary: L("A tile that resists harder the further you pull, then springs home.", "越拉越费力的方块，松手后弹性归位。"),
        prompt: L(
            "A 120 pt rounded-square tile (continuous 30 pt corners, indigo-to-violet gradient, soft coloured shadow) rests at the centre of the stage. Dragging it in any direction maps each axis of the finger translation d through a rubber-band curve, offset = (1 − 1 ∕ (d·c ∕ L + 1))·L, so the first points track almost 1:1 and resistance grows asymptotically toward the limit L, exactly like UIScrollView overscroll. While pulled, the tile stretches up to 8% along the pull axis and thins across it, and a faint dashed boundary ring fades in over 200 ms. On release it returns home on a spring (response 0.45 s, damping 0.62) that overshoots once before settling, with a soft haptic. Elastic, tactile and physically honest.",
            "中央是一个120 pt的方块（30 pt连续圆角、靛紫渐变、同色柔和投影）。向任意方向拖动时，手指在横纵两轴的位移d各自经过橡皮筋函数offset = (1−1/(d·c/L + 1))·L映射：起步几乎1:1，越往外阻力越大，无限逼近上限L，如同UIScrollView越界回弹。拉扯时方块沿拉伸方向最多伸长8%、横向相应变细，一圈虚线边界在200毫秒内淡入。松手后以弹簧（响应0.45秒、阻尼0.62）回到原位，过冲一次再稳住，伴随柔和触感。真实可信。"
        ),
        implementation: L(
            "DragGesture feeds the raw translation into the shared rubberBand(_:limit:coefficient:) function; the tile is stretched along the drag angle with rotate–scale–rotate and released with a spring.",
            "DragGesture 的原始位移经全局 rubberBand(_:limit:coefficient:) 函数衰减；通过“旋转—缩放—反旋转”沿拖拽方向拉伸方块，松手时用弹簧动画归位。"
        ),
        apis: ["DragGesture", "rubberBand", "offset", "scaleEffect(x:y:)", "spring(response:dampingFraction:)"],
        tags: ["rubber band", "overscroll", "elastic", "resistance", "橡皮筋", "阻尼", "回弹", "越界"],
        params: [
            .slider("limit", L("Stretch limit", "拉伸上限"), 40...200, default: 110, step: 1, decimals: 0, unit: "pt"),
            .slider("coefficient", L("Resistance", "阻力系数"), 0.2...1.2, default: 0.55),
            .slider("response", L("Spring response", "弹簧响应"), 0.2...1.0, default: 0.45, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.3...1.0, default: 0.62),
        ]
    ) { ctx in
        RubberBandDemo(ctx: ctx)
    }
}

private struct RubberBandDemo: View {
    let ctx: DemoContext
    @State private var drag: CGSize = .zero
    @State private var isDragging = false
    /// True while a real finger holds the tile.
    @State private var held = false
    /// The scripted stretch, cancelled on the first real touch.
    @State private var script: Task<Void, Never>?
    /// Resets on system cancellation too, so a stolen touch never leaves the tile stretched.
    @GestureState private var pressing = false

    var body: some View {
        let limit = ctx.cg("limit")
        let coefficient = ctx.cg("coefficient")
        let x = rubberBand(drag.width, limit: limit, coefficient: coefficient)
        let y = rubberBand(drag.height, limit: limit, coefficient: coefficient)
        let distance = sqrt(x * x + y * y)
        let stretch = 1 + min(distance / max(limit, 1), 1) * 0.08
        let radians = Double(atan2(y, x))

        ZStack {
            Circle()
                .strokeBorder(Color.primary.opacity(0.18), style: StrokeStyle(lineWidth: 1.5, dash: [4, 6]))
                .frame(width: min(120 + limit * 2, 330), height: min(120 + limit * 2, 330))
                .opacity(isDragging ? 1 : 0)

            tile
                .rotationEffect(.radians(-radians))
                .scaleEffect(x: stretch, y: 1 / stretch)
                .rotationEffect(.radians(radians))
                .offset(x: x, y: y)
                .gesture(dragGesture)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Drag the tile in any direction", "向任意方向拖动方块"), ctx: ctx)
                .padding(.bottom, 14)
        }
        .autoplay(ctx.isPreview, every: 1.5) { simulate() }
        .onChange(of: pressing) { _, isPressing in
            if !isPressing { endHold(completed: false) }
        }
        .onDisappear { script?.cancel() }
    }

    private var tile: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(Palette.primary)
            .frame(width: 120, height: 120)
            .overlay {
                Image(systemName: "hand.draw.fill")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.95))
            }
            .shadow(color: Palette.indigo.opacity(0.35), radius: 20, y: 12)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($pressing) { _, state, _ in state = true }
            .onChanged { value in
                if !held {
                    held = true
                    script?.cancel()
                    script = nil
                    withAnimation(.easeOut(duration: 0.2)) { isDragging = true }
                }
                drag = value.translation
            }
            .onEnded { _ in endHold(completed: true) }
    }

    /// Release or system cancellation (silent, no haptic): the tile springs back to centre.
    private func endHold(completed: Bool) {
        guard held else { return }
        held = false
        release(haptic: completed)
    }

    /// Simulated drags release from a Task (outside the muted autoplay call), so they pass `haptic: false`.
    private func release(haptic: Bool = true) {
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            drag = .zero
            isDragging = false
        }
        if haptic && !ctx.isPreview { Haptics.tap(.soft) }
    }

    private func simulate() {
        guard !held else { return }
        let angle = Double.random(in: 0..<(2 * Double.pi))
        withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
            drag = CGSize(width: cos(angle) * 260, height: sin(angle) * 260)
            isDragging = true
        }
        script?.cancel()
        script = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.7))
            guard !Task.isCancelled else { return }
            release(haptic: false)
        }
    }
}
