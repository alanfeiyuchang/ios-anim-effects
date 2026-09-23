import SwiftUI

extension Effect {
    static let navigationNotchTabBar = Effect(
        id: "navigation.notch-tab-bar",
        category: .navigation,
        interaction: .tap,
        name: L("Curved Notch Tab Bar", "凹槽标签栏"),
        summary: L(
            "A smooth notch slides along the bar's top edge, and the selected icon rides above it in a floating bubble.",
            "标签栏顶边的一道平滑凹槽沿边滑动，选中图标乘着上方的悬浮圆泡随行。"
        ),
        prompt: L(
            "A 312 × 64 pt tab bar whose top edge has a smooth, 76 pt-wide, 30 pt-deep notch cut under the selected tab; a 54 pt gradient bubble floats in the notch carrying that tab's icon. Choosing another tab slides the bubble across on a spring (response ≈0.42 s, damping 0.7) while the notch follows a touch later on a softer spring, so the bar's edge seems to flow like liquid behind the bubble. The bubble dips 6 pt mid-flight and pops back up, its icon cross-fades with a symbol replace, and the icon that left its slot fades back into the bar as the new slot's icon rises out. A medium haptic on arrival. Fluid, tangible, a classic Dribbble move done right.",
            "一个 312 × 64pt 的标签栏，顶边在选中标签下方挖出一道宽 76pt、深 30pt 的平滑凹槽；一个 54pt 的渐变圆泡悬浮在凹槽中，载着该标签的图标。切换标签时，圆泡以弹簧（响应约 0.42 秒、阻尼 0.7）横向滑过去，凹槽稍晚一步以更柔的弹簧跟随，标签栏的边缘仿佛液体一样在圆泡身后流动。圆泡在途中下沉 6pt 再弹回，图标以符号替换淡入淡出；离开的图标淡回标签栏，新位置的图标升入圆泡。到达时伴随中等触觉。流畅、可触，把经典的 Dribbble 动效做到位。"
        ),
        implementation: L(
            "The bar is a custom Shape whose notch centre is its animatableData, built from two cubic curves; the bubble is a Circle offset on its own spring with a keyframeAnimator dip, so the notch and bubble can lag each other.",
            "标签栏是一个自定义 Shape，其凹槽中心为 animatableData，由两段三次贝塞尔曲线构成；圆泡是一个以独立弹簧偏移的 Circle，并用 keyframeAnimator 做下沉，因此凹槽与圆泡可以相互错位。"
        ),
        apis: ["Shape", "animatableData", "addCurve(to:control1:control2:)", "keyframeAnimator", "contentTransition(.symbolEffect(.replace))"],
        tags: ["tab bar", "notch", "curved", "bubble", "标签栏", "凹槽", "曲线", "悬浮"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.25...0.8, default: 0.42, unit: "s"),
            .slider("depth", L("Notch depth", "凹槽深度"), 18...40, default: 30, decimals: 0, unit: "pt"),
            .toggle("lag", L("Liquid lag", "液态滞后"), default: true),
        ]
    ) { ctx in
        NotchTabBarDemo(ctx: ctx)
    }
}

private let notchSymbols: [String] = ["house.fill", "chart.bar.fill", "bell.fill", "person.fill"]

private struct NotchTabBarDemo: View {
    let ctx: DemoContext
    @State private var selected = 0
    @State private var notchX: CGFloat = 54
    @State private var moves = 0

