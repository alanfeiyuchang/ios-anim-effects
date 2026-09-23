import SwiftUI

extension Effect {
    static let scrollHidingHeader = Effect(
        id: "scroll.hiding-header",
        category: .scroll,
        interaction: .scroll,
        name: L("Hide-on-Scroll Bars", "滚动隐藏栏"),
        summary: L("The header and tab bar slide away while you read down and spring back the moment you scroll up.", "向下阅读时头部与标签栏滑走，一向上滚动就立刻弹回。"),
        prompt: L(
            "A feed with a 56 pt frosted header (title, avatar and filter chips) on top and a floating 58 pt capsule tab bar at the bottom. Once the feed has scrolled more than 60 pt, scrolling down by more than 6 pt hides both bars: the header slides up out of view and the tab bar sinks 90 pt, each on a snappy spring (response 0.35 s, damping 0.82), with the tab bar trailing by 50 ms. The instant the reader scrolls up by the same amount, both spring back, and they are always shown near the top. A hairline divider under the header fades in once content passes beneath it. Direction-aware, unobtrusive and fast, like Safari and most social feeds.",
            "一个信息流，顶部是 56 pt 高的磨砂头部（标题、头像与筛选标签），底部悬浮一条 58 pt 高的胶囊标签栏。信息流滚动超过 60 pt 后，只要向下滚动超过 6 pt，两条栏就会隐藏：头部向上滑出视野，标签栏下沉 90 pt，各自使用干脆的弹簧（响应 0.35 秒、阻尼 0.82），标签栏比头部晚 50 毫秒。读者一旦向上滚动同样的距离，两者立即弹回；接近顶部时则始终显示。内容滑到头部下方后，头部下沿的细分隔线随之淡入。感知方向、不打扰、反应迅速，就像 Safari 和大多数社交信息流。"
        ),
        implementation: L(
            "onScrollGeometryChange reports the content offset; the action compares it with an anchor offset to accumulate the scroll direction, toggles a hidden flag past the threshold, and both bars offset with springs (the tab bar's delayed).",
            "onScrollGeometryChange 报告内容偏移；回调将其与锚点偏移比较以累计滚动方向，超过阈值即切换隐藏标志，两条栏随之以弹簧偏移（标签栏的动画带延迟）。"
        ),
        apis: ["onScrollGeometryChange", "ScrollPosition", "spring(response:dampingFraction:)", "Material", "overlay(alignment:)"],
        tags: ["header", "hide on scroll", "tab bar", "direction", "头部", "滚动隐藏", "标签栏", "方向感知"],
        params: [
            .slider("threshold", L("Direction threshold", "方向阈值"), 2...30, default: 6, step: 1, decimals: 0, unit: "pt"),
            .toggle("tabBar", L("Hide tab bar too", "同时隐藏标签栏"), default: true),
        ]
    ) { ctx in
        ScrollHidingHeaderDemo(ctx: ctx)
    }
}

private struct ScrollHidingHeaderDemo: View {
    let ctx: DemoContext
    @State private var position = ScrollPosition(edge: .top)
    @State private var hidden = false
    @State private var offset: CGFloat = 0
    /// Offset where the current scroll direction started.
    @State private var anchor: CGFloat = 0
    @State private var step = 0

    private let headerHeight: CGFloat = 56

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(0..<16, id: \.self) { i in
                    ScrollKitRow(index: i + 2, language: ctx.language)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, headerHeight + 10)
            .padding(.bottom, 90)
        }
        .scrollIndicators(.hidden)
        .scrollPosition($position)
        .onScrollGeometryChange(for: CGFloat.self, of: { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        }, action: { _, newValue in
            track(newValue)
        })
        .overlay(alignment: .top) {
            ScrollHidingHeaderBar(scrolled: offset > 4, language: ctx.language)
                .frame(height: headerHeight)
                .offset(y: hidden ? -headerHeight - 12 : 0)
                .animation(.spring(response: 0.35, dampingFraction: 0.82), value: hidden)
        }
        .overlay(alignment: .bottom) {
            ScrollHidingTabBar()
                .padding(.bottom, 14)
                .offset(y: hidden && ctx.bool("tabBar") ? 90 : 0)
                .animation(.spring(response: 0.35, dampingFraction: 0.82).delay(0.05), value: hidden)
        }
        .clipped()
        .autoplay(ctx.isPreview, every: 1.4) { autoScroll() }
    }

    private func track(_ newOffset: CGFloat) {
        offset = newOffset
        let threshold = ctx.cg("threshold")
        if newOffset < 60 {
            if hidden { hidden = false }
            anchor = newOffset
            return
        }
        let delta = newOffset - anchor
        if delta > threshold {
            if !hidden { hidden = true }
            anchor = newOffset
        } else if delta < -threshold {
            if hidden { hidden = false }
            anchor = newOffset
        } else if (hidden && delta > 0) || (!hidden && delta < 0) {
            // Keep the anchor at the extreme of the current direction.
            anchor = newOffset
        }
    }

    private func autoScroll() {
        let targets: [CGFloat] = [260, 520, 420, 700, 560, 0]
        let target = targets[step % targets.count]
        step += 1
        withAnimation(.smooth(duration: 1.0)) {
            position.scrollTo(y: target)
        }
    }
}

private struct ScrollHidingHeaderBar: View {
    let scrolled: Bool
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 10) {
            ScrollKitIcon(index: 6, size: 30)
                .clipShape(Circle())
            Text(L("Following", "关注"), language)
                .font(.headline)
            Spacer(minLength: 0)
            ForEach(0..<2, id: \.self) { i in
                Text(i == 0 ? L("All", "全部") : L("Photos", "照片"), language)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(i == 0 ? Color.white : Color.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(i == 0 ? AnyShapeStyle(Palette.primary) : AnyShapeStyle(Color.primary.opacity(0.08)), in: Capsule())
            }
        }
        .padding(.horizontal, 16)
        .frame(maxHeight: .infinity)
        .background(.regularMaterial)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(height: 0.5)
                .opacity(scrolled ? 1 : 0)
                .animation(.easeOut(duration: 0.2), value: scrolled)
        }
    }
}

private struct ScrollHidingTabBar: View {
    private let symbols = ["house.fill", "magnifyingglass", "plus.app.fill", "bell.fill", "person.crop.circle"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(symbols.indices, id: \.self) { i in
                Image(systemName: symbols[i])
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(i == 0 ? AnyShapeStyle(Palette.primary) : AnyShapeStyle(Color.secondary))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(width: 260, height: 58)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(0.14), radius: 14, y: 6)
    }
}
