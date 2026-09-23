import SwiftUI

extension Effect {
    static let buttonsGooeySplit = Effect(
        id: "buttons.gooey-split",
        category: .buttons,
        interaction: .tap,
        name: L("Gooey Split", "粘滞分裂"),
        summary: L("A Share pill pinches apart into three liquid action bubbles.", "“分享”胶囊像液体一样拉丝分裂成三个操作气泡。"),
        prompt: L(
            "Under a small post card sits a 200 × 56 pt indigo-violet \"Share\" pill. On tap the pill contracts to a 56 pt circle while two circles bud out of its sides and travel 84 pt left and right on an underdamped spring (response 0.55 s, damping 0.62). Because the shapes are blurred and alpha-thresholded together, they stay joined by stretchy liquid necks that thin and snap as they separate, then wobble into three clean bubbles — message, link and mail — whose glyphs fade and scale in 80 ms behind the motion. Each bubble is its own button: touch-down shrinks its glyph to 86% under a soft white highlight, and releasing fires a success haptic, drops a small \"Link copied\"-style confirmation capsule below and pulls everything back in — the necks re-form and the drops merge into the pill as the label returns. The metaball edge gets a sub-point feather so it never looks aliased. Organic, tactile, a little magical.",
            "一张小型动态卡片下方是一枚 200 × 56pt 的靛紫色“分享”胶囊。点击后，胶囊收缩成 56pt 的圆，两侧同时“长出”两个圆形，以欠阻尼弹簧（响应 0.55 秒、阻尼 0.62）分别向左右移动 84pt。由于这些形状一起经过模糊与透明度阈值处理，分离过程中彼此之间会拉出有弹性的液体细颈，细颈逐渐变细、断开，最后晃动着落定为三个干净的气泡——消息、链接与邮件，图标比运动晚 80 毫秒缩放淡入。每个气泡都是独立按钮：按下时图标缩到 86% 并浮现柔和白色高光，松手触发成功触觉，下方弹出“链接已复制”之类的确认小胶囊，同时把气泡吸回——细颈重新连起，液滴融回胶囊，文字重新出现。液体边缘带不到 1pt 的羽化，避免锯齿。有机、可触、带一点魔法感。"
        ),
        implementation: L(
            "An Animatable view receives the spring-interpolated progress and redraws a Canvas whose layer stacks alphaThreshold on blur (the metaball trick); the Canvas masks a LinearGradient, and plain SwiftUI glyphs ride the same spring above it.",
            "Animatable 视图接收弹簧插值后的进度，重绘一个在图层上叠加 alphaThreshold 与 blur 滤镜的 Canvas（经典 metaball 技巧）；Canvas 作为 LinearGradient 的遮罩，普通 SwiftUI 图标以同一弹簧在其上方移动。"
        ),
        apis: ["Canvas", "GraphicsContext.Filter.alphaThreshold", "GraphicsContext.Filter.blur", "Animatable", "mask"],
        tags: ["gooey", "metaball", "liquid", "share", "粘滞", "液体", "融合", "分享"],
        params: [
            .slider("spread", L("Spread", "分离距离"), 64...100, default: 84, decimals: 0, unit: "pt"),
            .slider("goo", L("Gooeyness", "粘稠度"), 4...14, default: 9, decimals: 0),
            .slider("damping", L("Damping", "阻尼"), 0.4...0.95, default: 0.62),
        ]
    ) { ctx in
        ButtonGooeySplitDemo(ctx: ctx)
    }
}

private struct ButtonGooeyAction {
    let symbol: String
    let side: CGFloat
    let done: LocalizedText
}

/// Touch-down feedback for a single gooey bubble: glyph shrinks under a soft highlight.
private struct ButtonGooeyBubbleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.86 : 1)
            .background(Circle().fill(Color.white.opacity(configuration.isPressed ? 0.22 : 0)))
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

private struct ButtonGooeySplitDemo: View {
    let ctx: DemoContext
    @State private var open = false
    @State private var confirmation: LocalizedText?
    @State private var confirmTask: Task<Void, Never>?

    private let actions: [ButtonGooeyAction] = [
        ButtonGooeyAction(symbol: "message.fill", side: -1, done: L("Sent to Messages", "已发送到信息")),
        ButtonGooeyAction(symbol: "link", side: 0, done: L("Link copied", "链接已复制")),
        ButtonGooeyAction(symbol: "envelope.fill", side: 1, done: L("Mail draft created", "已创建邮件草稿")),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 26) {
                postCard
                share
                    .padding(.bottom, 24)
            }
            Spacer()
            DemoHint(text: L("Tap Share, then pick a bubble", "点击分享，再选一个气泡"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.8, delay: 0.5) { toggle() }
    }

