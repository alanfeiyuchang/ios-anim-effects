import SwiftUI

extension Effect {
    static let morphNativeZoom = Effect(
        id: "morph.native-zoom",
        category: .morph,
        interaction: .tap,
        name: L("Native Zoom Transition", "系统缩放转场"),
        summary: L(
            "iOS 18's built-in zoom push: a tile grows into its detail page and shrinks back home.",
            "iOS 18 原生缩放推入：图块放大成详情页，返回时再缩回原位。"
        ),
        prompt: L(
            "A grid of rounded gradient tiles inside a navigation stack. Tapping a tile pushes its detail page with the system zoom transition: the page grows out of the tile's exact frame and corner radius to fill the screen while the grid dims behind it, all on the system's fluid, interruptible spring. The detail — large artwork, title, metadata and a short description — is fully live during the motion. Going back reverses it into the same tile; the page can also be pulled down or swiped from the leading edge, following the finger and shrinking toward its source until release decides whether it completes or springs back. Native, continuous and physically anchored to where it came from.",
            "导航栈中排着一组圆角渐变图块。点击任意图块，以系统缩放转场推入详情页：页面从该图块的精确位置与圆角中“长”出来并铺满屏幕，背后的网格随之变暗，整个过程使用系统流畅、可随时打断的弹簧。详情页（大幅插图、标题、信息与简介）在运动过程中完全可交互。返回时反向缩回同一个图块；也可以向下拖拽或从左边缘右滑，页面跟手缩小并飞向来源图块，松手时再决定完成返回还是弹回原处。原生、连贯，始终与出发点保持物理关联。"
        ),
        implementation: L(
            "A local NavigationStack bound to a path array; each NavigationLink(value:) is tagged with matchedTransitionSource(id:in:), and the destination applies navigationTransition(.zoom(sourceID:in:)) with the same id and namespace. Previews push and pop by editing the path.",
            "舞台内的 NavigationStack 绑定路径数组；每个 NavigationLink(value:) 标注 matchedTransitionSource(id:in:)，目标页以相同 ID 与命名空间应用 navigationTransition(.zoom(sourceID:in:))。预览模式通过修改路径自动推入与返回。"
        ),
        apis: ["navigationTransition(.zoom(sourceID:in:))", "matchedTransitionSource(id:in:)", "NavigationStack(path:)", "navigationDestination(for:)", "@Namespace"],
        tags: ["zoom", "navigation", "hero", "ios 18", "缩放转场", "导航", "推入", "系统转场"],
        params: [
            .choice("columns", L("Columns", "列数"), [L("2", "2"), L("3", "3")], default: 1),
            .slider("corner", L("Tile corner radius", "图块圆角"), 4...28, default: 18, decimals: 0, unit: "pt"),
            .slider("spacing", L("Tile spacing", "图块间距"), 4...16, default: 10, decimals: 0, unit: "pt"),
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

private struct NativeZoomDemo: View {
    let ctx: DemoContext
    @Namespace private var zoom
    @State private var path: [Int] = []
    @State private var autoIndex = 0

    var body: some View {
        NavigationStack(path: $path) {
            ZoomGridScreen(ctx: ctx, namespace: zoom)
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: Int.self) { id in
                    ZoomDetailScreen(tile: zoomTiles[id % zoomTiles.count], language: ctx.language) {
                        path.removeAll()
                    }
                    .navigationTransition(.zoom(sourceID: id, in: zoom))
                    .toolbar(.hidden, for: .navigationBar)
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.2) {
            // Push and pop by editing the path; the system plays the zoom both ways.
            if path.isEmpty {
                path = [zoomTiles[autoIndex % zoomTiles.count].id]
                autoIndex += 2
            } else {
                path.removeAll()
            }
        }
    }
}

private struct ZoomGridScreen: View {
    let ctx: DemoContext
    let namespace: Namespace.ID

    private var columnCount: Int { ctx.int("columns") == 0 ? 2 : 3 }

    var body: some View {
        let spacing = ctx.cg("spacing")
        let columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(ctx.language == .zh ? "相簿" : "Albums")
                    .font(.title2.weight(.bold))
                DemoHint(text: L("Tap a tile · pull down or swipe right to go back", "点击图块 · 下拉或右滑返回"), ctx: ctx)
            }
            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(zoomTiles) { tile in
                    NavigationLink(value: tile.id) {
                        ZoomTileArt(tile: tile, symbolSize: columnCount == 2 ? 34 : 26)
                            .aspectRatio(1, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: ctx.cg("corner"), style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .matchedTransitionSource(id: tile.id, in: namespace)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.stage)
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
