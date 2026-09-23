import SwiftUI

extension Effect {
    static let inputsDragStepper = Effect(
        id: "inputs.drag-stepper",
        category: .inputs,
        interaction: .gesture,
        name: L("Swipe Stepper", "拨动式步进器"),
        summary: L("Flick the number knob left or right; it stretches on a leash, clicks the value and springs home.", "左右拨动数字旋钮：像被绳牵着一样拉伸，“咔哒”改值后弹回原位。"),
        prompt: L(
            "A 230 × 64 pt pill with faint chevrons at both ends and a 56 pt knob in the middle showing the value. Dragging the knob sideways moves it on a leash: rubber-band resistance caps travel at ~90 pt, and the knob stretches up to 12% along the drag while the chevron on that side brightens and slides outward. Crossing 36 pt fires the step — the number rolls toward the drag direction with numeric digits and a medium haptic — and holding past the threshold repeats every 350 ms. On release the knob snaps back to centre on an underdamped spring (response 0.4 s, damping 0.52), wobbling once. Vertical flicks are ignored. A compact, gesture-first stepper that feels like flicking a physical toggle.",
            "一枚 230 × 64pt 胶囊，两端是淡淡的箭头，中间是显示数值的 56pt 旋钮。横向拖动时旋钮像被绳子牵着：橡皮筋阻尼把行程限制在约 90pt，旋钮沿拖动方向最多拉伸 12%，同侧箭头变亮并外滑。越过 36pt 即触发一步——数字朝拖动方向滚动更新，伴随中等触觉——保持在阈值外则每 350 毫秒重复一次。松手后旋钮以欠阻尼弹簧（响应 0.4 秒、阻尼 0.52）弹回中心并轻晃一下，纵向拨动被忽略。手感像拨动实体开关。"
        ),
        implementation: L(
            "DragGesture translation is passed through rubberBand for the knob offset and a proportional scaleEffect(x:); crossing the threshold changes the value and starts a repeating Task, and release springs the offset back.",
            "DragGesture 的位移经 rubberBand 转换为旋钮偏移，并按比例施加 scaleEffect(x:)；越过阈值即改值并启动重复 Task，松手时以弹簧复位偏移。"
        ),
        apis: ["DragGesture", "rubberBand", "scaleEffect(x:y:anchor:)", "contentTransition(.numericText)", "spring(response:dampingFraction:)"],
        tags: ["stepper", "swipe", "drag", "knob", "步进器", "拨动", "拖拽", "旋钮"],
        params: [
            .slider("threshold", L("Step threshold", "触发距离"), 20...56, default: 36, decimals: 0, unit: "pt"),
            .slider("response", L("Return response", "回弹响应"), 0.2...0.8, default: 0.4, unit: "s"),
            .slider("damping", L("Return damping", "回弹阻尼"), 0.3...1.0, default: 0.52),
        ]
    ) { ctx in
        DragStepperDemo(ctx: ctx)
    }
}

private struct DragStepperDemo: View {
    let ctx: DemoContext
    @State private var value = 3
    @State private var offset: CGFloat = 0
    @State private var engaged = 0
    @State private var repeatTask: Task<Void, Never>?
    @State private var step = 0
    /// True while a real finger is down; `@GestureState` also resets on system cancellation,
    /// which is what releases the knob and stops the repeat loop when `onEnded` never comes.
    @GestureState private var touching = false

