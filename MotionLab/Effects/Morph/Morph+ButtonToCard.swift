import SwiftUI

extension Effect {
    static let morphButtonToCard = Effect(
        id: "morph.button-to-card",
        category: .morph,
        interaction: .tap,
        name: L("Button to Card", "按钮变卡片"),
        summary: L(
            "A pill button fluidly grows into a content card, then folds back into itself.",
            "胶囊按钮流畅地生长为一张内容卡片，再无缝收回原形。"
        ),
        prompt: L(
            "A 54 pt gradient pill button with a sparkle glyph rests at the bottom of the screen. On tap it becomes the card: a shared-element morph grows its background into a 300 pt-wide card anchored to the same bottom edge, interpolating width, height and continuous corner radius (27 → 30 pt) on a single spring (response ≈0.5 s, damping ≈0.82), while the icon and title glide along with it into the card header. As the card settles, its body — three feature rows and a white call-to-action — rises 10 pt from a 6 pt blur, staggered about 60 ms per row, and the page behind recedes to 95% scale with a soft blur. Closing reverses it: the body fades out within 120 ms first, then the card folds back into the pill. It should feel like one physical object changing shape, never a screen being swapped.",
            "底部一枚高 54pt 的渐变胶囊按钮，带星光图标。点击后按钮本身「长成」卡片：通过共享元素（matched geometry）形变，背景向上扩展为宽 300pt、底边对齐的内容卡片，宽、高与连续圆角（27 → 30pt）由同一条弹簧曲线（响应约 0.5 秒、阻尼约 0.82）驱动；图标与标题随之平滑滑入卡片页眉。卡片落定后，三行功能说明与白色主按钮从 6pt 模糊中上浮 10pt 依次出现，每行错开约 60 毫秒；背后的页面同步缩小到 95% 并轻微虚化。收起时先在 120 毫秒内淡出正文，再让卡片收拢回胶囊。整体要像同一个实体在改变形态，而不是切换了一个页面。"
        ),
        implementation: L(
            "Pill and card are two views sharing matchedGeometryEffect ids for background, icon and title; card body rows are revealed by a state flipped in onAppear with per-row delayed springs, and collapse runs a completion-chained withAnimation.",
            "胶囊与卡片是两个视图，背景、图标和标题共享 matchedGeometryEffect ID；卡片正文由 onAppear 中切换的状态驱动逐行延迟弹簧出现，收起时用带 completion 的 withAnimation 串联两段动画。"
        ),
        apis: ["matchedGeometryEffect", "@Namespace", "withAnimation(_:completion:)", "spring(response:dampingFraction:)", "blur(radius:)"],
        tags: ["hero", "shared element", "expand", "container transform", "共享元素", "展开", "按钮变形", "卡片"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.2...1.0, default: 0.5, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.82),
            .slider("stagger", L("Content stagger", "内容错开"), 0.0...0.15, default: 0.06, decimals: 3, unit: "s"),
            .toggle("recede", L("Recede background", "背景后退"), default: true),
        ]
    ) { ctx in
        ButtonToCardDemo(ctx: ctx)
    }
}

// MARK: - Demo

private struct ButtonToCardDemo: View {
    let ctx: DemoContext
    @Namespace private var ns
    @State private var expanded = false
    @State private var showContent = false

    private var spring: Animation {
        .spring(response: ctx["response"], dampingFraction: ctx["damping"])
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            BackdropList(receded: expanded && ctx.bool("recede"), language: ctx.language)
            if expanded {
                ProCard(ns: ns, ctx: ctx, showContent: $showContent, onClose: toggle)
            } else {
                ProPill(ns: ns, ctx: ctx, onTap: toggle)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.4) { toggle() }
    }

    private func toggle() {
        if !ctx.isPreview { Haptics.tap(.medium) }
        if expanded {
            withAnimation(.easeOut(duration: 0.12)) {
                showContent = false
            } completion: {
                withAnimation(spring) { expanded = false }
            }
        } else {
            withAnimation(spring) { expanded = true }
        }
    }
}

// MARK: - Pieces

