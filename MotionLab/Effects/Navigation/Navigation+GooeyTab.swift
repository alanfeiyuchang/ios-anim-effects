import SwiftUI

extension Effect {
    static let navigationGooeyTab = Effect(
        id: "navigation.gooey-tab",
        category: .navigation,
        interaction: .tap,
        name: L("Gooey Tab Blob", "黏液标签指示器"),
        summary: L(
            "The selection is a liquid blob: its head races to the new tab and the tail stretches, necks and snaps after it.",
            "选中态是一团液体：头部冲向新标签，尾部被拉长、变细，再啪地跟上。"
        ),
        prompt: L(
            "A 300 × 64 pt floating tab bar with four icons; the selected icon sits in a 50 pt gradient blob. Choosing a tab splits the blob into a head and a tail that travel on separate springs: the head leaps to the new tab first (response ≈0.3 s, damping 0.72) while the tail follows ≈100 ms later on a softer spring. Both are drawn as metaballs — blurred ≈9 pt and alpha-thresholded — plus a bridge whose thickness shrinks with their distance, so the blob stretches into a droplet, necks thin and pulls itself back together at the destination. The chosen icon turns white and bounces. It feels viscous, alive and a little mischievous.",
            "一个 300 × 64pt 的悬浮标签栏，含四个图标；选中图标坐在一团 50pt 的渐变液滴里。切换标签时，液滴分成头、尾两部分，由各自的弹簧驱动：头部先跃向新标签（响应约 0.3 秒、阻尼 0.72），尾部延迟约 100 毫秒以更柔的弹簧跟上。两者以融球方式绘制——约 9pt 模糊后再做透明度阈值——中间还有一段粗细随距离变细的连接桥，于是液滴被拉成水滴状、颈部变细，最终在目标处重新聚拢。被选中的图标变白并弹跳一下。黏稠、有生命力，还带点调皮。"
        ),
        implementation: L(
            "Two nested Animatable views each interpolate one coordinate (head and tail), so the two withAnimation springs stay independent; the inner view draws both circles and a bridge in a Canvas with blur and alphaThreshold filters, used as the mask of a gradient.",
            "两个嵌套的 Animatable 视图各自插值一个坐标（头与尾），让两次 withAnimation 的弹簧互不干扰；内层视图在带模糊与 alphaThreshold 滤镜的 Canvas 中绘制两个圆与连接桥，作为渐变的遮罩。"
        ),
        apis: ["Canvas", "GraphicsContext.Filter.alphaThreshold", "Animatable", "withAnimation", "symbolEffect(.bounce)"],
        tags: ["gooey", "metaball", "tab bar", "liquid", "黏液", "融球", "标签栏", "液态"],
        params: [
            .slider("response", L("Head response", "头部响应"), 0.15...0.7, default: 0.3, unit: "s"),
            .slider("lag", L("Tail lag", "尾部延迟"), 0.0...0.3, default: 0.1, unit: "s"),
            .slider("goo", L("Goo", "黏度"), 4...14, default: 9, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        GooeyTabDemo(ctx: ctx)
    }
}

private let gooeySymbols: [String] = ["house.fill", "magnifyingglass", "bell.fill", "person.fill"]
private let gooeyTitles: [LocalizedText] = [L("Home", "首页"), L("Search", "搜索"), L("Alerts", "通知"), L("Profile", "我的")]

private struct GooeyTabDemo: View {
    let ctx: DemoContext
    @State private var selected = 0
    @State private var head: CGFloat = 0
    @State private var tail: CGFloat = 0
    @State private var bounces: [Int] = [0, 0, 0, 0]

    private let barWidth: CGFloat = 300

    /// Grid previews and still thumbnails get faint screen content above the bar.
    private var thumbnail: Bool { ctx.isPreview || ctx.isStill }

    var body: some View {
        VStack(spacing: 30) {
            Text(gooeyTitles[selected], ctx.language)
                .font(.title2.weight(.bold))
                .id(selected)
                .transition(.blurReplace)
            if thumbnail {
                NavigationScreenPlaceholder(rows: 2, showsTitle: false)
            }
            bar
            DemoHint(text: L("Tap a tab", "点击任一标签"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.2) { select((selected + 1) % gooeySymbols.count) }
    }

    private var bar: some View {
        ZStack {
            Capsule()
                .fill(Palette.elevated)
                .overlay(Capsule().strokeBorder(Palette.stroke))
                .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
            GooeyHeadLayer(head: head, tail: tail, goo: ctx.cg("goo"), count: gooeySymbols.count)
            HStack(spacing: 0) {
                ForEach(0..<gooeySymbols.count, id: \.self) { index in
                    Image(systemName: gooeySymbols[index])
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(index == selected ? Color.white : Color.secondary)
                        .symbolEffect(.bounce, value: bounces[index])
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture { select(index) }
                }
            }
        }
        .frame(width: barWidth, height: 64)
    }

    private func select(_ index: Int) {
        guard index != selected else { return }
        if !ctx.isPreview { Haptics.selection() }
        let target = CGFloat(index)
        bounces[index] += 1
        withAnimation(.easeInOut(duration: 0.2)) { selected = index }
        withAnimation(.spring(response: ctx["response"], dampingFraction: 0.72)) { head = target }
        withAnimation(.spring(response: ctx["response"] * 1.5, dampingFraction: 0.8).delay(ctx["lag"])) { tail = target }
    }
}

/// Interpolates only the head position and hands the tail through to the inner layer.
private struct GooeyHeadLayer: View, Animatable {
    var head: CGFloat
    let tail: CGFloat
    let goo: CGFloat
    let count: Int

    var animatableData: CGFloat {
        get { head }
        set { head = newValue }
    }

    var body: some View {
        GooeyTailLayer(head: head, tail: tail, goo: goo, count: count)
    }
}

/// Interpolates the tail position and draws both blobs as a thresholded metaball.
private struct GooeyTailLayer: View, Animatable {
    let head: CGFloat
    var tail: CGFloat
    let goo: CGFloat
    let count: Int

    var animatableData: CGFloat {
        get { tail }
        set { tail = newValue }
    }

    var body: some View {
        LinearGradient(colors: [Palette.indigo, Palette.violet, Palette.pink], startPoint: .leading, endPoint: .trailing)
            .mask {
                Canvas { context, size in
                    context.addFilter(.alphaThreshold(min: 0.5, color: .white))
                    context.addFilter(.blur(radius: goo))
                    context.drawLayer { layer in
                        let slot: CGFloat = size.width / CGFloat(count)
                        let midY: CGFloat = size.height / 2
                        let headX: CGFloat = (head + 0.5) * slot
                        let tailX: CGFloat = (tail + 0.5) * slot
                        let distance: CGFloat = abs(headX - tailX)
                        let headRadius: CGFloat = 25
                        let tailRadius: CGFloat = max(25 - distance * 0.08, 14)
                        layer.fill(Path(ellipseIn: CGRect(x: headX - headRadius, y: midY - headRadius, width: headRadius * 2, height: headRadius * 2)), with: .color(.white))
                        layer.fill(Path(ellipseIn: CGRect(x: tailX - tailRadius, y: midY - tailRadius, width: tailRadius * 2, height: tailRadius * 2)), with: .color(.white))
                        let neck: CGFloat = max(22 - distance * 0.12, 0)
                        if neck > 0 {
                            let bridge = CGRect(x: min(headX, tailX), y: midY - neck / 2, width: distance, height: neck)
                            layer.fill(Path(roundedRect: bridge, cornerRadius: neck / 2), with: .color(.white))
                        }
                    }
                }
                .blur(radius: 0.6)
            }
            .allowsHitTesting(false)
    }
}
