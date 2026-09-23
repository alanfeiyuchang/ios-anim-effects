import SwiftUI

extension Effect {
    static let scrollPagingCarousel = Effect(
        id: "scroll.paging-carousel",
        category: .scroll,
        interaction: .scroll,
        name: L("Snapping Carousel", "吸附轮播"),
        summary: L("Center-snapping cards with peeking neighbours that scale down and a stretching page indicator.", "居中吸附的卡片轮播，两侧卡片露出并缩小，页码指示器随之伸缩。"),
        prompt: L(
            "A horizontal carousel of tall gradient cards (210×250 pt, 28 pt corners) is centered in the viewport with the neighbouring cards peeking in from both sides. As a card moves away from the center it scales down continuously toward 86% and fades to ~65% opacity, then scales back up as it approaches, so the focused card always reads as the hero. Releasing a swipe snaps the nearest card to the exact center with the system's deceleration curve. Beneath, a page indicator of 7 pt dots stretches the active dot into a 22 pt gradient capsule, springing between positions (response 0.4 s, damping 0.7). App Store-quality: focused, weighty and effortless.",
            "一排竖版渐变卡片（210×250 pt，28 pt 圆角）横向排列并在视口中居中，左右两侧露出相邻卡片的一部分。卡片离开中心时连续缩小至 86%、透明度降到约 65%，靠近中心时再放大恢复，因此聚焦的卡片始终是主角。滑动松手后，最近的卡片以系统减速曲线精确吸附到正中。下方的页码指示器由 7 pt 圆点组成，当前页圆点伸长为 22 pt 的渐变胶囊，并在位置间以弹簧（响应 0.4 秒、阻尼 0.7）切换。App Store 级品质：聚焦、有分量、毫不费力。"
        ),
        implementation: L(
            "A LazyHStack marked scrollTargetLayout with scrollTargetBehavior(.viewAligned) and centered contentMargins; visualEffect scales cards by distance from center, and scrollPosition(id:) feeds the page dots.",
            "LazyHStack 标记 scrollTargetLayout，配合 scrollTargetBehavior(.viewAligned) 与居中的 contentMargins；visualEffect 按到中心的距离缩放卡片，scrollPosition(id:) 驱动页码圆点。"
        ),
        apis: ["scrollTargetBehavior(.viewAligned)", "scrollTargetLayout", "scrollPosition(id:)", "visualEffect", "contentMargins"],
        tags: ["carousel", "paging", "snap", "page control", "轮播", "分页", "吸附", "指示器"],
        params: [
            .slider("sideScale", L("Side scale", "两侧缩放"), 0.7...1.0, default: 0.86),
            .slider("spacing", L("Spacing", "间距"), 0...30, default: 14, step: 1, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        ScrollPagingDemo(ctx: ctx)
    }
}

private struct ScrollPagingDemo: View {
    let ctx: DemoContext
    @State private var current: Int? = 0
    @State private var width: CGFloat = 340
    @State private var direction = 1

    private let count = 6
    private let cardWidth: CGFloat = 210

    var body: some View {
        VStack(spacing: 18) {
            carousel
            ScrollPageDots(count: count, current: current ?? 0)
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
                            let mid = proxy.frame(in: .scrollView).midX
                            let t = min(abs(mid - viewport / 2) / pitch, 1)
                            return content
                                .scaleEffect(1 - (1 - CGFloat(sideScale)) * t)
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
        .scrollIndicators(.hidden)
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

private struct ScrollPageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == current ? AnyShapeStyle(Palette.primary) : AnyShapeStyle(Color.primary.opacity(0.18)))
                    .frame(width: i == current ? 22 : 7, height: 7)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: current)
    }
}
