import SwiftUI

extension Effect {
    static let scrollInfiniteCarousel = Effect(
        id: "scroll.infinite-carousel",
        category: .scroll,
        interaction: .scroll,
        name: L("Infinite Carousel", "无限循环轮播"),
        summary: L("A seamless looping carousel that auto-advances and never hits an end.", "无缝循环、自动轮播、永远滑不到尽头的卡片轮播。"),
        prompt: L(
            "A center-snapping carousel of gradient cards (180×220 pt, 26 pt corners) that loops seamlessly in both directions. Neighbouring cards peek in at ~86% scale and 60% opacity, scaling up as they reach the center. Every ~2.2 s, while the user isn't touching, it auto-advances one card with a smooth spring (response 0.55 s, damping 0.86). The illusion of infinity comes from several copies of the set laid end to end: whenever scrolling comes to rest, the position silently jumps to the identical card in the middle copy, invisible to the eye. A row of dots below tracks the real index with a stretching active capsule. Effortless, ambient and endlessly browsable.",
            "一排居中吸附的渐变卡片（180×220 pt，26 pt 圆角），可向两个方向无缝循环。相邻卡片以约 86% 缩放、60% 透明度露出，滑到中心时逐渐放大。在用户未触摸时，每约 2.2 秒以平滑弹簧（响应 0.55 秒、阻尼 0.86）自动前进一张。无限的错觉来自首尾相接的多份相同内容：每当滚动停止，位置会静默跳到中间那份中完全相同的卡片，肉眼无法察觉。下方一排圆点追踪真实索引，当前点伸展为胶囊。轻松、氛围感十足，可无限浏览。"
        ),
        implementation: L(
            "The set is repeated five times; scrollPosition(id:) tracks the centered card and onScrollPhaseChange recenters to the middle copy (without animation) whenever the phase returns to .idle. A task-based autoplay advances the id.",
            "将内容重复五份；scrollPosition(id:) 追踪居中卡片，onScrollPhaseChange 在滚动阶段回到 .idle 时（无动画）重定位到中间那份。基于 task 的自动播放推进 id。"
        ),
        apis: ["onScrollPhaseChange", "scrollPosition(id:)", "scrollTargetBehavior(.viewAligned)", "scrollTransition"],
        tags: ["infinite", "loop", "carousel", "autoplay", "无限", "循环", "轮播", "自动播放"],
        params: [
            .slider("scale", L("Side shrink", "两侧缩小"), 0...0.3, default: 0.14),
            .toggle("auto", L("Auto-advance", "自动轮播"), default: true),
            .slider("interval", L("Interval", "轮播间隔"), 1...4, default: 2.2, unit: "s"),
        ]
    ) { ctx in
        ScrollInfiniteDemo(ctx: ctx)
    }
}

private struct ScrollInfiniteDemo: View {
    let ctx: DemoContext
    @State private var current: Int? = 12
    @State private var width: CGFloat = 340
    @State private var idle = true

    private let base = 6
    private let copies = 5
    private let cardWidth: CGFloat = 180

    var body: some View {
        VStack(spacing: 18) {
            carousel
            ScrollInfiniteDots(count: base, current: (current ?? 0) % base)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview || ctx.bool("auto"), every: ctx["interval"], delay: 1.0) { advance() }
    }

    private var carousel: some View {
        let shrink = ctx["scale"]
        return ScrollView(.horizontal) {
            LazyHStack(spacing: 14) {
                ForEach(0..<(base * copies), id: \.self) { i in
                    ScrollKitArt(index: (i % base) * 2, language: ctx.language)
                        .frame(width: cardWidth, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                            let v = abs(phase.value)
                            return content
                                .scaleEffect(1 - CGFloat(v * shrink))
                                .opacity(1 - v * 0.4)
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
        .onScrollPhaseChange { _, newPhase in
            idle = newPhase == .idle
            if newPhase == .idle { recenter() }
        }
        .frame(height: 230)
        .onGeometryChange(for: CGFloat.self, of: { proxy in proxy.size.width }, action: { newWidth in
            width = newWidth
        })
    }

    /// Jump (without animation) to the same card in the middle copy.
    private func recenter() {
        guard let index = current else { return }
        let target = base * 2 + index % base
        if target != index { current = target }
    }

    private func advance() {
        guard idle else { return }
        let index = current ?? base * 2
        // Safety net in case a programmatic scroll never reported an idle phase.
        if index >= base * 4 - 1 || index <= base {
            current = base * 2 + index % base
            return
        }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
            current = index + 1
        }
    }
}

private struct ScrollInfiniteDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == current ? AnyShapeStyle(Palette.aurora) : AnyShapeStyle(Color.primary.opacity(0.18)))
                    .frame(width: i == current ? 20 : 7, height: 7)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.72), value: current)
    }
}
