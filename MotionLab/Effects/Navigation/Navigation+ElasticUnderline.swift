import SwiftUI

extension Effect {
    static let navigationElasticUnderline = Effect(
        id: "navigation.elastic-underline",
        category: .navigation,
        interaction: .tap,
        name: L("Elastic Tab Underline", "弹性标签下划线"),
        summary: L(
            "A tab underline whose leading and trailing edges travel on separate springs, stretching like elastic.",
            "下划线的前后两端由各自的弹簧驱动，移动时像橡皮筋一样拉伸。"
        ),
        prompt: L(
            "A row of text tabs (For You, Following, Trending, Live) with a 3 pt rounded underline hugging the selected label's exact width. When a new tab is chosen, the underline's two ends move independently: the edge facing the direction of travel leaps first on a quick spring (response ≈0.28 s), while the trailing edge follows ≈120 ms later on a softer spring, so the line first stretches across both tabs and then contracts onto the new label like a rubber band. Labels cross-fade from secondary grey to primary, a faint glow blooms under the line, and the content card below swaps with a blur-replace. Playful, organic and precise.",
            "一排文字标签（推荐、关注、热门、直播），下方是一条 3pt 的圆角下划线，精确贴合当前选中文字的宽度。切换标签时，下划线的两端独立运动：朝移动方向的一端先以快速弹簧（响应约 0.28 秒）跃出，另一端延迟约 120 毫秒以更柔和的弹簧跟上——线条先横跨两个标签被拉长，再像橡皮筋一样收缩到新标签下方。文字颜色在次级灰与主色间过渡，下划线下方泛起淡淡的光晕，下方内容卡片以模糊替换切换。俏皮、有机，又不失精准。"
        ),
        implementation: L(
            "Each label's frame is measured with onGeometryChange in a named coordinate space; the underline is a capsule inset by two separately animated paddings (leading and trailing), each driven by its own withAnimation spring and delay.",
            "每个标签的外框通过 onGeometryChange 在命名坐标空间中测量；下划线是一个由两段独立动画的内边距（左、右）约束的胶囊，两端各由自己的 withAnimation 弹簧与延迟驱动。"
        ),
        apis: ["onGeometryChange", "coordinateSpace(.named)", "padding(_:_:)", "withAnimation", "transition(.blurReplace)"],
        tags: ["tabs", "underline", "indicator", "elastic", "标签页", "下划线", "指示器", "弹性"],
        params: [
            .slider("lag", L("Trailing-edge lag", "尾端延迟"), 0.0...0.3, default: 0.12, decimals: 2, unit: "s"),
            .slider("response", L("Spring response", "弹簧响应"), 0.15...0.8, default: 0.28, unit: "s"),
            .slider("thickness", L("Thickness", "线条粗细"), 2...6, default: 3, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        ElasticUnderlineDemo(ctx: ctx)
    }
}

private let elasticTabs: [LocalizedText] = [L("For You", "推荐"), L("Following", "关注"), L("Trending", "热门"), L("Live", "直播")]
private let elasticSymbols: [String] = ["sparkles", "person.2.fill", "flame.fill", "dot.radiowaves.left.and.right"]

private struct ElasticUnderlineDemo: View {
    let ctx: DemoContext
    @State private var selected = 0
    @State private var frames: [Int: CGRect] = [:]
    @State private var leftEdge: CGFloat = 0
    @State private var rightEdge: CGFloat = 0
    @State private var rowWidth: CGFloat = 0

    var body: some View {
        VStack(spacing: 26) {
            tabRow
            ZStack {
                contentCard
                    .id(selected)
                    .transition(.blurReplace)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.3) {
            select(selected == elasticTabs.count - 1 ? 0 : selected + 1)
        }
    }

    private var tabRow: some View {
        HStack(spacing: 22) {
            ForEach(0..<elasticTabs.count, id: \.self) { index in
                Text(elasticTabs[index], ctx.language)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(index == selected ? Color.primary : Color.secondary)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                    .onTapGesture { select(index) }
                    .onGeometryChange(for: CGRect.self) { proxy in
                        proxy.frame(in: .named("elasticTabs"))
                    } action: { frame in
                        frames[index] = frame
                        if index == selected && rightEdge == 0 {
                            leftEdge = frame.minX
                            rightEdge = frame.maxX
                        }
                    }
            }
        }
        .coordinateSpace(.named("elasticTabs"))
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            rowWidth = width
        }
        .overlay(alignment: .bottomLeading) { underline }
    }

    private var underline: some View {
        let thickness = ctx.cg("thickness")
        return Capsule()
            .fill(Palette.primary)
            .frame(height: thickness)
            .shadow(color: Palette.indigo.opacity(0.5), radius: 6, y: 2)
            .padding(.leading, leftEdge)
            .padding(.trailing, max(rowWidth - rightEdge, 0))
            .opacity(rightEdge > 0 ? 1 : 0)
    }

    private var contentCard: some View {
        VStack(spacing: 10) {
            Image(systemName: elasticSymbols[selected])
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Palette.primary)
            PlaceholderLines(count: 3)
                .frame(width: 200)
        }
        .padding(22)
        .frame(width: 280)
        .demoCard(cornerRadius: 24)
    }

    private func select(_ index: Int) {
        guard index != selected, let target = frames[index] else { return }
        if !ctx.isPreview { Haptics.selection() }
        let movingRight = index > selected
        let lead = Animation.spring(response: ctx["response"], dampingFraction: 0.78)
        let follow = Animation.spring(response: ctx["response"] * 1.25, dampingFraction: 0.86).delay(ctx["lag"])
        withAnimation(.snappy) { selected = index }
        withAnimation(movingRight ? lead : follow) { rightEdge = target.maxX }
        withAnimation(movingRight ? follow : lead) { leftEdge = target.minX }
    }
}
