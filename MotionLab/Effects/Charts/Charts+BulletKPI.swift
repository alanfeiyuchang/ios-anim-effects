import SwiftUI

extension Effect {
    static let chartsBulletKPI = Effect(
        id: "charts.bullet-kpi",
        category: .charts,
        interaction: .tap,
        name: L("Bullet Chart Targets", "子弹图目标达成"),
        summary: L("Three bullet charts race toward their targets; each marker pops green the instant its bar crosses it.", "三条子弹图冲向目标线，进度条越线的一瞬间，目标标记弹跳变绿。"),
        prompt: L(
            "A goals card with three bullet charts (Revenue, NPS, Uptime): each row has three grey qualitative bands (60 / 80 / 100%), a 10 pt measure capsule and a 3 × 26 pt target marker. On refresh the measures grow from zero on a decelerating curve (0.2, 0.8, 0.2, 1, 1.2 s), 150 ms apart. The marker is evaluated against the live, interpolated bar, not the final value: at the exact frame a bar crosses its target the marker turns green, swells to 1.5× on a bouncy spring (response 0.3 s, damping 0.45) and a light haptic ticks; bars that fall short leave it amber. Percentages count along with the bars and a summary pill rolls to “2 of 3 on track”. Motivating, honest, scannable.",
            "一张目标卡片含三条子弹图（营收、NPS、可用率）：每行有三段灰色定性区间（60 / 80 / 100%）、一条 10pt 高的实绩胶囊与一根 3 × 26pt 目标标记。刷新时实绩条以减速曲线（0.2, 0.8, 0.2, 1，1.2 秒）从零生长，行间错开 150ms。标记跟随动画中实时插值的进度，而非最终数值：越过目标的那一帧，标记立即变绿，以弹簧（响应 0.3 秒、阻尼 0.45）弹跳放大到 1.5 倍并触发轻触感；未达标的行保持琥珀色。百分比同步计数，汇总胶囊滚动为“3 项中 2 项达标”。"
        ),
        implementation: L(
            "Each row is an Animatable view whose animatableData is the measure, so its body sees every interpolated frame and derives crossed = measure ≥ target; an inner .animation(value: crossed) pops the marker and sensoryFeedback(trigger: crossed) fires the haptic mid-animation.",
            "每一行是 Animatable 视图，animatableData 为实绩值，因此 body 能看到每一帧的插值并得出 crossed = 实绩 ≥ 目标；内部的 .animation(value: crossed) 让标记弹跳，sensoryFeedback(trigger: crossed) 在动画途中触发触感。"
        ),
        apis: ["Animatable", "timingCurve", "animation(_:value:)", "sensoryFeedback", "contentTransition(.numericText)"],
        tags: ["bullet chart", "target", "goal", "kpi", "子弹图", "目标", "达成", "指标"],
        params: [
            .slider("duration", L("Grow duration", "生长时长"), 0.6...2.4, default: 1.2, unit: "s"),
            .slider("stagger", L("Row stagger", "行错峰"), 0...0.4, default: 0.15, unit: "s"),
        ]
    ) { ctx in
        BulletKPIDemo(ctx: ctx)
    }
}

private struct BulletMetric {
    let title: LocalizedText
    let target: Double
    let tint: Color
}

private let bulletMetrics: [BulletMetric] = [
    BulletMetric(title: L("Revenue", "营收"), target: 0.72, tint: Palette.indigo),
    BulletMetric(title: L("NPS", "NPS"), target: 0.64, tint: Palette.violet),
    BulletMetric(title: L("Uptime", "可用率"), target: 0.86, tint: Palette.sky),
]

private struct BulletKPIDemo: View {
    let ctx: DemoContext
    /// Seeded with a settled quarter so still snapshots show bars; `onAppear` rewinds and plays.
    @State private var measures: [Double] = [0.78, 0.57, 0.91]
    @State private var finals: [Double] = [0.78, 0.57, 0.91]
    /// The arrival entrance plays silently; crossing haptics start once the user taps.
    @State private var userRefreshed = false