    private var postCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Palette.aurora)
                .frame(height: 96)
                .overlay(alignment: .bottomLeading) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(12)
                }
            Text(ctx.language == .zh ? "极光配色 · 第 12 期" : "Aurora palette · Issue 12")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(12)
        .frame(width: 240)
        .demoCard(cornerRadius: 22)
    }

    private var share: some View {
        let spring = Animation.spring(response: 0.55, dampingFraction: ctx["damping"])
        let spread = ctx.cg("spread")
        return ZStack {
            ButtonGooeyBlob(progress: open ? 1 : 0, spread: spread, goo: ctx.cg("goo"))
                .shadow(color: Palette.indigo.opacity(0.35), radius: 14, y: 8)
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .accessibilityHidden(true)
                Text(ctx.language == .zh ? "分享" : "Share")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .opacity(open ? 0 : 1)
            .scaleEffect(open ? 0.7 : 1)
            .animation(.easeOut(duration: open ? 0.12 : 0.25).delay(open ? 0 : 0.2), value: open)
            ForEach(actions.indices, id: \.self) { index in
                let action = actions[index]
                Button { perform(action) } label: {
                    Image(systemName: action.symbol)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .contentShape(Circle())
                }
                .buttonStyle(ButtonGooeyBubbleStyle())
                .accessibilityLabel(Text(action.done, ctx.language))
                .allowsHitTesting(open)
                .offset(x: open ? action.side * spread : 0)
                .scaleEffect(open ? 1 : 0.3)
                .opacity(open ? 1 : 0)
                .animation(open ? spring.delay(0.08) : Animation.easeIn(duration: 0.12), value: open)
            }
        }
        .frame(width: 320, height: 110)
        .animation(spring, value: open)
        .contentShape(Rectangle())
        .onTapGesture { toggle() }
        .overlay(alignment: .bottom) { confirmationChip.offset(y: 30) }
    }

    @ViewBuilder
    private var confirmationChip: some View {
        if let confirmation {
            Label {
                Text(confirmation, ctx.language)
            } icon: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Palette.green)
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Palette.stroke))
            .transition(.move(edge: .top).combined(with: .opacity))
            .id(confirmation.en)
        }
    }

    private func toggle() {
        if !ctx.isPreview { Haptics.tap(open ? .soft : .light) }
        open.toggle()
    }

    private func perform(_ action: ButtonGooeyAction) {
        guard open else { return }
        Haptics.success()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { confirmation = action.done }
        confirmTask?.cancel()
        confirmTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(220))
            guard !Task.isCancelled else { return }
            open = false
            try? await Task.sleep(for: .seconds(1.4))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) { confirmation = nil }
        }
    }
}

/// The metaball layer. Animatable so the spring interpolates `progress` and the Canvas redraws every frame.
private struct ButtonGooeyBlob: View, Animatable {
    var progress: CGFloat
    let spread: CGFloat
    let goo: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    private let diameter: CGFloat = 56
    private let pillWidth: CGFloat = 200

    var body: some View {
        LinearGradient(colors: [Palette.indigo, Palette.violet], startPoint: .leading, endPoint: .trailing)
            .mask {
                Canvas { context, size in
                    context.addFilter(.alphaThreshold(min: 0.5, color: .white))
                    context.addFilter(.blur(radius: goo))
                    context.drawLayer { layer in
                        for rect in shapes(in: size) {
                            let path = Path(roundedRect: rect, cornerRadius: diameter / 2, style: .continuous)
                            layer.fill(path, with: .color(.white))
                        }
                    }
                }
                // Feather the thresholded edge by a fraction of a point so the curve never looks aliased.
                .blur(radius: 0.7)
            }
    }

    private func shapes(in size: CGSize) -> [CGRect] {
        let mid = CGPoint(x: size.width / 2, y: size.height / 2)
        // The pill only shrinks (clamped), while the side drops may overshoot with the spring.
        let squeeze = min(max(progress, 0), 1)
        let width = diameter + (pillWidth - diameter) * (1 - squeeze)
        var rects = [CGRect(x: mid.x - width / 2, y: mid.y - diameter / 2, width: width, height: diameter)]
        for side in [CGFloat(-1), CGFloat(1)] {
            let x = mid.x + side * spread * progress
            rects.append(CGRect(x: x - diameter / 2, y: mid.y - diameter / 2, width: diameter, height: diameter))
        }
        return rects
    }
}
