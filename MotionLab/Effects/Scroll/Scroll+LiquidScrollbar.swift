import SwiftUI

extension Effect {
    static let scrollLiquidScrollbar = Effect(
        id: "scroll.liquid-scrollbar",
        category: .scroll,
        interaction: .scroll,
        name: L("Liquid Scrollbar", "液态滚动条"),
        summary: L("A custom scroll thumb that stretches with speed, squashes at the ends and melts away when idle.", "自定义滚动滑块：随速度拉长、在两端被挤扁、静止时悄然消融。"),
        prompt: L(
            "A list scrolls with a custom thumb along its right edge. At rest the thumb is invisible; as soon as scrolling starts it fades in and widens from 5 to 8 pt on a quick spring. Its length is proportional to the visible fraction, but it also stretches with speed — up to 60% longer at 30 pt per frame, trailing opposite the motion — and eases back when the scroll slows (spring response 0.3 s, damping 0.55). Pulled past either end, it squashes against the edge, losing up to 70% of its length while bulging 2 pt wider, like a droplet. A small bubble beside it shows the percentage read. 0.8 s after the scroll settles, thumb and bubble melt away. Fluid, alive and unobtrusive.",
            "一个列表在滚动，右侧边缘有一个自定义滑块。静止时滑块不可见；一开始滚动，它就以快速弹簧淡入，宽度从 5 pt 变为 8 pt。滑块长度与可见比例成正比，但也会随速度拉长——每帧 30 pt 时最多拉长 60%，并向运动的反方向拖尾——滚动变慢时再回弹（弹簧响应 0.3 秒、阻尼 0.55）。越过两端继续拉动时，它会被挤压在边缘，长度最多减少 70%，同时像水滴一样鼓宽 2 pt。旁边的小气泡显示已读百分比。滚动停下 0.8 秒后，滑块和气泡一起消融。流畅、灵动、不打扰。"
        ),
        implementation: L(
            "onScrollGeometryChange reports offset, range and viewport as one Equatable struct; the action derives a per-frame velocity and overscroll that set the thumb's length, anchor and width through an .animation(spring, value:), and onScrollPhaseChange plus a delayed Task controls visibility.",
            "onScrollGeometryChange 把偏移、可滚动范围与视口打包成一个 Equatable 结构体；回调据此推算每帧速度与越界量，经由 .animation(spring, value:) 决定滑块的长度、锚点与宽度，onScrollPhaseChange 配合延时 Task 控制显隐。"
        ),
        apis: ["onScrollGeometryChange", "onScrollPhaseChange", "animation(_:value:)", "Task.sleep", "scaleEffect(x:y:anchor:)"],
        tags: ["scrollbar", "thumb", "liquid", "velocity", "滚动条", "滑块", "液态", "速度"],
        params: [
            .slider("stretch", L("Speed stretch", "速度拉伸"), 0...1.2, default: 0.6),
            .slider("hide", L("Hide delay", "隐藏延迟"), 0.2...2.0, default: 0.8, unit: "s"),
            .toggle("bubble", L("Percent bubble", "百分比气泡"), default: true),
        ]
    ) { ctx in
        ScrollLiquidBarDemo(ctx: ctx)
    }
}

private struct ScrollLiquidMetrics: Equatable {
    var offset: CGFloat = 0
    var range: CGFloat = 1
    var viewport: CGFloat = 1
}

private struct ScrollLiquidBarDemo: View {
    let ctx: DemoContext
    @State private var position = ScrollPosition(edge: .top)
    @State private var metrics = ScrollLiquidMetrics()
    @State private var velocity: CGFloat = 0
    @State private var visible = false
    @State private var hideTask: Task<Void, Never>?
    @State private var down = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(0..<18, id: \.self) { i in
                    ScrollKitRow(index: i + 1, language: ctx.language)
                }
            }
            .padding(.horizontal, 16)
            .padding(.trailing, 10)
            .padding(.vertical, 14)
        }
        .scrollIndicators(.hidden)
        .scrollPosition($position)
        .onScrollGeometryChange(for: ScrollLiquidMetrics.self, of: { geometry in
            ScrollLiquidMetrics(
                offset: geometry.contentOffset.y + geometry.contentInsets.top,
                range: max(geometry.contentSize.height - geometry.containerSize.height, 1),
                viewport: max(geometry.containerSize.height, 1)
            )
        }, action: { oldValue, newValue in
            metrics = newValue
            velocity = (newValue.offset - oldValue.offset).clamped(to: -30...30)
        })
        .onScrollPhaseChange { _, newPhase in
            if newPhase.isScrolling {
                hideTask?.cancel()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { visible = true }
            } else {
                velocity = 0
                scheduleHide()
            }
        }
        .overlay(alignment: .topTrailing) {
            ScrollLiquidThumb(
                metrics: metrics,
                velocity: velocity,
                stretch: ctx.cg("stretch"),
                showsBubble: ctx.bool("bubble"),
                visible: visible
            )
            .padding(.trailing, 5)
            .allowsHitTesting(false)
        }
        .autoplay(ctx.isPreview, every: 2.4) {
            down.toggle()
            withAnimation(.easeInOut(duration: 1.3)) {
                position.scrollTo(edge: down ? .bottom : .top)
            }
        }
    }

    private func scheduleHide() {
        hideTask?.cancel()
        let delay = ctx["hide"]
        hideTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.35)) { visible = false }
        }
    }
}

private struct ScrollLiquidThumb: View {
    let metrics: ScrollLiquidMetrics
    let velocity: CGFloat
    let stretch: CGFloat
    let showsBubble: Bool
    let visible: Bool

    private let inset: CGFloat = 6

    var body: some View {
        let track = metrics.viewport - inset * 2
        let content = metrics.range + metrics.viewport
        let baseLength = max(track * metrics.viewport / content, 28)
        let progress = (metrics.offset / metrics.range).clamped(to: 0...1)
        // Overscroll past either end squashes the thumb against that edge.
        let over = metrics.offset < 0 ? -metrics.offset : max(metrics.offset - metrics.range, 0)
        let squash = min(over / 120, 0.7)
        let speed = min(abs(velocity) / 30, 1) * stretch
        let length = max(baseLength * (1 + speed) * (1 - squash), 10)
        let top = inset + (track - baseLength) * progress
        // Stretch trails behind the motion: grow upward when moving down and vice versa.
        let y = velocity > 0 ? top + baseLength - length : top
        let width: CGFloat = (visible ? 8 : 5) + squash / 0.7 * 2
        ZStack(alignment: .topTrailing) {
            Capsule()
                .fill(LinearGradient(colors: [Palette.sky, Palette.violet], startPoint: .top, endPoint: .bottom))
                .frame(width: width, height: length)
                .offset(y: y)
            if showsBubble {
                Text(verbatim: "\(Int((progress * 100).rounded()))%")
                    .font(.caption2.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Palette.indigo, in: Capsule())
                    .offset(x: -16, y: top + baseLength / 2 - 10)
            }
        }
        .frame(width: 60, height: metrics.viewport, alignment: .topTrailing)
        .opacity(visible ? 1 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.55), value: velocity)
    }
}
