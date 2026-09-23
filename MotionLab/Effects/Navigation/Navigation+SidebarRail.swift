import SwiftUI

extension Effect {
    static let navigationSidebarRail = Effect(
        id: "navigation.sidebar-rail",
        category: .navigation,
        interaction: .tap,
        name: L("Expanding Sidebar Rail", "可展开侧边栏"),
        summary: L(
            "An icon rail widens into a labelled sidebar while the content beside it reflows.",
            "图标导航栏展开为带文字的侧边栏，旁边的内容随之重排。"
        ),
        prompt: L(
            "A compact 56 pt navigation rail of icons sits on the leading edge of an iPad-style window. Tapping the sidebar toggle widens it to 150 pt on a spring (response ≈0.45 s, damping ≈0.82) while the content column squeezes and its cards reflow in step; labels slide in from 8 pt left out of a 4 pt blur, cascading 30 ms per row top to bottom, and collapse instantly in reverse. The selection is a soft tinted rounded rectangle that glides between rows as one shape via matched geometry, the selected icon and label switch to the accent color, and the content header swaps with a blur-replace. A selection tick fires on each change. Orderly, spatial and calm — the rail never loses its icons, it only reveals words.",
            "iPad 风格窗口的左侧是一条 56 pt 宽的紧凑图标导航栏。点击侧边栏按钮，它以弹簧（响应约 0.45 秒、阻尼约 0.82）加宽到 150 pt，右侧内容列同步收窄、卡片随之重排；文字从左侧 8 pt 处、4 pt 模糊中滑入，自上而下每行错开 30 毫秒，收起时则反向立即消失。选中态是一块淡色圆角矩形，借助几何匹配作为同一个形状在各行之间滑行；选中的图标与文字切换为强调色，内容标题以模糊替换切换，每次切换都伴随选择触感。井然有序、有空间感、沉静——导航栏从不丢失图标，只是把文字展露出来。"
        ),
        implementation: L(
            "The rail's frame width animates between two values while each label carries its own delayed animation keyed on the expanded flag; the selection background uses a single matchedGeometryEffect id, and the content column is flexible so it reflows in the same transaction.",
            "导航栏的宽度在两个值之间动画，每个文字标签以展开状态为 key 带各自的延迟动画；选中背景使用同一个 matchedGeometryEffect ID，内容列为弹性宽度，在同一事务中随之重排。"
        ),
        apis: ["matchedGeometryEffect", "frame(width:)", "animation(_:value:)", "transition(.blurReplace)"],
        tags: ["sidebar", "navigation rail", "ipad", "expand", "侧边栏", "导航栏", "展开", "iPad"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.9, default: 0.45, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.82),
            .slider("stagger", L("Label stagger", "文字错开"), 0.0...0.08, default: 0.03, decimals: 3, unit: "s"),
        ]
    ) { ctx in
        SidebarRailDemo(ctx: ctx)
    }
}

private struct RailItem {
    let symbol: String
    let title: LocalizedText
    let colors: [Color]
}

private let railItems: [RailItem] = [
    RailItem(symbol: "house.fill", title: L("Home", "首页"), colors: [Palette.indigo, Palette.violet]),
    RailItem(symbol: "photo.on.rectangle", title: L("Library", "资料库"), colors: [Palette.amber, Palette.coral]),
    RailItem(symbol: "star.fill", title: L("Favorites", "收藏"), colors: [Palette.pink, Palette.violet]),
    RailItem(symbol: "clock.fill", title: L("Recents", "最近"), colors: [Palette.mint, Palette.sky]),
    RailItem(symbol: "trash.fill", title: L("Deleted", "已删除"), colors: [Color(hex: 0x8E8E93), Color(hex: 0x5A5A60)]),
]

private struct SidebarRailDemo: View {
    let ctx: DemoContext
    @Namespace private var ns
    @State private var expanded = false
    @State private var selected = 0
    @State private var tick = 0

    private var spring: Animation { .spring(response: ctx["response"], dampingFraction: ctx["damping"]) }
    private var railWidth: CGFloat { expanded ? 150 : 56 }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 26, style: .continuous)
        VStack(spacing: 14) {
            HStack(spacing: 0) {
                rail
                Rectangle()
                    .fill(Palette.stroke)
                    .frame(width: 1)
                content
            }
            .frame(width: 320, height: 280)
            .background(Palette.elevated)
            .clipShape(shape)
            .overlay(shape.strokeBorder(Palette.stroke))
            .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
            DemoHint(text: L("Tap the sidebar button or a row", "点击侧边栏按钮或任意一行"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.3) {
            tick += 1
            if tick % 3 == 1 { toggle() } else { select((selected + 1) % railItems.count) }
        }
    }

    // MARK: Rail

    private var rail: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: toggle) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 40, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.bottom, 6)
            ForEach(0..<railItems.count, id: \.self) { index in
                row(index)
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .frame(width: railWidth, alignment: .leading)
        .frame(maxHeight: .infinity)
        .background(Palette.surface)
        .clipped()
    }

    private func row(_ index: Int) -> some View {
        let item = railItems[index]
        let isSelected = selected == index
        return Button { select(index) } label: {
            HStack(spacing: 10) {
                Image(systemName: item.symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 24)
                Text(item.title, ctx.language)
                    .font(.subheadline.weight(isSelected ? .semibold : .medium))
                    .fixedSize()
                    .opacity(expanded ? 1 : 0)
                    .offset(x: expanded ? 0 : -8)
                    .blur(radius: expanded ? 0 : 4)
                    .animation(
                        expanded ? spring.delay(0.04 + Double(index) * ctx["stagger"]) : .easeOut(duration: 0.1),
                        value: expanded
                    )
            }
            .foregroundStyle(isSelected ? Palette.indigo : Color.secondary)
            .padding(.horizontal, 8)
            // A fixed frame (rail width minus padding) lets the fixed-size label overflow invisibly
            // while the selection background always matches the rail.
            .frame(width: railWidth - 16, height: 38, alignment: .leading)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(Palette.indigo.opacity(0.14))
                        .matchedGeometryEffect(id: "selection", in: ns)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Content

    private var content: some View {
        let item = railItems[selected]
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack(alignment: .leading) {
                    Text(item.title, ctx.language)
                        .font(.title3.weight(.bold))
                        .fixedSize()
                        .id(selected)
                        .transition(.blurReplace)
                }
                Spacer(minLength: 0)
                Image(systemName: "magnifyingglass")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 10) {
                tile(item, symbolIndex: 0)
                tile(item, symbolIndex: 1)
            }
            HStack(spacing: 10) {
                tile(item, symbolIndex: 2)
                tile(item, symbolIndex: 3)
            }
            PlaceholderLines(count: 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func tile(_ item: RailItem, symbolIndex: Int) -> some View {
        let symbols = ["photo.fill", "sparkles", "leaf.fill", "heart.fill"]
        return RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(
                LinearGradient(
                    colors: item.colors.map { $0.opacity(1 - 0.18 * Double(symbolIndex)) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 70)
            .frame(maxWidth: .infinity)
            .overlay {
                Image(systemName: symbols[symbolIndex % symbols.count])
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
    }

    // MARK: Actions

    private func toggle() {
        if !ctx.isPreview { Haptics.tap() }
        withAnimation(spring) { expanded.toggle() }
    }

    private func select(_ index: Int) {
        guard index != selected else { return }
        if !ctx.isPreview { Haptics.selection() }
        withAnimation(spring) { selected = index }
    }
}
