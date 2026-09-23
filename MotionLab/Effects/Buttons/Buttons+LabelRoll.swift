import SwiftUI

extension Effect {
    static let buttonsLabelRoll = Effect(
        id: "buttons.label-roll",
        category: .buttons,
        interaction: .tap,
        name: L("Label Roll", "文字翻滚"),
        summary: L("Each letter rolls out and back in, one after another.", "按钮文字逐字向上翻滚，替换成一模一样的新文字。"),
        prompt: L(
            "A near-black capsule CTA (\"Get started\" with a trailing arrow) with a faint top sheen, paired with a quieter outline button. On tap every character of the label slides up out of a 24 pt clipping line while an identical copy rises in from below, each letter on its own spring (response 0.45 s, damping 0.85) with a 25 ms left-to-right stagger, so the word ripples like a split-flap wave while keeping its original kerning. As the wave reaches the last letter, the arrow shoots out to the right and a fresh one slides in from the left. The swap is invisible at rest, so it can repeat forever. The button dips to 97% on press with a light haptic. Crisp, editorial and quietly playful — the web's favourite hover, adapted for touch.",
            "近黑色胶囊主按钮（“立即开始”+ 箭头）顶部带淡淡光泽，旁边是一枚安静的描边次按钮。点击后，每个字符在 24pt 高的裁切行内向上滑出，相同的副本从下方升起；每个字各用弹簧（响应 0.45 秒、阻尼 0.85），从左到右错开 25 毫秒，整行像翻牌一样掀起波浪，字距不变。波浪到达末字时，箭头向右射出、新箭头从左侧滑入。静止时替换不可见，可无限重复。按下时按钮轻压到 97% 并伴随轻触觉。利落、克制，又带点俏皮。"
        ),
        implementation: L(
            "The label stays one Text (so kerning is intact) drawn by a custom TextRenderer: an animatable clock runs linearly, and each glyph slice is drawn twice — leaving and arriving — offset by an analytic spring evaluated at clock − index × stagger; afterwards the clock resets instantly with disablesAnimations.",
            "标签仍是一个完整的 Text（保留原有字距），由自定义 TextRenderer 绘制：一个可动画的时钟线性推进，每个字形切片绘制两次（离开与进入），其位移取时钟减去序号 × 错峰后代入解析弹簧函数的值；结束后在 disablesAnimations 事务中瞬间复位时钟。"
        ),
        apis: ["TextRenderer", "Text.Layout", "Animatable", "Transaction.disablesAnimations", "ButtonStyle"],
        tags: ["text roll", "hover", "stagger", "letters", "文字翻滚", "逐字", "错峰", "按钮文字"],
        params: [
            .slider("stagger", L("Letter stagger", "逐字间隔"), 0...0.06, default: 0.025, decimals: 3, unit: "s"),
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.8, default: 0.45, unit: "s"),
            .choice("direction", L("Direction", "方向"), [L("Up", "向上"), L("Down", "向下")], default: 0),
        ]
    ) { ctx in
        ButtonLabelRollDemo(ctx: ctx)
    }
}

private struct ButtonLabelRollDemo: View {
    let ctx: DemoContext
    @State private var rolled = false
    @State private var clock: Double = 0

