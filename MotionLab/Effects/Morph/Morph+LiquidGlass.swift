import SwiftUI

extension Effect {
    static let morphLiquidGlass = Effect(
        id: "morph.liquid-glass",
        category: .morph,
        interaction: .tap,
        name: L("Liquid Glass Morph", "液态玻璃融合"),
        summary: L(
            "Glass buttons bud off one another and melt back together like droplets.",
            "玻璃按钮像水滴一样从彼此中分裂而出，又融合回去。"
        ),
        prompt: L(
            "A tinted Liquid Glass plus button floats over a vivid gradient. On tap, three secondary glass buttons bud out to its right: each bulges from the parent's edge, stretches into a liquid bridge, then pinches off into its own 56 pt circle as it springs into place (response 0.5 s, damping 0.75), the glass refracting and highlighting the backdrop as shapes merge and part. The plus rotates 45° into a close glyph. Collapsing reverses it, the buttons melting back like merging droplets; touches get the interactive glass bounce. Before iOS 26 the same choreography is a frosted metaball: blurred, alpha-thresholded circles stay bridged until they pass the merge distance.",
            "一枚着色的液态玻璃加号按钮浮在鲜艳渐变上。轻点，三个次级玻璃按钮从它右侧“分裂”而出：先在母按钮边缘鼓起，拉成液桥，再断开成各自 56 pt 的圆，以弹簧（响应 0.5 秒、阻尼 0.75）落位；融合与分离全程，玻璃持续折射背景、泛着高光。加号旋转 45° 变成关闭符号。收起时一切倒放，按钮像水滴汇合般融回母体；触摸带有玻璃的交互回弹。iOS 26 之前以磨砂融球呈现同一编排：模糊后做透明度阈值的圆形始终以液桥相连，直到间距超过融合距离才断开。"
        ),
        implementation: L(
            "On iOS 26, buttons live in a GlassEffectContainer and carry glassEffect(.regular.interactive()) plus glassEffectID in a shared namespace so SwiftUI morphs the glass shapes; on iOS 18 a Canvas stacks alphaThreshold on blur (radius driven by the merge distance) to draw spring-interpolated circles as a metaball that masks a frosted material.",
            "iOS 26 上按钮位于 GlassEffectContainer 中，使用 glassEffect(.regular.interactive()) 与共享命名空间的 glassEffectID，由 SwiftUI 负责玻璃形状的融合形变；更早的系统用 Canvas 叠加模糊与 alphaThreshold（半径随融合距离变化）绘制弹簧插值的圆形融球，并作为磨砂材质的遮罩。"
        ),
        apis: ["GlassEffectContainer", "glassEffect(_:in:)", "glassEffectID(_:in:)", "Glass.interactive()", "Canvas", "GraphicsContext.Filter.alphaThreshold"],
        tags: ["liquid glass", "glass", "ios 26", "metaball", "液态玻璃", "玻璃", "融合", "水滴"],
        params: [
            .slider("spacing", L("Merge distance", "融合距离"), 0...60, default: 30, decimals: 0, unit: "pt"),
            .slider("gap", L("Button gap", "按钮间距"), 4...24, default: 12, decimals: 0, unit: "pt"),
            .slider("response", L("Spring response", "弹簧响应"), 0.2...1.0, default: 0.5, unit: "s"),
        ],
        requirement: "iOS 26"
    ) { ctx in
        LiquidGlassDemo(ctx: ctx)
    }
}

private let glassActions: [String] = ["camera.fill", "photo.fill", "mic.fill"]

private struct LiquidGlassDemo: View {
    let ctx: DemoContext
    @State private var expanded = false

    var body: some View {
        ZStack {
            GlassBackdrop()
            toolbar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap the + button", "点击“+”按钮"), ctx: ctx)
                .environment(\.colorScheme, .dark)
                .padding(.bottom, 16)
                .allowsHitTesting(false)
        }
        .autoplay(ctx.isPreview, every: 1.8) { toggle() }
    }

    @ViewBuilder private var toolbar: some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            GlassToolbar(expanded: expanded, spacing: ctx.cg("spacing"), gap: ctx.cg("gap"), onToggle: toggle)
        } else {
            FallbackToolbar(expanded: expanded, spacing: ctx.cg("spacing"), gap: ctx.cg("gap"), onToggle: toggle)
        }
        #else
        FallbackToolbar(expanded: expanded, spacing: ctx.cg("spacing"), gap: ctx.cg("gap"), onToggle: toggle)
        #endif
    }

    private func toggle() {
        if !ctx.isPreview { Haptics.tap(.medium) }
        withAnimation(.spring(response: ctx["response"], dampingFraction: 0.75)) {
            expanded.toggle()
        }
    }
}

#if compiler(>=6.2)
@available(iOS 26.0, *)
private struct GlassToolbar: View {
    let expanded: Bool
    let spacing: CGFloat
    let gap: CGFloat
    let onToggle: () -> Void
    @Namespace private var glass

    private let main: CGFloat = 64
    private let small: CGFloat = 56
    private let inset: CGFloat = 12

    var body: some View {
        // Same fixed-width, leading-aligned frame as the fallback, so + stays put and the actions bud out to its
        // right instead of the centred row sliding left as it grows.
        let width: CGFloat = inset * 2 + main + CGFloat(glassActions.count) * (small + gap)
        container
            .padding(.leading, inset)
            .frame(width: width, height: 100, alignment: .leading)
    }

