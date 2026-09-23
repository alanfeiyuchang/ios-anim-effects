import SwiftUI

extension Effect {
    static let cardsNotificationStack = Effect(
        id: "cards.notification-stack",
        category: .cards,
        interaction: .tap,
        name: L("Notification Stack", "通知堆叠"),
        summary: L("Lock-screen style grouped notifications that unfold into a list.", "锁屏式分组通知，点击后逐条展开成列表。"),
        prompt: L(
            "A group of four notification cards (300×64 pt, 18 pt corners) is collapsed into a stack: only the front card shows content, while two plates peek beneath it, each 10 pt lower and 5% narrower, their content hidden. Tapping the group unfolds it into a vertical list with 8 pt gaps — each card springs to its slot (response ≈0.5 s, damping ≈0.78) with a 40 ms stagger top to bottom, scaling back to 100% and fading its content in as it separates. The header pill cross-fades from “4 new” to “Show less”. Tapping again gathers the cards back behind the first one in reverse order. Tidy, calm and unmistakably iOS.",
            "四条通知卡片（300×64 pt，18 pt 圆角）收拢成一叠：只有最前面的卡片显示内容，其下方露出两层底板，每层下移 10 pt、收窄 5%，内容隐藏。点击该组后展开成竖向列表，间距 8 pt——每张卡片以弹簧（响应约 0.5 秒、阻尼约 0.78）从上到下错开 40 毫秒依次落位，缩放恢复到 100%，分离时内容淡入。标题胶囊从「4 条新通知」淡入淡出切换为「收起」。再次点击，卡片按相反顺序收回到第一张之后。整洁、从容，是地道的 iOS 手感。"
        ),
        implementation: L(
            "Cards share a top-aligned ZStack; collapsed vs expanded offsets, scales and content opacity are computed per index, each with a delayed .animation(_:value:) for the stagger.",
            "卡片共享一个顶部对齐的 ZStack；按索引分别计算收起与展开时的位移、缩放和内容透明度，并各自使用带延迟的 .animation(_:value:) 形成错峰。"
        ),
        apis: ["ZStack", "scaleEffect(_:anchor:)", "animation(_:value:)", "zIndex"],
        tags: ["notification", "stack", "group", "expand", "通知", "堆叠", "分组", "展开"],
        params: [
            .slider("stagger", L("Stagger", "错峰间隔"), 0...0.1, default: 0.04, unit: "s"),
            .slider("response", L("Spring response", "弹簧响应"), 0.3...0.9, default: 0.5, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.78),
        ]
    ) { ctx in
        CardsNotificationDemo(ctx: ctx)
    }
}

private struct CardsNotificationItem {
    let app: LocalizedText
    let message: LocalizedText
    let time: LocalizedText
    let symbol: String
    let colors: [Color]
}

private let cardsNotificationItems: [CardsNotificationItem] = [
    CardsNotificationItem(app: L("Messages", "信息"), message: L("Mia: Dinner at 8? I booked the terrace.", "Mia：八点吃饭？我订了露台位。"), time: L("now", "现在"), symbol: "message.fill", colors: [Palette.green, Palette.mint]),
    CardsNotificationItem(app: L("Calendar", "日历"), message: L("Design review starts in 15 minutes", "设计评审将在 15 分钟后开始"), time: L("2m", "2 分钟前"), symbol: "calendar", colors: [Palette.red, Palette.coral]),
    CardsNotificationItem(app: L("Fitness", "健身"), message: L("You closed all three rings today", "今天你合上了全部三个圆环"), time: L("18m", "18 分钟前"), symbol: "figure.run", colors: [Palette.pink, Palette.violet]),
    CardsNotificationItem(app: L("Weather", "天气"), message: L("Clear skies all afternoon, 24°", "整个下午晴朗，24°"), time: L("1h", "1 小时前"), symbol: "cloud.sun.fill", colors: [Palette.sky, Palette.blue]),
]

private struct CardsNotificationDemo: View {
    let ctx: DemoContext
    @State private var expanded = false

    private let rowHeight: CGFloat = 64
    private let gap: CGFloat = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            ZStack(alignment: .top) {
                ForEach(cardsNotificationItems.indices, id: \.self) { i in
                    row(i)
                }
            }
            .frame(width: 300, height: 4 * rowHeight + 3 * gap, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.0) { toggle() }
    }

    private var header: some View {
        HStack {
            Text(L("Notifications", "通知中心"), ctx.language)
                .font(.headline)
            Spacer(minLength: 0)
            Text(expanded ? L("Show less", "收起") : L("4 new", "4 条新通知"), ctx.language)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Palette.elevated, in: Capsule())
                .contentTransition(.opacity)
                .animation(.snappy, value: expanded)
                .onTapGesture(perform: toggle)
        }
        .frame(width: 300)
    }

    private func row(_ i: Int) -> some View {
        let depth = CGFloat(i)
        let order = expanded ? i : cardsNotificationItems.count - 1 - i
        let spring = Animation.spring(response: ctx["response"], dampingFraction: ctx["damping"])
            .delay(Double(order) * ctx["stagger"])
        return CardsNotificationRow(item: cardsNotificationItems[i], language: ctx.language, height: rowHeight)
            .opacity(expanded || i == 0 ? 1 : 0.001)
            .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
            .scaleEffect(expanded ? 1 : 1 - depth * 0.05, anchor: .top)
            .offset(y: expanded ? depth * (rowHeight + gap) : depth * 10)
            .opacity(expanded || i < 3 ? 1 : 0)
            .zIndex(Double(cardsNotificationItems.count - i))
            .onTapGesture(perform: toggle)
            .animation(spring, value: expanded)
    }

    private func toggle() {
        if !ctx.isPreview { Haptics.tap(.soft) }
        expanded.toggle()
    }
}

private struct CardsNotificationRow: View {
    let item: CardsNotificationItem
    let language: AppLanguage
    let height: CGFloat

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(
                    LinearGradient(colors: item.colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(item.app, language)
                        .font(.subheadline.weight(.semibold))
                    Spacer(minLength: 0)
                    Text(item.time, language)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(item.message, language)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .frame(width: 300, height: height)
    }
}