    private let barWidth: CGFloat = 312
    private let inset: CGFloat = 20
    private let barHeight: CGFloat = 64

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)
            bar
            DemoHint(text: L("Tap a tab", "点击任一标签"), ctx: ctx)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.2) { select((selected + 1) % notchSymbols.count) }
    }

    private func centerX(_ index: Int) -> CGFloat {
        let slot: CGFloat = (barWidth - inset * 2) / CGFloat(notchSymbols.count)
        return inset + (CGFloat(index) + 0.5) * slot
    }

    private var bar: some View {
        ZStack(alignment: .topLeading) {
            NotchBarShape(notchX: notchX, depth: ctx.cg("depth"))
                .fill(Palette.elevated)
                .shadow(color: .black.opacity(0.14), radius: 16, y: 6)
            icons
            bubble
        }
        .frame(width: barWidth, height: barHeight)
    }

    private var icons: some View {
        HStack(spacing: 0) {
            ForEach(0..<notchSymbols.count, id: \.self) { index in
                let isSelected = index == selected
                Image(systemName: notchSymbols[index])
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Color.secondary)
                    .opacity(isSelected ? 0 : 1)
                    .offset(y: isSelected ? 14 : 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture { select(index) }
                    .animation(.easeInOut(duration: 0.25), value: selected)
            }
        }
        .padding(.horizontal, inset)
        .frame(width: barWidth, height: barHeight)
    }

    private var bubble: some View {
        Image(systemName: notchSymbols[selected])
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(.white)
            .contentTransition(.symbolEffect(.replace))
            .frame(width: 54, height: 54)
            .background(Palette.primary, in: Circle())
            .shadow(color: Palette.indigo.opacity(0.4), radius: 10, y: 5)
            .keyframeAnimator(initialValue: CGFloat(0), trigger: moves) { content, dip in
                content.offset(y: dip)
            } keyframes: { _ in
                KeyframeTrack(\.self) {
                    CubicKeyframe(6, duration: 0.14)
                    SpringKeyframe(0, duration: 0.4, spring: .bouncy)
                }
            }
            .offset(x: centerX(selected) - 27, y: -27 - 4)
            .animation(.spring(response: ctx["response"], dampingFraction: 0.7), value: selected)
            .allowsHitTesting(false)
    }

    private func select(_ index: Int) {
        guard index != selected else { return }
        let response: Double = ctx["response"]
        moves += 1
        // The haptic lands with the bubble (~80% of the spring response), not on touch-down.
        // Autoplay mutes Haptics while it runs, so simulated taps stay silent after the delay too.
        let live: Bool = !ctx.isPreview && !Haptics.isMuted
        let arrival: Double = response * 0.8
        let current = moves
        if live {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(arrival))
                guard !Task.isCancelled, moves == current else { return }
                Haptics.tap(.medium)
            }
        }
        withAnimation(.snappy) { selected = index }
        let notchAnimation: Animation = ctx.bool("lag")
            ? .spring(response: response * 1.3, dampingFraction: 0.78).delay(0.05)
            : .spring(response: response, dampingFraction: 0.7)
        withAnimation(notchAnimation) { notchX = centerX(index) }
    }
}

private struct NotchBarShape: Shape {
    var notchX: CGFloat
    let depth: CGFloat

    var animatableData: CGFloat {
        get { notchX }
        set { notchX = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let corner: CGFloat = 16
        let notchWidth: CGFloat = 76
        let half: CGFloat = notchWidth / 2
        let x: CGFloat = min(max(notchX, rect.minX + corner + half), rect.maxX - corner - half)
        let top: CGFloat = rect.minY
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: top + corner))
        path.addQuadCurve(to: CGPoint(x: rect.minX + corner, y: top), control: CGPoint(x: rect.minX, y: top))
        path.addLine(to: CGPoint(x: x - half, y: top))
        path.addCurve(
            to: CGPoint(x: x, y: top + depth),
            control1: CGPoint(x: x - half * 0.45, y: top),
            control2: CGPoint(x: x - half * 0.62, y: top + depth)
        )
        path.addCurve(
            to: CGPoint(x: x + half, y: top),
            control1: CGPoint(x: x + half * 0.62, y: top + depth),
            control2: CGPoint(x: x + half * 0.45, y: top)
        )
        path.addLine(to: CGPoint(x: rect.maxX - corner, y: top))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: top + corner), control: CGPoint(x: rect.maxX, y: top))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - corner))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - corner, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + corner, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - corner), control: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
