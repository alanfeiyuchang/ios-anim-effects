import SwiftUI

extension Effect {
    static let cardsShuffle = Effect(
        id: "cards.shuffle",
        category: .cards,
        interaction: .tap,
        name: L("Card Shuffle", "卡片洗牌"),
        summary: L("The front card slides out, tilts, and tucks behind the stack.", "最前方的卡片滑出、倾斜，再塞回卡堆最后。"),
        prompt: L(
            "Four 160 pt payment cards are stacked with each one behind stepping 16 pt higher and 6% smaller, so their top edges peek out like a deck. On tap the front card and the deck part until their centres are about 175 pt apart (card ~80 pt right, deck ~95 pt left), so the card fully clears the deck yet both stay on stage; it rises 24 pt with an 8° tilt on a quick spring (response 0.32 s, damping 0.8). After 300 ms, with the card clear, its z-order drops over empty space and it glides into the rearmost slot on a softer spring (response 0.55 s, damping 0.75) while the rest advance one slot and grow. It reads as one dealer-like flick, finished with a soft haptic.",
            "四张160 pt宽的支付卡层叠摆放，后方每张依次上移16 pt、缩小6%，顶边错落露出，像一副牌。轻点后最前面的卡片与卡堆向两侧分开，中心相距约175 pt（卡片右移约80 pt，卡堆左移约95 pt），卡片完全脱离卡堆又都不出画面；同时以快速弹簧（响应0.32秒、阻尼0.8）上抬24 pt、倾斜8°。300毫秒后卡片已完全离开卡堆，层级在空白处降到最底，再以更柔的弹簧（响应0.55秒、阻尼0.75）滑进最后一位，其余卡片各前进一格并放大补位。像荷官一记利落的洗牌，收尾一下轻柔触感。"
        ),
        implementation: L(
            "Two chained springs: the first sets a `pulled` card (offset + rotation) and parts it from the deck by at least its tilted width, the second, fired via asyncAfter, moves it to the end of the order array — its zIndex drops instantly, but only once nothing overlaps it, while offsets and scales animate.",
            "两段衔接的弹簧：第一段标记被抽出的卡片（位移 + 旋转），并让它与卡堆至少拉开倾斜后的整卡宽度；第二段通过 asyncAfter 将其移到顺序数组末尾——zIndex 在无任何重叠时才瞬间下降，位移与缩放则继续动画。"
        ),
        apis: ["zIndex", "offset", "rotationEffect", "spring(response:dampingFraction:)", "DispatchQueue.asyncAfter"],
        tags: ["shuffle", "deck", "stack", "reorder", "洗牌", "卡堆", "切换", "层叠"],
        params: [
            .slider("tilt", L("Pull tilt", "抽出倾斜"), 4...14, default: 8, step: 1, decimals: 0, unit: "°"),
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

    // Geometry for the z-swap: it must happen over empty space, so the pulled card (scaled 1.02 and
    // tilted 4–14°) and the deck's front card (depth 1, 94%) part by at least their half-widths combined.
    private static let cardWidth: CGFloat = 160
    private static let pullScale: CGFloat = 1.02
    /// The card and the deck part to 175 pt between centres, or wider when a steep tilt needs it.
    private static let separation: CGFloat = 175
    private var pullTilt: Double { ctx["tilt"] }
    /// Half the pulled card's bounding width at the current tilt.
    private var pulledHalf: CGFloat {
        let w = Self.cardWidth * Self.pullScale
        let h = w * 158 / 250
        let a = pullTilt * .pi / 180
        return (w * CGFloat(cos(a)) + h * CGFloat(sin(a))) / 2
    }
    /// Half the width of the deck's front card while the pulled card is out.
    private static var deckHalf: CGFloat { cardWidth * 0.94 / 2 }
    /// Smallest centre separation with a clear gap (~169 pt at 8°, ~173 pt at 14°).
    private var clearance: CGFloat { pulledHalf + Self.deckHalf + 6 }
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
        let x = offsetX(isPulled: isPulled)
        return CardsCreditCard(theme: themes[id], width: Self.cardWidth, last4: numbers[id])
            .shadow(color: .black.opacity(isPulled ? 0.22 : 0.16), radius: isPulled ? 16 : 12, y: isPulled ? 12 : 8)
            .scaleEffect(isPulled ? Self.pullScale : 1 - CGFloat(depth) * 0.06)
            .rotationEffect(.degrees(isPulled ? pullTilt : 0))
            .offset(x: x, y: isPulled ? -24 : CGFloat(depth) * -16)
            .zIndex(Double(order.count - depth))
    }

    /// Parts the pulled card (right) and the deck (left) by 175 pt, never less than the clearance, with the
    /// pair's outer edges centred so both stay on stage.
    private func offsetX(isPulled: Bool) -> CGFloat {
        guard pulled != nil else { return 0 }
        let separation = max(Self.separation, clearance)
        let cardX = (separation + Self.deckHalf - pulledHalf) / 2
        return isPulled ? cardX : cardX - separation
    }

    private func shuffle() {
        guard pulled == nil, let top = order.first else { return }
        if !ctx.isPreview { Haptics.tap(.soft) }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
            pulled = top
        }
        // Reorder once the pull has landed (the 0.32 s spring is within ~1% by 300 ms, slightly past
        // its target): the card then fully clears the deck, so the instant zIndex drop is invisible.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
                let first = order.removeFirst()
                order.append(first)
                pulled = nil
            }
        }
    }
}
