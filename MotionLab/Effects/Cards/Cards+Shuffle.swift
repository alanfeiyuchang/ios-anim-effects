import SwiftUI

extension Effect {
    static let cardsShuffle = Effect(
        id: "cards.shuffle",
        category: .cards,
        interaction: .tap,
        name: L("Card Shuffle", "卡片洗牌"),
        summary: L("The front card slides out, tilts, and tucks behind the stack.", "最前方的卡片滑出、倾斜，再塞回卡堆最后。"),
        prompt: L(
            "A stack of four payment cards is layered with each card behind stepping 16 pt higher and 6% smaller, so their top edges peek out like a deck. On tap the front card is pulled ~110 pt to the right of the deck — it travels 65% of that while the deck counter-shifts 35% to the left, so the pulled card stays inside the frame — rising 24 pt and rotating 8° on a quick spring (≈320 ms). At the apex (~300 ms, when the spring has nearly arrived) its z-order drops behind the others and it glides back into the rearmost slot on a softer spring (response ≈0.55 s, damping ≈0.75), while the remaining cards each advance one slot forward and grow to fill the front. The overlap of the two springs makes the motion read as one continuous, dealer-like flick, finished with a soft haptic.",
            "四张支付卡片层叠排列，后方每张依次上移 16 pt、缩小 6%，顶边错落露出，像一副牌。点击时最前方的卡片被抽到卡堆右侧约 110 pt 处——卡片自身移动其中 65%，卡堆同时向左反向让出 35%，保证抽出的卡片始终留在画面内——并以快速弹簧（约 320 毫秒）上抬 24 pt、旋转 8°。在动作顶点（约 300 毫秒，弹簧几乎到位时）其层级降到其余卡片之后，再以更柔和的弹簧（响应约 0.55 秒、阻尼约 0.75）滑回最后一位，其余卡片则各前进一格并放大补位。两段弹簧相互衔接，让整个动作像荷官洗牌般一气呵成，并伴随轻柔触感。"
        ),
        implementation: L(
            "Two chained springs: the first sets a `pulled` card (offset + rotation), the second, fired via asyncAfter, moves it to the end of the order array — its zIndex drops instantly while offsets and scales animate.",
            "两段衔接的弹簧：第一段标记被抽出的卡片（位移 + 旋转），第二段通过 asyncAfter 将其移到顺序数组末尾——zIndex 瞬间下降，位移与缩放则继续动画。"
        ),
        apis: ["zIndex", "offset", "rotationEffect", "spring(response:dampingFraction:)", "DispatchQueue.asyncAfter"],
        tags: ["shuffle", "deck", "stack", "reorder", "洗牌", "卡堆", "切换", "层叠"],
        params: [
            .slider("distance", L("Slide distance", "滑出距离"), 60...180, default: 110, step: 5, decimals: 0, unit: "pt"),
            .slider("response", L("Spring response", "弹簧响应"), 0.3...1.0, default: 0.55, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.75),
        ]
    ) { ctx in
        CardsShuffleDemo(ctx: ctx)
    }
}

private struct CardsShuffleDemo: View {
    let ctx: DemoContext
    @State private var order: [Int] = [0, 1, 2, 3]
    @State private var pulled: Int?

    private let themes = [0, 3, 2, 4]
    private let numbers = ["4821", "0937", "5510", "7264"]

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                ForEach(themes.indices, id: \.self) { id in
                    card(id)
                }
            }
            .frame(height: 220)
            .offset(y: 20)
            .contentShape(Rectangle())
            .onTapGesture(perform: shuffle)
            DemoHint(text: L("Tap to shuffle", "点击洗牌"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.4) { shuffle() }
    }

    private func card(_ id: Int) -> some View {
        let depth = order.firstIndex(of: id) ?? 0
        let isPulled = pulled == id
        let distance = ctx.cg("distance")
        // Split the pull between the card (right) and the deck (left) so the card stays on stage.
        let x: CGFloat = isPulled ? distance * 0.65 : (pulled == nil ? 0 : -distance * 0.35)
        return CardsCreditCard(theme: themes[id], width: 200, last4: numbers[id])
            .shadow(color: .black.opacity(isPulled ? 0.22 : 0.16), radius: isPulled ? 16 : 12, y: isPulled ? 12 : 8)
            .scaleEffect(isPulled ? 1.02 : 1 - CGFloat(depth) * 0.06)
            .rotationEffect(.degrees(isPulled ? 8 : 0))
            .offset(x: x, y: isPulled ? -24 : CGFloat(depth) * -16)
            .zIndex(Double(order.count - depth))
    }

    private func shuffle() {
        guard pulled == nil, let top = order.first else { return }
        if !ctx.isPreview { Haptics.tap(.soft) }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
            pulled = top
        }
        // Reorder once the pull has (nearly) arrived: the card is then furthest from the deck,
        // so the instant zIndex drop happens with the least overlap.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
                let first = order.removeFirst()
                order.append(first)
                pulled = nil
            }
        }
    }
}
