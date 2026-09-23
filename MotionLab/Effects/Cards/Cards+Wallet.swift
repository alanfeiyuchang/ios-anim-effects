import SwiftUI

extension Effect {
    static let cardsWalletStack = Effect(
        id: "cards.wallet-stack",
        category: .cards,
        interaction: .tap,
        name: L("Wallet Stack", "钱包卡片堆"),
        summary: L("Apple Wallet-style cards: tap one to lift it out while the rest tuck away.", "类 Apple 钱包卡片堆：点选一张抽出，其余卡片收拢到底部。"),
        prompt: L(
            "Four payment cards are stacked vertically like Apple Wallet, each overlapping the previous one and exposing a 46 pt header strip. Tapping a card slides it up to the top slot while the remaining cards drop away and compress into a tight pile at the bottom edge — 12 pt apart, scaled 90–96%, partly running off-screen. Every card moves on its own spring (response ≈0.5 s, damping ≈0.8) with a 35 ms stagger by position, so the stack ripples rather than moving as one block. Tapping the selected card reverses the choreography and fans the stack back open. Soft shadows and a light haptic make it feel tangible and orderly.",
            "四张支付卡片像 Apple 钱包一样纵向层叠，每张压住上一张，只露出 46 pt 的顶部条。点击某张卡片，它会滑到顶部位置，其余卡片下沉并在底部边缘收拢成紧密的一叠——间距 12 pt、缩放 90%–96%，部分延伸出屏幕。每张卡片各自使用弹簧（响应约 0.5 秒、阻尼约 0.8），并按位置错开 35 毫秒，使整叠卡片呈涟漪般依次运动而非整体平移。再次点击已选中的卡片则反向回放，重新展开卡片堆。柔和投影与轻触感让它显得真实而有序。"
        ),
        implementation: L(
            "Cards live in a top-aligned ZStack; each computes its y offset and scale from the selected index, with a per-card .animation(_:value:) whose delay creates the stagger.",
            "卡片放在顶部对齐的 ZStack 中，各自根据选中索引计算 y 偏移与缩放；每张卡片使用带延迟的 .animation(_:value:) 形成错峰。"
        ),
        apis: ["ZStack", "offset", "animation(_:value:)", "spring(response:dampingFraction:)", "delay"],
        tags: ["wallet", "stack", "apple pay", "cards", "钱包", "卡片堆", "层叠", "展开"],
        params: [
            .slider("peek", L("Header peek", "露出高度"), 28...70, default: 46, step: 1, decimals: 0, unit: "pt"),
            .slider("response", L("Spring response", "弹簧响应"), 0.25...1.0, default: 0.5, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.8),
        ]
    ) { ctx in
        CardsWalletDemo(ctx: ctx)
    }
}

private struct CardsWalletDemo: View {
    let ctx: DemoContext
    @State private var selected: Int?
    @State private var autoStep = 0

    private let themes = [0, 2, 3, 5]
    private let numbers = ["4821", "0937", "5510", "7264"]

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                ForEach(themes.indices, id: \.self) { index in
                    card(index)
                }
            }
            .frame(width: 250, height: 300, alignment: .top)
            DemoHint(text: L("Tap a card", "点击一张卡片"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.6) { autoAdvance() }
    }

    private func card(_ index: Int) -> some View {
        CardsCreditCard(theme: themes[index], last4: numbers[index])
            .shadow(color: .black.opacity(0.18), radius: 10, y: 6)
            .brightness(isTucked(index) ? -0.04 : 0)
            .scaleEffect(scale(index), anchor: .top)
            .offset(y: offsetY(index))
            .zIndex(Double(index))
            .onTapGesture { select(index) }
            .animation(
                .spring(response: ctx["response"], dampingFraction: ctx["damping"]).delay(Double(index) * 0.035),
                value: selected
            )
    }

    private func isTucked(_ index: Int) -> Bool {
        guard let selected else { return false }
        return selected != index
    }

    /// Position of `index` inside the tucked pile (0 = top of the pile).
    private func pileSlot(_ index: Int) -> Int {
        let others = themes.indices.filter { $0 != selected }
        return others.firstIndex(of: index) ?? 0
    }

    private func offsetY(_ index: Int) -> CGFloat {
        guard let selected else { return CGFloat(index) * ctx.cg("peek") }
        if index == selected { return 0 }
        return 182 + CGFloat(pileSlot(index)) * 12
    }

    private func scale(_ index: Int) -> CGFloat {
        guard isTucked(index) else { return 1 }
        return 0.9 + CGFloat(pileSlot(index)) * 0.03
    }

    private func select(_ index: Int) {
        Haptics.tap(.soft)
        selected = selected == index ? nil : index
    }

    private func autoAdvance() {
        let sequence: [Int?] = [2, nil, 0, nil, 3, nil]
        selected = sequence[autoStep % sequence.count]
        autoStep += 1
    }
}
