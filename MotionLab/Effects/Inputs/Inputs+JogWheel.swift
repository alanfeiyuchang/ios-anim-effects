import SwiftUI

extension Effect {
    static let inputsJogWheel = Effect(
        id: "inputs.jog-wheel",
        category: .inputs,
        interaction: .gesture,
        name: L("Inertial Jog Wheel", "惯性飞梭轮"),
        summary: L("A video-editor jog wheel you spin by hand; flick it and it coasts to a stop.", "视频剪辑用的飞梭轮：手动转动，甩一下还会自己滑行减速。"),
        prompt: L(
            "A 220 pt jog wheel from a video-editing console: a brushed disc ringed with 36 grip dimples and a finger well, above a timecode readout. Circular dragging turns the wheel 1:1 with the finger's angle around the centre; every 10° advances one frame with a selection haptic, and the readout counts in monospaced digits. The angular velocity of the last moments is tracked, so a flick keeps the wheel coasting after release: it travels velocity × 0.35 s further on a strong ease-out curve (0.15, 0.7, 0.3, 1) lasting 1.2 s, capped at three turns, while the timecode keeps counting every frame it passes. A faint motion-blur arc trails the finger well while spinning. Weighty, precise and addictive.",
            "220pt 的视频剪辑飞梭轮：拉丝圆盘外圈 36 个防滑凹点，一个指窝，下方是时间码读数。沿圆周拖动时轮子随手指角度 1:1 转动，每 10° 前进一帧并触发选择触觉，读数以等宽数字计数。系统记录松手前的角速度，甩动后轮子继续滑行：额外转过“角速度 × 0.35 秒”，采用强缓出曲线（0.15, 0.7, 0.3, 1），历时 1.2 秒，最多三圈，时间码数过经过的每一帧。高速转动时指窝后拖出一道淡淡的动态模糊弧。厚重、精准、让人上瘾。"
        ),
        implementation: L(
            "atan2 of the touch relative to the centre gives an angle whose wrapped delta accumulates into rotation; timestamps give angular velocity for the coast, animated with a timingCurve. An Animatable face view recomputes the timecode on every interpolated frame.",
            "用 atan2 计算触点相对圆心的角度，处理跨界后的增量累加为旋转量；借助时间戳得到角速度用于惯性滑行，并以 timingCurve 动画。Animatable 表盘视图会在每个插值帧重新计算时间码。"
        ),
        apis: ["DragGesture", "atan2", "Animatable", "timingCurve(_:_:_:_:duration:)", "rotationEffect"],
        tags: ["dial", "jog wheel", "inertia", "rotation", "旋钮", "飞梭", "惯性", "转盘"],
        params: [
            .slider("coast", L("Coast time", "滑行时间"), 0...0.8, default: 0.35, unit: "s"),
            .slider("duration", L("Coast duration", "滑行时长"), 0.4...2.5, default: 1.2, unit: "s"),
            .slider("detent", L("Degrees per frame", "每帧角度"), 5...30, default: 10, decimals: 0, unit: "°"),
        ]
    ) { ctx in
        JogWheelDemo(ctx: ctx)
    }
}

private struct JogWheelDemo: View {
    let ctx: DemoContext
    @State private var rotation: Double = 0
    @State private var lastAngle: Double?
    @State private var lastTime: Date = .now
    @State private var velocity: Double = 0
    @State private var spinning = false
    /// Bumped by every coast and every grab, so a stale coast never clears `spinning` under the finger.
    @State private var coastGeneration = 0
    /// The coast in flight, so a grab starts from the angle on screen rather than the landing angle.
    @State private var inFlight: JogCoast?
    @State private var step = 0

