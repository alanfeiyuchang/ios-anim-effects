import SwiftUI

extension Effect {
    static let chartsWaffleKPI = Effect(
        id: "charts.waffle-kpi",
        category: .charts,
        interaction: .tap,
        name: L("Snaking Waffle Percent", "蛇形华夫格百分比"),
        summary: L("A 10 × 10 waffle chart that fills square by square in a snaking path while the percentage counts in step.", "10 × 10 华夫格沿蛇形路径逐格填充，百分比同步计数。"),
        prompt: L(
            "A KPI card with a 10 × 10 waffle grid (18 pt squares, 5 pt continuous corners, 4 pt gaps) and a 46 pt percentage above it. Each square is one percent. When the value rises, squares fill one at a time along a snaking path — left to right on the bottom row, right to left on the next, and so on — 12 ms apart, each popping from 0 to full size on a bouncy spring (response 0.3 s, damping 0.55) in a colour that ramps from mint through sky to indigo along the path. When it falls, squares empty in reverse from the head of the snake. The number counts linearly for exactly as long as the fill takes; a tap mid-fill restarts from the squares on screen. Tangible, countable, playful.",
            "一张 KPI 卡片，包含 10 × 10 的华夫格（每格 18pt，5pt 连续圆角，间距 4pt），上方是 46pt 的百分比数字。每一格代表 1%。数值上升时，格子沿蛇形路径逐一填充——底行从左到右、上一行从右到左，依此类推——间隔 12ms，每格以弹性弹簧（响应 0.3 秒、阻尼 0.55）从 0 弹到原尺寸，颜色沿路径从薄荷绿经天蓝渐变到靛蓝。数值下降时，格子从“蛇头”开始反向逐格清空。数字线性计数，时长与填充完全一致；中途点击从屏幕上已填的格数续起。具体、可数、充满趣味。"
        ),
        implementation: L(
            "Each square knows its serpentine order and carries .animation(spring.delay(d), value: filled), with d measured from the previous count in the direction of change; an Animatable text view counts along a TimelineView clock over the same duration, and a new tap starts from the on-screen square count.",
            "每个格子知道自己在蛇形路径上的序号，并带有 .animation(spring.delay(d), value: filled)，d 从上一次的数量沿变化方向计算；Animatable 文本视图按 TimelineView 时钟在相同时长内计数；新的点击从屏幕上的格数开始。"
        ),
        apis: ["animation(_:value:)", "Animation.delay", "Animatable", "scaleEffect", "Color.mix(with:by:)"],
        tags: ["waffle chart", "percentage", "kpi", "unit chart", "华夫格", "百分比", "指标", "进度"],
        params: [
            .slider("step", L("Square interval", "逐格间隔"), 0.004...0.03, default: 0.012, decimals: 3, unit: "s"),
            .slider("damping", L("Pop damping", "弹出阻尼"), 0.3...1.0, default: 0.55),
        ]
    ) { ctx in
        WaffleKPIDemo(ctx: ctx)
    }
}

