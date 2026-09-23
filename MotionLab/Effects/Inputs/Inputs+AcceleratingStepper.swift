import SwiftUI

extension Effect {
    static let inputsAcceleratingStepper = Effect(
        id: "inputs.accelerating-stepper",
        category: .inputs,
        interaction: .gesture,
        name: L("Press-and-Hold Accelerating Stepper", "长按加速步进器"),
        summary: L("Hold + or − and the value runs faster and in bigger jumps, with a speed ring and motion blur.", "按住加减号，数值越跑越快、步子越来越大，并有速度环与动态模糊。"),
        prompt: L(
            "A calorie-goal stepper: a large rounded number flanked by 60 pt circular − and + buttons. A tap changes the value by 10. Holding a button repeats: the first repeat waits 400 ms, then each interval shrinks by 18% down to 50 ms, and after 8 repeats the step grows to 50, after 20 to 100 — announced by a small capsule badge (×1 → ×5 → ×10) that pops in with a spring. A progress ring around the held button fills with the current speed, and the number blurs up to 3 pt and rolls faster as it accelerates, each change rolling vertically with numeric digits and a soft haptic. Releasing snaps the blur away, drains the ring in 300 ms and settles the badge. Efficient for big ranges, and you can feel it gaining momentum.",
            "卡路里目标步进器：大号圆体数字两侧是 60pt 圆形 − 与 + 按钮，单击变化 10。按住则连续重复：首次重复前等 400 毫秒，之后每次间隔缩短 18%，最短 50 毫秒；重复 8 次后步长变为 50，20 次后变为 100，由一枚小胶囊角标（×1 → ×5 → ×10）以弹簧弹出提示。被按住的按钮外圈进度环随速度填满，数字随加速最多模糊 3pt、越滚越快，每次变化都纵向滚动并伴随柔和触觉。松手后模糊立刻消失，进度环 300 毫秒内清空，角标归位。能感到它在加速。"
        ),
        implementation: L(
            "A zero-distance DragGesture starts a Task loop that shortens its sleep geometrically and escalates the step size; the speed fraction drives a trimmed Circle ring and a blur radius, and the digits use contentTransition(.numericText).",
            "零距离 DragGesture 启动一个 Task 循环，按几何级数缩短等待并逐级增大步长；速度比例驱动 trim 圆环与模糊半径，数字使用 contentTransition(.numericText)。"
        ),
        apis: ["DragGesture(minimumDistance: 0)", "Task", "Circle().trim", "blur(radius:)", "contentTransition(.numericText)"],
        tags: ["stepper", "long press", "accelerate", "repeat", "步进器", "长按", "加速", "连续"],
        params: [
            .slider("acceleration", L("Interval decay", "间隔衰减"), 0.6...0.95, default: 0.82),
            .slider("fastest", L("Fastest interval", "最短间隔"), 0.03...0.2, default: 0.05, unit: "s"),
            .toggle("blur", L("Speed blur", "速度模糊"), default: true),
        ]
    ) { ctx in
        AcceleratingStepperDemo(ctx: ctx)
    }
}

private struct AcceleratingStepperDemo: View {
    let ctx: DemoContext
    @State private var value = 2000
    @State private var holding = 0
    @State private var speed: Double = 0
    @State private var multiplier = 1
    @State private var repeatTask: Task<Void, Never>?
    @State private var step = 0
    /// Ends a simulated hold; a real press cancels it so it can't cut the user's hold short.
    @State private var introTask: Task<Void, Never>?
    /// The real finger's hold direction (−1 / 0 / +1). `@GestureState` also resets when the system
    /// cancels the touch (Control Center pull, incoming call), so the repeat loop can never run away.
    @GestureState private var held = 0

