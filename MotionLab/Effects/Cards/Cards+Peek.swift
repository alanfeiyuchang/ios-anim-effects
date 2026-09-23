import SwiftUI

extension Effect {
    static let cardsPeek = Effect(
        id: "cards.peek",
        category: .cards,
        interaction: .gesture,
        name: L("Long-press Peek", "长按预览"),
        summary: L("Long-press a tile to lift it forward over a blurred backdrop with quick actions.", "长按卡片将其抬起放大，背景模糊并弹出快捷操作。"),
        prompt: L(
            "A 2×2 grid of rounded album tiles (120 pt, 26 pt corners). Pressing a tile immediately sinks it to 95% as feedback; after a 350 ms hold it springs forward to the center and scales to ~140% (response ≈0.42 s, damping ≈0.72) with a medium haptic, while the rest of the grid blurs by 8 pt and a 22% black scrim fades in behind it. A quick-action menu (Share, Favorite, Delete) materialises beneath the lifted tile from 85% scale anchored at its top edge, in a frosted material panel. Tapping anywhere returns the tile to its slot along the same spring as the backdrop clears. Focused, iOS-native context-menu energy.",
            "2×2 排列的圆角专辑卡片（120 pt，26 pt 圆角）。手指按下时卡片立即下沉到 95% 作为反馈；按住 350 毫秒后，它以弹簧（响应约 0.42 秒、阻尼约 0.72）弹到舞台中央并放大到约 140%，伴随中等触感，其余卡片模糊 8 pt，后方淡入 22% 黑色遮罩。快捷菜单（分享、收藏、删除）以磨砂材质面板从被抬起卡片下方、以顶边为锚点从 85% 缩放浮现。点击任意处，卡片沿同一弹簧回到原位，背景随之恢复清晰。专注、原生的 iOS 上下文菜单质感。"
        ),
        implementation: L(
            "onLongPressGesture(minimumDuration:perform:onPressingChanged:) drives a pressed scale and a `peeked` index; the peeked tile gets zIndex, offset and scale, siblings get blur, and the menu is inserted with a scale + opacity transition.",
            "onLongPressGesture(minimumDuration:perform:onPressingChanged:) 驱动按压缩放与 `peeked` 索引；被预览的卡片提升 zIndex 并施加位移与缩放，其余卡片模糊，菜单以缩放 + 透明度转场插入。"
        ),
        apis: ["onLongPressGesture(minimumDuration:perform:onPressingChanged:)", "blur", "zIndex", "transition", "Material"],
        tags: ["peek", "long press", "context menu", "preview", "长按", "预览", "上下文菜单", "模糊"],
        params: [
            .slider("scale", L("Peek scale", "预览放大"), 1.2...1.7, default: 1.4),
            .slider("blur", L("Backdrop blur", "背景模糊"), 0...16, default: 8, step: 1, decimals: 0, unit: "pt"),
            .slider("response", L("Spring response", "弹簧响应"), 0.25...0.8, default: 0.42, unit: "s"),
        ]
    ) { ctx in
        CardsPeekDemo(ctx: ctx)
    }
}

private struct CardsPeekTile {
    let title: LocalizedText
    let symbol: String
    let colors: [Color]
}

private let cardsPeekTiles: [CardsPeekTile] = [
    CardsPeekTile(title: L("Nightfall", "夜幕"), symbol: "moon.stars.fill", colors: [Palette.indigo, Palette.violet]),
    CardsPeekTile(title: L("Tides", "潮汐"), symbol: "water.waves", colors: [Palette.sky, Palette.blue]),
    CardsPeekTile(title: L("Bloom", "花开"), symbol: "camera.macro", colors: [Palette.pink, Palette.coral]),
    CardsPeekTile(title: L("Ember", "余烬"), symbol: "flame.fill", colors: [Palette.amber, Palette.coral]),
]

private let cardsPeekMenuTransition: AnyTransition = .scale(scale: 0.85, anchor: .top).combined(with: .opacity)

