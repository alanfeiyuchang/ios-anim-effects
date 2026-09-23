import SwiftUI

extension Effect {
    static let scrollStackCarousel = Effect(
        id: "scroll.stack-carousel",
        category: .scroll,
        interaction: .scroll,
        name: L("Stacked Carousel", "堆叠轮播"),
        summary: L("Cards that scroll past the center don't leave: they pile up behind it, shrinking and dimming.", "滚过中心的卡片不会离开，而是在它后方叠成一摞，逐渐缩小变暗。"),
        prompt: L(
            "A horizontal carousel of 190×240 pt gradient cards snaps one card to the center. Upcoming cards wait in line on the right at normal spacing, but a card that scrolls past the center does not slide away: it is pulled back so only 12% of its travel shows, stacking behind the focused card as a deck that peeks out about 25 pt per card on the left, while each step back shrinks it by 8%, dims it by 18% and blurs it up to 3 pt. All of it is a continuous function of the scroll offset, so the pile builds and unbuilds exactly under the finger, and releases snap a card to the center with a light selection tick. Compact, tidy and tactile.",
            "一排 190×240 pt 的渐变卡片横向轮播，每次吸附一张到正中。即将出现的卡片在右侧以正常间距排队；而滚过中心的卡片并不会滑走：它被拉回，只保留 12% 的位移，在聚焦卡片后面叠成一摞，每张向左露出约 25 pt；每往后退一层就缩小 8%、变暗 18%，并最多模糊 3 pt。这一切都是滚动偏移的连续函数，因此卡堆在手指下精确地堆起与散开；松手后一张卡片吸附到正中，并伴随轻微的选择触感。紧凑、整齐、有触感。"
        ),
        implementation: L(
            "Spacer padding centers item i at offset i × stride; a custom ScrollTargetBehavior snaps to whole strides. Each card's visualEffect reads its signed distance from the center and, only for cards already past it, adds a counter-offset plus scale, brightness and blur.",
            "两侧留白让第 i 张卡在偏移为 i × 步长时居中；自定义 ScrollTargetBehavior 吸附到整步长。每张卡的 visualEffect 读取自身到中心的有符号距离，只对已经滚过中心的卡片施加反向偏移，以及缩放、亮度与模糊。"
        ),
        apis: ["visualEffect", "ScrollTargetBehavior", "ScrollPosition", "onScrollGeometryChange", "sensoryFeedback"],
        tags: ["carousel", "stack", "deck", "pile", "轮播", "堆叠", "卡堆", "滚动"],
        params: [
            .slider("peek", L("Pile peek", "堆叠露出"), 0.04...0.3, default: 0.12),
            .slider("shrink", L("Shrink per card", "每层缩小"), 0...0.15, default: 0.08),
        ]
    ) { ctx in
        ScrollStackCarouselDemo(ctx: ctx)
    }
}

private struct ScrollStackCarouselDemo: View {
    let ctx: DemoContext
    @State private var position = ScrollPosition(edge: .leading)
    @State private var current = 0
    @State private var width: CGFloat = 340
    @State private var direction = 1

    private let count = 8
    private let cardWidth: CGFloat = 190
    private let spacing: CGFloat = 16
    private var stride: CGFloat { cardWidth + spacing }

    var body: some View {
        VStack(spacing: 14) {
            carousel
            Text(ScrollKit.title(current + 1), ctx.language)
                .font(.headline)
                .contentTransition(.interpolate)
                .animation(.snappy, value: current)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sensoryFeedback(.selection, trigger: current) { _, _ in !ctx.isPreview }
        .autoplay(ctx.isPreview, every: 1.3) { advance() }
    }

    private var carousel: some View {
        let peek = ctx.cg("peek")
        let shrink = ctx.cg("shrink")
        let viewport = max(width, 1)
        let stride = self.stride
        let count = self.count
        return ScrollView(.horizontal) {
            LazyHStack(spacing: spacing) {
                ForEach(0..<count, id: \.self) { i in
                    ScrollKitArt(index: i + 1, language: ctx.language)
                        .frame(width: cardWidth, height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .shadow(color: .black.opacity(0.14), radius: 10, y: 6)
                        .visualEffect { content, proxy in
                            let mid: CGFloat = proxy.frame(in: .scrollView).midX
                            let d: CGFloat = (mid - viewport / 2) / stride
                            let past: CGFloat = max(-d, 0)
                            let pull: CGFloat = past * stride * (1 - peek)
                            let scale: CGFloat = max(1 - past * shrink, 0.5)
                            let dim: Double = -Double(min(past, 3)) * 0.18
                            let blur: CGFloat = min(past * 1.5, 3)
                            return content
                                .scaleEffect(scale)
                                .brightness(dim)
                                .blur(radius: blur)
                                .offset(x: pull)
                        }
                        .onTapGesture { select(i) }
                }
            }
            .padding(.horizontal, max((width - cardWidth) / 2, 0))
        }
        .scrollTargetBehavior(ScrollStrideSnap(stride: stride))
        .scrollPosition($position)
        .onScrollGeometryChange(for: Int.self, of: { geometry in
            let offset = geometry.contentOffset.x + geometry.contentInsets.leading
            return Int((offset / stride).rounded()).clamped(to: 0...(count - 1))
        }, action: { _, newValue in
            current = newValue
        })
        .scrollIndicators(.hidden)
        .frame(height: 260)
        .onGeometryChange(for: CGFloat.self, of: { proxy in proxy.size.width }, action: { newWidth in
            width = newWidth
        })
    }

    private func select(_ i: Int) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
            position.scrollTo(x: CGFloat(i) * stride)
        }
    }

    private func advance() {
        if current + direction >= count || current + direction < 0 { direction = -direction }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.86)) {
            position.scrollTo(x: CGFloat(current + direction) * stride)
        }
    }
}
