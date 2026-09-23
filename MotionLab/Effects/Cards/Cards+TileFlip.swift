import SwiftUI

extension Effect {
    static let cardsTileFlip = Effect(
        id: "cards.tile-flip",
        category: .cards,
        interaction: .tap,
        name: L("Tile Cascade Flip", "瓷砖级联翻转"),
        summary: L("A card split into 12 tiles that flip one after another in a wave to reveal a new picture.", "卡片被切成 12 块瓷砖，以波浪般的顺序逐块翻转，拼出新画面。"),
        prompt: L(
            "A 252×176 pt card is sliced into a 4×3 mosaic of 60×56 pt tiles with 4 pt gaps and 8 pt corners; together the tiles show a night scene. Tapping flips every tile 180° around its vertical axis in perspective, each on its own spring (response 0.55 s, damping 0.72), but started in a wave: tiles are delayed 50 ms per step along the diagonal from the top-left corner (or outward from the center, or in a scattered order). Mid-turn each tile shrinks to about 88%, widening the gaps, and its back face carries the matching slice of a daytime scene, so the new picture assembles as the wave passes. Each further tap sends the same wave again, turning the picture back over. Crisp, rhythmic and satisfying, like a split-flap board.",
            "一张252×176 pt的卡片被切成4×3的马赛克，每块60×56 pt，间隙4 pt，圆角8 pt，拼在一起是一幅夜景。点击后，每块瓷砖都绕竖直轴以透视翻转180°，各自使用弹簧（响应0.55秒、阻尼0.72），但按波浪依次启动：从左上角沿对角线每一步延迟50毫秒（也可从中心向外扩散，或随机错落）。翻到一半时瓷砖缩小到约88%，间隙随之变宽；背面是白昼画面中对应的那一块，于是新画面随着波浪逐渐拼合。再次点击，波浪再扫一遍把画面翻回。清脆而有节奏。"
        ),
        implementation: L(
            "Each tile is an Animatable view that clips its slice of a full-size artwork by offsetting it inside a fixed frame; the flip angle comes from a shared turn counter and each tile gets its own .animation(spring.delay(order × stagger), value:). The grid is flattened with drawingGroup so the wave renders as one Metal layer.",
            "每块瓷砖是一个 Animatable 视图，通过在固定 frame 内偏移整幅画面来裁出自己的那一块；翻转角度来自共享的翻转计数，每块瓷砖各自带 .animation(spring.delay(次序 × 间隔), value:)；整个网格用 drawingGroup 压平为一个 Metal 图层渲染。"
        ),
        apis: ["Animatable", "rotation3DEffect", "animation(_:value:)", "Animation.delay", "clipped()"],
        tags: ["flip", "tiles", "mosaic", "cascade", "翻转", "瓷砖", "马赛克", "级联"],
        params: [
            .slider("stagger", L("Stagger", "错落间隔"), 0.02...0.12, default: 0.05, unit: "s"),
            .choice("pattern", L("Wave", "波浪"), [L("Diagonal", "对角"), L("Ripple", "扩散"), L("Scatter", "随机")], default: 0),
            .toggle("vertical", L("Flip vertically", "纵向翻转"), default: false),
        ]
    ) { ctx in
        CardsTileFlipDemo(ctx: ctx)
    }
}

private enum CardsTileGrid {
    static let columns = 4
    static let rows = 3
    static let tile = CGSize(width: 60, height: 56)
    static let gap: CGFloat = 4
    static var width: CGFloat { CGFloat(columns) * tile.width + CGFloat(columns - 1) * gap }
    static var height: CGFloat { CGFloat(rows) * tile.height + CGFloat(rows - 1) * gap }
}

private struct CardsTileFlipDemo: View {
    let ctx: DemoContext
    @State private var turns = 0

