import SwiftUI

extension Effect {
    static let morphListGrid = Effect(
        id: "morph.list-grid",
        category: .morph,
        interaction: .state,
        name: L("List ↔ Grid Morph", "列表 ↔ 网格形变"),
        summary: L(
            "Rows reflow into tiles and back, every item traveling to its new slot.",
            "列表行与网格瓦片互相重排，每个元素都飞向新的位置。"
        ),
        prompt: L(
            "A collection of six items can be shown as a list (38 pt rows: icon, title, subtitle) or a 3-column grid of square-ish tiles. Toggling the layout morphs every item in place: each one travels from its old frame to its new one while its own contents re-flow from a horizontal to a vertical stack — the icon grows from 28 to 36 pt and the corner radius shifts from 14 to 18 pt. Items move on a spring (response ≈0.5 s, damping ≈0.8) with a ~25 ms cascade in reading order, so the change ripples across the collection. The toggle glyph swaps list ↔ grid with a symbol replace and a selection haptic. Nothing fades — objects visibly keep their identity.",
            "六个条目可以显示为列表（高 38pt 的行：图标、标题、副标题），也可以显示为三列近方形的网格瓦片。切换布局时每个条目都原地形变：从旧位置移动到新位置，同时内部内容从横向排列重排为纵向排列——图标从 28pt 放大到 36pt，圆角从 14pt 过渡到 18pt。条目以弹簧（响应约 0.5 秒、阻尼约 0.8）移动，并按阅读顺序错开约 25 毫秒，形成波浪式的级联。切换按钮的图标以符号替换动画在列表与网格之间转换，并伴随选择触觉。全程没有淡入淡出——每个对象都清晰地保持自身身份。"
        ),
        implementation: L(
            "A custom Layout places items in N columns; changing its column count inside withAnimation animates every subview's frame, while each item switches between HStackLayout and VStackLayout through AnyLayout to keep child identity.",
            "自定义 Layout 按 N 列摆放条目，在 withAnimation 中修改列数即可动画所有子视图的外框；每个条目内部通过 AnyLayout 在 HStackLayout 与 VStackLayout 间切换以保持子视图身份。"
        ),
        apis: ["Layout", "AnyLayout", "HStackLayout", "VStackLayout", "contentTransition(.symbolEffect(.replace))"],
        tags: ["layout", "grid", "list", "reflow", "布局切换", "网格", "列表", "重排"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.2...1.0, default: 0.5, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.8),
            .slider("cascade", L("Cascade", "级联错开"), 0.0...0.08, default: 0.025, decimals: 3, unit: "s"),
        ]
    ) { ctx in
        ListGridDemo(ctx: ctx)
    }
}

private struct LibraryItem {
    let symbol: String
    let color: Color
    let title: LocalizedText
    let subtitle: LocalizedText
}

private let libraryItems: [LibraryItem] = [
    LibraryItem(symbol: "music.note", color: Palette.pink, title: L("Music", "音乐"), subtitle: L("128 songs", "128 首歌曲")),
    LibraryItem(symbol: "photo.fill", color: Palette.amber, title: L("Photos", "照片"), subtitle: L("2,341 items", "2,341 项")),
    LibraryItem(symbol: "book.fill", color: Palette.coral, title: L("Books", "图书"), subtitle: L("12 titles", "12 本")),
    LibraryItem(symbol: "film.fill", color: Palette.indigo, title: L("Films", "影片"), subtitle: L("36 movies", "36 部")),
    LibraryItem(symbol: "mic.fill", color: Palette.mint, title: L("Podcasts", "播客"), subtitle: L("9 shows", "9 个节目")),
    LibraryItem(symbol: "doc.fill", color: Palette.sky, title: L("Files", "文件"), subtitle: L("420 MB", "420 MB")),
]

private struct ListGridDemo: View {
    let ctx: DemoContext
    @State private var isGrid = false

    private var spring: Animation { .spring(response: ctx["response"], dampingFraction: ctx["damping"]) }

    var body: some View {
        VStack(spacing: 14) {
            CollectionLayout(columns: isGrid ? 3 : 1, itemHeight: isGrid ? 104 : 38, spacing: isGrid ? 8 : 4) {
                ForEach(0..<libraryItems.count, id: \.self) { index in
                    LibraryCell(item: libraryItems[index], isGrid: isGrid, language: ctx.language)
                        .animation(spring.delay(Double(index) * ctx["cascade"]), value: isGrid)
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            toggleButton
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.8) { toggle() }
    }

    private var toggleButton: some View {
        Button(action: toggle) {
            Label(
                isGrid ? (ctx.language == .zh ? "列表" : "List") : (ctx.language == .zh ? "网格" : "Grid"),
                systemImage: isGrid ? "list.bullet" : "square.grid.3x2.fill"
            )
            .font(.subheadline.weight(.semibold))
            .contentTransition(.symbolEffect(.replace))
            .padding(.horizontal, 18)
            .frame(height: 40)
            .demoGlass(Capsule(), material: .thinMaterial)
            .overlay(Capsule().strokeBorder(Palette.stroke))
        }
        .buttonStyle(.plain)
    }

    private func toggle() {
        if !ctx.isPreview { Haptics.selection() }
        withAnimation(spring) { isGrid.toggle() }
    }
}

private struct LibraryCell: View {
    let item: LibraryItem
    let isGrid: Bool
    let language: AppLanguage

    var body: some View {
        let layout = isGrid
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))
        layout {
            Image(systemName: item.symbol)
                .font(.system(size: isGrid ? 16 : 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: isGrid ? 36 : 28, height: isGrid ? 36 : 28)
                .background(item.color.gradient, in: RoundedRectangle(cornerRadius: isGrid ? 10 : 8, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title, language)
                    .font(.subheadline.weight(.semibold))
                Text(item.subtitle, language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, isGrid ? 10 : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.elevated, in: RoundedRectangle(cornerRadius: isGrid ? 18 : 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: isGrid ? 18 : 14, style: .continuous).strokeBorder(Palette.stroke))
    }
}

/// Places subviews row by row in `columns` equal-width columns of fixed height.
private struct CollectionLayout: Layout {
    var columns: Int
    var itemHeight: CGFloat
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 300
        let rows = (subviews.count + max(columns, 1) - 1) / max(columns, 1)
        let height = CGFloat(rows) * itemHeight + CGFloat(max(rows - 1, 0)) * spacing
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let cols = max(columns, 1)
        let cellWidth = (bounds.width - CGFloat(cols - 1) * spacing) / CGFloat(cols)
        for (index, subview) in subviews.enumerated() {
            let column = index % cols
            let row = index / cols
            let origin = CGPoint(
                x: bounds.minX + CGFloat(column) * (cellWidth + spacing),
                y: bounds.minY + CGFloat(row) * (itemHeight + spacing)
            )
            subview.place(at: origin, anchor: .topLeading, proposal: ProposedViewSize(width: cellWidth, height: itemHeight))
        }
    }
}
