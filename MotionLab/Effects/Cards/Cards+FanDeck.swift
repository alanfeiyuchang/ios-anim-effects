import SwiftUI

extension Effect {
    static let cardsFanDeck = Effect(
        id: "cards.fan-deck",
        category: .cards,
        interaction: .tap,
        name: L("Fanned Deck", "扇形展开牌组"),
        summary: L("A neat stack of cards that spreads into a hand-held fan, one card lifting on tap.", "整齐的牌堆展开成手持扇形，点击可抽起单张。"),
        prompt: L(
            "Five playing cards (104×150 pt, 14 pt corners) rest in a loose pile with ±3° of natural jitter. On tap they spread into a hand-held fan: each card rotates around a shared pivot about 90 pt below the deck, evenly distributed across a 56° arc, and rises 12 pt. The cards travel on individual springs (response ≈0.5 s, damping ≈0.72) staggered by 30 ms from left to right, so the fan unrolls like a flick of the wrist, and collapse in the reverse order. While fanned, tapping a card slides it 30 pt outward along its own radius; tapping it again gathers the deck. Crisp shadows and a soft haptic sell the tactility.",
            "五张扑克牌（104×150 pt，14 pt 圆角）松散地叠在一起，带 ±3° 的自然错位。点击后展开成手持扇形：每张牌绕位于牌堆下方约 90 pt 的共同支点旋转，均匀分布在 56° 的弧度内，并整体上移 12 pt。每张牌使用独立弹簧（响应约 0.5 秒、阻尼约 0.72），从左到右错开 30 毫秒，像手腕一抖般依次铺开，收起时则反向依次合拢。展开状态下点击某张牌，它会沿自身半径方向向外抽出 30 pt；再次点击则收拢牌组。清晰的投影与轻柔触感增强了真实手感。"
        ),
        implementation: L(
            "Each card uses rotationEffect with an anchor below its bottom edge (UnitPoint y 1.6) so all cards share one pivot; a per-card delayed spring via .animation(_:value:) creates the stagger.",
            "每张牌使用锚点位于底边下方（UnitPoint y 为 1.6）的 rotationEffect，使所有牌共享一个支点；逐张带延迟的 .animation(_:value:) 弹簧形成错峰。"
        ),
        apis: ["rotationEffect(_:anchor:)", "animation(_:value:)", "delay", "spring(response:dampingFraction:)"],
        tags: ["fan", "deck", "playing cards", "spread", "扇形", "牌组", "展开", "扑克"],
        params: [
            .slider("spread", L("Fan angle", "扇形角度"), 20...90, default: 56, step: 1, decimals: 0, unit: "°"),
            .slider("stagger", L("Stagger", "错峰间隔"), 0...0.08, default: 0.03, unit: "s"),
            .slider("response", L("Spring response", "弹簧响应"), 0.25...1.0, default: 0.5, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.4...1.0, default: 0.72),
        ]
    ) { ctx in
        CardsFanDemo(ctx: ctx)
    }
}

private struct CardsPlayingCardModel {
    let rank: String
    let suit: String
    let red: Bool
}

private let cardsFanHand: [CardsPlayingCardModel] = [
    CardsPlayingCardModel(rank: "10", suit: "suit.heart.fill", red: true),
    CardsPlayingCardModel(rank: "J", suit: "suit.club.fill", red: false),
    CardsPlayingCardModel(rank: "Q", suit: "suit.diamond.fill", red: true),
    CardsPlayingCardModel(rank: "K", suit: "suit.spade.fill", red: false),
    CardsPlayingCardModel(rank: "A", suit: "suit.heart.fill", red: true),
]

private struct CardsFanDemo: View {
    let ctx: DemoContext
    @State private var fanned = false
    @State private var lifted: Int?
    @State private var autoStep = 0

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                ForEach(cardsFanHand.indices, id: \.self) { i in
                    card(i)
                }
            }
            .frame(width: 300, height: 250)
            .offset(y: 30)
            DemoHint(text: L("Tap to fan, tap a card to draw it", "点击展开，点击单张抽出"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // The detail stage deals the fan itself (below), so the intro play must not advance the script again.
        .autoplay(ctx.isPreview, every: 1.3) { if ctx.isPreview { autoAdvance() } }
        .task {
            // In the detail stage, deal the fan once on arrival so the stage never opens on a static pile.
            guard !ctx.isPreview else { return }
            try? await Task.sleep(for: .seconds(0.55))
            if !Task.isCancelled && !fanned { fanned = true }
        }
    }

    private func card(_ i: Int) -> some View {
        let count = cardsFanHand.count
        let order = fanned ? i : count - 1 - i
        let spring = Animation.spring(response: ctx["response"], dampingFraction: ctx["damping"])
            .delay(Double(order) * ctx["stagger"])
        return CardsPlayingCard(model: cardsFanHand[i])
            .offset(y: lifted == i ? -30 : 0)
            .rotationEffect(.degrees(angle(i)), anchor: UnitPoint(x: 0.5, y: 1.6))
            .offset(y: fanned ? -12 : 0)
            .onTapGesture { tap(i) }
            .animation(spring, value: fanned)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: lifted)
    }

    private func angle(_ i: Int) -> Double {
        let count = cardsFanHand.count
        guard fanned else { return Double(i - count / 2) * 1.5 }
        let spread = ctx["spread"]
        return -spread / 2 + spread * Double(i) / Double(count - 1)
    }

    private func tap(_ i: Int) {
        Haptics.tap(.soft)
        if !fanned {
            fanned = true
        } else if lifted == i {
            lifted = nil
            fanned = false
        } else {
            lifted = i
        }
    }

    private func autoAdvance() {
        switch autoStep % 4 {
        case 0: fanned = true
        case 1: lifted = 3
        case 2: lifted = 1
        default:
            lifted = nil
            fanned = false
        }
        autoStep += 1
    }
}

private struct CardsPlayingCard: View {
    let model: CardsPlayingCardModel

    private var tint: Color { model.red ? Palette.red : Color.primary }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Palette.elevated)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(tint.opacity(0.14), lineWidth: 1)
                .padding(7)
            Image(systemName: model.suit)
                .font(.system(size: 40))
                .foregroundStyle(tint.gradient)
            corner
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(10)
            corner
                .rotationEffect(.degrees(180))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(10)
        }
        .frame(width: 104, height: 150)
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(0.14), radius: 10, y: 5)
    }

    private var corner: some View {
        VStack(spacing: 1) {
            Text(verbatim: model.rank)
                .font(.system(size: 17, weight: .bold, design: .rounded))
            Image(systemName: model.suit)
                .font(.system(size: 11))
        }
        .foregroundStyle(tint)
    }
}
