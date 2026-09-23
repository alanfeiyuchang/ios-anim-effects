import SwiftUI

extension Effect {
    static let chartsBarRace = Effect(
        id: "charts.bar-race",
        category: .charts,
        interaction: .tap,
        name: L("Re-sorting Bar Race", "重排序条形竞赛"),
        summary: L("Horizontal bars that resize and overtake each other, gliding into their new ranks.", "水平条形同时伸缩并相互超越，平滑滑入新名次。"),
        prompt: L(
            "A ranked horizontal bar chart of six rows (26 pt tall, 8 pt gaps): rank number, label, a 150 pt capsule track with a gradient bar in each item’s color, and a counting value. Every refresh assigns new values and re-sorts descending in a single spring (response ≈ 0.6 s, damping ≈ 0.8): bars stretch or shrink to their new widths while the rows physically slide past each other to their new positions, so overtakes are visible rather than instant swaps. Rank digits roll with a numeric content transition, values count through intermediate numbers in sync with the bar widths, and the leader’s rank badge fills with its color. Motion is simultaneous but never chaotic because every property shares one spring. It tells the story of change, not just the result.",
            "一张六行的排名水平条形图（行高 26pt、行距 8pt）：名次数字、标签、150pt 的胶囊轨道配各自颜色的渐变条，以及实时计数的数值。每次刷新都会赋予新数值，并在同一个弹簧（响应约 0.6 秒、阻尼约 0.8）中按降序重排：条形伸缩到新宽度的同时，各行真实地相互滑过、移动到新位置，超越过程清晰可见，而非瞬间换位。名次数字以数字内容转场滚动，数值与条形宽度同步经过每个中间值，第一名的名次徽章填充为其主题色。所有属性共享同一弹簧，因此动作同时发生却毫不杂乱。它讲述的是“变化的过程”，而不仅仅是结果。"
        ),
        implementation: L(
            "Rows are a ForEach keyed by stable ids inside a VStack; values and array order change together in one withAnimation(.spring), so SwiftUI animates both the layout move and the bar widths. An Animatable label counts the value.",
            "行由 VStack 中以稳定 id 标识的 ForEach 构成；数值与数组顺序在同一个 withAnimation(.spring) 中改变，SwiftUI 同时为布局位移与条形宽度做动画，Animatable 标签负责计数。"
        ),
        apis: ["ForEach(id:)", "withAnimation(.spring)", "Animatable", "contentTransition(.numericText)", "Capsule"],
        tags: ["bar chart race", "ranking", "leaderboard", "reorder", "排行", "条形图", "排序", "竞赛"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.3...1.2, default: 0.6, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.8),
            .toggle("sort", L("Re-sort", "重新排序"), default: true),
        ]
    ) { ctx in
        BarRaceDemo(ctx: ctx)
    }
}

private struct RaceItem: Identifiable {
    let id: Int
    let name: LocalizedText
    let color: Color
    var value: Double
}

private let raceSeed: [RaceItem] = [
    RaceItem(id: 0, name: L("Aurora", "极光"), color: Palette.indigo, value: 82),
    RaceItem(id: 1, name: L("Nimbus", "雨云"), color: Palette.pink, value: 64),
    RaceItem(id: 2, name: L("Solace", "晴空"), color: Palette.amber, value: 58),
    RaceItem(id: 3, name: L("Tidal", "潮汐"), color: Palette.mint, value: 47),
    RaceItem(id: 4, name: L("Ember", "余烬"), color: Palette.coral, value: 36),
    RaceItem(id: 5, name: L("Vertex", "顶点"), color: Palette.sky, value: 25),
]

private struct BarRaceDemo: View {
    let ctx: DemoContext
    @State private var items = raceSeed

    var body: some View {
        let maxValue = max(items.map(\.value).max() ?? 1, 1)
        VStack(spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.element.id) { rank, item in
                RaceRow(item: item, rank: rank, maxValue: maxValue, language: ctx.language)
            }
        }
        .padding(16)
        .demoCard()
        .contentShape(Rectangle())
        .onTapGesture { shuffle() }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap to update", "点击更新数据"), ctx: ctx)
                .padding(.bottom, 8)
        }
        .autoplay(ctx.isPreview, every: 1.8, delay: 1.0) { shuffle() }
    }

    private func shuffle() {
        var next = items
        for index in next.indices {
            let drift = Double.random(in: -26...30)
            next[index].value = min(max(next[index].value + drift, 12), 100)
        }
        if ctx.bool("sort") {
            next.sort { $0.value > $1.value }
        }
        if !ctx.isPreview { Haptics.selection() }
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            items = next
        }
    }
}

private struct RaceRow: View {
    let item: RaceItem
    let rank: Int
    let maxValue: Double
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 10) {
            Text(verbatim: "\(rank + 1)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(rank)))
                .foregroundStyle(rank == 0 ? Color.white : Color.secondary)
                .frame(width: 22, height: 22)
                .background(
                    Circle().fill(rank == 0 ? AnyShapeStyle(item.color.gradient) : AnyShapeStyle(Color.primary.opacity(0.06)))
                )
            Text(item.name, language)
                .font(.footnote.weight(.semibold))
                .lineLimit(1)
                .frame(width: 52, alignment: .leading)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.06))
                Capsule()
                    .fill(LinearGradient(colors: [item.color.opacity(0.7), item.color], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(150 * item.value / maxValue, 14))
            }
            .frame(width: 150, height: 14)
            RaceValue(value: item.value)
        }
        .frame(height: 26)
    }
}

private struct RaceValue: View, Animatable {
    var value: Double

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text(verbatim: "\(Int(value.rounded()))")
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .monospacedDigit()
            .frame(width: 28, alignment: .trailing)
    }
}