    private var container: some View {
        GlassEffectContainer(spacing: spacing) {
            HStack(spacing: gap) {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(expanded ? 45 : 0))
                    .frame(width: main, height: main)
                    .contentShape(Circle())
                    .glassEffect(.regular.tint(Palette.indigo.opacity(0.55)).interactive(), in: .circle)
                    .glassEffectID("main", in: glass)
                    .onTapGesture(perform: onToggle)
                if expanded {
                    ForEach(glassActions, id: \.self) { symbol in
                        Image(systemName: symbol)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: small, height: small)
                            .contentShape(Circle())
                            .glassEffect(.regular.interactive(), in: .circle)
                            .glassEffectID(symbol, in: glass)
                            .onTapGesture(perform: onToggle)
                    }
                }
            }
        }
    }
}
#endif

/// iOS 18 fallback: the same budding/merging choreography drawn as a metaball.
/// A Canvas blurs and alpha-thresholds the circles together (the "gooey" trick), and the result
/// masks a frosted material, so neighbors stay joined by liquid bridges while they are closer than
/// the merge distance. Glyphs ride the same spring on top.
private struct FallbackToolbar: View {
    let expanded: Bool
    let spacing: CGFloat
    let gap: CGFloat
    let onToggle: () -> Void

    private let main: CGFloat = 64
    private let small: CGFloat = 56
    private let inset: CGFloat = 12

    var body: some View {
        let width = inset * 2 + main + CGFloat(glassActions.count) * (small + gap)
        ZStack(alignment: .leading) {
            GooeyGlassLayer(
                progress: expanded ? 1 : 0,
                gap: gap,
                goo: 2 + spacing * 0.22,
                main: main,
                small: small,
                inset: inset
            )
            .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
            .allowsHitTesting(false)
            secondaryGlyphs
            mainGlyph
        }
        .frame(width: width, height: 100, alignment: .leading)
    }

    private var mainGlyph: some View {
        Image(systemName: "plus")
            .font(.title2.weight(.semibold))
            .foregroundStyle(.white)
            .rotationEffect(.degrees(expanded ? 45 : 0))
            .frame(width: main, height: main)
            .contentShape(Circle())
            .onTapGesture(perform: onToggle)
            .offset(x: inset)
    }

    private var secondaryGlyphs: some View {
        ForEach(Array(glassActions.enumerated()), id: \.element) { index, symbol in
            let travel = main / 2 + gap + small / 2 + CGFloat(index) * (small + gap)
            Image(systemName: symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: small, height: small)
                .contentShape(Circle())
                .onTapGesture(perform: onToggle)
                .scaleEffect(expanded ? 1 : 0.4)
                .opacity(expanded ? 1 : 0)
                .offset(x: inset + main / 2 - small / 2 + (expanded ? travel : 0))
                .allowsHitTesting(expanded)
        }
    }
}

/// The metaball layer. Animatable so the spring interpolates `progress` and the Canvas redraws every frame.
private struct GooeyGlassLayer: View, Animatable {
    var progress: CGFloat
    let gap: CGFloat
    let goo: CGFloat
    let main: CGFloat
    let small: CGFloat
    let inset: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            LinearGradient(
                stops: [
                    .init(color: Palette.indigo.opacity(0.6), location: 0),
                    .init(color: Palette.indigo.opacity(0.5), location: 0.2),
                    .init(color: .white.opacity(0.14), location: 0.34),
                    .init(color: .white.opacity(0.14), location: 1),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            // Soft specular sheen across the top of every drop.
            LinearGradient(colors: [.white.opacity(0.35), .clear], startPoint: .top, endPoint: .center)
        }
        .mask {
            Canvas { context, size in
                context.addFilter(.alphaThreshold(min: 0.5, color: .white))
                context.addFilter(.blur(radius: goo))
                context.drawLayer { layer in
                    for rect in circles(in: size) {
                        layer.fill(Path(ellipseIn: rect), with: .color(.white))
                    }
                }
            }
        }
    }

    private func circles(in size: CGSize) -> [CGRect] {
        let centerY = size.height / 2
        let mainX = inset + main / 2
        var rects = [CGRect(x: mainX - main / 2, y: centerY - main / 2, width: main, height: main)]
        // Drops grow from a bud to full size while they travel (the spring may overshoot the travel).
        let grow = min(max(progress, 0), 1)
        let radius = small / 2 * (0.45 + 0.55 * grow)
        for index in 0..<glassActions.count {
            let travel = (main / 2 + gap + small / 2 + CGFloat(index) * (small + gap)) * progress
            rects.append(CGRect(x: mainX + travel - radius, y: centerY - radius, width: radius * 2, height: radius * 2))
        }
        return rects
    }
}

private struct GlassBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Palette.violet, Palette.pink, Palette.amber], startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle()
                .fill(Palette.sky)
                .frame(width: 180, height: 180)
                .blur(radius: 30)
                .offset(x: -90, y: -80)
            Circle()
                .fill(Palette.mint.opacity(0.8))
                .frame(width: 140, height: 140)
                .blur(radius: 24)
                .offset(x: 110, y: 90)
            Text("Aa")
                .font(.system(size: 120, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.25))
                .offset(y: -6)
        }
    }
}