    private var title: String { ctx.language == .zh ? "立即开始" : "Get started" }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 22) {
                VStack(spacing: 6) {
                    Text(ctx.language == .zh ? "让界面动起来" : "Make it move")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    Text(ctx.language == .zh ? "一套为 iOS 打造的动效词典" : "A motion dictionary for iOS")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 10) {
                    primaryButton
                    secondaryButton
                }
            }
            Spacer()
            DemoHint(text: L("Tap the dark button", "点击黑色按钮"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.6, delay: 0.5) { roll() }
    }

    private var primaryButton: some View {
        Button(action: roll) {
            HStack(spacing: 8) {
                Text(verbatim: title)
                    .textRenderer(
                        ButtonRollRenderer(
                            clock: clock,
                            stagger: ctx["stagger"],
                            response: ctx["response"],
                            direction: ctx.int("direction") == 1 ? -1 : 1
                        )
                    )
                    .clipped()
                ButtonRollingArrow(
                    rolled: rolled,
                    // Fires as the wave reaches the last letter.
                    delay: Double(max(title.count - 1, 0)) * ctx["stagger"],
                    response: ctx["response"]
                )
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .frame(height: 54)
            .background(Color.adaptive(light: 0x16161A, dark: 0x2C2C32), in: Capsule())
            .overlay {
                Capsule()
                    .fill(LinearGradient(colors: [Color.white.opacity(0.14), .clear], startPoint: .top, endPoint: .center))
                    .padding(1)
                    .allowsHitTesting(false)
            }
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 1))
            .shadow(color: .black.opacity(0.25), radius: 14, y: 8)
        }
        .buttonStyle(ButtonRollPressStyle())
    }

    private var secondaryButton: some View {
        Text(ctx.language == .zh ? "了解更多" : "Learn more")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 18)
            .frame(height: 54)
            .overlay(Capsule().strokeBorder(Color.primary.opacity(0.15), lineWidth: 1))
    }

    private func roll() {
        guard !rolled else { return }
        if !ctx.isPreview { Haptics.tap() }
        let settle = ctx["response"] * 2 + Double(title.count) * ctx["stagger"]
        rolled = true
        // The renderer evaluates each glyph's spring itself, so the clock just runs linearly.
        withAnimation(.linear(duration: settle)) { clock = settle }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(settle + 0.05))
            // Both copies are identical, so snapping back is invisible and the roll can repeat.
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                rolled = false
                clock = 0
            }
        }
    }
}

/// Rolls every glyph of one laid-out Text (kerning intact): each glyph is drawn leaving and arriving,
/// driven by an analytic underdamped spring (damping 0.85) started `index × stagger` after the clock.
private struct ButtonRollRenderer: TextRenderer {
    var clock: Double
    var stagger: Double
    var response: Double
    var direction: Double

    var animatableData: Double {
        get { clock }
        set { clock = newValue }
    }

    private static func spring(_ t: Double, response: Double) -> Double {
        guard t > 0 else { return 0 }
        let zeta = 0.85
        let omega = 2 * Double.pi / max(response, 0.05)
        let damped = omega * (1 - zeta * zeta).squareRoot()
        let decay = exp(-zeta * omega * t)
        return 1 - decay * (cos(damped * t) + (zeta * omega / damped) * sin(damped * t))
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        var index = 0
        for line in layout {
            for run in line {
                for glyph in run {
                    let progress = Self.spring(clock - Double(index) * stagger, response: response)
                    let travel = Double(glyph.typographicBounds.rect.height) + 4
                    var leaving = context
                    leaving.translateBy(x: 0, y: CGFloat(-travel * progress * direction))
                    leaving.draw(glyph)
                    var arriving = context
                    arriving.translateBy(x: 0, y: CGFloat(travel * (1 - progress) * direction))
                    arriving.draw(glyph)
                    index += 1
                }
            }
        }
    }
}

/// The arrow leaves to the right while a fresh one slides in from the left.
private struct ButtonRollingArrow: View {
    let rolled: Bool
    let delay: Double
    let response: Double

    var body: some View {
        let animation: Animation? = rolled ? Animation.spring(response: response, dampingFraction: 0.85).delay(delay) : nil
        ZStack {
            Image(systemName: "arrow.right")
                .offset(x: rolled ? 22 : 0)
                .opacity(rolled ? 0 : 1)
            Image(systemName: "arrow.right")
                .offset(x: rolled ? 0 : -22)
                .opacity(rolled ? 1 : 0)
        }
        .animation(animation, value: rolled)
        .frame(width: 20, height: 24)
        .clipped()
    }
}

private struct ButtonRollPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
