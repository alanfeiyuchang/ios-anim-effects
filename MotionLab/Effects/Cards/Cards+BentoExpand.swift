import SwiftUI

extension Effect {
    static let cardsBentoExpand = Effect(
        id: "cards.bento-expand",
        category: .cards,
        interaction: .tap,
        name: L("Bento Expand", "便当格展开"),
        summary: L("Tap a tile in a 2×2 bento grid: it grows to fill the grid while the others reflow into a strip.", "点击 2×2 便当格中的一块：它放大占满网格，其余卡片重排成底部一行。"),
        prompt: L(
            "A 300×300 pt bento grid of four rounded tiles (22 pt corners, 10 pt gaps), each with a gradient glyph and a title. Tapping a tile reflows the whole layout on one spring (response 0.5 s, damping 0.8): the chosen tile grows from its corner to a 300×228 pt hero, while the other three shrink and slide into a strip of 62 pt tiles along the bottom, keeping their order. Inside the hero, the glyph scales up 1.4× and three lines of detail fade and rise in 150 ms after the layout starts. Tapping the hero collapses everything back to the grid; tapping a strip tile swaps it in. Structured, fluid and spatially honest.",
            "一个 300×300 pt 的便当式网格，由四块圆角卡片组成（22 pt 圆角、10 pt 间距），每块都有渐变图标和标题。点击某块时，整个布局以同一个弹簧（响应 0.5 秒、阻尼 0.8）重排：被选中的卡片从所在角落放大为 300×228 pt 的主卡，另外三块缩小并滑入底部 62 pt 高的一行，保持原有顺序。主卡内的图标放大到 1.4 倍，布局开始 150 毫秒后三行详情上浮淡入。点击主卡则全部收回网格；点击底部小卡则与主卡互换。结构清晰、流畅、空间关系真实可信。"
        ),
        implementation: L(
            "A pure function returns each tile's frame for the current selection; tiles are placed with frame + position inside a fixed 300×300 ZStack, so one withAnimation(spring) interpolates every size and position together.",
            "一个纯函数根据当前选中项返回每块卡片的 frame；卡片在固定 300×300 的 ZStack 中通过 frame + position 摆放，因此一次 withAnimation(spring) 就能同时插值所有尺寸与位置。"
        ),
        apis: ["frame(width:height:)", "position(x:y:)", "withAnimation(.spring)", "transition(.opacity.combined(with:))"],
        tags: ["bento", "grid", "expand", "reflow", "便当格", "网格", "展开", "重排"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.25...1.0, default: 0.5, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.4...1.0, default: 0.8),
        ]
    ) { ctx in
        CardsBentoDemo(ctx: ctx)
    }
}

private struct CardsBentoTile {
    let title: LocalizedText
    let symbol: String
    let colors: [Color]
    let detail: LocalizedText
}

private let cardsBentoTiles: [CardsBentoTile] = [
    CardsBentoTile(title: L("Sleep", "睡眠"), symbol: "moon.zzz.fill", colors: [Palette.indigo, Palette.violet], detail: L("7 h 42 min · deep 1 h 50", "7 小时 42 分 · 深睡 1 小时 50 分")),
    CardsBentoTile(title: L("Steps", "步数"), symbol: "figure.walk", colors: [Palette.mint, Palette.sky], detail: L("9,214 steps · 6.8 km", "9214 步 · 6.8 公里")),
    CardsBentoTile(title: L("Heart", "心率"), symbol: "heart.fill", colors: [Palette.pink, Palette.coral], detail: L("62 bpm resting · HRV 48 ms", "静息 62 次/分 · HRV 48 毫秒")),
    CardsBentoTile(title: L("Focus", "专注"), symbol: "scope", colors: [Palette.amber, Palette.coral], detail: L("3 sessions · 2 h 10 min", "3 个时段 · 2 小时 10 分")),
]

private struct CardsBentoDemo: View {
    let ctx: DemoContext
    @State private var selected: Int?
    @State private var step = 0

    private let side: CGFloat = 300
    private let gap: CGFloat = 10

    var body: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .topLeading) {
                ForEach(cardsBentoTiles.indices, id: \.self) { i in
                    tile(i)
                }
            }
            .frame(width: side, height: side)
            DemoHint(text: L("Tap a tile", "点击任意一块"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.6) { autoStep() }
    }

    private func tile(_ i: Int) -> some View {
        let rect = frame(for: i)
        let isHero = selected == i
        return CardsBentoTileView(tile: cardsBentoTiles[i], hero: isHero, compact: selected != nil && !isHero, language: ctx.language)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .onTapGesture { select(i) }
    }

    private func frame(for i: Int) -> CGRect {
        let half = (side - gap) / 2
        guard let selected else {
            let column = CGFloat(i % 2)
            let row = CGFloat(i / 2)
            return CGRect(x: column * (half + gap), y: row * (half + gap), width: half, height: half)
        }
        let stripHeight: CGFloat = 62
        if i == selected {
            return CGRect(x: 0, y: 0, width: side, height: side - stripHeight - gap)
        }
        let others = cardsBentoTiles.indices.filter { $0 != selected }
        let slot = CGFloat(others.firstIndex(of: i) ?? 0)
        let width = (side - gap * 2) / 3
        return CGRect(x: slot * (width + gap), y: side - stripHeight, width: width, height: stripHeight)
    }

    private func select(_ i: Int) {
        Haptics.tap(.soft)
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            selected = selected == i ? nil : i
        }
    }

    private func autoStep() {
        let sequence: [Int?] = [0, 2, nil, 3, 1, nil]
        let next = sequence[step % sequence.count]
        step += 1
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            selected = next
        }
    }
}

private struct CardsBentoTileView: View {
    let tile: CardsBentoTile
    let hero: Bool
    let compact: Bool
    let language: AppLanguage

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: compact ? 18 : 22, style: .continuous)
                .fill(Palette.elevated)
                .overlay(RoundedRectangle(cornerRadius: compact ? 18 : 22, style: .continuous).strokeBorder(Palette.stroke))
                .shadow(color: .black.opacity(hero ? 0.16 : 0.08), radius: hero ? 16 : 8, y: hero ? 10 : 4)
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        if compact {
            glyph
                .scaleEffect(0.8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                glyph
                    .scaleEffect(hero ? 1.4 : 1, anchor: .topLeading)
                    .padding(.bottom, hero ? 12 : 0)
                Spacer(minLength: 0)
                Text(tile.title, language)
                    .font(hero ? .title3.weight(.bold) : .headline)
                if hero {
                    Text(tile.detail, language)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .transition(Self.detailIn(delay: 0.15, rise: 10))
                    PlaceholderLines(count: 2)
                        .transition(Self.detailIn(delay: 0.2, rise: 14))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    /// Detail lines fade and rise in slightly after the layout starts moving.
    private static func detailIn(delay: Double, rise: CGFloat) -> AnyTransition {
        AnyTransition.opacity
            .combined(with: AnyTransition.offset(x: 0, y: rise))
            .animation(Animation.easeOut(duration: 0.3).delay(delay))
    }

    private var glyph: some View {
        Image(systemName: tile.symbol)
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 40, height: 40)
            .background(
                LinearGradient(colors: tile.colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
    }
}
