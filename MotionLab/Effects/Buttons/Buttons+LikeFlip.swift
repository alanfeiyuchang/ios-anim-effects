import SwiftUI

extension Effect {
    static let buttonsLikeFlip = Effect(
        id: "buttons.like-flip",
        category: .buttons,
        interaction: .tap,
        name: L("Coin-Flip Heart", "翻币爱心"),
        summary: L("The like button hops and flips like a coin to reveal its filled side.", "点赞按钮像硬币一样跳起翻面，露出实心的一面。"),
        prompt: L(
            "A 92 pt coin-like disc on a recipe card: the front is a soft neutral face with an outlined heart, the back a glossy pink-to-coral face with a white filled heart. On tap the coin hops 34 pt (250 ms up, ease-out; 250 ms down, ease-in) while flipping 180° around its vertical axis on a spring (response 0.6 s, damping 0.7) with strong perspective; the face swaps exactly when the disc is edge-on. A diagonal glint sweeps across it at the top of the hop, its ground shadow shrinks to 60% and fades while airborne, and on landing it squashes to 92% tall before settling. A success haptic lands with it. Tapping again flips it onward to the neutral side. Playful, tangible and a little lucky.",
            "一张菜谱卡片上有一枚 92pt 的硬币状圆盘：正面是柔和中性色配空心爱心，背面是粉到珊瑚色的光亮面配白色实心爱心。点击后硬币向上跳起 34pt（上升 250 毫秒 ease-out，下落 250 毫秒 ease-in），同时绕竖直轴以弹簧（响应 0.6 秒、阻尼 0.7）翻转 180°，透视感强烈；圆盘侧立的瞬间正好切换正反面。跳到最高点时一道斜向高光扫过盘面，地面投影在空中缩小到 60% 并变淡，落地时高度被压扁到 92% 再回弹。落地伴随成功触感。再次点击则继续翻到中性面。俏皮、有实物感，还带点好运气。"
        ),
        implementation: L(
            "An Animatable view receives the accumulated flip angle and picks the visible face from it (the back is pre-rotated 180°), under rotation3DEffect with perspective; a keyframeAnimator on a flip counter drives hop, squash, glint and shadow.",
            "一个 Animatable 视图接收累计的翻转角度，并据此选择可见的一面（背面预先旋转 180°），外层使用带透视的 rotation3DEffect；以翻转计数触发的 keyframeAnimator 驱动跳起、压扁、高光与投影。"
        ),
        apis: ["Animatable", "rotation3DEffect", "keyframeAnimator", "KeyframeTrack", "spring(response:dampingFraction:)"],
        tags: ["like", "flip", "coin", "3d", "点赞", "翻转", "硬币", "立体"],
        params: [
            .slider("hop", L("Hop height", "跳起高度"), 0...60, default: 34, decimals: 0, unit: "pt"),
            .slider("response", L("Flip response", "翻转响应"), 0.3...1.0, default: 0.6, unit: "s"),
            .choice("axis", L("Flip axis", "翻转轴"), [L("Vertical", "竖直"), L("Horizontal", "水平")], default: 0),
        ]
    ) { ctx in
        ButtonLikeFlipDemo(ctx: ctx)
    }
}

private struct ButtonCoinHop {
    var lift: CGFloat = 0
    var squash: CGFloat = 1
    var glint: CGFloat = -1
    var shadow: CGFloat = 1
}

private struct ButtonLikeFlipDemo: View {
    let ctx: DemoContext
    @State private var angle: Double = 0
    @State private var flips = 0
    @State private var saves = 312

    private var liked: Bool { flips % 2 == 1 }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            card
            Spacer()
            DemoHint(text: L("Tap the coin", "点击硬币"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.5, delay: 0.4) { flip() }
    }

    private var card: some View {
        VStack(spacing: 12) {
            coin
                .frame(height: 150, alignment: .bottom)
            Text(L("Lemon ricotta pancakes", "柠檬乳清松饼"), ctx.language)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(L("\(saves) cooks loved this", "\(saves) 位厨友喜欢"), ctx.language)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(liked ? Palette.pink : Color.secondary)
                .contentTransition(.numericText(value: Double(saves)))
        }
        .padding(20)
        .frame(width: 280)
        .demoCard(cornerRadius: 26)
    }