    var body: some View {
        let onTrack = zip(finals, bulletMetrics).filter { $0.0 >= $0.1.target }.count
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(ctx.language == .zh ? "季度目标" : "Quarter goals")
                    .font(.headline)
                Spacer()
                summaryPill(onTrack)
            }
            ForEach(bulletMetrics.indices, id: \.self) { index in
                BulletRow(
                    metric: bulletMetrics[index],
                    measure: measures[index],
                    language: ctx.language,
                    haptics: !ctx.isPreview && userRefreshed
                )
            }
        }
        .padding(18)
        .frame(width: 300)
        .demoCard()
        .contentShape(Rectangle())
        .onTapGesture {
            userRefreshed = true
            refresh()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap to refresh", "点击刷新"), ctx: ctx)
                .padding(.bottom, 10)
        }
        .onAppear {
            ChartEntrance.replay(reset: {
                measures = [0, 0, 0]
                finals = [0, 0, 0]
            }, then: {
                refresh()
            })
        }
        // The entrance already runs in onAppear, so the detail stage's one-shot intro is turned off.
        .autoplay(ctx.isPreview, every: ctx["duration"] + 1.8, delay: ctx["duration"] + 1.6, intro: false) {
            refresh()
        }
    }

    private func summaryPill(_ onTrack: Int) -> some View {
        let all = onTrack == bulletMetrics.count
        let text = ctx.language == .zh ? "\(bulletMetrics.count) 项中 \(onTrack) 项达标" : "\(onTrack) of \(bulletMetrics.count) on track"
        return Text(text)
            .font(.caption.weight(.bold))
            .monospacedDigit()
            .contentTransition(.numericText(value: Double(onTrack)))
            .foregroundStyle(all ? Palette.green : Palette.amber)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background((all ? Palette.green : Palette.amber).opacity(0.14), in: Capsule())
    }

    private func refresh() {
        let targets = bulletMetrics.map { metric in
            // Mostly on target, sometimes short, occasionally well ahead.
            min(max(metric.target + Double.random(in: -0.22...0.2), 0.3), 0.98)
        }
        let duration = ctx["duration"]
        let stagger = ctx["stagger"]
        withAnimation(.easeIn(duration: 0.2)) { measures = [0, 0, 0] }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.25))
            let curve = Animation.timingCurve(0.2, 0.8, 0.2, 1, duration: duration)
            for index in targets.indices {
                withAnimation(curve.delay(Double(index) * stagger)) {
                    measures[index] = targets[index]
                }
            }
            withAnimation(.easeOut(duration: 0.4).delay(Double(targets.count) * stagger + duration * 0.6)) {
                finals = targets
            }
        }
    }
}

private struct BulletRow: View, Animatable {
    let metric: BulletMetric
    var measure: Double
    let language: AppLanguage
    let haptics: Bool

    var animatableData: Double {
        get { measure }
        set { measure = newValue }
    }

    private let trackWidth: CGFloat = 264

    var body: some View {
        let crossed = measure >= metric.target && measure > 0
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(metric.title, language)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text(verbatim: "\(Int((measure * 100).rounded()))%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            ZStack(alignment: .leading) {
                bands
                Capsule()
                    .fill(metric.tint.gradient)
                    .frame(width: max(trackWidth * CGFloat(measure), 10), height: 10)
                    .opacity(measure > 0.005 ? 1 : 0)
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(crossed ? Palette.green : Palette.amber)
                    .frame(width: 3, height: 26)
                    .scaleEffect(crossed ? 1.5 : 1, anchor: .center)
                    .animation(.spring(response: 0.3, dampingFraction: 0.45), value: crossed)
                    .shadow(color: (crossed ? Palette.green : Palette.amber).opacity(0.5), radius: crossed ? 6 : 0)
                    .offset(x: trackWidth * CGFloat(metric.target) - 1.5)
            }
            .frame(width: trackWidth, height: 26)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: crossed) { _, newValue in
            newValue && haptics
        }
    }

    private var bands: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Color.primary.opacity(0.06)).frame(width: trackWidth, height: 18)
            Capsule().fill(Color.primary.opacity(0.09)).frame(width: trackWidth * 0.8, height: 18)
            Capsule().fill(Color.primary.opacity(0.13)).frame(width: trackWidth * 0.6, height: 18)
        }
    }
}
