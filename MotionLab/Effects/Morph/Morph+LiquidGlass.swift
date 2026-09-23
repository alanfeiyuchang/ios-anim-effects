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
            "A single tinted Liquid Glass button with a plus glyph floats over a vivid gradient. On tap, three secondary glass buttons bud out of it to the right, each first appearing as a bulge on the parent's edge, stretching into a liquid bridge and then pinching off into its own 56 pt circle as it springs into place (response ≈0.5 s, damping ≈0.75); the glass refracts and specular-highlights the backdrop continuously as shapes merge and separate. The plus rotates 45° into a close glyph. Collapsing reverses it: buttons are drawn back and melt into the parent like droplets merging. Glass responds to touch with the interactive glass bounce.",
            "一枚带加号、着色的液态玻璃按钮悬浮在鲜艳的渐变背景上。点击后，三个次级玻璃按钮从它右侧「分裂」而出：先在母按钮边缘鼓起，再拉伸成液体般的连接桥，最后断开成各自 56pt 的圆形，并以弹簧（响应约 0.5 秒、阻尼约 0.75）落位；在形状融合与分离的全过程中，玻璃持续折射背景并带有高光。加号旋转 45° 变为关闭符号。收起时反向进行：按钮被吸回并像水滴汇合一样融进母按钮。玻璃在触摸时带有交互式回弹。"
        ),
        implementation: L(
            "On iOS 26, buttons live in a GlassEffectContainer and carry glassEffect(.regular.interactive()) plus glassEffectID in a shared namespace so SwiftUI morphs the glass shapes; earlier systems fall back to material circles that scale out of the main button.",
            "iOS 26 上按钮位于 GlassEffectContainer 中，使用 glassEffect(.regular.interactive()) 与共享命名空间的 glassEffectID，由 SwiftUI 负责玻璃形状的融合形变；更早的系统回退为从主按钮缩放而出的材质圆形。"
        ),
        apis: ["GlassEffectContainer", "glassEffect(_:in:)", "glassEffectID(_:in:)", "Glass.interactive()", "ultraThinMaterial"],
        tags: ["liquid glass", "glass", "ios 26", "metaball", "液态玻璃", "玻璃", "融合", "水滴"],
        params: [
            .slider("spacing", L("Merge distance", "融合距离"), 0...60, default: 30, decimals: 0, unit: "pt"),
            .slider("gap", L("Button gap", "按钮间距"), 4...30, default: 12, decimals: 0, unit: "pt"),
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
        .autoplay(ctx.isPreview, every: 1.8) { toggle() }
    }

    @ViewBuilder private var toolbar: some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            GlassToolbar(expanded: expanded, spacing: ctx.cg("spacing"), gap: ctx.cg("gap"), onToggle: toggle)
        } else {
            FallbackToolbar(expanded: expanded, gap: ctx.cg("gap"), onToggle: toggle)
        }
        #else
        FallbackToolbar(expanded: expanded, gap: ctx.cg("gap"), onToggle: toggle)
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

    var body: some View {
        GlassEffectContainer(spacing: spacing) {
            HStack(spacing: gap) {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(expanded ? 45 : 0))
                    .frame(width: 64, height: 64)
                    .contentShape(Circle())
                    .glassEffect(.regular.tint(Palette.indigo.opacity(0.55)).interactive(), in: .circle)
                    .glassEffectID("main", in: glass)
                    .onTapGesture(perform: onToggle)
                if expanded {
                    ForEach(glassActions, id: \.self) { symbol in
                        Image(systemName: symbol)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
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

private struct FallbackToolbar: View {
    let expanded: Bool
    let gap: CGFloat
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: gap) {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(expanded ? 45 : 0))
                .frame(width: 64, height: 64)
                .background(Palette.indigo.opacity(0.55), in: Circle())
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 1))
                .contentShape(Circle())
                .onTapGesture(perform: onToggle)
                .zIndex(1)
            if expanded {
                ForEach(Array(glassActions.enumerated()), id: \.element) { index, symbol in
                    Image(systemName: symbol)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 1))
                        .contentShape(Circle())
                        .onTapGesture(perform: onToggle)
                        .transition(
                            .scale(scale: 0.2)
                                .combined(with: .offset(x: -CGFloat(index + 1) * (56 + gap)))
                                .combined(with: .opacity)
                        )
                }
            }
        }
        .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
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
