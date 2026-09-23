import SwiftUI

extension Effect {
    static let cardsNotificationStack = Effect(
        id: "cards.notification-stack",
        category: .cards,
        interaction: .tap,
        name: L("Notification Stack", "通知堆叠"),
        summary: L("Lock-screen style grouped notifications that unfold into a list.", "锁屏式分组通知，点击后逐条展开成列表。"),
        prompt: L(
            "Under a large lock-screen clock, four 300×60 pt notification cards with 18 pt corners sit collapsed: only the front one shows content, while two plates peek out beneath it, each 12 pt lower and 5% smaller and faintly tinted with their app colour. Tapping unfolds the group into a list with 6 pt gaps: cards spring into place top to bottom with a 40 ms stagger (response 0.5 s, damping 0.78), growing back to full size, shedding the tint and fading their content in, while the clock condenses to half size and the date fades out. The header pill cross-fades from “4 new” to “Show less”, and a second tap gathers the cards back in reverse order. Tidy, calm and unmistakably iOS.",
            "锁屏大号时钟下方，四条300×60 pt、18 pt圆角的通知收成一叠：只有最前面一条显示内容，下面露出两层底板，每层下移12 pt、缩小5%，并透出一点所属App的颜色。轻点后整组展开成间距6 pt的列表：卡片自上而下错开40毫秒，以弹簧（响应0.5秒、阻尼0.78）依次落位，恢复原大、褪去底色、内容淡入；时钟同时缩到一半，日期淡出让位。标题胶囊由「4条新通知」淡变为「收起」，再点一次，卡片按相反顺序收回。整洁从容，地道的iOS味道。"
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

    private let rowHeight: CGFloat = 60
    private let gap: CGFloat = 6
    private let plateStep: CGFloat = 12

    private var spring: Animation {
        .spring(response: ctx["response"], dampingFraction: ctx["damping"])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            clock
            header
            ZStack(alignment: .top) {
                ForEach(cardsNotificationItems.indices, id: \.self) { i in
                    row(i)
                }
            }
            // The group's footprint follows its state so the collapsed stack sits centred on the
            // stage instead of hugging the top of an empty, list-sized frame.
            .frame(width: 300, height: expanded ? 4 * rowHeight + 3 * gap : rowHeight + 2 * plateStep, alignment: .top)
            .animation(spring, value: expanded)
            DemoHint(text: L("Tap the stack", "点击通知组"), ctx: ctx)
                .frame(width: 300)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.0) { toggle() }
    }

    /// Lock-screen clock: large at rest, condensing to a small time when the list needs the room.
    private var clock: some View {
        VStack(spacing: 0) {
            Text(verbatim: "9:41")
                .font(.system(size: 60, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .scaleEffect(expanded ? 0.5 : 1, anchor: .top)
                .frame(height: expanded ? 34 : 64, alignment: .top)
            Text(L("Tuesday, June 9", "6月9日 星期二"), ctx.language)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .opacity(expanded ? 0 : 1)
                .frame(height: expanded ? 0 : 20)
                .clipped()
        }
        .frame(width: 300)
        .animation(spring, value: expanded)
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
        let item = cardsNotificationItems[i]
        let order = expanded ? i : cardsNotificationItems.count - 1 - i
        let delayed = spring.delay(Double(order) * ctx["stagger"])
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        return CardsNotificationRow(item: item, language: ctx.language, height: rowHeight)
            .opacity(expanded || i == 0 ? 1 : 0.001)
            .background(Palette.elevated, in: shape)
            // Collapsed plates pick up a hint of their app's colour so the depth reads as layers.
            .overlay(shape.fill(item.colors[0].opacity(expanded || i == 0 ? 0 : 0.14)).allowsHitTesting(false))
            .overlay(shape.strokeBorder(Palette.stroke))
            .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
            .scaleEffect(expanded ? 1 : 1 - depth * 0.05, anchor: .top)
            .offset(y: expanded ? depth * (rowHeight + gap) : depth * plateStep)
            .opacity(expanded || i < 3 ? 1 : 0)
            .zIndex(Double(cardsNotificationItems.count - i))
            .onTapGesture(perform: toggle)
            .animation(delayed, value: expanded)
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
