import SwiftUI

extension Effect {
    static let gesturesRubberBand = Effect(
        id: "gestures.rubber-band",
        category: .gestures,
        interaction: .gesture,
        name: L("Rubber-Band Drag", "橡皮筋拖拽"),
        summary: L("A tile that resists harder the further you pull, then springs home.", "越拉越费力的方块，松手后弹性归位。"),
        prompt: L(
            "A 120 pt rounded-square tile (continuous 30 pt corners, indigo-to-violet gradient, soft colored shadow) rests at the center of the stage. Dragging it in any direction maps each axis of the finger translation d through a rubber-band curve, offset = (1 − 1 ∕ (d·c ∕ L + 1))·L, so the first points track almost 1:1 and resistance grows asymptotically toward the limit L, exactly like UIScrollView overscroll. While pulled, the tile stretches up to 8% along the pull axis (and thins across it) and a faint dashed boundary ring fades in over 200 ms. On release it returns home on a spring (response ≈ 0.45 s, damping ≈ 0.62) that overshoots once before settling, with a soft haptic. It feels elastic, tactile and physically honest.",
            "舞台中央静置一个 120pt 的连续圆角方块（圆角 30pt，靛蓝到紫色渐变，带同色柔和投影）。向任意方向拖拽时，手指在横纵两轴上的位移 d 分别经过橡皮筋函数 offset =(1 − 1/(d·c/L + 1))·L 映射：起步几乎 1:1 跟手，越往外阻力越大并无限逼近上限 L，与 UIScrollView 越界回弹如出一辙。拉扯过程中方块沿拉伸方向最多伸长 8%、垂直方向相应变细，同时一圈虚线边界在 200ms 内淡入。松手后以弹簧（响应约 0.45 秒、阻尼约 0.62）回到原位，过冲一次后稳定，并伴随柔和触感。整体手感弹性十足、真实可信。"
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
            .onChanged { value in
                if !isDragging {
                    withAnimation(.easeOut(duration: 0.2)) { isDragging = true }
                }
                drag = value.translation
            }
            .onEnded { _ in release() }
    }

    private func release() {
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            drag = .zero
            isDragging = false
        }
        if !ctx.isPreview { Haptics.tap(.soft) }
    }

    private func simulate() {
        let angle = Double.random(in: 0..<(2 * Double.pi))
        withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
            drag = CGSize(width: cos(angle) * 260, height: sin(angle) * 260)
            isDragging = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.7))
            release()
        }
    }
}
