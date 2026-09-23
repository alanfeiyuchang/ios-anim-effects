import SwiftUI

extension Effect {
    static let scrollInfiniteCarousel = Effect(
        id: "scroll.infinite-carousel",
        category: .scroll,
        interaction: .scroll,
        name: L("Infinite Carousel", "无限循环轮播"),
        summary: L("A seamless looping carousel that auto-advances and never hits an end.", "无缝循环、自动轮播、永远滑不到尽头的卡片轮播。"),
        prompt: L(
            "A centre-snapping carousel of 180×220 pt gradient cards with 26 pt corners loops seamlessly in both directions. Neighbours rest one pitch from the centre at 86% scale and 60% opacity and interpolate linearly up to 100% as they slide in. Every 2.2 s, while the user isn't touching, it advances one card on a smooth spring (response 0.55 s, damping 0.86). Infinity is an illusion of five copies laid end to end: whenever scrolling comes to rest, the position silently jumps to the identical card in the middle copy, and a row of dots below tracks the real index with a stretching active capsule. Effortless, ambient and endlessly browsable.",
            "一排居中吸附的渐变卡片（180×220 pt，26 pt 圆角），可向两个方向无缝循环。相邻卡片停在距中心一个卡位处，缩放 86%、不透明度 60%，滑向中心时线性恢复到 100%。用户不触摸时，每 2.2 秒以平滑弹簧（响应 0.55 秒、阻尼 0.86）自动前进一张。所谓无限，其实是五份相同内容首尾相接：每当滚动停下，位置就悄悄跳到中间那份里一模一样的卡片上，下方圆点则追踪真实页码，当前点伸展成胶囊。轻松、有氛围，可以一直刷下去。"
        ),
        implementation: L(
            "The set is repeated five times; scrollPosition(id:) tracks the centered card and onScrollPhaseChange recenters to the middle copy (without animation) whenever the phase returns to .idle. Each card's visualEffect scales and fades it by its distance from the centre measured in card pitches; a task-based autoplay advances the id.",
            "将内容重复五份；scrollPosition(id:) 追踪居中卡片，onScrollPhaseChange 在滚动阶段回到 .idle 时（无动画）重定位到中间那份。每张卡片的 visualEffect 按其到中心的距离（以卡片间距为单位）缩放与淡出；基于 task 的自动播放推进 id。"
        ),
        apis: ["onScrollPhaseChange", "scrollPosition(id:)", "scrollTargetBehavior(.viewAligned)", "visualEffect"],
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

private let scrollInfiniteSpace = "scroll.infinite-carousel"

private struct ScrollInfiniteDemo: View {
    let ctx: DemoContext
    @State private var current: Int? = 12
    @State private var width: CGFloat = 340
    @State private var idle = true

    private let base = 6
    private let copies = 5
    private let cardWidth: CGFloat = 180
    private let spacing: CGFloat = 14

    var body: some View {
        VStack(spacing: 18) {
            carousel
            ScrollInfiniteDots(count: base, current: (current ?? 0) % base)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview || ctx.bool("auto"), every: ctx["interval"], delay: 1.0) { advance() }
    }

    private var carousel: some View {
        let shrink = CGFloat(ctx["scale"])
        let viewport = width
        let pitch = cardWidth + spacing
        return ScrollView(.horizontal) {
            LazyHStack(spacing: spacing) {
                ForEach(0..<(base * copies), id: \.self) { i in
                    ScrollKitArt(index: (i % base) * 2, language: ctx.language)
                        .frame(width: cardWidth, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .visualEffect { content, proxy in
                            // 0 at the centre, 1 one full card-pitch away (the resting neighbour).
                            let mid = proxy.frame(in: .named(scrollInfiniteSpace)).midX
                            let t = min(abs(mid - viewport / 2) / pitch, 1)
                            return content
                                .scaleEffect(1 - shrink * t)
                                .opacity(1 - Double(t) * 0.4)
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
        .coordinateSpace(.named(scrollInfiniteSpace))
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
