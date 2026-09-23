import SwiftUI

extension Effect {
    static let gesturesPiPSnap = Effect(
        id: "gestures.pip-snap",
        category: .gestures,
        interaction: .gesture,
        name: L("Picture-in-Picture Snap", "画中画角落吸附"),
        summary: L("A floating video window that flies to the corner your throw points at.", "悬浮视频小窗，按甩动方向飞向对应角落。"),
        prompt: L(
            "A 104 × 66 pt floating video window (14 pt continuous corners, ocean gradient with a play glyph, deep soft shadow) is docked in one corner of a phone-sized screen with 12 pt insets. While dragged it tracks the finger, lifts to 105% scale and the four corner slots appear as faint dashed outlines, the predicted target filling with a light tint. On release the end point is projected from the gesture’s predicted velocity (current position + momentum × (predicted − current)), the nearest corner wins, and the window flies there on a spring (response ≈ 0.5 s, damping ≈ 0.78) with a medium haptic. A short flick is enough to cross the screen, mirroring iOS Picture-in-Picture.",
            "一个 104 × 66pt 的悬浮视频小窗（14pt 连续圆角、海洋色渐变与播放图标、深而柔和的投影）以 12pt 边距停靠在手机屏幕的某个角落。拖拽时小窗跟手并放大到 105%，四个角落槽位以淡淡的虚线框浮现，预测目标槽位同步填充浅色。松手时，根据手势预测速度推算落点（当前位置 + 动量系数 ×（预测位置 − 当前位置）），取最近的角落，小窗以弹簧（响应约 0.5 秒、阻尼约 0.78）飞向该处，并伴随中等触感。轻轻一甩即可横跨屏幕，与 iOS 画中画的手感一致。"
        ),
        implementation: L(
            "DragGesture’s predictedEndTranslation is blended with the live translation to project a landing point; the nearest of four corner anchors is chosen and applied with a spring.",
            "将 DragGesture 的 predictedEndTranslation 与实时位移按动量系数混合得到预测落点，选取最近的角落锚点并用弹簧动画吸附。"
        ),
        apis: ["DragGesture", "predictedEndTranslation", "spring(response:dampingFraction:)", "offset"],
        tags: ["picture in picture", "PiP", "snap", "corner", "projection", "画中画", "吸附", "角落", "小窗"],
        params: [
            .slider("momentum", L("Momentum", "动量系数"), 0...1.5, default: 1),
            .slider("response", L("Spring response", "弹簧响应"), 0.2...1.0, default: 0.5, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.4...1.0, default: 0.78),
        ]
    ) { ctx in
        PiPSnapDemo(ctx: ctx)
    }
}

private enum PiPMetrics {
    static let screen = CGSize(width: 232, height: 320)
    static let window = CGSize(width: 104, height: 66)
    static let inset: CGFloat = 12

    /// Top-left origin of the window in each corner: 0 TL, 1 TR, 2 BL, 3 BR.
    static func origin(_ corner: Int) -> CGPoint {
        let x = corner % 2 == 0 ? inset : screen.width - inset - window.width
        let y = corner < 2 ? inset + 18 : screen.height - inset - window.height
        return CGPoint(x: x, y: y)
    }

    static func nearest(to point: CGPoint) -> Int {
        var best = 0
        var bestDistance = CGFloat.greatestFiniteMagnitude
        for corner in 0..<4 {
            let o = origin(corner)
            let d = ((o.x - point.x) * (o.x - point.x) + (o.y - point.y) * (o.y - point.y)).squareRoot()
            if d < bestDistance {
                bestDistance = d
                best = corner
            }
        }
        return best
    }
}

private struct PiPSnapDemo: View {
    let ctx: DemoContext
    @State private var corner = 3
    @State private var drag: CGSize = .zero
    @State private var isDragging = false
    @State private var target = 3

    var body: some View {
        let origin = PiPMetrics.origin(corner)
        VStack(spacing: 14) {
            ZStack(alignment: .topLeading) {
                PhoneScreen()
                slots
                PiPWindow(isDragging: isDragging)
                    .frame(width: PiPMetrics.window.width, height: PiPMetrics.window.height)
                    .offset(x: origin.x + drag.width, y: origin.y + drag.height)
                    .gesture(dragGesture)
            }
            .frame(width: PiPMetrics.screen.width, height: PiPMetrics.screen.height)
            DemoHint(text: L("Throw the window toward a corner", "把小窗甩向任意角落"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.6) { autoThrow() }
    }

    private var slots: some View {
        ForEach(0..<4, id: \.self) { index in
            let o = PiPMetrics.origin(index)
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(index == target ? 0.08 : 0))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                )
                .frame(width: PiPMetrics.window.width, height: PiPMetrics.window.height)
                .offset(x: o.x, y: o.y)
                .opacity(isDragging ? 1 : 0)
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !isDragging {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { isDragging = true }
                }
                drag = value.translation
                let next = PiPMetrics.nearest(to: projected(value))
                if next != target {
                    withAnimation(.easeOut(duration: 0.15)) { target = next }
                }
            }
            .onEnded { value in
                snap(to: PiPMetrics.nearest(to: projected(value)))
            }
    }

    private func projected(_ value: DragGesture.Value) -> CGPoint {
        let origin = PiPMetrics.origin(corner)
        let momentum = ctx.cg("momentum")
        let dx = value.translation.width + (value.predictedEndTranslation.width - value.translation.width) * momentum
        let dy = value.translation.height + (value.predictedEndTranslation.height - value.translation.height) * momentum
        return CGPoint(x: origin.x + dx, y: origin.y + dy)
    }

    private func snap(to next: Int) {
        let changed = next != corner
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            corner = next
            target = next
            drag = .zero
            isDragging = false
        }
        if changed && !ctx.isPreview { Haptics.tap(.medium) }
    }

    private func autoThrow() {
        let options = (0..<4).filter { $0 != corner }
        let next = options.randomElement() ?? 0
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            isDragging = true
            target = next
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.35))
            snap(to: next)
        }
    }
}

private struct PhoneScreen: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 36, style: .continuous)
            .fill(Palette.elevated)
            .overlay(alignment: .top) {
                VStack(alignment: .leading, spacing: 14) {
                    Capsule().fill(Color.primary.opacity(0.9)).frame(width: 64, height: 18)
                        .frame(maxWidth: .infinity)
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                        .frame(height: 96)
                    PlaceholderLines(count: 4)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
            .overlay(RoundedRectangle(cornerRadius: 36, style: .continuous).strokeBorder(Palette.stroke, lineWidth: 1))
            .shadow(color: .black.opacity(0.1), radius: 18, y: 10)
    }
}

private struct PiPWindow: View {
    let isDragging: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(LinearGradient(colors: [Palette.violet, Palette.blue, Palette.sky], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                Image(systemName: "play.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white.opacity(0.95))
            }
            .overlay(alignment: .bottom) {
                Capsule()
                    .fill(.white.opacity(0.35))
                    .frame(height: 3)
                    .overlay(alignment: .leading) {
                        Capsule().fill(.white).frame(width: 36, height: 3)
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)
            }
            .shadow(color: .black.opacity(isDragging ? 0.32 : 0.22), radius: isDragging ? 20 : 12, y: isDragging ? 12 : 6)
            .scaleEffect(isDragging ? 1.05 : 1)
    }
}
