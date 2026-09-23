import SwiftUI

extension Effect {
    static let scrollPagingCarousel = Effect(
        id: "scroll.paging-carousel",
        category: .scroll,
        interaction: .scroll,
        name: L("Snapping Carousel", "吸附轮播"),
        summary: L("Center-snapping cards whose neighbours lean and dip, with a liquid page indicator scrubbed by the scroll.", "居中吸附的卡片轮播，两侧卡片倾斜下沉，液态页码指示器随滚动拉伸。"),
        prompt: L(
            "A horizontal carousel of tall 210×250 pt gradient cards with 28 pt corners centres one card, with neighbours peeking in from both sides. As a card leaves the centre it scales continuously toward 86%, fades to 65% opacity, leans up to 8° away from the middle around its bottom edge and dips 10 pt, so the neighbours read like cards propped on a shelf; releasing a swipe snaps the nearest card to the exact centre with the system deceleration curve. Beneath, a liquid page indicator of 7 pt dots is scrubbed directly by the scroll: between pages the active gradient capsule stretches its trailing edge to the next dot first, then pulls its leading edge after it. Focused, weighty and effortless.",
            "一排210×250 pt、28 pt圆角的竖版渐变卡片横向轮播，一张居中，左右露出相邻卡片。卡片离开中心时连续缩小到86%、淡到65%不透明度，并以底边为轴向外倾斜最多8°、下沉10 pt，两侧卡片像斜靠在架子上；松手后，最近的一张以系统减速曲线精确吸附到正中。下方是由7 pt圆点组成的液态页码指示器，直接由滚动驱动：翻页途中，当前的渐变胶囊先把前缘伸到下一颗圆点，再把后缘拉过去。聚焦、有分量、毫不费力。"
        ),
        implementation: L(
            "A LazyHStack marked scrollTargetLayout with scrollTargetBehavior(.viewAligned) and centered contentMargins; visualEffect scales, tilts and dips cards by their signed distance from center, and onScrollGeometryChange turns the offset into a continuous page position that shapes the liquid indicator.",
            "LazyHStack 标记 scrollTargetLayout，配合 scrollTargetBehavior(.viewAligned) 与居中的 contentMargins；visualEffect 按到中心的有符号距离缩放、倾斜并下沉卡片，onScrollGeometryChange 把偏移换算为连续页码位置，塑造液态指示器。"
        ),
        apis: ["scrollTargetBehavior(.viewAligned)", "scrollTargetLayout", "scrollPosition(id:)", "visualEffect", "onScrollGeometryChange"],
        tags: ["carousel", "paging", "snap", "page control", "轮播", "分页", "吸附", "指示器"],
        params: [
            .slider("sideScale", L("Side scale", "两侧缩放"), 0.7...1.0, default: 0.86),
            .slider("spacing", L("Spacing", "间距"), 0...30, default: 14, step: 1, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        ScrollPagingDemo(ctx: ctx)
    }
}

private let scrollPagingSpace = "scroll.paging-carousel"

private struct ScrollPagingDemo: View {
    let ctx: DemoContext
    @State private var current: Int? = 1
    @State private var width: CGFloat = 340
    @State private var direction = 1
    /// Continuous page position (0 = first card centered), drives the liquid page indicator.
    @State private var progress: CGFloat = 1

    private let count = 6
    private let cardWidth: CGFloat = 210

    var body: some View {
        VStack(spacing: 18) {
            carousel
            ScrollPageDots(count: count, progress: progress)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.6) { advance() }
    }

    private var carousel: some View {
        let sideScale = ctx["sideScale"]
        let spacing = ctx.cg("spacing")
        let viewport = width
        let pitch = cardWidth + spacing
        return ScrollView(.horizontal) {
            LazyHStack(spacing: spacing) {
                ForEach(0..<count, id: \.self) { i in
                    ScrollKitArt(index: i + 2, language: ctx.language)
                        .frame(width: cardWidth, height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .visualEffect { content, proxy in
                            let mid = proxy.frame(in: .named(scrollPagingSpace)).midX
                            let d = ((mid - viewport / 2) / pitch).clamped(to: -1...1)
                            let t = abs(d)
                            // Neighbours lean away from the center (±8°) and dip 10 pt per step.
                            return content
                                .scaleEffect(1 - (1 - CGFloat(sideScale)) * t)
                                .rotationEffect(.degrees(Double(d) * 8), anchor: .bottom)
                                .offset(y: 10 * t)
                                .opacity(1 - Double(t) * 0.35)
                        }
                        .id(i)
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, max((width - cardWidth) / 2, 0), for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $current, anchor: .center)
        .onScrollGeometryChange(for: CGFloat.self, of: { geometry in
            (geometry.contentOffset.x + geometry.contentInsets.leading) / max(pitch, 1)
        }, action: { _, newValue in
            progress = newValue
        })
        .scrollIndicators(.hidden)
        // Measure cards against the scroll view's own bounds: with contentMargins
        // the `.scrollView` space is offset by the leading margin, which left the
        // centered card slightly shrunk and dimmed.
        .coordinateSpace(.named(scrollPagingSpace))
        .frame(height: 260)
        .onGeometryChange(for: CGFloat.self, of: { proxy in proxy.size.width }, action: { newWidth in
            width = newWidth
        })
    }

    private func advance() {
        let now = current ?? 0
        if now + direction >= count || now + direction < 0 { direction = -direction }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.88)) {
            current = now + direction
        }
    }
}

/// Liquid page indicator: the active capsule is scrubbed by the scroll position. Between two pages its
/// leading edge waits while the trailing edge races ahead, then the leading edge catches up.
private struct ScrollPageDots: View {
    let count: Int
    let progress: CGFloat

    private let dot: CGFloat = 7
    private let gap: CGFloat = 6

    var body: some View {
        let step = dot + gap
        let clamped = progress.clamped(to: 0...CGFloat(max(count - 1, 0)))
        let page = floor(clamped)
        let f = clamped - page
        let lead = page * step + max(0, f * 2 - 1) * step
        let trail = page * step + dot + min(1, f * 2) * step
        ZStack(alignment: .leading) {
            HStack(spacing: gap) {
                ForEach(0..<count, id: \.self) { _ in
                    Circle()
                        .fill(Color.primary.opacity(0.18))
                        .frame(width: dot, height: dot)
                }
            }
            Capsule()
                .fill(Palette.primary)
                .frame(width: trail - lead, height: dot)
                .offset(x: lead)
        }
    }
}