private struct WaffleKPIDemo: View {
    let ctx: DemoContext
    /// Seeded with a settled value so still snapshots show filled cells; `onAppear` fills from zero.
    @State private var percent = 68
    @State private var previous = 0
    /// The running fill (square counts, start, interval, duration), so a tap mid-cascade restarts from what is on
    /// screen rather than from the previous target.
    @State private var cascade = WaffleCascade(from: 68, to: 68, fromValue: 68, start: .distantPast, step: 0.012, duration: 0)
    @State private var counting = false
    @State private var generation = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .lastTextBaseline) {
                // The number follows the cascade's own clock (linear, same duration as the fill) instead of an
                // implicit animation, so an interrupted count restarts from the number on screen.
                TimelineView(.animation(minimumInterval: nil, paused: !counting)) { timeline in
                    WaffleNumber(value: counting ? cascade.value(at: timeline.date) : Double(percent))
                }
                Text(ctx.language == .zh ? "的新用户完成了引导" : "of new users finished onboarding")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            VStack(spacing: 4) {
                ForEach((0..<10).reversed(), id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<10, id: \.self) { column in
                            let order = row * 10 + (row % 2 == 0 ? column : 9 - column)
                            WaffleCell(
                                order: order,
                                filled: order < percent,
                                delay: delay(for: order),
                                damping: ctx["damping"]
                            )
                        }
                    }
                }
            }
        }
        .padding(18)
        .frame(width: 280)
        .demoCard()
        .contentShape(Rectangle())
        .onTapGesture { update(haptic: true) }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap for a new value", "点击更新数值"), ctx: ctx)
                .padding(.bottom, 2)
        }
        .onAppear {
            ChartEntrance.replay(isStill: ctx.isStill, reset: {
                percent = 0
                counting = false
                generation += 1
            }, then: {
                update(haptic: false)
            })
        }
        // The entrance already runs in onAppear, so the detail stage's one-shot intro is turned off.
        .autoplay(ctx.isPreview, every: 2.8, delay: 2.6, intro: false) { update(haptic: false) }
    }

    private func delay(for order: Int) -> Double {
        let step = ctx["step"]
        if percent >= previous {
            return Double(max(order - previous, 0)) * step
        }
        return Double(max(previous - 1 - order, 0)) * step
    }

    private func update(haptic: Bool) {
        let step = ctx["step"]
        let now = Date()
        // Start from what is on screen: mid-cascade that is the squares already switched, not the previous target.
        let shown = counting ? cascade.filled(at: now) : percent
        let shownValue = counting ? cascade.value(at: now) : Double(percent)
        var next = Int.random(in: 18...96)
        if abs(next - shown) < 12 { next = shown > 55 ? next - 30 : next + 30 }
        next = next.clamped(to: 5...99)
        let duration = Double(abs(next - shown)) * step + 0.2
        previous = shown
        cascade = WaffleCascade(from: shown, to: next, fromValue: shownValue, start: now, step: step, duration: duration)
        counting = true
        percent = next
        generation += 1
        let token = generation
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration))
            if token == generation { counting = false }
        }
        if haptic && !ctx.isPreview { Haptics.tap(.light) }
    }
}

/// One fill cascade: squares switch one per `step` from `from` toward `to`, and the number counts linearly
/// from the value it showed (`fromValue`) to `to` over `duration`.
private struct WaffleCascade {
    let from: Int
    let to: Int
    let fromValue: Double
    let start: Date
    let step: Double
    let duration: Double

    func value(at date: Date) -> Double {
        let progress = duration > 0 ? (date.timeIntervalSince(start) / duration).clamped(to: 0...1) : 1
        return fromValue + (Double(to) - fromValue) * progress
    }

    /// Squares switched so far (a square counts once its pop has started).
    func filled(at date: Date) -> Int {
        let elapsed = date.timeIntervalSince(start)
        let span = abs(to - from)
        guard elapsed >= 0, span > 0 else { return elapsed >= 0 ? to : from }
        let started = min(Int(elapsed / max(step, 0.001)) + 1, span)
        return from + (to >= from ? started : -started)
    }
}

private struct WaffleCell: View {
    let order: Int
    let filled: Bool
    let delay: Double
    let damping: Double

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color.primary.opacity(0.07))
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(color)
                .scaleEffect(filled ? 1 : 0.01)
                .opacity(filled ? 1 : 0)
                .animation(.spring(response: 0.3, dampingFraction: damping).delay(delay), value: filled)
        }
        .frame(width: 18, height: 18)
    }

    private var color: Color {
        let t = Double(order) / 99
        if t < 0.5 {
            return Palette.mint.mix(with: Palette.sky, by: t * 2)
        }
        return Palette.sky.mix(with: Palette.indigo, by: (t - 0.5) * 2)
    }
}

private struct WaffleNumber: View, Animatable {
    var value: Double

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text(verbatim: "\(Int(value.rounded()))")
                .font(.system(size: 46, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text(verbatim: "%")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .fixedSize()
    }
}
