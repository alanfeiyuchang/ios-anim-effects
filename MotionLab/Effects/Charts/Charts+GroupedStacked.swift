import SwiftUI

extension Effect {
    static let chartsGroupedStacked = Effect(
        id: "charts.grouped-stacked",
        category: .charts,
        interaction: .tap,
        name: L("Grouped ⇄ Stacked Bars", "分组 ⇄ 堆叠柱状图"),
        summary: L("A staged, two-beat transition: segments climb onto each other first, then slide together into one column.", "分两拍的过渡：各段先向上叠起，再横向并拢成一根柱子。"),
        prompt: L(
            "Five quarters of three product lines (indigo, pink, amber) shown first as grouped bars — three 12 pt columns side by side per quarter. On tap the chart turns into stacked bars in two separate beats, the classic staged transition: beat one lifts each segment vertically onto the ones before it, keeping its x and width (spring response 0.45 s, damping 0.8, 40 ms stagger per quarter); 420 ms later beat two slides the lifted segments sideways and widens them from 12 pt to 34 pt so they merge into one column. Going back reverses the order — first spread apart, then drop down — so no segment ever moves diagonally or overlaps another. The mode pill slides between Grouped and Stacked. Rigorous, legible, data-journalism grade.",
            "五个季度、三条产品线（靛蓝、粉、琥珀）的数据，起初是分组柱状图：每季度三根 12pt 宽的柱子并排。点击后图表分两拍变为堆叠柱状图：第一拍，各段保持横向位置与宽度，只竖直叠到前面各段之上（弹簧响应 0.45 秒、阻尼 0.8，每季度错开 40ms）；420ms 后第二拍，抬起的各段横向滑动并从 12pt 加宽到 34pt，合并成一根柱子。切回时顺序相反——先横向分开，再落回基线——任何一段都不会斜向移动或重叠。模式胶囊在“分组”与“堆叠”间滑动。严谨清晰，达到数据新闻水准。"
        ),
        implementation: L(
            "Two Bools split the layout: lifted drives each segment's y offset and merged drives its x offset and width. Each segment has one .animation(value:) per Bool with a quarter-based delay, and toggling sets the Bools 420 ms apart in the right order.",
            "用两个 Bool 拆分布局：lifted 控制每段的纵向偏移，merged 控制横向偏移与宽度。每段为每个 Bool 各挂一个带季度延迟的 .animation(value:)，切换时按正确顺序相隔 420ms 设置两个 Bool。"
        ),
        apis: ["animation(_:value:)", "Animation.delay", "offset(x:y:)", "matchedGeometryEffect", "Task.sleep"],
        tags: ["stacked bar", "grouped bar", "staged transition", "morph", "堆叠柱状图", "分组柱状图", "分阶段过渡", "形变"],
        params: [
            .slider("gap", L("Beat gap", "两拍间隔"), 0.2...0.8, default: 0.42, unit: "s"),
            .slider("stagger", L("Quarter stagger", "季度错峰"), 0...0.1, default: 0.04, unit: "s"),
        ]
    ) { ctx in
        GroupedStackedDemo(ctx: ctx)
    }
}

private let groupedData: [[CGFloat]] = [
    [0.22, 0.14, 0.10],
    [0.28, 0.18, 0.12],
    [0.20, 0.26, 0.16],
    [0.34, 0.22, 0.14],
    [0.30, 0.30, 0.22],
]
private let groupedColors: [Color] = [Palette.indigo, Palette.pink, Palette.amber]

private struct GroupedStackedDemo: View {
    let ctx: DemoContext
    @State private var lifted = false
    @State private var merged = false
    @State private var stacked = false
    @State private var busy = false
    @Namespace private var pill

    private let plot = CGSize(width: 264, height: 180)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            modePill
            ZStack(alignment: .bottomLeading) {
                Rectangle()
                    .fill(Color.primary.opacity(0.18))
                    .frame(height: 1)
                ForEach(0..<groupedData.count, id: \.self) { quarter in
                    ForEach(0..<3, id: \.self) { series in
                        segment(quarter: quarter, series: series)
                    }
                }
            }
            .frame(width: plot.width, height: plot.height, alignment: .bottomLeading)
            quarterRow
        }
        .padding(18)
        .demoCard()
        .contentShape(Rectangle())
        .onTapGesture { toggle(haptic: true) }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            ChartTapCue(text: L("Tap to restack", "点击切换堆叠"), ctx: ctx)
                .padding(.bottom, 6)
        }
        .autoplay(ctx.isPreview, every: 2.8, delay: 1.0) { toggle(haptic: false) }
    }

    private var modePill: some View {
        HStack(spacing: 0) {
            pillLabel(L("Grouped", "分组"), active: !stacked)
            pillLabel(L("Stacked", "堆叠"), active: stacked)
        }
        .padding(3)
        .background(Color.primary.opacity(0.06), in: Capsule())
    }

    private func pillLabel(_ text: LocalizedText, active: Bool) -> some View {
        Text(text, ctx.language)
            .font(.caption.weight(.semibold))
            .foregroundStyle(active ? AnyShapeStyle(Color.white) : AnyShapeStyle(Color.secondary))
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background {
                if active {
                    Capsule()
                        .fill(Palette.primary)
                        .matchedGeometryEffect(id: "mode", in: pill)
                }
            }
    }

    private func segment(quarter: Int, series: Int) -> some View {
        let values = groupedData[quarter]
        let height: CGFloat = values[series] * plot.height
        var below: CGFloat = 0
        for index in 0..<series { below += values[index] * plot.height }
        let slot: CGFloat = plot.width / CGFloat(groupedData.count)
        let center: CGFloat = slot * (CGFloat(quarter) + 0.5)
        let groupedX: CGFloat = center + CGFloat(series - 1) * 14
        let width: CGFloat = merged ? 34 : 12
        let x: CGFloat = (merged ? center : groupedX) - width / 2
        let y: CGFloat = lifted ? -below : 0
        let delay = Double(quarter) * ctx["stagger"]
        let spring = Animation.spring(response: 0.45, dampingFraction: 0.8).delay(delay)
        return UnevenRoundedRectangle(
            topLeadingRadius: series == 2 || !lifted ? 4 : 0,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: series == 2 || !lifted ? 4 : 0,
            style: .continuous
        )
        .fill(groupedColors[series].gradient)
        .frame(width: width, height: height)
        .offset(x: x, y: y)
        .animation(spring, value: lifted)
        .animation(spring, value: merged)
    }

    private var quarterRow: some View {
        HStack(spacing: 0) {
            ForEach(0..<groupedData.count, id: \.self) { quarter in
                Text(verbatim: "Q\(quarter + 1)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(width: plot.width)
    }

    private func toggle(haptic: Bool) {
        guard !busy else { return }
        busy = true
        if haptic && !ctx.isPreview { Haptics.tap(.light) }
        let gap = ctx["gap"]
        let goingStacked = !stacked
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { stacked = goingStacked }
        Task { @MainActor in
            if goingStacked {
                lifted = true
                try? await Task.sleep(for: .seconds(gap))
                merged = true
            } else {
                merged = false
                try? await Task.sleep(for: .seconds(gap))
                lifted = false
            }
            try? await Task.sleep(for: .seconds(0.5))
            busy = false
        }
    }
}
