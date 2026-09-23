import SwiftUI

extension Effect {
    static let morphNativeZoom = Effect(
        id: "morph.native-zoom",
        category: .morph,
        interaction: .tap,
        name: L("Zoom Push Transition", "缩放推入转场"),
        summary: L(
            "The iOS 18 zoom push: a tile grows into its detail page and shrinks back home.",
            "iOS 18 风格缩放推入：图块放大成详情页，返回时再缩回原位。"
        ),
        prompt: L(
            "A grid of rounded gradient tiles. Tapping a tile (it first presses in slightly) opens its detail page with a zoom push: the page grows out of the tile's exact frame and corner radius to fill the screen on a smooth spring (response 0.5 s, damping 0.86), cross-fading from the tile artwork to the full page while the grid dims to 30% behind it. Closing reverses the path into the same tile. The page can also be pulled down or swiped right: it follows the finger, shrinks up to 30% and rounds its corners; release past a third of the way (or with a flick) flies it home, otherwise it springs back. Continuous, interruptible and anchored to where it came from.",
            "一组圆角渐变图块。点击时图块先轻压，随后详情页从它的精确位置与圆角中“长”出来铺满屏幕：弹簧（响应 0.5 秒、阻尼 0.86）平滑舒展，图块插画渐隐为完整页面，背后网格压暗至 30%。关闭时沿原路缩回同一图块。也可下拉或右滑，页面跟手缩小（最多 30%）并变圆角；拖过三分之一或快速甩出即飞回原位，否则弹回。连贯、可打断，始终锚定出发点。"
        ),
        implementation: L(
            "Tiles report their frames with onGeometryChange into a named coordinate space; the full-size detail page is placed by an Animatable modifier that interpolates frame, scale and corner radius from the source rect, so no nested NavigationStack is needed. In a real app, use navigationTransition(.zoom(sourceID:in:)) with matchedTransitionSource.",
            "图块通过 onGeometryChange 在命名坐标空间中上报自身位置；全尺寸详情页由遵循 Animatable 的修饰器从来源矩形插值出位置、缩放与圆角，无需嵌套 NavigationStack。真实 App 中可直接使用 navigationTransition(.zoom(sourceID:in:)) 配合 matchedTransitionSource。"
        ),
        apis: ["onGeometryChange(for:of:action:)", "Animatable", "coordinateSpace(_:)", "DragGesture", "navigationTransition(.zoom(sourceID:in:))"],
        tags: ["zoom", "navigation", "hero", "ios 18", "缩放转场", "导航", "推入", "系统转场"],
        params: [
            .choice("columns", L("Columns", "列数"), [L("2", "2"), L("3", "3")], default: 1),
            .slider("corner", L("Tile corner radius", "图块圆角"), 4...28, default: 18, decimals: 0, unit: "pt"),
            .slider("press", L("Tile press scale", "图块按压缩放"), 0.85...1.0, default: 0.94),
        ]
    ) { ctx in
        NativeZoomDemo(ctx: ctx)
    }
}

private struct ZoomTile: Identifiable, Hashable {
    let id: Int
    let symbol: String
    let colors: [Color]
    let title: LocalizedText
    let meta: LocalizedText
    let blurb: LocalizedText
}

private let zoomTiles: [ZoomTile] = [
    ZoomTile(id: 0, symbol: "mountain.2.fill", colors: [Palette.sky, Palette.indigo], title: L("Alpine Lake", "高山湖泊"),
             meta: L("Photo · 4K · 12 MB", "照片 · 4K · 12 MB"), blurb: L("First light over still water, shot at 5:40 AM.", "清晨 5:40，第一缕光落在平静的湖面上。")),
    ZoomTile(id: 1, symbol: "sun.horizon.fill", colors: [Palette.amber, Palette.coral], title: L("Golden Hour", "黄金时刻"),
             meta: L("Photo · 4K · 9 MB", "照片 · 4K · 9 MB"), blurb: L("Warm backlight and long shadows on the dunes.", "暖色逆光与沙丘上拉长的影子。")),
    ZoomTile(id: 2, symbol: "leaf.fill", colors: [Palette.mint, Palette.green], title: L("Fern Study", "蕨类习作"),
             meta: L("Photo · Macro · 7 MB", "照片 · 微距 · 7 MB"), blurb: L("A macro of new fronds unrolling after rain.", "雨后新叶舒展开来的微距特写。")),
    ZoomTile(id: 3, symbol: "moon.stars.fill", colors: [Palette.violet, Color(hex: 0x241B5C)], title: L("Night Sky", "星夜"),
             meta: L("Photo · 30 s exposure", "照片 · 30 秒曝光"), blurb: L("The Milky Way rising above the ridge line.", "银河从山脊线上方缓缓升起。")),
    ZoomTile(id: 4, symbol: "water.waves", colors: [Palette.sky, Palette.mint], title: L("Tide Pools", "潮汐池"),
             meta: L("Photo · 4K · 10 MB", "照片 · 4K · 10 MB"), blurb: L("Low tide reveals a tiny world between rocks.", "退潮后，礁石间露出一个微小的世界。")),
    ZoomTile(id: 5, symbol: "flame.fill", colors: [Palette.coral, Palette.pink], title: L("Campfire", "篝火"),
             meta: L("Video · 0:42", "视频 · 0:42"), blurb: L("Sparks drifting up into a cold autumn night.", "火星飘进寒冷的秋夜。")),
]

private let zoomStageSpace = "morph.native-zoom.stage"

