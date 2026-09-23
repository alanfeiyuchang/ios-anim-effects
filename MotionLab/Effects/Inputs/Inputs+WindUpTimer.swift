import SwiftUI

extension Effect {
    static let inputsWindUpTimer = Effect(
        id: "inputs.wind-up-timer",
        category: .inputs,
        interaction: .gesture,
        name: L("Wind-Up Timer", "发条计时器"),
        summary: L("Twist the dial to wind it; let go and it unwinds in real time, then rings.", "拧动表盘上发条，松手后实时回转，归零时响铃摇晃。"),
        prompt: L(
            "A kitchen-timer dial (210 pt) whose numbered face rotates under a fixed red index at 12 o'clock, with a coral wedge showing the remaining time like a Time Timer. Twisting clockwise winds it: the face follows the finger's angle, ratcheting to 5-second notches with a selection haptic on each click, up to one full turn (60 s). On release it unwinds at a constant, linear rate back to zero — here sped up 4× — while the wedge shrinks and the centre readout counts down every second. At zero the whole timer rings: it shakes ±8° with a decaying keyframed wobble for 600 ms, the index glows and a success haptic fires. Grabbing it mid-run freezes it where it is. Mechanical, playful and immediately understandable.",
            "一只 210pt 的厨房计时器表盘：带数字的表面在 12 点钟方向固定的红色指针下转动，珊瑚色扇形像 Time Timer 一样显示剩余时间。顺时针拧动即上发条：表面跟随手指角度转动，并以 5 秒一格的棘轮吸附，每一格一次选择触觉，最多一整圈（60 秒）。松手后以恒定的线性速度回转到零（演示中加速 4 倍），扇形随之缩小，中心读数逐秒倒数。归零时整个计时器“响铃”：以关键帧衰减摆动左右摇晃 ±8°，持续 600 毫秒，指针发光并触发成功触觉。运行中抓住它会让它停在当前位置。机械、俏皮、一看就懂。"
        ),
        implementation: L(
            "Wrapped atan2 deltas accumulate into a clamped angle; release starts a linear animation back to zero whose duration is angle ÷ rate, and an Animatable face redraws the wedge and seconds per frame. Grabbing computes the elapsed position and sets it inside a transaction with animations disabled.",
            "处理跨界后的 atan2 增量累加为受限角度；松手时启动一个线性动画回到零，时长为 角度 ÷ 速率，Animatable 表盘每帧重绘扇形与秒数。运行中抓取时根据已过时间计算当前位置，并在禁用动画的事务中写回。"
        ),
        apis: ["DragGesture", "atan2", "Animatable", "linear(duration:)", "keyframeAnimator", "Transaction"],
        tags: ["dial", "timer", "wind up", "countdown", "旋钮", "计时器", "发条", "倒计时"],
        params: [
            .slider("speed", L("Playback speed", "播放倍速"), 1...10, default: 4, step: 1, decimals: 0, unit: "×"),
            .slider("notch", L("Ratchet notch", "棘轮刻度"), 1...10, default: 5, step: 1, decimals: 0, unit: "s"),
            .slider("shake", L("Ring shake", "响铃摇晃"), 0...16, default: 8, decimals: 0, unit: "°"),
        ]
    ) { ctx in
        WindUpTimerDemo(ctx: ctx)
    }
}

private struct WindUpTimerDemo: View {
    let ctx: DemoContext
    /// 0…360°, 6° per second.
    @State private var angle: Double = 0
    @State private var lastTouch: Double?
    @State private var runStart: Date?
    @State private var runFrom: Double = 0
    @State private var runID = 0
    @State private var rings = 0
    @State private var lastNotch = 0

