import SwiftUI

extension Effect {
    static let scrollParallaxPager = Effect(
        id: "scroll.parallax-pager",
        category: .scroll,
        interaction: .scroll,
        name: L("Parallax Pager", "视差分页"),
        summary: L("Paging cards act as windows: the backdrop lags, the glyph drifts and the title races ahead.", "分页卡片像一扇扇窗：背景滞后、图形漂移、标题抢先滑出。"),
        prompt: L(
            "A pager of 250×250 pt cards with 28 pt corners and 12 pt gaps, snapping one card to the center with its neighbours peeking. Each card holds three depth layers that move at different speeds relative to the card: the oversized gradient backdrop counter-scrolls at 60% so it seems to stay behind the window, the big glyph drifts at 30%, and the title runs 25% ahead of the card while fading out over half a page. As a result every swipe reveals a different part of each backdrop and the layers visibly separate in depth. Paging uses view-aligned snapping; a thin progress capsule below fills continuously with the scroll. Rich, layered and cinematic.",
            "一组 250×250 pt、28 pt 圆角、间距 12 pt 的卡片分页排列，每次吸附一张到中央，两侧露出相邻卡片。每张卡片内有三个景深图层，相对卡片以不同速度移动：超大的渐变背景以 60% 反向滚动，看起来像停留在窗户后面；大图形以 30% 漂移；标题则比卡片多走 25%、抢先滑出，并在半页距离内淡出。因此每次滑动都会露出背景的不同部分，图层之间明显拉开景深。分页使用视图对齐吸附；下方一条细胶囊随滚动连续填充。丰富、有层次、电影感十足。"
        ),
        implementation: L(
            "The three layers each use visualEffect to read the card's distance from the viewport center (measured with onGeometryChange) and apply their own offset factor inside a clipped card; scrollTargetBehavior(.viewAligned) snaps, and onScrollGeometryChange drives the progress capsule.",
            "三个图层各自通过 visualEffect 读取卡片到视口中心的距离（视口宽度由 onGeometryChange 测得），在裁剪后的卡片内施加各自的偏移系数；scrollTargetBehavior(.viewAligned) 负责吸附，onScrollGeometryChange 驱动进度胶囊。"
        ),
        apis: ["visualEffect", "scrollTargetBehavior(.viewAligned)", "scrollTargetLayout", "onScrollGeometryChange", "contentMargins"],
        tags: ["parallax", "pager", "depth", "carousel", "视差", "分页", "景深", "轮播"],
        params: [
            .slider("backdrop", L("Backdrop lag", "背景滞后"), 0...1, default: 0.6),
            .slider("title", L("Title lead", "标题超前"), 0...0.6, default: 0.25),
        ]
    ) { ctx in
        ScrollParallaxPagerDemo(ctx: ctx)
    }
}

private let scrollParallaxPagerSpace = "scroll.parallax-pager"

private struct ScrollParallaxPagerDemo: View {
    let ctx: DemoContext
    @State private var current: Int? = 0
    @State private var width: CGFloat = 340
    @State private var progress: CGFloat = 0
    @State private var direction = 1

    private let count = 6
    private let side: CGFloat = 250
    private let spacing: CGFloat = 12

