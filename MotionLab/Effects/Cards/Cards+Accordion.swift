import SwiftUI

extension Effect {
    static let cardsAccordion = Effect(
        id: "cards.accordion",
        category: .cards,
        interaction: .tap,
        name: L("Accordion Cards", "手风琴卡片"),
        summary: L("Stacked summary cards that expand in place to reveal a detail panel.", "纵向排列的摘要卡片，点击原地展开详情面板。"),
        prompt: L(
            "A column of three rounded summary cards (20 pt corners, 62 pt tall) shows an icon tile, title, amount and a chevron. Tapping one grows its height smoothly on a spring (response ≈0.5 s, damping ≈0.82) while its siblings slide to make room; the chevron rotates 180°, and the detail panel — a divider, a seven-bar mini chart and two lines of copy — fades in while drifting down 10 pt from beneath the header, with its content clipped to the growing card. The expanded card deepens its shadow to feel lifted, and the other cards recede to 97% scale and 60% opacity. Tapping another card hands the expansion over in a single fluid motion.",
            "一列三张圆角摘要卡片（20 pt 圆角，高 62 pt），展示图标方块、标题、金额与折叠箭头。点击其中一张，其高度以弹簧（响应约 0.5 秒、阻尼约 0.82）平滑增长，相邻卡片随之让位；箭头旋转 180°，详情面板——分隔线、七柱迷你图表与两行文字——从标题下方淡入并下移 10 pt 落定，内容被裁剪在逐渐变高的卡片内。展开的卡片投影加深、显得被抬起，其余卡片退后至 97% 缩放与 60% 透明度。点击另一张卡片时，展开状态在一次流畅运动中交接过去。"
        ),
        implementation: L(
            "A VStack of cards whose detail section is conditionally inserted with an asymmetric opacity + offset transition inside withAnimation(.spring), so SwiftUI animates the height change and the reflow of siblings.",
            "卡片放在 VStack 中，详情区域在 withAnimation(.spring) 内以不对称的透明度 + 位移转场条件插入，SwiftUI 自动为高度变化和兄弟卡片的重排做动画。"
        ),
        apis: ["withAnimation", "transition(.asymmetric)", "clipShape", "rotationEffect"],
        tags: ["accordion", "expand", "collapse", "disclosure", "手风琴", "展开", "折叠", "卡片"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.25...1.0, default: 0.5, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.82),
            .toggle("dim", L("Recede others", "其余卡片后退"), default: true),
        ]
    ) { ctx in
        CardsAccordionDemo(ctx: ctx)
    }
}

private struct CardsAccordionItem {
    let title: LocalizedText
    let subtitle: LocalizedText
    let symbol: String
    let colors: [Color]
    let amount: String
    let bars: [CGFloat]
    /// Two short detail rows: the largest charge and the budget status.
    let notes: [LocalizedText]
}

private let cardsAccordionItems: [CardsAccordionItem] = [
    CardsAccordionItem(title: L("Travel", "旅行"), subtitle: L("12 transactions", "12 笔交易"), symbol: "airplane", colors: [Palette.sky, Palette.blue], amount: "$1,284", bars: [22, 36, 28, 44, 30, 18, 40], notes: [L("Largest: flight to Tokyo · $486", "最大一笔：飞往东京 · $486"), L("64% of monthly budget", "已用月度预算 64%")]),
    CardsAccordionItem(title: L("Dining", "餐饮"), subtitle: L("28 transactions", "28 笔交易"), symbol: "fork.knife", colors: [Palette.amber, Palette.coral], amount: "$642", bars: [30, 24, 40, 20, 44, 34, 26], notes: [L("Largest: Friday dinner · $92", "最大一笔：周五晚餐 · $92"), L("On track · $158 left", "进度正常 · 剩余 $158")]),
    CardsAccordionItem(title: L("Shopping", "购物"), subtitle: L("9 transactions", "9 笔交易"), symbol: "bag.fill", colors: [Palette.violet, Palette.pink], amount: "$918", bars: [18, 28, 22, 34, 26, 44, 38], notes: [L("Largest: running shoes · $139", "最大一笔：跑鞋 · $139"), L("12% over budget", "超出预算 12%")]),
]

private let cardsAccordionReveal: AnyTransition = .asymmetric(
    insertion: .opacity.combined(with: .offset(y: -10)),
    removal: .opacity
)

private struct CardsAccordionDemo: View {
    let ctx: DemoContext
    @State private var expanded: Int?
    @State private var autoStep = 0

    var body: some View {
        VStack(spacing: 10) {
            ForEach(cardsAccordionItems.indices, id: \.self) { i in
                CardsAccordionCard(item: cardsAccordionItems[i], expanded: expanded == i, language: ctx.language)
                    .scaleEffect(recedes(i) ? 0.97 : 1)
                    .opacity(recedes(i) ? 0.6 : 1)
                    .onTapGesture { toggle(i) }
            }
        }
        .frame(width: 300)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.6) { autoAdvance() }
    }

    private func recedes(_ i: Int) -> Bool {
        guard ctx.bool("dim"), let expanded else { return false }
        return expanded != i
    }

    private func toggle(_ i: Int) {
        Haptics.tap(.soft)
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            expanded = expanded == i ? nil : i
        }
    }

    private func autoAdvance() {
        let sequence: [Int?] = [0, 1, 2, nil]
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            expanded = sequence[autoStep % sequence.count]
        }
        autoStep += 1
    }
}

private struct CardsAccordionCard: View {
    let item: CardsAccordionItem
    let expanded: Bool
    let language: AppLanguage

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 20, style: .continuous) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if expanded {
                details
                    .transition(cardsAccordionReveal)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.elevated, in: shape)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(expanded ? 0.14 : 0.06), radius: expanded ? 18 : 8, y: expanded ? 10 : 4)
        .contentShape(shape)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: item.symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(
                    LinearGradient(colors: item.colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title, language)
                    .font(.subheadline.weight(.semibold))
                Text(item.subtitle, language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Text(verbatim: item.amount)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
            Image(systemName: "chevron.down")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .rotationEffect(.degrees(expanded ? 180 : 0))
        }
        .padding(12)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(item.bars.indices, id: \.self) { i in
                    Capsule()
                        .fill(LinearGradient(colors: item.colors, startPoint: .top, endPoint: .bottom))
                        .opacity(i == 4 ? 1 : 0.35)
                        .frame(width: 18, height: item.bars[i])
                }
            }
            .frame(height: 44, alignment: .bottom)
            VStack(alignment: .leading, spacing: 5) {
                ForEach(item.notes.indices, id: \.self) { i in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(item.colors[0])
                            .frame(width: 5, height: 5)
                        Text(item.notes[i], language)
                            .font(.caption)
                            .foregroundStyle(i == 0 ? Color.primary : Color.secondary)
                    }
                }
            }
        }
        .padding([.horizontal, .bottom], 14)
    }
}
