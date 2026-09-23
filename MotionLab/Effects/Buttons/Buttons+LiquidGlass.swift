import SwiftUI

extension Effect {
    static let buttonsLiquidGlass = Effect(
        id: "buttons.liquid-glass",
        category: .buttons,
        interaction: .tap,
        name: L("Liquid Glass Save Button", "液态玻璃收藏按钮"),
        summary: L(
            "A tinted glass “Save” pill melts into a check and buds off an Undo button.",
            "着色玻璃“收藏”胶囊融化成对勾，并分裂出一枚“撤销”按钮。"
        ),
        prompt: L(
            "Over a vivid landscape photo card, a 52 pt orange-tinted Liquid Glass capsule reads “Save to trip” with a bookmark glyph, and a round glass heart button floats in the top corner. Touching any glass button gives the system's interactive glass response — a slight swell and a specular glint that follows the finger. On tap the capsule morphs, as one continuous piece of glass, into a green-tinted 52 pt check circle while an “Undo” glass capsule buds out of its trailing edge, joined by a liquid bridge until they are ~16 pt apart, then pinches off; everything rides one spring (response 0.45 s, damping 0.8) and a success haptic fires. Undo (or the check) melts the two drops back into the Save pill. Before iOS 26 the same choreography uses frosted-material capsules with a gradient rim and a matched-geometry morph. Fluid, optical and quietly premium.",
            "一张色彩饱满的风景照片卡片上，悬浮着一枚 52pt、橙色着色的液态玻璃胶囊“收藏到行程”（带书签图标），右上角还有一枚圆形玻璃爱心按钮。触摸任何玻璃按钮都会有系统的交互式玻璃反馈——轻微膨胀，并有一道随手指移动的高光。点击后，胶囊作为一整块玻璃连续形变为 52pt 的绿色对勾圆，同时从其右缘“长出”一枚“撤销”玻璃胶囊；两者在相距约 16pt 之前由液态桥连接，随后断开。全部由同一弹簧（响应 0.45 秒、阻尼 0.8）驱动，并触发成功触感。点击“撤销”（或对勾）两颗液滴又融回“收藏”胶囊。iOS 26 之前以磨砂材质胶囊加渐变描边，通过 matchedGeometryEffect 完成同样的编排。流动、通透，低调而高级。"
        ),
        implementation: L(
            "On iOS 26 the pills sit in a GlassEffectContainer(spacing:) and carry glassEffect(.regular.tint(…).interactive(), in: .capsule/.circle) plus glassEffectID in one namespace, so SwiftUI melts and splits the glass as the saved flag flips inside a spring; the heart uses .buttonStyle(.glass). Guarded by #if compiler(>=6.2) and #available, with a material + matchedGeometryEffect fallback.",
            "iOS 26 上，胶囊位于 GlassEffectContainer(spacing:) 中，使用 glassEffect(.regular.tint(…).interactive(), in: .capsule/.circle) 与同一命名空间的 glassEffectID；在弹簧中切换收藏状态时，SwiftUI 自动完成玻璃的融合与分裂；爱心按钮使用 .buttonStyle(.glass)。以 #if compiler(>=6.2) 与 #available 保护，回退为材质胶囊 + matchedGeometryEffect。"
        ),
        apis: ["GlassEffectContainer", "glassEffect(_:in:)", "glassEffectID(_:in:)", "buttonStyle(.glass)", "matchedGeometryEffect"],
        tags: ["liquid glass", "glass button", "ios 26", "morph", "液态玻璃", "玻璃按钮", "收藏", "形变"],
        params: [
            .slider("spacing", L("Merge distance", "融合距离"), 0...40, default: 16, decimals: 0, unit: "pt"),
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.9, default: 0.45, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.8),
        ],
        requirement: "iOS 26"
    ) { ctx in
        ButtonLiquidGlassDemo(ctx: ctx)
    }
}

private struct ButtonLiquidGlassDemo: View {
    let ctx: DemoContext
    @State private var saved = false
    @State private var liked = false

    private var zh: Bool { ctx.language == .zh }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            card
            Spacer(minLength: 0)
            DemoHint(text: L("Tap Save, then Undo", "点击收藏，再点撤销"), ctx: ctx)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.8, delay: 0.5) { toggle() }
    }

    private var card: some View {
        ZStack(alignment: .bottom) {
            LandscapeArt(seed: 1)
            LinearGradient(colors: [.clear, Color.black.opacity(0.35)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 2) {
                Text(zh ? "法国 · 尼斯" : "France · Nice")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
                Text(zh ? "天使湾日落" : "Sunset on the Baie")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(18)
            actions
                .padding(.bottom, 20)
        }
        .overlay(alignment: .topTrailing) {
            ButtonGlassHeart(liked: liked) {
                if !ctx.isPreview { Haptics.tap() }
                withAnimation(.snappy) { liked.toggle() }
            }
            .padding(14)
        }
        .frame(width: 300, height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 18, y: 10)
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder private var actions: some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            ButtonGlassActions(saved: saved, spacing: ctx.cg("spacing"), language: ctx.language, onToggle: toggle)
        } else {
            ButtonFallbackGlassActions(saved: saved, language: ctx.language, onToggle: toggle)
        }
        #else
        ButtonFallbackGlassActions(saved: saved, language: ctx.language, onToggle: toggle)
        #endif
    }

    private func toggle() {
        if !ctx.isPreview {
            if saved { Haptics.tap(.soft) } else { Haptics.success() }
        }
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            saved.toggle()
        }
    }
}