    var body: some View {
        VStack(spacing: 18) {
            pager
            Capsule()
                .fill(Color.primary.opacity(0.1))
                .frame(width: 120, height: 4)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Palette.aurora)
                        .frame(width: max(120 * progress, 4), height: 4)
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.6) { advance() }
    }

    private var pager: some View {
        let viewport = width
        let pitch = side + spacing
        let backdrop = ctx.cg("backdrop")
        let lead = ctx.cg("title")
        return ScrollView(.horizontal) {
            LazyHStack(spacing: spacing) {
                ForEach(0..<count, id: \.self) { i in
                    ScrollParallaxWindow(index: i, language: ctx.language, side: side, viewport: viewport, pitch: pitch, backdrop: backdrop, lead: lead)
                        .id(i)
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, max((width - side) / 2, 0), for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $current, anchor: .center)
        .scrollIndicators(.hidden)
        .coordinateSpace(.named(scrollParallaxPagerSpace))
        .onScrollGeometryChange(for: CGFloat.self, of: { geometry in
            let range = geometry.contentSize.width - geometry.containerSize.width + geometry.contentInsets.leading + geometry.contentInsets.trailing
            guard range > 0 else { return 0 }
            let offset = geometry.contentOffset.x + geometry.contentInsets.leading
            return (offset / range).clamped(to: 0...1)
        }, action: { _, newValue in
            progress = newValue
        })
        .frame(height: side + 10)
        .onGeometryChange(for: CGFloat.self, of: { proxy in proxy.size.width }, action: { newWidth in
            width = newWidth
        })
    }

    private func advance() {
        let now = current ?? 0
        if now + direction >= count || now + direction < 0 { direction = -direction }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.9)) {
            current = now + direction
        }
    }
}

/// One card with three layers, each shifted by its own share of the card's distance from center.
private struct ScrollParallaxWindow: View {
    let index: Int
    let language: AppLanguage
    let side: CGFloat
    let viewport: CGFloat
    let pitch: CGFloat
    let backdrop: CGFloat
    let lead: CGFloat

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            backdropLayer
            glyphLayer
            titleLayer
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Color.white.opacity(0.18), lineWidth: 1))
    }

    private var backdropLayer: some View {
        let viewport = self.viewport
        let factor = backdrop
        return LinearGradient(colors: ScrollKit.colors(index + 1) + ScrollKit.colors(index + 3), startPoint: .leading, endPoint: .trailing)
            .overlay {
                HStack(spacing: 34) {
                    ForEach(0..<5, id: \.self) { k in
                        Circle()
                            .fill(Color.white.opacity(0.1 + Double(k % 3) * 0.06))
                            .frame(width: 40 + CGFloat(k % 2) * 30)
                    }
                }
            }
            .frame(width: side * 2.2, height: side)
            .visualEffect { content, proxy in
                let distance: CGFloat = proxy.frame(in: .named(scrollParallaxPagerSpace)).midX - viewport / 2
                return content.offset(x: -distance * factor)
            }
            .frame(width: side, height: side)
    }

    private var glyphLayer: some View {
        let viewport = self.viewport
        return Image(systemName: ScrollKit.symbol(index + 2))
            .font(.system(size: 76, weight: .semibold))
            .foregroundStyle(Color.white.opacity(0.95))
            .shadow(color: .black.opacity(0.18), radius: 10, y: 6)
            .frame(width: side, height: side)
            .visualEffect { content, proxy in
                let distance: CGFloat = proxy.frame(in: .named(scrollParallaxPagerSpace)).midX - viewport / 2
                return content.offset(x: -distance * 0.3, y: -16)
            }
    }

    private var titleLayer: some View {
        let viewport = self.viewport
        let pitch = max(self.pitch, 1)
        let lead = self.lead
        return VStack(alignment: .leading, spacing: 2) {
            Text(ScrollKit.title(index + 2), language)
                .font(.title3.weight(.bold))
            Text(ScrollKit.subtitle(index + 2), language)
                .font(.caption.weight(.medium))
                .opacity(0.85)
        }
        .foregroundStyle(.white)
        .padding(18)
        // Fill the card so the layer's midX is the card's center.
        .frame(width: side, height: side, alignment: .bottomLeading)
        .visualEffect { content, proxy in
            let distance: CGFloat = proxy.frame(in: .named(scrollParallaxPagerSpace)).midX - viewport / 2
            let fade: Double = 1 - Double(min(abs(distance) / (pitch / 2), 1))
            return content
                .offset(x: distance * lead)
                .opacity(fade)
        }
    }
}