private struct ProPill: View {
    let ns: Namespace.ID
    let ctx: DemoContext
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .matchedGeometryEffect(id: "icon", in: ns)
                Text(ctx.language == .zh ? "升级 Pro" : "Go Pro")
                    .matchedGeometryEffect(id: "title", in: ns)
            }
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .frame(height: 54)
            .background {
                RoundedRectangle(cornerRadius: 27, style: .continuous)
                    .fill(Palette.primary)
                    .matchedGeometryEffect(id: "bg", in: ns)
                    .shadow(color: Palette.indigo.opacity(0.35), radius: 14, y: 8)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct ProCard: View {
    let ns: Namespace.ID
    let ctx: DemoContext
    @Binding var showContent: Bool
    let onClose: () -> Void

    private var zh: Bool { ctx.language == .zh }

    private var features: [(String, String)] {
        zh
            ? [("wand.and.stars", "全部 300+ 动效"), ("slider.horizontal.3", "实时参数调节"), ("doc.on.doc", "一键复制提示词")]
            : [("wand.and.stars", "All 300+ effects"), ("slider.horizontal.3", "Live parameter tuning"), ("doc.on.doc", "One-tap prompt copy")]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, item in
                    Label(item.1, systemImage: item.0)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.92))
                        .modifier(StaggerReveal(visible: showContent, delay: 0.08 + Double(index) * ctx["stagger"]))
                }
            }
            cta
                .modifier(StaggerReveal(visible: showContent, delay: 0.08 + 3 * ctx["stagger"]))
        }
        .padding(22)
        .frame(width: 300, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Palette.primary)
                .overlay {
                    RadialGradient(colors: [.white.opacity(0.28), .clear], center: .topLeading, startRadius: 0, endRadius: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                }
                .matchedGeometryEffect(id: "bg", in: ns)
                .shadow(color: Palette.indigo.opacity(0.35), radius: 24, y: 14)
        }
        .onAppear { showContent = true }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "sparkles")
                .matchedGeometryEffect(id: "icon", in: ns)
            Text(zh ? "升级 Pro" : "Go Pro")
                .matchedGeometryEffect(id: "title", in: ns)
            Spacer(minLength: 0)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .frame(width: 28, height: 28)
                    .background(.white.opacity(0.2), in: Circle())
            }
            .buttonStyle(.plain)
            .modifier(StaggerReveal(visible: showContent, delay: 0.05))
        }
        .font(.headline)
        .foregroundStyle(.white)
    }

    private var cta: some View {
        Button(action: onClose) {
            Text(zh ? "继续 · ¥28/月" : "Continue · $3.99/mo")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.indigo)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(.white, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct BackdropList: View {
    let receded: Bool
    let language: AppLanguage

    private let rows: [(String, [Color], LocalizedText, LocalizedText)] = [
        ("sparkles", [Palette.indigo, Palette.violet], L("Spring Button", "弹簧按钮"), L("Buttons · 3 params", "按钮 · 3 个参数")),
        ("rectangle.stack.fill", [Palette.pink, Palette.coral], L("Wallet Stack", "钱包卡片堆叠"), L("Cards · 4 params", "卡片 · 4 个参数")),
        ("waveform", [Palette.mint, Palette.sky], L("Audio Wave", "音频波形"), L("Loading · 4 params", "加载 · 4 个参数")),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(0..<rows.count, id: \.self) { index in
                let row = rows[index]
                HStack(spacing: 12) {
                    Image(systemName: row.0)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            LinearGradient(colors: row.1, startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.2, language)
                            .font(.subheadline.weight(.semibold))
                        Text(row.3, language)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 32) // clear the stage's reset button
        .scaleEffect(receded ? 0.95 : 1, anchor: .top)
        .blur(radius: receded ? 6 : 0)
        .opacity(receded ? 0.5 : 1)
    }
}

/// Rises from a blur with a per-item delay when `visible` flips on; fades out quickly when it flips off.
private struct StaggerReveal: ViewModifier {
    let visible: Bool
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 10)
            .blur(radius: visible ? 0 : 6)
            .animation(
                visible ? .spring(response: 0.45, dampingFraction: 0.86).delay(delay) : .easeOut(duration: 0.12),
                value: visible
            )
    }
}