    private let size: CGFloat = 220

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            JogWheelFace(rotation: rotation, degreesPerFrame: ctx["detent"], size: size, spinning: spinning)
                .contentShape(Circle())
                .gesture(drag)
                .scaleEffect(ctx.isPreview ? 0.9 : 1)
            Spacer(minLength: 0)
            DemoHint(text: L("Spin the wheel, then flick it", "转动轮盘，再甩一下试试"), ctx: ctx)
                .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.2, delay: 0.3) { previewFling() }
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let dx = Double(value.location.x - size / 2)
                let dy = Double(value.location.y - size / 2)
                guard hypot(dx, dy) > 18 else { return }
                let angle: Double = atan2(dy, dx) * 180 / .pi
                let now = Date.now
                if let last = lastAngle {
                    var delta: Double = angle - last
                    if delta > 180 { delta -= 360 }
                    if delta < -180 { delta += 360 }
                    let dt: Double = max(now.timeIntervalSince(lastTime), 0.001)
                    let instant: Double = delta / dt
                    velocity = velocity * 0.6 + instant * 0.4
                    let before = Int((rotation / ctx["detent"]).rounded(.down))
                    stopCoast(at: rotation + delta)
                    let after = Int((rotation / ctx["detent"]).rounded(.down))
                    if before != after { Haptics.selection() }
                } else {
                    velocity = 0
                    coastGeneration += 1
                    let onScreen: Double = inFlight?.value(at: now) ?? rotation
                    inFlight = nil
                    stopCoast(at: onScreen)
                }
                lastAngle = angle
                lastTime = now
                if !spinning { spinning = true }
            }
            .onEnded { _ in
                lastAngle = nil
                let idle = Date.now.timeIntervalSince(lastTime) > 0.08
                let speed = idle ? 0 : velocity
                coast(by: speed * ctx["coast"])
            }
    }

    /// Sets the rotation without animation, which also halts an in-flight coast.
    private func stopCoast(at value: Double) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { rotation = value }
    }

    private func coast(by extra: Double) {
        let capped = extra.clamped(to: -1080...1080)
        let duration = ctx["duration"]
        inFlight = JogCoast(from: rotation, delta: capped, start: .now, duration: duration)
        withAnimation(.timingCurve(JogCoast.curve, duration: duration)) {
            rotation += capped
        }
        coastGeneration += 1
        let current = coastGeneration
        Task {
            try? await Task.sleep(for: .seconds(abs(capped) > 1 ? duration : 0.1))
            guard coastGeneration == current, lastAngle == nil else { return }
            spinning = false
        }
    }

    private func previewFling() {
        step += 1
        let direction: Double = step % 2 == 0 ? -1 : 1
        spinning = true
        coast(by: direction * 540)
    }
}

/// A coast described by its start, so the angle on screen can be computed at any moment.
private struct JogCoast {
    static let curve = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.15, y: 0.7),
        endControlPoint: UnitPoint(x: 0.3, y: 1)
    )
    let from: Double
    let delta: Double
    let start: Date
    let duration: Double

    func value(at date: Date) -> Double {
        guard duration > 0 else { return from + delta }
        let progress: Double = (date.timeIntervalSince(start) / duration).clamped(to: 0...1)
        return from + delta * Self.curve.value(at: progress)
    }
}

/// The wheel re-renders for every interpolated rotation, so the timecode counts through a coast.
private struct JogWheelFace: View, Animatable {
    var rotation: Double
    let degreesPerFrame: Double
    let size: CGFloat
    let spinning: Bool
    @Environment(\.colorScheme) private var scheme

    var animatableData: Double {
        get { rotation }
        set { rotation = newValue }
    }

    private var timecode: String {
        let frames = Int((rotation / degreesPerFrame).rounded(.down))
        let sign = frames < 0 ? "-" : ""
        let total = abs(frames)
        let seconds = total / 24
        return sign + String(format: "00:%02d:%02d:%02d", seconds / 60, seconds % 60, total % 24)
    }

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                disc
                grips
                    .rotationEffect(.degrees(rotation))
                fingerWell
                    .rotationEffect(.degrees(rotation))
            }
            .frame(width: size, height: size)
            Text(timecode)
                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                .foregroundStyle(spinning ? Palette.indigo : Color.primary)
        }
    }

    private var disc: some View {
        let light = scheme == .light
        return ZStack {
            Circle()
                .fill(
                    AngularGradient(
                        colors: light
                            ? [Color(hex: 0xE4E6EC), .white, Color(hex: 0xD4D7DF), .white, Color(hex: 0xE4E6EC)]
                            : [Color(hex: 0x2A2C33), Color(hex: 0x3B3E47), Color(hex: 0x24262C), Color(hex: 0x3B3E47), Color(hex: 0x2A2C33)],
                        center: .center
                    )
                )
                .shadow(color: .black.opacity(light ? 0.18 : 0.5), radius: 16, y: 10)
            Circle()
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            Circle()
                .fill(Palette.elevated)
                .frame(width: size * 0.34, height: size * 0.34)
                .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
        }
    }

    private var grips: some View {
        ZStack {
            ForEach(0..<36, id: \.self) { index in
                Circle()
                    .fill(Color.primary.opacity(0.14))
                    .frame(width: 5, height: 5)
                    .offset(y: -size / 2 + 12)
                    .rotationEffect(.degrees(Double(index) * 10))
            }
        }
    }

    private var fingerWell: some View {
        ZStack {
            Circle()
                .trim(from: 0.0, to: 0.08)
                .stroke(Palette.indigo.opacity(spinning ? 0.35 : 0), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90 - 30))
                .frame(width: size * 0.66, height: size * 0.66)
            Circle()
                .fill(
                    LinearGradient(colors: [Color.black.opacity(0.18), Color.white.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                )
                .frame(width: 30, height: 30)
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.1)))
                .offset(y: -size * 0.33)
        }
    }
}
