import Foundation

/// Families (variation groups) of `EffectCategory.cards`.
///
/// To add a variation: append the effect to `CardEffects.all`, then add one
/// `"<effect id>": "<family id>",` line to `membership` below. Each effect id may appear only once
/// (a duplicate dictionary key traps at launch). See docs/FAMILIES.md.
enum CardsFamilies {
    static let all: [EffectFamily] = [
        EffectFamily(
            id: "cards.tilt",
            category: .cards,
            name: L("Tilt & Foil", "倾斜与光泽"),
            summary: L("Cards that tilt in 3D under the finger with glare, foil or parallax depth.", "随手指 3D 倾斜，带高光、镭射或视差层次的卡片。"),
            symbol: "rotate.3d"
        ),
        EffectFamily(
            id: "cards.flip",
            category: .cards,
            name: L("Flip & Reveal", "翻转与揭示"),
            summary: L("Cards that turn over or get scratched away to show what's behind.", "翻面或被刮开以露出背后内容的卡片。"),
            symbol: "arrow.left.arrow.right"
        ),
        EffectFamily(
            id: "cards.swipe",
            category: .cards,
            name: L("Card Swipe", "卡片滑动"),
            summary: L("Decks you fling, shuffle and cycle through, card by card.", "逐张甩出、洗牌与轮换的卡组。"),
            symbol: "hand.draw.fill"
        ),
        EffectFamily(
            id: "cards.stack",
            category: .cards,
            name: L("Stacks & Decks", "堆叠与牌组"),
            summary: L("Piles of cards that fan, lift, unfold and pin into place.", "扇形展开、抬起、展开与吸顶的卡片堆。"),
            symbol: "rectangle.stack.fill"
        ),
        EffectFamily(
            id: "cards.expand",
            category: .cards,
            name: L("Expand & Peek", "展开与预览"),
            summary: L("Cards that expand in place or lift forward for a quick look.", "原地展开或抬起预览的卡片。"),
            symbol: "rectangle.expand.vertical"
        ),
    ]

    static let membership: [String: String] = [
        // Tilt & foil
        "cards.tilt-3d": "cards.tilt",
        "cards.holographic": "cards.tilt",
        "cards.parallax-layers": "cards.tilt",
        // Flip & reveal
        "cards.flip": "cards.flip",
        "cards.scratch-reveal": "cards.flip",
        // Card swipe
        "cards.swipe-stack": "cards.swipe",
        "cards.shuffle": "cards.swipe",
        // Stacks & decks
        "cards.wallet-stack": "cards.stack",
        "cards.fan-deck": "cards.stack",
        "cards.notification-stack": "cards.stack",
        "cards.stacking-scroll": "cards.stack",
        // Expand & peek
        "cards.peek": "cards.expand",
        "cards.accordion": "cards.expand",
    ]
}
