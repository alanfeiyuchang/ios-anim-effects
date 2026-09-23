import SwiftUI

extension Effect {
    static let gesturesSlideToConfirm = Effect(
        id: "gestures.slide-to-confirm",
        category: .gestures,
        interaction: .gesture,
        name: L("Slide to Confirm", "滑动确认"),
        summary: L("A shimmering track whose knob must be dragged to the end to commit.", "带流光文字的滑轨，把滑块拖到尽头才会提交。"),
        prompt: L(
            "A 290 × 64 pt capsule track with a 56 pt white knob (chevron glyph, soft shadow) inset 4 pt on the left. The label “Slide to confirm” carries a light band that sweeps across it every 2 s. Dragging moves the knob 1:1 while an aurora-gradient fill trails behind it and the label fades out twice as fast as the knob travels; pulling past either end is rubber-banded. Releasing beyond 80% of the travel (or flicking hard past halfway) snaps the knob to the end on a spring (response 0.35 s, damping 0.8), the whole track floods green, the chevron morphs into a checkmark via a symbol replace transition and a success haptic plays; after 1.8 s it resets. Releasing short springs the knob back (damping 0.7). Deliberate and safe, yet delightful.",
            "一条 290 × 64pt 的胶囊滑轨，左侧内嵌 4pt 放置 56pt 的白色滑块（双箭头图标、柔和投影）。“滑动以确认”文字上每 2 秒扫过一道高光。拖动时滑块 1:1 跟手，身后拖出极光渐变填充，文字以滑块行程两倍的速度淡出；超出两端均有橡皮筋阻尼。松手时若超过行程 80%（或在过半后快速甩动），滑块以弹簧（响应 0.35 秒、阻尼 0.8）吸附到终点，整条滑轨铺满绿色，箭头通过符号替换转场变为对勾，并触发成功触感；1.8 秒后自动复位。未达阈值则以弹簧（阻尼 0.7）弹回起点。操作郑重安全，又不失愉悦。"
        ),
        implementation: L(
            "A DragGesture on the knob drives a clamped, rubber-banded x offset; a TimelineView animates the label’s gradient shimmer and contentTransition(.symbolEffect(.replace)) swaps the glyph on success.",
            "滑块上的 DragGesture 驱动带夹紧与橡皮筋的 x 偏移；TimelineView 驱动文字的渐变流光，成功时用 contentTransition(.symbolEffect(.replace)) 切换图标。"
        ),
        apis: ["DragGesture", "TimelineView", "LinearGradient", "contentTransition(.symbolEffect)", "rubberBand"],
        tags: ["slide to unlock", "confirm", "slider", "shimmer", "swipe", "滑动解锁", "滑动确认", "流光", "滑块"],
        params: [
            .slider("threshold", L("Commit threshold", "确认阈值"), 0.6...0.95, default: 0.8),
            .slider("damping", L("Return damping", "回弹阻尼"), 0.4...1.0, default: 0.7),
        ]
    ) { ctx in
        SlideToConfirmDemo(ctx: ctx)
    }
}

private struct SlideToConfirmDemo: View {
    let ctx: DemoContext
    @State private var x: CGFloat = 0
    @State private var confirmed = false

    private let trackWidth: CGFloat = 290
    private let knob: CGFloat = 56
    private let inset: CGFloat = 4
    private var maxX: CGFloat { trackWidth - knob - inset * 2 }

    var body: some View {
        let progress = min(max(x / maxX, 0), 1)
        VStack(spacing: 18) {
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(confirmed ? AnyShapeStyle(Palette.green.gradient) : AnyShapeStyle(Color.primary.opacity(0.07)))
                Capsule()
                    .fill(Palette.aurora)
                    .frame(width: knob + inset * 2 + max(x, 0))
                    .opacity(confirmed ? 0 : 0.3 + 0.7 * Double(progress))
                label(progress: progress)
                knobView
                    .offset(x: inset + x)
                    .gesture(dragGesture)
            }
            .frame(width: trackWidth, height: knob + inset * 2)
            .overlay(Capsule().strokeBorder(Palette.stroke, lineWidth: 1))
            DemoHint(text: L("Drag the knob to the end", "把滑块拖到最右端"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 3.4, delay: 0.8) { simulate() }
    }

    @ViewBuilder
    private func label(progress: CGFloat) -> some View {
        if confirmed {
            Label(ctx.language == .zh ? "已确认" : "Confirmed", systemImage: "lock.open.fill")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
        } else {
            ShimmerText(text: ctx.language == .zh ? "滑动以确认" : "Slide to confirm")
                .padding(.leading, knob)
                .frame(maxWidth: .infinity)
                .opacity(Double(max(1 - progress * 2, 0)))
                .transition(.opacity)
        }
    }

    private var knobView: some View {
        Circle()
            .fill(.white)
            .frame(width: knob, height: knob)
            .overlay {
                Image(systemName: confirmed ? "checkmark" : "chevron.right.2")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(confirmed ? Palette.green : Palette.indigo)
                    .contentTransition(.symbolEffect(.replace))
            }
            .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard !confirmed else { return }
                let raw = value.translation.width
                if raw < 0 {
                    x = rubberBand(raw, limit: 20)
                } else if raw > maxX {
                    x = maxX + rubberBand(raw - maxX, limit: 16)
                } else {
                    x = raw
                }
            }
            .onEnded { value in
                guard !confirmed else { return }
                let flicked = value.predictedEndTranslation.width > maxX * 1.2 && x > maxX * 0.5
                if x > maxX * ctx.cg("threshold") || flicked {
                    confirm()
                } else {
                    withAnimation(.spring(response: 0.45, dampingFraction: ctx["damping"])) { x = 0 }
                }
            }
    }

    private func confirm() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            x = maxX
            confirmed = true
        }
        if !ctx.isPreview { Haptics.success() }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
                confirmed = false
                x = 0
            }
        }
    }

    private func simulate() {
        guard !confirmed else { return }
        withAnimation(.easeInOut(duration: 0.8)) { x = maxX * 0.92 }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.85))
            confirm()
        }
    }
}

private struct ShimmerText: View {
    let text: String

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let phase = CGFloat(t.truncatingRemainder(dividingBy: 2.0) / 2.0)
            Text(text)
                .font(.headline)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.primary.opacity(0.35), Color.primary.opacity(0.95), Color.primary.opacity(0.35)],
                        startPoint: UnitPoint(x: phase * 3 - 1.5, y: 0.5),
                        endPoint: UnitPoint(x: phase * 3 - 0.5, y: 0.5)
                    )
                )
        }
    }
}
