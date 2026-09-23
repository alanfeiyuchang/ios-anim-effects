import SwiftUI

extension Effect {
    static let navigationPageDots = Effect(
        id: "navigation.page-dots",
        category: .navigation,
        interaction: .scroll,
        name: L("Expanding Page Dots", "伸展页码指示器"),
        summary: L(
            "Page-indicator dots that stretch, crawl or swell continuously with the swipe.",
            "随滑动连续伸展、蠕动或膨胀的页码圆点。"
        ),
        prompt: L(
            "A horizontally paged carousel of gradient cards with a row of 8 pt page dots beneath. The indicator is bound to the live scroll offset, not the settled page: in Stretch mode the active dot widens into a 26 pt capsule and hands that width to its neighbor proportionally as the user drags, color and opacity blending with it; in Worm mode a single capsule crawls between dots — its leading edge races ahead during the first half of the swipe and its trailing edge catches up in the second; in Scale mode dots swell to 160%. Because it tracks the finger 1:1 and settles with the paging spring, it feels physically connected to the content.",
            "一个水平分页的渐变卡片轮播，下方是一排 8pt 的页码圆点。指示器绑定实时滚动偏移，而不是停稳后的页码：在「伸展」模式下，当前圆点拉宽为 26pt 的胶囊，并随手指拖动按比例把宽度「交接」给相邻圆点，颜色与透明度同步混合；在「蠕虫」模式下，一个胶囊在圆点间爬行——滑动前半段头部先冲出去，后半段尾部再追上；在「缩放」模式下圆点膨胀到 160%。由于它 1:1 跟随手指并随分页弹簧落定，指示器与内容在物理上紧密相连。"
        ),
        implementation: L(
            "A paging ScrollView with containerRelativeFrame pages reports contentOffset.x / width through onScrollGeometryChange; every dot derives its width, scale and tint from its distance to that fractional page.",
            "使用 containerRelativeFrame 分页的 ScrollView，通过 onScrollGeometryChange 输出 contentOffset.x / 宽度 的连续页码；每个圆点根据与该小数页码的距离计算宽度、缩放与颜色。"
        ),
        apis: ["scrollTargetBehavior(.paging)", "containerRelativeFrame", "onScrollGeometryChange", "scrollPosition(id:)"],
        tags: ["page control", "dots", "indicator", "carousel", "页码", "圆点", "指示器", "轮播"],
        params: [
            .choice("style", L("Style", "样式"), [L("Stretch", "伸展"), L("Worm", "蠕虫"), L("Scale", "缩放")], default: 0),
            .slider("width", L("Active width", "选中宽度"), 14...40, default: 26, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        PageDotsDemo(ctx: ctx)
    }
}

private let dotPages: [(String, [Color])] = [
    ("sparkles", [Palette.indigo, Palette.violet]),
    ("leaf.fill", [Palette.mint, Palette.sky]),
    ("flame.fill", [Palette.amber, Palette.coral]),
    ("heart.fill", [Palette.pink, Palette.violet]),
    ("moon.stars.fill", [Palette.blue, Color(hex: 0x241B5C)]),
]

private struct PageDotsDemo: View {
    let ctx: DemoContext
    @State private var page: Int? = 0
    @State private var progress: CGFloat = 0

    var body: some View {
        VStack(spacing: 22) {
            carousel
            PageIndicator(
                count: dotPages.count,
                progress: progress,
                style: ctx.int("style"),
                activeWidth: ctx.cg("width")
            )
            DemoHint(text: L("Swipe the cards", "左右滑动卡片"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.4) {
            withAnimation(.smooth(duration: 0.6)) {
                page = ((page ?? 0) + 1) % dotPages.count
            }
        }
    }

    private var carousel: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(0..<dotPages.count, id: \.self) { index in
                    pageCard(index)
                        .padding(.horizontal, 32)
                        .containerRelativeFrame(.horizontal)
                        .id(index)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .scrollPosition(id: $page)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.containerSize.width > 0 ? geometry.contentOffset.x / geometry.containerSize.width : 0
        } action: { _, newValue in
            progress = newValue
        }
        .frame(height: 234)
    }

    private func pageCard(_ index: Int) -> some View {
        let spec = dotPages[index]
        return RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(LinearGradient(colors: spec.1, startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                Image(systemName: spec.0)
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
            }
            .shadow(color: spec.1[0].opacity(0.3), radius: 14, y: 8)
            .padding(.vertical, 24) // room for the drop shadow inside the scroll view's clip
    }
}

private struct PageIndicator: View {
    let count: Int
    let progress: CGFloat
    let style: Int
    let activeWidth: CGFloat

    private let dot: CGFloat = 8
    private let spacing: CGFloat = 8

    var body: some View {
        switch style {
        case 1: worm
        case 2: scaled
        default: stretched
        }
    }

    private func weight(_ index: Int) -> CGFloat {
        max(0, 1 - abs(progress - CGFloat(index)))
    }

    private var stretched: some View {
        HStack(spacing: spacing) {
            ForEach(0..<count, id: \.self) { index in
                let w = weight(index)
                Capsule()
                    .fill(Color.primary.opacity(0.18))
                    .overlay(Capsule().fill(Palette.indigo).opacity(Double(w)))
                    .frame(width: dot + (activeWidth - dot) * w, height: dot)
            }
        }
    }

    private var scaled: some View {
        HStack(spacing: spacing + 4) {
            ForEach(0..<count, id: \.self) { index in
                let w = weight(index)
                Circle()
                    .fill(Color.primary.opacity(0.18))
                    .overlay(Circle().fill(Palette.indigo).opacity(Double(w)))
                    .frame(width: dot, height: dot)
                    .scaleEffect(1 + 0.6 * w)
            }
        }
    }

    private var worm: some View {
        let clamped = progress.clamped(to: 0...CGFloat(max(count - 1, 0)))
        let base = clamped.rounded(.down)
        let fraction = clamped - base
        let step = dot + spacing
        let leading = (base + max(0, fraction * 2 - 1)) * step
        let trailing = (base + min(1, fraction * 2)) * step + dot
        return ZStack(alignment: .leading) {
            HStack(spacing: spacing) {
                ForEach(0..<count, id: \.self) { _ in
                    Circle()
                        .fill(Color.primary.opacity(0.18))
                        .frame(width: dot, height: dot)
                }
            }
            Capsule()
                .fill(Palette.indigo)
                .frame(width: max(trailing - leading, dot), height: dot)
                .offset(x: leading)
        }
    }
}