// MARK: - iOS 26

#if compiler(>=6.2)
@available(iOS 26.0, *)
private struct ButtonGlassActions: View {
    let saved: Bool
    let spacing: CGFloat
    let language: AppLanguage
    let onToggle: () -> Void
    @Namespace private var glass

    var body: some View {
        GlassEffectContainer(spacing: spacing) {
            HStack(spacing: 10) {
                if saved {
                    Button(action: onToggle) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.tint(Palette.green.opacity(0.7)).interactive(), in: .circle)
                    .glassEffectID("primary", in: glass)
                    .accessibilityLabel(Text(L("Saved", "已收藏"), language))
                    Button(action: onToggle) {
                        Label {
                            Text(L("Undo", "撤销"), language)
                        } icon: {
                            Image(systemName: "arrow.uturn.backward")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .frame(height: 52)
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .glassEffectID("undo", in: glass)
                } else {
                    Button(action: onToggle) {
                        Label {
                            Text(L("Save to trip", "收藏到行程"), language)
                        } icon: {
                            Image(systemName: "bookmark.fill")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .frame(height: 52)
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.tint(Signature.accent.opacity(0.65)).interactive(), in: .capsule)
                    .glassEffectID("primary", in: glass)
                }
            }
        }
    }
}
#endif

/// Round heart in the corner: the system glass button style on iOS 26, a material circle before.
private struct ButtonGlassHeart: View {
    let liked: Bool
    let action: () -> Void

    var body: some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            Button(action: action) { glyph }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
        } else {
            fallback
        }
        #else
        fallback
        #endif
    }

    private var glyph: some View {
        Image(systemName: liked ? "heart.fill" : "heart")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(liked ? Palette.pink : Color.white)
            .contentTransition(.symbolEffect(.replace))
            .frame(width: 24, height: 24)
    }

    private var fallback: some View {
        Button(action: action) {
            glyph
                .frame(width: 44, height: 44)
                .background { ButtonFallbackGlass(shape: Circle(), tint: nil) }
        }
        .buttonStyle(SportPressStyle(scale: 0.9, dim: 0.05))
    }
}

// MARK: - iOS 18 fallback

/// A frosted stand-in for Liquid Glass: material, optional tint, a bright top rim fading to the bottom.
private struct ButtonFallbackGlass<S: Shape>: View {
    let shape: S
    let tint: Color?

    var body: some View {
        ZStack {
            shape.fill(.ultraThinMaterial)
            if let tint {
                shape.fill(tint.opacity(0.55))
            }
            shape.fill(LinearGradient(colors: [Color.white.opacity(0.22), .clear], startPoint: .top, endPoint: .center))
            shape.stroke(
                LinearGradient(colors: [Color.white.opacity(0.65), Color.white.opacity(0.1)], startPoint: .top, endPoint: .bottom),
                lineWidth: 1
            )
        }
    }
}

private struct ButtonFallbackGlassActions: View {
    let saved: Bool
    let language: AppLanguage
    let onToggle: () -> Void
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 10) {
            if saved {
                Button(action: onToggle) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background {
                            ButtonFallbackGlass(shape: Capsule(), tint: Palette.green)
                                .matchedGeometryEffect(id: "primary", in: ns)
                        }
                }
                .buttonStyle(SportPressStyle(scale: 0.94, dim: 0.04))
                .accessibilityLabel(Text(L("Saved", "已收藏"), language))
                Button(action: onToggle) {
                    Label {
                        Text(L("Undo", "撤销"), language)
                    } icon: {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .frame(height: 52)
                    .background { ButtonFallbackGlass(shape: Capsule(), tint: nil) }
                }
                .buttonStyle(SportPressStyle(scale: 0.94, dim: 0.04))
                .transition(.scale(scale: 0.3, anchor: .leading).combined(with: .opacity))
            } else {
                Button(action: onToggle) {
                    Label {
                        Text(L("Save to trip", "收藏到行程"), language)
                    } icon: {
                        Image(systemName: "bookmark.fill")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .frame(height: 52)
                    .background {
                        ButtonFallbackGlass(shape: Capsule(), tint: Signature.accent)
                            .matchedGeometryEffect(id: "primary", in: ns)
                    }
                }
                .buttonStyle(SportPressStyle(scale: 0.94, dim: 0.04))
            }
        }
    }
}