private struct NativeZoomDemo: View {
    let ctx: DemoContext
    @State private var shown = 0
    @State private var open: CGFloat = 0
    @State private var drag: CGSize = .zero
    @State private var frames: [Int: CGRect] = [:]
    @State private var stage: CGSize = .zero
    @State private var autoIndex = 0

    private var lift: CGFloat { min(max(drag.width, drag.height, 0) / 320, 1) }

    var body: some View {
        ZStack {
            ZoomGridScreen(ctx: ctx, hidden: open > 0 ? shown : nil, onTap: present) { id, rect in
                frames[id] = rect
            }
            Color.black
                .opacity(0.3 * Double(open))
                .allowsHitTesting(false)
            page
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .coordinateSpace(.named(zoomStageSpace))
        .onGeometryChange(for: CGSize.self) { $0.size } action: { stage = $0 }
        .autoplay(ctx.isPreview, every: 2.2) {
            if open > 0 {
                close()
            } else {
                present(zoomTiles[autoIndex % zoomTiles.count].id)
                autoIndex += 2
            }
        }
    }

    private var page: some View {
        let tile = zoomTiles[shown % zoomTiles.count]
        return ZoomDetailScreen(tile: tile, language: ctx.language, onClose: close)
            .modifier(ZoomPresentModifier(
                progress: open, lift: lift, source: frames[shown] ?? .zero,
                stage: stage, corner: ctx.cg("corner"), tile: tile
            ))
            .scaleEffect(1 - lift * 0.3)
            .offset(x: drag.width * 0.6, y: drag.height * 0.6)
            .allowsHitTesting(open > 0.5)
            .gesture(dismissDrag)
    }

    private var dismissDrag: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { drag = $0.translation }
            .onEnded { value in
                let flick = max(value.predictedEndTranslation.width, value.predictedEndTranslation.height)
                if lift > 0.33 || flick > 420 {
                    close()
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { drag = .zero }
                }
            }
    }

    private func present(_ id: Int) {
        guard open == 0, frames[id] != nil else { return }
        shown = id
        Haptics.tap(.soft)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) { open = 1 }
    }

    private func close() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
            open = 0
            drag = .zero
        }
    }
}

/// Places the full-size page inside the source tile's rect at progress 0 and full-stage at 1.
private struct ZoomPresentModifier: ViewModifier, Animatable {
    var progress: CGFloat
    var lift: CGFloat
    let source: CGRect
    let stage: CGSize
    let corner: CGFloat
    let tile: ZoomTile

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(progress, lift) }
        set {
            progress = newValue.first
            lift = newValue.second
        }
    }

    func body(content: Content) -> some View {
        let p = progress
        let w = source.width + (stage.width - source.width) * p
        let h = source.height + (stage.height - source.height) * p
        let x = source.midX + (stage.width / 2 - source.midX) * p
        let y = source.midY + (stage.height / 2 - source.midY) * p
        let s = stage.width > 0 ? w / stage.width : 1
        let radius = corner * (1 - p) + 34 * lift
        return content
            .frame(width: stage.width, height: stage.height)
            .scaleEffect(s, anchor: .top)
            .frame(width: w, height: h, alignment: .top)
            .overlay {
                ZoomTileArt(tile: tile, symbolSize: 30 + 34 * p)
                    .opacity(Double(max(0, 1 - p * 2.2)))
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: .black.opacity(0.22 * Double(lift)), radius: 24, y: 12)
            .position(x: x, y: y)
            .opacity(p > 0.001 ? 1 : 0)
    }
}

private struct ZoomTilePressStyle: ButtonStyle {
    let scale: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

private struct ZoomGridScreen: View {
    let ctx: DemoContext
    let hidden: Int?
    let onTap: (Int) -> Void
    let onFrame: (Int, CGRect) -> Void

    private var columnCount: Int { ctx.int("columns") == 0 ? 2 : 3 }

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: columnCount)
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(ctx.language == .zh ? "相簿" : "Albums")
                    .font(.title2.weight(.bold))
                DemoHint(text: L("Tap a tile · pull down or swipe right to go back", "点击图块 · 下拉或右滑返回"), ctx: ctx)
            }
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(zoomTiles) { tile in
                    tileButton(tile)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func tileButton(_ tile: ZoomTile) -> some View {
        // Two columns use landscape tiles so all three rows fit the 340 pt preview and the detail stage.
        let ratio: CGFloat = columnCount == 2 ? 1.8 : 1
        return Button { onTap(tile.id) } label: {
            ZoomTileArt(tile: tile, symbolSize: columnCount == 2 ? 34 : 26)
                .aspectRatio(ratio, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: ctx.cg("corner"), style: .continuous))
        }
        .buttonStyle(ZoomTilePressStyle(scale: ctx.cg("press")))
        .opacity(hidden == tile.id ? 0 : 1)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(zoomStageSpace)) } action: { onFrame(tile.id, $0) }
    }
}

private struct ZoomTileArt: View {
    let tile: ZoomTile
    let symbolSize: CGFloat

    var body: some View {
        ZStack {
            LinearGradient(colors: tile.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: tile.symbol)
                .font(.system(size: symbolSize, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
        }
    }
}

private struct ZoomDetailScreen: View {
    let tile: ZoomTile
    let language: AppLanguage
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZoomTileArt(tile: tile, symbolSize: 64)
                .frame(height: 170)
                .overlay(alignment: .topLeading) {
                    Button(action: onClose) {
                        Image(systemName: "chevron.down")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(.black.opacity(0.25), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(12)
                }
            VStack(alignment: .leading, spacing: 4) {
                Text(tile.title, language)
                    .font(.title3.weight(.bold))
                Text(tile.meta, language)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 18)
            Text(tile.blurb, language)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 18)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Palette.elevated)
    }
}