    private let size: CGFloat = 210
    private var rate: Double { 6 * max(ctx["speed"], 1) }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            TimerFace(angle: angle, size: size)
                .keyframeAnimator(initialValue: 0.0, trigger: rings) { content, wobble in
                    content.rotationEffect(.degrees(wobble))
                } keyframes: { _ in
                    KeyframeTrack(\.self) {
                        CubicKeyframe(ctx["shake"], duration: 0.06)
                        CubicKeyframe(-ctx["shake"] * 0.8, duration: 0.1)
                        CubicKeyframe(ctx["shake"] * 0.55, duration: 0.1)
                        CubicKeyframe(-ctx["shake"] * 0.35, duration: 0.1)
                        CubicKeyframe(ctx["shake"] * 0.15, duration: 0.1)
                        SpringKeyframe(0, duration: 0.14, spring: .smooth)
                    }
                }
                .contentShape(Circle())
                .gesture(drag)
                .scaleEffect(ctx.isPreview ? 0.92 : 1)
            Spacer(minLength: 0)
            DemoHint(text: L("Twist clockwise to wind, then let go", "顺时针拧动上发条，然后松手"), ctx: ctx)
                .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 5.0, delay: 0.3) { previewWind() }
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if runStart != nil { freeze() }
                let dx = Double(value.location.x - size / 2)
                let dy = Double(value.location.y - size / 2)
                guard hypot(dx, dy) > 16 else { return }
                let touch: Double = atan2(dy, dx) * 180 / .pi
                if let last = lastTouch {
                    var delta: Double = touch - last
                    if delta > 180 { delta -= 360 }
                    if delta < -180 { delta += 360 }
                    let notchDegrees: Double = 6 * max(ctx["notch"], 1)
                    let free: Double = (angle + delta).clamped(to: 0...360)
                    setImmediately(free)
                    let notch = Int((free / notchDegrees).rounded(.down))
                    if notch != lastNotch {
                        lastNotch = notch
                        Haptics.selection()
                    }
                }
                lastTouch = touch
            }
            .onEnded { _ in
                lastTouch = nil
                let notchDegrees: Double = 6 * max(ctx["notch"], 1)
                let snapped: Double = (angle / notchDegrees).rounded() * notchDegrees
                setImmediately(snapped.clamped(to: 0...360))
                run()
            }
    }

    private func setImmediately(_ value: Double) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { angle = value }
    }

    /// Stops a running countdown at its current position.
    private func freeze() {
        guard let start = runStart else { return }
        let elapsed = Date.now.timeIntervalSince(start)
        let remaining = max(runFrom - elapsed * rate, 0)
        runStart = nil
        runID += 1
        setImmediately(remaining)
    }

    private func run(silent: Bool = false) {
        guard angle > 0.5 else { return }
        let muted = ctx.isPreview || silent
        runID += 1
        let id = runID
        let duration = angle / rate
        runFrom = angle
        runStart = .now
        withAnimation(.linear(duration: duration)) { angle = 0 }
        Task {
            try? await Task.sleep(for: .seconds(duration))
            guard id == runID else { return }
            runStart = nil
            lastNotch = 0
            rings += 1
            if !muted { Haptics.success() }
        }
    }

    private func previewWind() {
        guard runStart == nil else { return }
        withAnimation(.smooth(duration: 0.6)) { angle = 90 }
        // Captured now: autoplay mutes haptics only for the synchronous part of the action.
        let muted = Haptics.isMuted
        Task {
            try? await Task.sleep(for: .seconds(0.75))
            run(silent: muted)
        }
    }
}

/// Face, wedge and readout re-render for every interpolated angle.
private struct TimerFace: View, Animatable {
    var angle: Double
    let size: CGFloat

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    private var seconds: Int { Int((angle / 6).rounded(.up)) }

    var body: some View {
        ZStack {
            Circle()
                .fill(Palette.elevated)
                .shadow(color: .black.opacity(0.16), radius: 16, y: 10)
            TimerWedge(degrees: angle)
                .fill(Palette.coral.opacity(0.85))
                .padding(22)
            numbers
                .rotationEffect(.degrees(angle))
            Circle()
                .fill(Palette.elevated)
                .frame(width: 70, height: 70)
                .shadow(color: .black.opacity(0.12), radius: 5, y: 2)
            Text(String(format: "0:%02d", seconds))
                .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.primary)
            index
        }
        .frame(width: size, height: size)
    }

    private var numbers: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                VStack(spacing: 3) {
                    Text("\(index * 5)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Capsule()
                        .fill(Color.primary.opacity(0.35))
                        .frame(width: 2, height: 6)
                    Spacer(minLength: 0)
                }
                .padding(.top, 6)
                .rotationEffect(.degrees(Double(index) * -30))
            }
        }
    }

    private var index: some View {
        VStack {
            TimerIndexTriangle()
                .fill(Palette.red)
                .frame(width: 14, height: 12)
                .shadow(color: Palette.red.opacity(angle < 0.5 ? 0.8 : 0), radius: 6)
                .offset(y: -8)
            Spacer(minLength: 0)
        }
    }
}

/// Remaining-time wedge measured clockwise from 12 o'clock back toward the index.
private struct TimerWedge: Shape {
    var degrees: Double

    var animatableData: Double {
        get { degrees }
        set { degrees = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard degrees > 0.1 else { return path }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        path.move(to: center)
        path.addArc(
            center: center,
            radius: min(rect.width, rect.height) / 2,
            startAngle: .degrees(-90),
            endAngle: .degrees(-90 + degrees),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

private struct TimerIndexTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
