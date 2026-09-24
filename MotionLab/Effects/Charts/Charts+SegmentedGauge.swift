import SwiftUI

extension Effect {
    static let chartsSegmentedGauge = Effect(
        id: "charts.segmented-gauge",
        category: .charts,
        interaction: .tap,
        name: L("Segmented LED Gauge", "分段 LED 仪表"),
        summary: L("Thirty LED ticks along a 240° arc switch on one by one — and off in reverse — with a heat ramp.", "240° 弧线上的三十格 LED 依次点亮、反向熄灭，颜色随负载由冷变热。"),
        prompt: L(
            "A 230 pt gauge made of 30 capsule ticks (18 × 6 pt) spaced along a 240° arc open at the bottom, with the reading in the centre. Unlit ticks are 8% grey at 80% size. When the value rises, ticks switch on strictly one at a time, 25 ms apart, each popping to full size with a coloured glow on a quick ease-out (150 ms); the colour ramps from mint through amber (60%) to red at the top end. When the value falls, ticks switch off in reverse from the tip, at the same cadence. The centre number counts linearly for exactly as long as the ticks take (a tap mid-cascade restarts from the ticks and number on screen) and the status word (Normal / Busy / Critical) cross-fades to its colour. Hardware-like, rhythmic and readable.",
            "一个 230pt 的仪表，由 30 个胶囊刻度（18 × 6pt）沿底部开口的 240° 弧线排列，读数位于中心。未点亮的刻度为 8% 灰色、尺寸 80%。数值上升时，刻度严格逐格点亮，间隔 25ms，每格以 150ms 的快速缓出放大到原尺寸并带同色光晕；颜色从薄荷绿经琥珀色（60% 处）渐变到末端的红色。数值下降时，刻度从末端反向逐格熄灭，节奏相同。中心数字线性计数，时长与刻度动画一致（中途点击从屏幕当前状态续起），状态文字（正常 / 繁忙 / 过载）交叉淡入对应颜色。硬件质感、节奏分明、清晰易读。"
        ),
        implementation: L(
            "Each tick carries .animation(.easeOut.delay(d), value: isLit), where d is computed from its distance to the previous lit count in the direction of change; an Animatable text view counts along a TimelineView clock whose linear duration matches the cascade, and a new tap starts from the on-screen tick count and number.",
            "每个刻度带有 .animation(.easeOut.delay(d), value: isLit)，d 由该刻度沿变化方向到上一次点亮数的距离计算；Animatable 文本视图按 TimelineView 时钟线性计数，时长与级联一致；新的点击从屏幕上的刻度数与读数开始。"
        ),
        apis: ["animation(_:value:)", "Animation.delay", "Animatable", "rotationEffect", "Color.mix(with:by:)"],
        tags: ["gauge", "led", "segments", "meter", "仪表", "分段", "指示灯", "负载"],
        params: [
            .slider("count", L("Segments", "分段数"), 16...40, default: 30, step: 1, decimals: 0),
            .slider("step", L("Tick interval", "逐格间隔"), 0.01...0.06, default: 0.025, decimals: 3, unit: "s"),
        ]
    ) { ctx in
        SegmentedGaugeDemo(ctx: ctx)
    }
}

private let gaugeStart: Double = 150
private let gaugeSweep: Double = 240

private struct SegmentedGaugeDemo: View {
    let ctx: DemoContext
    /// Seeded with a settled reading so still snapshots show lit ticks; `onAppear` sweeps up from zero.
    @State private var value: Double = 64
    @State private var previousLit = 0
    /// The running cascade (lit counts and readout values, start, tick interval, duration), so a tap mid-cascade
    /// restarts from what is on screen rather than from the previous target.
    @State private var cascade = GaugeCascade(fromLit: 0, toLit: 0, fromValue: 64, toValue: 64, start: .distantPast, step: 0.025, duration: 0)
    @State private var counting = false
    @State private var generation = 0