private struct CardsPeekDemo: View {
    let ctx: DemoContext
    @State private var peeked: Int?
    @State private var pressing: Int?
    @State private var autoIndex = 0

    var body: some View {
        ZStack {
            ForEach(cardsPeekTiles.indices, id: \.self) { i in
                tile(i)
            }
            Color.black
                .opacity(peeked == nil ? 0 : 0.22)
                .zIndex(1)
                .allowsHitTesting(peeked != nil)
                .onTapGesture(perform: dismiss)
            if peeked != nil {
                CardsPeekMenu(language: ctx.language)
                    .offset(y: 104)
                    .onTapGesture {
                        Haptics.selection()
                        dismiss()
                    }
                    .zIndex(3)
                    .transition(cardsPeekMenuTransition)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Long-press a tile", "长按任一卡片"), ctx: ctx)
                .opacity(peeked == nil ? 1 : 0)
                .padding(.bottom, 10)
                .allowsHitTesting(false)
        }
        .autoplay(ctx.isPreview, every: 1.6) { autoAdvance() }
    }

    private func tile(_ i: Int) -> some View {
        let isPeeked = peeked == i
        let dimmed = peeked != nil && !isPeeked
        return CardsPeekTileView(tile: cardsPeekTiles[i], language: ctx.language)
            .scaleEffect(pressing == i ? 0.95 : 1)
            .blur(radius: dimmed ? ctx.cg("blur") : 0)
            .scaleEffect(isPeeked ? ctx.cg("scale") : 1)
            .offset(isPeeked ? CGSize(width: 0, height: -52) : slot(i))
            .zIndex(isPeeked ? 2 : 0)
            .onTapGesture {
                if peeked != nil { dismiss() }
            }
            .onLongPressGesture(minimumDuration: 0.35, perform: {
                peek(i)
            }, onPressingChanged: { isPressing in
                guard peeked == nil else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    pressing = isPressing ? i : nil
                }
            })
    }

    private func slot(_ i: Int) -> CGSize {
        let column: CGFloat = i % 2 == 0 ? -1 : 1
        let row: CGFloat = i < 2 ? -1 : 1
        return CGSize(width: column * 67, height: row * 67)
    }

    private func peek(_ i: Int, haptic: Bool = true) {
        guard peeked == nil else { return }
        if haptic && !ctx.isPreview { Haptics.tap(.medium) }
        withAnimation(.spring(response: ctx["response"], dampingFraction: 0.72)) {
            peeked = i
            pressing = nil
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: ctx["response"], dampingFraction: 0.8)) {
            peeked = nil
        }
    }

    private func autoAdvance() {
        if peeked == nil {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { pressing = autoIndex % 4 }
            let index = autoIndex % 4
            // Simulated presses stay silent, including the detail stage's intro play.
            let muted = Haptics.isMuted || ctx.isPreview
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { peek(index, haptic: !muted) }
            autoIndex += 1
        } else {
            dismiss()
        }
    }
}

private struct CardsPeekTileView: View {
    let tile: CardsPeekTile
    let language: AppLanguage

    var body: some View {
        LinearGradient(colors: tile.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay {
                Image(systemName: tile.symbol)
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                    .offset(y: -10)
            }
            .overlay(alignment: .bottomLeading) {
                Text(tile.title, language)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(12)
            }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: .black.opacity(0.14), radius: 10, y: 6)
    }
}

private struct CardsPeekMenu: View {
    let language: AppLanguage

    var body: some View {
        VStack(spacing: 0) {
            row(L("Share", "分享"), symbol: "square.and.arrow.up", tint: .primary)
            Divider()
            row(L("Favorite", "收藏"), symbol: "heart", tint: .primary)
            Divider()
            row(L("Delete", "删除"), symbol: "trash", tint: Palette.red)
        }
        .frame(width: 190)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
    }

    private func row(_ title: LocalizedText, symbol: String, tint: Color) -> some View {
        HStack {
            Text(title, language)
                .font(.subheadline)
            Spacer(minLength: 0)
            Image(systemName: symbol)
                .font(.subheadline)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 14)
        .frame(height: 38)
    }
}
