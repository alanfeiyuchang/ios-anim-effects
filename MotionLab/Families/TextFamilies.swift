import Foundation

/// Families (variation groups) of `EffectCategory.text`.
///
/// To add a variation: append the effect to `TextEffects.all`, then add one
/// `"<effect id>": "<family id>",` line to `membership` below. Each effect id may appear only once
/// (a duplicate dictionary key traps at launch). See docs/FAMILIES.md.
enum TextFamilies {
    static let all: [EffectFamily] = [
        EffectFamily(
            id: "text.number",
            category: .text,
            name: L("Number Counter", "数字滚动"),
            summary: L("Digits that roll, tick like an odometer or flip like a split-flap board.", "数字滚动、里程表跳动或翻页牌翻转。"),
            symbol: "number"
        ),
        EffectFamily(
            id: "text.reveal",
            category: .text,
            name: L("Text Reveal", "文字揭示"),
            summary: L("Words arriving on screen: blur-in, typing, decoding, hinging, rising.", "文字入场：模糊显现、打字、解码、翻转与升起。"),
            symbol: "text.append"
        ),
        EffectFamily(
            id: "text.kinetic",
            category: .text,
            name: L("Kinetic Type", "动态字形"),
            summary: L("Letters that keep moving: waves, weight shifts and orbiting rings.", "持续运动的字形：波浪、字重变化与环绕文字。"),
            symbol: "waveform.path"
        ),
        EffectFamily(
            id: "text.emphasis",
            category: .text,
            name: L("Light & Emphasis", "光效与强调"),
            summary: L("Shimmers, highlighter sweeps and karaoke fills that direct the eye.", "流光、荧光笔扫过与逐字填充，引导视线。"),
            symbol: "highlighter"
        ),
        EffectFamily(
            id: "text.ticker",
            category: .text,
            name: L("Rotating & Ticker", "轮播与跑马灯"),
            summary: L("Words that swap in a slot or scroll by endlessly.", "在槽位中轮换或无尽滚动的文字。"),
            symbol: "arrow.left.arrow.right"
        ),
    ]

    static let membership: [String: String] = [
        // Number counter
        "text.numeric-counter": "text.number",
        "text.odometer": "text.number",
        "text.split-flap": "text.number",
        // Text reveal
        "text.blur-reveal": "text.reveal",
        "text.typewriter": "text.reveal",
        "text.scramble": "text.reveal",
        "text.flip-in-3d": "text.reveal",
        "text.masked-lines": "text.reveal",
        // Kinetic type
        "text.wave": "text.kinetic",
        "text.circular-badge": "text.kinetic",
        "text.variable-weight": "text.kinetic",
        // Light & emphasis
        "text.shimmer": "text.emphasis",
        "text.highlighter": "text.emphasis",
        "text.synced-lyrics": "text.emphasis",
        // Rotating & ticker
        "text.rotating-words": "text.ticker",
        "text.marquee": "text.ticker",
    ]
}