    var body: some View {
        VStack(spacing: 30) {
            grid
                .contentShape(Rectangle())
                .onTapGesture(perform: flip)
                .shadow(color: .black.opacity(0.18), radius: 16, y: 10)
            DemoHint(text: L("Tap to flip the mosaic", "点击翻转马赛克"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.0) { flip() }
    }

    private var grid: some View {
        VStack(spacing: CardsTileGrid.gap) {
            ForEach(0..<CardsTileGrid.rows, id: \.self) { row in
                HStack(spacing: CardsTileGrid.gap) {
                    ForEach(0..<CardsTileGrid.columns, id: \.self) { column in
                        tile(column: column, row: row)
                    }
                }
            }
        }
        // Twelve tiles × two full artworks: flatten the mosaic into one Metal-rendered layer per frame.
        // Padding keeps the mid-flip perspective overhang inside the offscreen buffer.
        .padding(12)
        .drawingGroup()
        .padding(-12)
    }

    private func tile(column: Int, row: Int) -> some View {
        let delay = Double(order(column: column, row: row)) * ctx["stagger"]
        return CardsFlipTile(
            angle: Double(turns) * 180,
            column: column,
            row: row,
            vertical: ctx.bool("vertical")
        )
        .animation(.spring(response: 0.55, dampingFraction: 0.72).delay(delay), value: turns)
    }

    /// Wave step of a tile for the selected pattern.
    private func order(column: Int, row: Int) -> Int {
        switch ctx.int("pattern") {
        case 1:
            // Ripple: Chebyshev-ish distance from the grid center, in half steps.
            let dx = abs(Double(column) - 1.5)
            let dy = abs(Double(row) - 1.0)
            return Int(((dx + dy) * 2).rounded())
        case 2:
            return (column * 7 + row * 5 + 3) % 9
        default:
            return column + row
        }
    }

    private func flip() {
        Haptics.tap(.soft)
        turns += 1
    }
}

private struct CardsFlipTile: View, Animatable {
    var angle: Double
    let column: Int
    let row: Int
    let vertical: Bool

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    var body: some View {
        let remainder = angle.truncatingRemainder(dividingBy: 360)
        let normalized = remainder < 0 ? remainder + 360 : remainder
        let showBack = normalized > 90 && normalized < 270
        let dip = abs(sin(angle * .pi / 180))
        let axis: (x: CGFloat, y: CGFloat, z: CGFloat) = vertical ? (x: 1, y: 0, z: 0) : (x: 0, y: 1, z: 0)
        ZStack {
            slice(night: true)
                .opacity(showBack ? 0 : 1)
            slice(night: false)
                .rotation3DEffect(.degrees(180), axis: axis)
                .opacity(showBack ? 1 : 0)
        }
        .rotation3DEffect(.degrees(angle), axis: axis, perspective: 0.5)
        .scaleEffect(1 - 0.12 * dip)
    }

    private func slice(night: Bool) -> some View {
        let dx = -CGFloat(column) * (CardsTileGrid.tile.width + CardsTileGrid.gap)
        let dy = -CGFloat(row) * (CardsTileGrid.tile.height + CardsTileGrid.gap)
        return CardsTileArtwork(night: night)
            .frame(width: CardsTileGrid.width, height: CardsTileGrid.height)
            .offset(x: dx, y: dy)
            .frame(width: CardsTileGrid.tile.width, height: CardsTileGrid.tile.height, alignment: .topLeading)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

/// The full-size picture each tile shows a slice of: a night sky or a sunny day.
private struct CardsTileArtwork: View {
    let night: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: night ? [Color(hex: 0x1B1D4B), Color(hex: 0x5B3BFF), Color(hex: 0xA46BFF)] : [Color(hex: 0x3AC4FF), Color(hex: 0x8FE3FF), Color(hex: 0xFFE7A8)],
                startPoint: .top,
                endPoint: .bottom
            )
            Image(systemName: night ? "moon.stars.fill" : "sun.max.fill")
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(night ? Color.white.opacity(0.95) : Color(hex: 0xFFC247))
                .shadow(color: (night ? Color.white : Color(hex: 0xFFC247)).opacity(0.5), radius: 16)
                .offset(x: 58, y: -30)
            Image(systemName: "mountain.2.fill")
                .font(.system(size: 110, weight: .regular))
                .foregroundStyle(night ? Color(hex: 0x0E0F2A).opacity(0.9) : Color(hex: 0x1A9E9A))
                .offset(x: -40, y: 42)
            Text(verbatim: night ? "22:40" : "10:15")
                .font(.system(size: 22, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                .offset(x: -78, y: -58)
        }
        .clipped()
    }
}