    private let range: ClosedRange<Int> = 0...20
    private let limit: CGFloat = 90

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Text(L("Tickets", "票数"), ctx.language)
                .font(.headline)
                .foregroundStyle(.primary)
            pill
            Text(ctx.language == .zh ? "合计 ¥\(value * 80)" : "Total $\(value * 12)")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.secondary)
                .contentTransition(.numericText(value: Double(value)))
                .animation(.snappy, value: value)
            Spacer()
            DemoHint(text: L("Drag the number left or right", "左右拖动数字"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDisappear { repeatTask?.cancel() }
        .onChange(of: touching) { _, isTouching in
            if !isTouching { release() }
        }
        .autoplay(ctx.isPreview, every: 1.3, delay: 0.3) { previewFlick() }
    }

    private var pill: some View {
        let progress: CGFloat = min(abs(offset) / ctx.cg("threshold"), 1)
        let stretch: CGFloat = 1 + min(abs(offset) / limit, 1) * 0.12
        return ZStack {
            Capsule()
                .fill(Color.primary.opacity(0.06))
                .overlay(Capsule().strokeBorder(Palette.stroke))
            HStack {
                chevron("chevron.left", active: offset < 0, progress: progress, side: -1)
                Spacer(minLength: 0)
                chevron("chevron.right", active: offset > 0, progress: progress, side: 1)
            }
            .padding(.horizontal, 18)
            knob
                .scaleEffect(x: stretch, y: 2 - stretch, anchor: offset >= 0 ? .leading : .trailing)
                .offset(x: offset)
                .gesture(drag)
        }
        .frame(width: 230, height: 64)
    }

    private func chevron(_ symbol: String, active: Bool, progress: CGFloat, side: CGFloat) -> some View {
        let amount: CGFloat = active ? progress : 0
        return Image(systemName: symbol)
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(active && progress >= 1 ? Palette.indigo : Color.secondary)
            .opacity(0.35 + Double(amount) * 0.65)
            .offset(x: side * amount * 8)
    }

    private var knob: some View {
        Text("\(value)")
            .font(.system(size: 24, weight: .bold, design: .rounded).monospacedDigit())
            .foregroundStyle(.white)
            .contentTransition(.numericText(value: Double(value)))
            .frame(width: 56, height: 56)
            .background(Palette.primary, in: Circle())
            .shadow(color: Palette.indigo.opacity(0.35), radius: 8, y: 4)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .updating($touching) { _, state, _ in state = true }
            .onChanged { gesture in
                let dx: CGFloat = gesture.translation.width
                offset = rubberBand(dx, limit: limit, coefficient: 1.0)
                let side = offset >= ctx.cg("threshold") ? 1 : (offset <= -ctx.cg("threshold") ? -1 : 0)
                if side != engaged {
                    engaged = side
                    repeatTask?.cancel()
                    if side != 0 { startRepeating(side) }
                }
            }
    }

    /// Steps the value. Returns false once it rests on a range bound, so the repeat loop stops there:
    /// pushing against a bound gives one rigid tick per contact, never a buzz every 350 ms.
    @discardableResult
    private func change(_ delta: Int, silent: Bool = false) -> Bool {
        let target = (value + delta).clamped(to: range)
        let muted = ctx.isPreview || silent
        guard target != value else {
            if !muted { Haptics.tap(.rigid) }
            return false
        }
        if !muted { Haptics.tap(.medium) }
        withAnimation(.snappy(duration: 0.25)) { value = target }
        return target != range.lowerBound && target != range.upperBound
    }

    private func startRepeating(_ side: Int) {
        guard change(side) else { return }
        repeatTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(350))
                guard !Task.isCancelled, change(side) else { return }
            }
        }
    }

    /// Single cleanup for a normal end, a cancelled touch and the preview flick.
    private func release() {
        guard engaged != 0 || offset != 0 || repeatTask != nil else { return }
        repeatTask?.cancel()
        repeatTask = nil
        engaged = 0
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) { offset = 0 }
    }

    private func previewFlick() {
        step += 1
        let side: CGFloat = (step / 3) % 2 == 0 ? 1 : -1
        withAnimation(.easeOut(duration: 0.22)) { offset = side * (ctx.cg("threshold") + 8) }
        // Captured now: autoplay mutes haptics only for the synchronous part of the action.
        let muted = Haptics.isMuted
        Task {
            try? await Task.sleep(for: .seconds(0.24))
            change(Int(side), silent: muted)
            try? await Task.sleep(for: .seconds(0.2))
            release()
        }
    }
}
