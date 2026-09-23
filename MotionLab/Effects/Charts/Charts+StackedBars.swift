import SwiftUI
import Charts

extension Effect {
    static let chartsStackedBars = Effect(
        id: "charts.stacked-bars",
        category: .charts,
        interaction: .tap,
        name: L("Stacked Bars Re-stack", "堆叠柱重新堆叠"),
        summary: L("Toggle a series in the legend and every stack springs to its new height.", "在图例中开关某个系列，每根堆叠柱都会弹性调整到新高度。"),
        prompt: L(
            "A “Revenue by channel” card with six monthly stacked bars (Apr–Sep, 58% width, 3 pt corners) built from three series — Subscriptions (indigo), In-app (pink) and Ads (amber) — over a dashed grid with a trailing $0–$25k axis. On appear, month columns rise from the baseline one after another, 60 ms apart, on a spring (response ≈ 0.55 s, damping ≈ 0.75). Below, three legend chips act as toggles: switching a series off collapses its segments to zero while the segments above slide down to close the gap, all on one spring, and its chip dims with a strikethrough; switching it back re-stacks them. The header total rolls to the visible sum with a numeric transition. Tapping the chart replays the rise. Crisp, comparative and explorable.",
            "一张“各渠道营收”卡片：六个月（4 月～9 月）的堆叠柱（柱宽 58%，圆角 3pt）由三个系列组成——订阅（靛蓝）、应用内购（粉）与广告（琥珀），背景为虚线网格，右侧为 $0～$25k 刻度。出现时，各月的柱子依次从基线升起，间隔 60ms，使用弹簧（响应约 0.55 秒、阻尼约 0.75）。下方三枚图例胶囊即是开关：关闭某个系列时，它的分段缩为零、上方的分段随之下滑补位，全部在同一个弹簧中完成，对应胶囊变暗并加删除线；重新打开则再次堆叠。标题处的总额以数字滚动转场更新为可见系列之和。点击图表会重播升起动画。清爽、便于比较，也便于探索。"
        ),
        implementation: L(
            "Swift Charts BarMarks colored with foregroundStyle(by:) stack automatically; hidden series keep their marks at 0 so identities persist and withAnimation(.spring) interpolates every segment. A per-month grow factor animated with staggered delays drives the entrance.",
            "Swift Charts 的 BarMark 配合 foregroundStyle(by:) 自动堆叠；隐藏的系列保留标记但数值为 0，标识不变，withAnimation(.spring) 因此能插值每个分段。每个月独立的生长系数配合错峰延迟驱动入场。"
        ),
        apis: ["Chart", "BarMark", "foregroundStyle(by:)", "chartForegroundStyleScale", "contentTransition(.numericText)", "spring"],
        tags: ["stacked bar", "bar chart", "legend", "toggle", "series", "堆叠柱状图", "图例", "系列", "开关"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.3...1.2, default: 0.55, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.4...1.0, default: 0.75),
            .slider("stagger", L("Stagger", "错峰间隔"), 0...0.15, default: 0.06, unit: "s"),
        ]
    ) { ctx in
        StackedBarsDemo(ctx: ctx)
    }
}

private struct StackSeries {
    let name: LocalizedText
    let color: Color
}

private let stackSeries: [StackSeries] = [
    StackSeries(name: L("Subscriptions", "订阅"), color: Palette.indigo),
    StackSeries(name: L("In-app", "应用内购"), color: Palette.pink),
    StackSeries(name: L("Ads", "广告"), color: Palette.amber),
]

/// Revenue in $k per month (rows) and series (columns).
private let stackData: [[Double]] = [
    [8.2, 4.1, 2.0],
    [9.0, 4.6, 2.4],
    [10.1, 4.2, 2.9],
    [11.4, 5.3, 2.6],
    [12.2, 6.0, 3.1],
    [13.5, 6.4, 3.4],
]

private let stackMonthsEN = ["Apr", "May", "Jun", "Jul", "Aug", "Sep"]
private let stackMonthsZH = ["4月", "5月", "6月", "7月", "8月", "9月"]

private struct StackedBarsDemo: View {
    let ctx: DemoContext
    @State private var visible: [Bool] = Array(repeating: true, count: stackSeries.count)
    @State private var grow: [Double] = Array(repeating: 0, count: stackData.count)
    @State private var autoIndex = 0

    private var spring: Animation {
        .spring(response: ctx["response"], dampingFraction: ctx["damping"])
    }

    private var total: Double {
        var sum = 0.0
        for month in stackData.indices {
            for series in stackSeries.indices where visible[series] {
                sum += stackData[month][series] * grow[month]
            }
        }
        return sum
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            chart
                .frame(height: 170)
                .contentShape(Rectangle())
                .onTapGesture { rise() }
            legend
        }
        .padding(18)
        .frame(width: 310)
        .demoCard()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap a legend chip to toggle it", "点击图例开关系列"), ctx: ctx)
                .padding(.bottom, 8)
        }
        .onAppear { rise() }
        .autoplay(ctx.isPreview, every: 2.4, delay: 1.2) { toggleAndRestore() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(ctx.language == .zh ? "各渠道营收 · 近 6 个月" : "Revenue by channel · 6 months")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(String(format: "$%.1fk", total))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(value: total))
        }
    }

    private var chart: some View {
        let months = ctx.language == .zh ? stackMonthsZH : stackMonthsEN
        let names = stackSeries.map { $0.name(ctx.language) }
        return Chart {
            ForEach(stackData.indices, id: \.self) { month in
                ForEach(stackSeries.indices, id: \.self) { series in
                    BarMark(
                        x: .value("Month", months[month]),
                        y: .value("Revenue", visible[series] ? stackData[month][series] * grow[month] : 0),
                        width: .ratio(0.58)
                    )
                    .cornerRadius(3)
                    .foregroundStyle(by: .value("Series", names[series]))
                }
            }
        }
        .chartForegroundStyleScale(domain: names, range: stackSeries.map(\.color))
        .chartLegend(.hidden)
        .chartYScale(domain: 0.0...25.0)
        .chartYAxis {
            AxisMarks(position: .trailing, values: [0.0, 5.0, 10.0, 15.0, 20.0, 25.0]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 4]))
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(verbatim: "$\(Int(amount))k")
                            .font(.system(size: 9, weight: .semibold, design: .rounded).monospacedDigit())
                    }
                }
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 6) {
            ForEach(stackSeries.indices, id: \.self) { index in
                Button {
                    toggle(index)
                } label: {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(stackSeries[index].color)
                            .frame(width: 8, height: 8)
                        Text(stackSeries[index].name, ctx.language)
                            .font(.caption.weight(.semibold))
                            .strikethrough(!visible[index])
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.primary.opacity(visible[index] ? 0.07 : 0.03), in: Capsule())
                    .opacity(visible[index] ? 1 : 0.45)
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func toggle(_ index: Int) {
        // Keep at least one series visible so the chart never empties.
        guard !visible[index] || visible.filter({ $0 }).count > 1 else {
            Haptics.error()
            return
        }
        Haptics.selection()
        withAnimation(spring) { visible[index].toggle() }
    }

    private func rise() {
        grow = Array(repeating: 0, count: stackData.count)
        for month in stackData.indices {
            withAnimation(spring.delay(Double(month) * ctx["stagger"])) { grow[month] = 1 }
        }
    }

    /// Previews and the arrival intro: hide one series, then bring it back.
    private func toggleAndRestore() {
        let index = autoIndex % stackSeries.count
        autoIndex += 1
        withAnimation(spring) { visible[index] = false }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.1))
            withAnimation(spring) { visible[index] = true }
        }
    }
}
