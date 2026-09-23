import SwiftUI

extension Effect {
    static let cardsShuffle = Effect(
        id: "cards.shuffle",
        category: .cards,
        interaction: .tap,
        name: L("Card Shuffle", "卡片洗牌"),
        summary: L("The front card slides out, tilts, and tucks behind the stack.", "最前方的卡片滑出、倾斜，再塞回卡堆最后。"),
        prompt: L(
            "A stack of four payment cards is layered with each card behind stepping 16 pt higher and 6% smaller, so their top edges peek out like a deck. On tap the front card slides out to the right by ~150 pt, rising 20 pt and rotating 10° on a quick spring (≈320 ms); at the apex (~260 ms) its z-order drops behind the others and it glides back into the rearmost slot on a softer spring (response ≈0.55 s, damping ≈0.75), while the remaining cards each advance one slot forward and grow to fill the front. The overlap of the two springs makes the motion read as one continuous, dealer-like flick, finished with a soft haptic.",
            "四张支付卡片层叠排列，后方每张依次上移 16 pt、缩小 6%，顶边错落露出，像一副牌。点击时最前方的卡片以快速弹簧（约 320 毫秒）向右滑出约 150 pt，同时上抬 20 pt 并旋转 10°；在动作顶点（约 260 毫秒）其层级降到其余卡片之后，再以更柔和的弹簧（响应约 0.55 秒、阻尼约 0.75）滑回最后一位，其余卡片则各前进一格并放大补位。两段弹簧相互衔接，让整个动作像荷官洗牌般一气呵成，并伴随轻柔触感。"
        ),
        implementation: L(
            "Two chained springs: the first sets a `pulled` card (offset + rotation), the second, fired via asyncAfter, moves it to the end of the order array — its zIndex drops instantly while offsets and scales animate.",
            "两段衔接的弹簧：第一段标记被抽出的卡片（位移 + 旋转），第二段通过 asyncAfter 将其移到顺序数组末尾——zIndex 瞬间下降，位移与缩放则继续动画。"
        ),
        apis: ["zIndex", "offset", "rotationEffect", "spring(response:dampingFraction:)", "DispatchQueue.asyncAfter"],
        tags: ["shuffle", "deck", "stack", "reorder", "洗牌", "卡堆", "切换", "层叠"],
        params: [
            .slider("distance", L("Slide distance", "滑出距离"), 80...220, default: 150, step: 5, decimals: 0, unit: "pt"),
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
        return CardsCreditCard(theme: themes[id], width: 230, last4: numbers[id])
            .shadow(color: .black.opacity(0.16), radius: 12, y: 8)
            .scaleEffect(isPulled ? 1.02 : 1 - CGFloat(depth) * 0.06)
            .rotationEffect(.degrees(isPulled ? 10 : 0))
            .offset(x: isPulled ? ctx.cg("distance") : 0, y: isPulled ? -20 : CGFloat(depth) * -16)
            .zIndex(Double(order.count - depth))
    }

    private func shuffle() {
        guard pulled == nil, let top = order.first else { return }
        if !ctx.isPreview { Haptics.tap(.soft) }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
            pulled = top
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
            withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
                let first = order.removeFirst()
                order.append(first)
                pulled = nil
            }
        }
    }
}
