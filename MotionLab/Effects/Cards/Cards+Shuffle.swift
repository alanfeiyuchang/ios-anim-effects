import SwiftUI

extension Effect {
    static let cardsShuffle = Effect(
        id: "cards.shuffle",
        category: .cards,
        interaction: .tap,
        name: L("Card Shuffle", "卡片洗牌"),
        summary: L("The front card slides out, tilts, and tucks behind the stack.", "最前方的卡片滑出、倾斜，再塞回卡堆最后。"),
        prompt: L(
            "Four payment cards are stacked with each one behind stepping 16 pt higher and 6% smaller, so their top edges peek out like a deck. On tap the front card is pulled about 110 pt clear of the deck, travelling 65% of that itself while the deck counter-shifts 35% the other way so everything stays on stage, and it rises 24 pt with an 8° tilt on a quick spring (response 0.32 s, damping 0.8). After 300 ms, as that spring nearly lands, its z-order drops behind the others and it glides into the rearmost slot on a softer spring (response 0.55 s, damping 0.75) while the rest advance one slot and grow. The overlapping springs read as one dealer-like flick, finished with a soft haptic.",
            "四张支付卡层叠摆放，后方每张依次上移 16 pt、缩小 6%，顶边错落露出，像一副牌。轻点后最前面的卡片被抽离卡堆约 110 pt：它自己走 65%，卡堆反向让出 35%，保证不出画面；同时以快速弹簧（响应 0.32 秒、阻尼 0.8）上抬 24 pt、倾斜 8°。300 毫秒后第一段弹簧几近到位，卡片层级随即降到最底，再以更柔的弹簧（响应 0.55 秒、阻尼 0.75）滑进最后一位，其余卡片各前进一格并放大补位。两段弹簧首尾交叠，像荷官手里一记利落的洗牌，收尾是一下轻柔触感。"
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
