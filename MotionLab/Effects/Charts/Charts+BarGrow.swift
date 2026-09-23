import SwiftUI
import Charts

extension Effect {
    static let chartsBarGrow = Effect(
        id: "charts.bar-grow",
        category: .charts,
        interaction: .tap,
        name: L("Staggered Bar Growth", "柱状图错峰生长"),
        summary: L("Bars rise from the baseline one after another on bouncy springs.", "柱子从基线依次弹起，错落有致。"),
        prompt: L(
            "A seven-day bar chart (Swift Charts, 62% bar width, 6 pt continuous top corners, sky-to-indigo vertical gradient, dashed hairline grid at 0/25/50/75/100) sits in a card under a header showing the weekly total. On appear — and on every tap — the bars first collapse into the baseline in 180 ms, then grow back left to right, each starting 70 ms after the previous one on a spring (response ≈ 0.6 s, damping ≈ 0.62) that overshoots slightly and settles. Value labels ride on top of each bar and roll up from 0 with it on the same staggered spring, while the total rolls to its new number with a numeric content transition. The rhythm reads as a wave traveling across the chart: lively, confident and data-first.",
            "一张七天柱状图（Swift Charts，柱宽 62%，顶部 6pt 连续圆角，天蓝到靛蓝的竖向渐变，0/25/50/75/100 处为虚线细网格）置于卡片中，上方标题显示本周总量。出现时以及每次点击时，柱子先在 180ms 内收回基线，再从左到右依次生长：每根比前一根晚 70ms 启动，使用弹簧（响应约 0.6 秒、阻尼约 0.62），轻微过冲后稳定。数值标签跟随柱顶移动，并以同一错峰弹簧从 0 滚动增长到目标值；总量也通过数字内容转场滚动到新值。整体节奏像一道波浪掠过图表：活泼、自信、以数据为核心。"
        ),
        implementation: L(
            "Each datum carries a shown flag; BarMark reads value or 0, and a loop issues one withAnimation(.spring.delay(i × stagger)) per bar so Swift Charts interpolates them independently.",
            "每个数据项带有 shown 标记，BarMark 读取数值或 0；循环中为每根柱子单独调用 withAnimation(.spring.delay(i × 间隔))，Swift Charts 会分别插值。"
        ),
        apis: ["Chart", "BarMark", "chartYScale", "withAnimation", "contentTransition(.numericText)"],
        tags: ["bar chart", "stagger", "grow", "swift charts", "柱状图", "错峰", "生长", "图表"],
        params: [
            .slider("stagger", L("Stagger", "错峰间隔"), 0.02...0.2, default: 0.07, unit: "s"),
            .slider("response", L("Spring response", "弹簧响应"), 0.3...1.2, default: 0.6, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.4...1.0, default: 0.62),
        ]
    ) { ctx in
        BarGrowDemo(ctx: ctx)
    }
}

private struct BarDatum: Identifiable {
    let id: Int
    var value: Double
    var shown: Bool
}

private let weekdaysEN = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
private let weekdaysZH = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
private let barSeed: [Double] = [46, 72, 58, 94, 67, 38, 81]

private struct BarGrowDemo: View {
    let ctx: DemoContext
    /// Seeded with a settled week so still snapshots show data; `onAppear` rewinds and plays.
    @State private var bars: [BarDatum] = barSeed.enumerated().map { BarDatum(id: $0.offset, value: $0.element, shown: true) }
    @State private var total: Double = barSeed.reduce(0, +)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            chart
                .frame(height: 190)
        }
        .padding(18)
        .frame(width: 300)
        .demoCard()
        .contentShape(Rectangle())
        .onTapGesture { play() }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap to replay", "点击重播"), ctx: ctx)
                .padding(.bottom, 8)
        }
        .onAppear {
            ChartEntrance.replay(reset: {
                for index in bars.indices { bars[index].shown = false }
            }, then: {
                play()
            })
        }
        // The entrance already runs in onAppear, so the detail stage's one-shot intro is turned off.
        .autoplay(ctx.isPreview, every: 3.2, delay: 3.2, intro: false) { play() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(ctx.language == .zh ? "本周活跃" : "Weekly activity")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(verbatim: "\(Int(total))")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(value: total))
        }
    }

    private var chart: some View {
        let labels = ctx.language == .zh ? weekdaysZH : weekdaysEN
        return Chart(bars) { bar in
            BarMark(
                x: .value("Day", labels[bar.id]),
                y: .value("Value", bar.shown ? bar.value : 0),
                width: .ratio(0.62)
            )
            .cornerRadius(6)
            .foregroundStyle(LinearGradient(colors: [Palette.sky, Palette.indigo], startPoint: .top, endPoint: .bottom))
            .annotation(position: .top, spacing: 4) {
                // Rolls up from 0 with its bar (same staggered spring transaction), and back down on replay.
                let shownValue = bar.shown ? bar.value : 0
                Text(verbatim: "\(Int(shownValue))")
                    .font(.system(size: 10, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText(value: shownValue))
                    .opacity(bar.shown ? 1 : 0)
            }
        }
        .chartYScale(domain: 0...110)
        .chartYAxis {
            AxisMarks(values: [0, 25, 50, 75, 100]) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 4]))
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
            }
        }
    }

    private func play() {
        withAnimation(.easeIn(duration: 0.18)) {
            for index in bars.indices { bars[index].shown = false }
        }
        let stagger = ctx["stagger"]
        let spring = Animation.spring(response: ctx["response"], dampingFraction: ctx["damping"])
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.22))
            let values = (0..<7).map { _ in Double(Int.random(in: 28...100)) }
            for index in bars.indices { bars[index].value = values[index] }
            withAnimation(.snappy) { total = values.reduce(0, +) }
            for index in bars.indices {
                withAnimation(spring.delay(Double(index) * stagger)) {
                    bars[index].shown = true
                }
            }
        }
    }
}
