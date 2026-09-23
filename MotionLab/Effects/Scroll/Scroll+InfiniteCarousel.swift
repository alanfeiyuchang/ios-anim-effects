import SwiftUI

extension Effect {
    static let scrollInfiniteCarousel = Effect(
        id: "scroll.infinite-carousel",
        category: .scroll,
        interaction: .scroll,
        name: L("Infinite Carousel", "无限循环轮播"),
        summary: L("A seamless looping rolodex: neighbours recede, blur and tuck behind the focused card.", "无缝循环的卡片轮盘：两侧卡片后退、虚化并收拢到焦点卡片身后。"),
        prompt: L(
            "A centre-snapping carousel of 180×220 pt gradient cards with 26 pt corners loops seamlessly in both directions, arranged like a rolodex in depth. The focused card sits in front at full size; neighbours recede by 18% scale, tuck 60 pt inward so they overlap behind it, blur by 3 pt, dim 12% and fade to 70%, all interpolated continuously with distance so a card rises out of the stack as it slides to the centre. Every 2.2 s, while the user isn't touching, it advances one card on a smooth spring (response 0.55 s, damping 0.86). Infinity is five copies end to end: when scrolling rests, the position silently jumps to the same card in the middle copy, and dots below track the real index. Deep, ambient and endlessly browsable.",
            "一排居中吸附的渐变卡片（180×220 pt，26 pt圆角）可向两个方向无缝循环，像纵深排列的卡片轮盘。焦点卡片在最前方保持原大；两侧卡片缩小18%，向内收拢60 pt叠到它身后，模糊3 pt、变暗12%并淡到70%，全部随距离连续插值，卡片滑向中心时仿佛从牌堆中升起。用户不触摸时，每2.2秒以平滑弹簧（响应0.55秒、阻尼0.86）前进一张。无限其实是五份内容首尾相接：滚动停下时悄悄跳到中间那份的同一张，下方圆点追踪真实页码。"
        ),
        implementation: L(
            "The set is repeated five times; scrollPosition(id:) tracks the centred card and onScrollPhaseChange recentres to the middle copy (without animation) whenever the phase returns to .idle. Each card's visualEffect derives a signed distance in card pitches and applies scale, inward offset, blur, brightness and opacity, while zIndex keeps the focused card on top; a task-based autoplay advances the id.",
            "将内容重复五份；scrollPosition(id:) 追踪居中卡片，onScrollPhaseChange 在滚动阶段回到 .idle 时（无动画）重定位到中间那份。每张卡片的 visualEffect 按到中心的有符号距离（以卡片间距为单位）施加缩放、向内位移、模糊、亮度与透明度，zIndex 让焦点卡片始终在最上层；基于 task 的自动播放推进 id。"
        ),
        apis: ["onScrollPhaseChange", "scrollPosition(id:)", "scrollTargetBehavior(.viewAligned)", "visualEffect", "zIndex(_:)"],
        tags: ["infinite", "loop", "carousel", "rolodex", "depth", "无限", "循环", "轮播", "纵深"],
        params: [
            .slider("scale", L("Recede depth", "后退深度"), 0...0.3, default: 0.18),
            .slider("blur", L("Side blur", "两侧模糊"), 0...8, default: 3, decimals: 0, unit: "pt"),
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
        let sideBlur = ctx.cg("blur")
        let viewport = width
        let pitch = cardWidth + spacing
        return ScrollView(.horizontal) {
            LazyHStack(spacing: spacing) {
                ForEach(0..<(base * copies), id: \.self) { i in
                    ScrollKitArt(index: (i % base) * 2, language: ctx.language)
                        .frame(width: cardWidth, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .visualEffect { content, proxy in
                            // Signed distance in card pitches: 0 at the centre, ±1 for the resting neighbours.
                            let mid = proxy.frame(in: .named(scrollInfiniteSpace)).midX
                            let d: CGFloat = ((mid - viewport / 2) / pitch).clamped(to: -2...2)
                            let far: CGFloat = min(abs(d), 1.5)
                            let scale: CGFloat = 1 - shrink * far
                            let tuck: CGFloat = -d * 60
                            let radius: CGFloat = sideBlur * far
                            let dim: Double = -0.12 * Double(far)
                            let alpha: Double = 1 - 0.3 * Double(far)
                            return content
                                .scaleEffect(scale)
                                .offset(x: tuck)
                                .blur(radius: radius)
                                .brightness(dim)
                                .opacity(alpha)
                        }
                        .zIndex(depthOrder(i))
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

    /// The focused card draws on top; neighbours stack behind it by distance.
    private func depthOrder(_ i: Int) -> Double {
        -Double(abs(i - (current ?? base * 2)))
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