    private var coin: some View {
        let hop = ctx.cg("hop")
        let horizontalAxis = ctx.int("axis") == 1
        return Button(action: flip) {
            ButtonCoinFaces(angle: angle, horizontalAxis: horizontalAxis)
                .keyframeAnimator(initialValue: ButtonCoinHop(), trigger: flips) { content, value in
                    content
                        .overlay { ButtonCoinGlint(position: value.glint) }
                        .scaleEffect(x: 1, y: value.squash, anchor: .bottom)
                        .offset(y: -value.lift)
                        .background(alignment: .bottom) {
                            Ellipse()
                                .fill(Color.black.opacity(0.18 * Double(value.shadow)))
                                .frame(width: 70 * value.shadow, height: 12)
                                .blur(radius: 4)
                                .offset(y: 10)
                        }
                } keyframes: { _ in
                    KeyframeTrack(\.lift) {
                        CubicKeyframe(hop, duration: 0.25)
                        CubicKeyframe(0, duration: 0.25)
                        CubicKeyframe(0, duration: 0.3)
                    }
                    KeyframeTrack(\.squash) {
                        LinearKeyframe(1, duration: 0.5)
                        CubicKeyframe(0.92, duration: 0.08)
                        SpringKeyframe(1, duration: 0.35, spring: .bouncy)
                    }
                    KeyframeTrack(\.glint) {
                        LinearKeyframe(-1, duration: 0.15)
                        CubicKeyframe(1, duration: 0.3)
                    }
                    KeyframeTrack(\.shadow) {
                        CubicKeyframe(0.6, duration: 0.25)
                        CubicKeyframe(1, duration: 0.25)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(liked ? L("Unlike", "取消喜欢") : L("Like", "喜欢"), ctx.language))
    }

    private func flip() {
        flips += 1
        withAnimation(.spring(response: ctx["response"], dampingFraction: 0.7)) {
            angle += 180
            saves += liked ? 1 : -1
        }
        let muted = Haptics.isMuted
        let nowLiked = liked
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(480))
            guard !muted else { return }
            if nowLiked { Haptics.success() } else { Haptics.tap() }
        }
    }
}

/// Picks the visible face from the animated angle, so the swap happens exactly edge-on.
private struct ButtonCoinFaces: View, Animatable {
    var angle: Double
    /// false: spin around the vertical (y) axis; true: tumble around the horizontal (x) axis.
    let horizontalAxis: Bool

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    var body: some View {
        let remainder = angle.truncatingRemainder(dividingBy: 360)
        let normalized = remainder < 0 ? remainder + 360 : remainder
        let showBack = normalized > 90 && normalized < 270
        let axis: (x: CGFloat, y: CGFloat, z: CGFloat) = horizontalAxis ? (x: 1, y: 0, z: 0) : (x: 0, y: 1, z: 0)
        ZStack {
            front.opacity(showBack ? 0 : 1)
            back
                .rotation3DEffect(.degrees(180), axis: axis)
                .opacity(showBack ? 1 : 0)
        }
        .frame(width: 92, height: 92)
        .rotation3DEffect(.degrees(angle), axis: axis, perspective: 0.6)
    }

    private var front: some View {
        Circle()
            .fill(LinearGradient(colors: [Palette.elevated, Palette.surface], startPoint: .top, endPoint: .bottom))
            .overlay(Circle().strokeBorder(Color.primary.opacity(0.12), lineWidth: 3))
            .overlay {
                Image(systemName: "heart")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
    }

    private var back: some View {
        Circle()
            .fill(LinearGradient(colors: [Palette.pink, Palette.coral], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 3))
            .overlay {
                Image(systemName: "heart.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .shadow(color: Palette.pink.opacity(0.4), radius: 8, y: 4)
    }
}

/// A diagonal glint band; `position` runs −1 (off the left) → 1 (off the right).
private struct ButtonCoinGlint: View {
    let position: CGFloat

    var body: some View {
        LinearGradient(colors: [.clear, Color.white.opacity(0.6), .clear], startPoint: .leading, endPoint: .trailing)
            .frame(width: 26)
            .rotationEffect(.degrees(20))
            .offset(x: position * 70)
            .blendMode(.plusLighter)
            .frame(width: 92, height: 92)
            .clipShape(Circle())
            .allowsHitTesting(false)
    }
}
