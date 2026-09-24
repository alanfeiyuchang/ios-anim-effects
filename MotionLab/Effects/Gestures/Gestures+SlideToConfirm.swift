import SwiftUI

extension Effect {
    static let gesturesSlideToConfirm = Effect(
        id: "gestures.slide-to-confirm",
        category: .gestures,
        interaction: .gesture,
        name: L("Slide to Confirm", "滑动确认"),
        summary: L("A shimmering track whose knob must be dragged to the end to commit.", "带流光文字的滑轨，把滑块拖到尽头才会提交。"),
        prompt: L(
            "A 290×64 pt capsule track holds a 56 pt white chevron knob inset 4 pt on the left, beside a “Slide to confirm” label that a light band sweeps every 2 s. Touching presses the knob to 94% with a tighter shadow; dragging moves it 1:1 while an aurora-gradient fill clipped inside the track trails behind, the label fades twice as fast as the knob travels and both ends rubber-band. Releasing beyond 80% of the travel, or flicking hard past halfway, snaps the knob to the end on a spring (response 0.35 s, damping 0.8) as the track floods green, the chevron swaps to a checkmark and a success haptic plays, resetting after 1.8 s. Releasing short springs it back (damping 0.7). Deliberate and safe, yet delightful.",
            "一条290×64 pt的胶囊滑轨，左侧内嵌4 pt处是56 pt的白色箭头滑块，旁边的“滑动以确认”每2秒扫过一道高光。按住时滑块缩到94%、投影收紧；拖动时1:1跟手，身后拖出裁在滑轨内的极光渐变填充，文字以两倍于滑块行程的速度淡出，两端都带橡皮筋阻尼。松手时超过行程80%（或过半后用力一甩），滑块以弹簧（响应0.35秒、阻尼0.8）吸到终点，滑轨铺满绿色，箭头换成对勾，伴随成功触感，1.8秒后复位。不到阈值则以弹簧（阻尼0.7）弹回。郑重又愉悦。"
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
    @State private var pressed = false
    /// True while a real finger holds the knob.
    @State private var held = false
    /// The scripted slide, cancelled on the first real touch.
    @State private var script: Task<Void, Never>?
    /// Resets on system cancellation too, so a stolen touch never leaves the knob mid-track and pressed.
    @GestureState private var pressing = false

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
                    // Never wider than the track, even while the knob is rubber-banding past the end.
                    .frame(width: min(trackWidth, knob + inset * 2 + max(x, 0)))
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
        .onChange(of: pressing) { _, isPressing in
            if !isPressing { endHold() }
        }
        .onDisappear { script?.cancel() }
    }

    @ViewBuilder
    private func label(progress: CGFloat) -> some View {
        if confirmed {
            Label {
                Text(L("Confirmed", "已确认"), ctx.language)
            } icon: {
                Image(systemName: "lock.open.fill")
            }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
        } else {
            SlideShimmerLabel(text: ctx.language == .zh ? "滑动以确认" : "Slide to confirm", preview: ctx.isPreview, paused: progress > 0.5)
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
            .shadow(color: .black.opacity(pressed ? 0.12 : 0.18), radius: pressed ? 4 : 8, y: pressed ? 2 : 4)
            .scaleEffect(pressed ? 0.94 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: pressed)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($pressing) { _, state, _ in state = true }
            .onChanged { value in
                guard !confirmed else { return }
                if !held {
                    held = true
                    script?.cancel()
                    script = nil
                    pressed = true
                }
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
                guard held else { return }
                held = false
                pressed = false
                guard !confirmed else { return }
                let flicked = value.predictedEndTranslation.width > maxX * 1.2 && x > maxX * 0.5
                if x > maxX * ctx.cg("threshold") || flicked {
                    confirm()
                } else {
                    withAnimation(.spring(response: 0.45, dampingFraction: ctx["damping"])) { x = 0 }
                }
            }
    }

    /// System cancellation (no `onEnded`): the knob springs back to the start, unconfirmed.
    private func endHold() {
        guard held else { return }
        held = false
        pressed = false
        guard !confirmed else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: ctx["damping"])) { x = 0 }
    }

    /// Simulated slides confirm from a Task (outside the muted autoplay call), so they pass `haptic: false`.
    private func confirm(haptic: Bool = true) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            x = maxX
            confirmed = true
        }
        if haptic && !ctx.isPreview { Haptics.success() }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
                confirmed = false
                x = 0
            }
        }
    }

    private func simulate() {
        guard !confirmed, !held else { return }
        withAnimation(.easeInOut(duration: 0.8)) { x = maxX * 0.92 }
        script?.cancel()
        script = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.85))
            guard !Task.isCancelled else { return }
            confirm(haptic: false)
        }
    }
}

private struct SlideShimmerLabel: View {
    let text: String
    let preview: Bool
    /// Stops the shimmer once the label has faded out.
    let paused: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview), paused: paused)) { timeline in
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