    private let range: ClosedRange<Int> = 0...9990
    private let firstDelay: Double = 0.4

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            card
            Spacer()
            DemoHint(text: L("Press and hold + or −", "按住 + 或 −"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDisappear {
            repeatTask?.cancel()
            introTask?.cancel()
        }
        .onChange(of: held) { _, direction in
            if direction == 0 {
                end()
            } else {
                // A real press takes over a simulated hold, even in the same direction.
                introTask?.cancel()
                introTask = nil
                begin(direction)
            }
        }
        .autoplay(ctx.isPreview, every: 3.4, delay: 0.3) { previewHold() }
    }

    private var card: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Palette.coral)
                Text(L("Daily calorie goal", "每日热量目标"), ctx.language)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline.weight(.semibold))
            HStack(spacing: 14) {
                holdButton(symbol: "minus", direction: -1)
                number
                holdButton(symbol: "plus", direction: 1)
            }
            badge
                .frame(height: 24)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .frame(width: 316)
        .demoCard(cornerRadius: 26)
    }

    private var number: some View {
        let blurRadius: CGFloat = ctx.bool("blur") ? CGFloat(speed) * 3 : 0
        return VStack(spacing: 0) {
            Text(value.formatted())
                .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.primary)
                .contentTransition(.numericText(value: Double(value)))
                .blur(radius: blurRadius)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(verbatim: "kcal")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .frame(width: 120)
        .animation(.snappy(duration: max(0.3 - speed * 0.22, 0.08)), value: value)
    }

    private var badge: some View {
        Group {
            if multiplier > 1 {
                Text(verbatim: "×\(multiplier == 5 ? 5 : 10)")
                    .font(.caption.weight(.heavy).monospacedDigit())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Palette.sunset, in: Capsule())
                    .id(multiplier)
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
            } else {
                Text(verbatim: "×1")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(.tertiary)
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.55), value: multiplier)
    }

    private func holdButton(symbol: String, direction: Int) -> some View {
        let active = holding == direction
        return ZStack {
            Circle()
                .fill(Palette.primary)
            Circle()
                .trim(from: 0, to: active ? max(speed, 0.02) : 0)
                .stroke(Palette.amber, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(-5)
                .animation(.easeOut(duration: active ? 0.15 : 0.3), value: speed)
                .animation(.easeOut(duration: 0.3), value: active)
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: 60, height: 60)
        .scaleEffect(active ? 0.9 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: active)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($held) { _, state, _ in state = direction }
        )
    }

    /// Steps the value; returns false once it rests on a range bound, so the repeat loop stops there
    /// (one rigid tick on reaching the limit instead of a silent loop that keeps spinning).
    @discardableResult
    private func apply(_ delta: Int, muted: Bool) -> Bool {
        let target = (value + delta).clamped(to: range)
        guard target != value else {
            // Only a fresh press can land here (the loop stops at the bound): one tick per limit contact.
            if !muted { Haptics.tap(.rigid) }
            return false
        }
        let atLimit = target == range.lowerBound || target == range.upperBound
        if !muted { Haptics.tap(atLimit ? .rigid : .soft) }
        value = target
        return !atLimit
    }

    private func begin(_ direction: Int) {
        repeatTask?.cancel()
        holding = direction
        speed = 0
        multiplier = 1
        // Captured before the repeat Task: a simulated hold (preview or detail intro) must not buzz ~20 times.
        let muted = ctx.isPreview || Haptics.isMuted
        guard apply(direction * 10, muted: muted) else { return }
        let decay = ctx["acceleration"]
        let fastest = ctx["fastest"]
        let start = firstDelay
        repeatTask = Task { @MainActor in
            var interval = start
            var repeats = 0
            try? await Task.sleep(for: .seconds(interval))
            while !Task.isCancelled {
                repeats += 1
                let size = repeats > 20 ? 10 : (repeats > 8 ? 5 : 1)
                if size != multiplier { multiplier = size }
                guard apply(direction * 10 * size, muted: muted) else {
                    speed = 0
                    multiplier = 1
                    return
                }
                interval = max(interval * decay, fastest)
                speed = ((start - interval) / (start - fastest)).clamped(to: 0...1)
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }

    private func end() {
        repeatTask?.cancel()
        repeatTask = nil
        holding = 0
        speed = 0
        multiplier = 1
    }

    private func previewHold() {
        step += 1
        let direction = step % 2 == 1 ? 1 : -1
        begin(direction)
        introTask?.cancel()
        introTask = Task {
            try? await Task.sleep(for: .seconds(2.4))
            guard !Task.isCancelled else { return }
            end()
            introTask = nil
        }
    }
}