    var body: some View {
        let count = max(ctx.int("count"), 4)
        let lit = litCount(value, count: count)
        let step = ctx["step"]
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                GaugeTick(
                    index: index,
                    count: count,
                    isLit: index < lit,
                    delay: delay(for: index, lit: lit, step: step)
                )
            }
            readout
        }
        .frame(width: 240, height: 240)
        .contentShape(Circle())
        .onTapGesture { setRandom(haptic: true) }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap for a new reading", "点击获取新读数"), ctx: ctx)
                .padding(.bottom, 8)
        }
        .onAppear {
            ChartEntrance.replay(reset: {
                value = 0
                counting = false
                generation += 1
            }, then: {
                setRandom(haptic: false)
            })
        }
        // The entrance already runs in onAppear, so the detail stage's one-shot intro is turned off.
        .autoplay(ctx.isPreview, every: 2.4, delay: 2.2, intro: false) { setRandom(haptic: false) }
    }

    private var readout: some View {
        VStack(spacing: 4) {
            Text(ctx.language == .zh ? "CPU 负载" : "CPU load")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            // The readout follows the cascade's own clock (linear, same duration as the ticks) instead of an
            // implicit animation, so an interrupted count restarts from the number on screen.
            TimelineView(.animation(minimumInterval: nil, paused: !counting)) { timeline in
                GaugeReadout(value: counting ? cascade.value(at: timeline.date) : value, language: ctx.language)
            }
        }
        .offset(y: 8)
    }

    private func litCount(_ v: Double, count: Int) -> Int {
        Int((v / 100 * Double(count)).rounded())
    }

    private func delay(for index: Int, lit: Int, step: Double) -> Double {
        if lit >= previousLit {
            return Double(max(index - previousLit, 0)) * step
        }
        return Double(max(previousLit - 1 - index, 0)) * step
    }

    private func setRandom(haptic: Bool) {
        let count = max(ctx.int("count"), 4)
        let step = ctx["step"]
        let now = Date()
        // Start from what is on screen: mid-cascade that is the ticks already switched and the number shown now.
        let shownValue = counting ? cascade.value(at: now) : value
        let shownLit = (counting ? cascade.lit(at: now) : litCount(value, count: count)).clamped(to: 0...count)
        var next = Double(Int.random(in: 8...98))
        if abs(next - shownValue) < 15 { next = shownValue > 50 ? next - 40 : next + 40 }
        next = next.clamped(to: 4...99)
        let newLit = litCount(next, count: count)
        let duration = Double(abs(newLit - shownLit)) * step + 0.15
        previousLit = shownLit
        cascade = GaugeCascade(fromLit: shownLit, toLit: newLit, fromValue: shownValue, toValue: next, start: now, step: step, duration: duration)
        counting = true
        value = next
        generation += 1
        let token = generation
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration))
            if token == generation { counting = false }
        }
        if haptic && !ctx.isPreview { Haptics.tap(.light) }
    }
}

/// One tick cascade: ticks switch one per `step` from `fromLit` toward `toLit` while the readout counts linearly
/// from `fromValue` to `toValue` over `duration`.
private struct GaugeCascade {
    let fromLit: Int
    let toLit: Int
    let fromValue: Double
    let toValue: Double
    let start: Date
    let step: Double
    let duration: Double

    func value(at date: Date) -> Double {
        let progress = duration > 0 ? (date.timeIntervalSince(start) / duration).clamped(to: 0...1) : 1
        return fromValue + (toValue - fromValue) * progress
    }

    /// Ticks switched so far (a tick counts once its 150 ms pop has started).
    func lit(at date: Date) -> Int {
        let elapsed = date.timeIntervalSince(start)
        let span = abs(toLit - fromLit)
        guard elapsed >= 0, span > 0 else { return elapsed >= 0 ? toLit : fromLit }
        let started = min(Int(elapsed / max(step, 0.001)) + 1, span)
        return fromLit + (toLit >= fromLit ? started : -started)
    }
}

private struct GaugeTick: View {
    let index: Int
    let count: Int
    let isLit: Bool
    let delay: Double

    var body: some View {
        let t = Double(index) / Double(max(count - 1, 1))
        let angle = gaugeStart + gaugeSweep * t
        let color = rampColor(t)
        ZStack {
            Capsule()
                .fill(Color.primary.opacity(0.08))
            Capsule()
                .fill(color)
                .shadow(color: color.opacity(0.6), radius: 5)
                .opacity(isLit ? 1 : 0)
        }
        .frame(width: 18, height: 6)
        .scaleEffect(isLit ? 1 : 0.8)
        .animation(.easeOut(duration: 0.15).delay(delay), value: isLit)
        .offset(x: 104)
        .rotationEffect(.degrees(angle))
    }

    private func rampColor(_ t: Double) -> Color {
        if t < 0.6 {
            return Palette.mint.mix(with: Palette.amber, by: t / 0.6)
        }
        return Palette.amber.mix(with: Palette.red, by: (t - 0.6) / 0.4)
    }
}

/// Number and status word are both derived from the interpolated value, so the status flips
/// exactly when the count (and the lit ticks) cross the 55% / 82% thresholds, not at tap time.
private struct GaugeReadout: View, Animatable {
    var value: Double
    let language: AppLanguage

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        let status = Self.status(value)
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(verbatim: "\(Int(value.rounded()))")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text(verbatim: "%")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Text(status.label, language)
                .font(.caption.weight(.bold))
                .foregroundStyle(status.color)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: status.label.en)
        }
    }

    private static func status(_ v: Double) -> (label: LocalizedText, color: Color) {
        if v < 55 { return (L("Normal", "正常"), Palette.green) }
        if v < 82 { return (L("Busy", "繁忙"), Palette.amber) }
        return (L("Critical", "过载"), Palette.red)
    }
}
