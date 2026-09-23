import SwiftUI

extension Effect {
    static let buttonsLabelRoll = Effect(
        id: "buttons.label-roll",
        category: .buttons,
        interaction: .tap,
        name: L("Label Roll", "文字翻滚"),
        summary: L("Each letter rolls out and back in, one after another.", "按钮文字逐字向上翻滚，替换成一模一样的新文字。"),
        prompt: L(
            "A near-black capsule CTA (\"Get started\" with a trailing arrow) with a faint top sheen, paired with a quieter outline button. On tap every character of the label slides up out of a 24 pt clipping line while an identical copy rises in from below, each letter on its own spring (response 0.45 s, damping 0.85) with a 25 ms left-to-right stagger, so the word ripples like a split-flap wave. As the wave reaches the end, the arrow shoots out to the right and a fresh one slides in from the left. The swap is invisible at rest, so it can repeat forever. The button dips to 97% on press with a light haptic. Crisp, editorial and quietly playful — the web's favourite hover, adapted for touch.",
            "接近纯黑的胶囊主按钮（“立即开始”+ 尾部箭头），顶部带一层极淡的光泽，旁边是一枚更安静的描边次按钮。点击后，文字中的每个字符都在 24pt 高的裁切行内向上滑出，一模一样的副本同时从下方升起；每个字各自使用弹簧（响应 0.45 秒、阻尼 0.85），从左到右错开 25 毫秒，整行文字像翻牌一样掀起一道波浪。波浪抵达末尾时，箭头向右射出，新的箭头从左侧滑入。静止时替换不可见，因此可以无限重复。按下时按钮轻压到 97% 并伴随轻触觉。利落、有编辑感又带点俏皮——把网页上最受欢迎的悬停动效搬到了触屏上。"
        ),
        implementation: L(
            "Each character is a ZStack of two identical Texts offset by one line height inside a clipped row; a rolled flag offsets them by one line with a per-index delayed spring via animation(_:value:), then resets instantly inside a transaction with disablesAnimations.",
            "每个字符是由两份相同 Text 组成的 ZStack，二者相距一个行高，放在裁切的行容器中；rolled 状态通过 animation(_:value:) 以按索引延迟的弹簧把它们平移一个行高，结束后在 disablesAnimations 的事务中瞬间复位。"
        ),
        apis: ["animation(_:value:)", "Transaction.disablesAnimations", "clipped()", "offset", "ButtonStyle"],
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
                ButtonRollingLabel(
                    text: title,
                    rolled: rolled,
                    direction: ctx.int("direction") == 1 ? -1 : 1,
                    stagger: ctx["stagger"],
                    response: ctx["response"]
                )
                ButtonRollingArrow(
                    rolled: rolled,
                    delay: Double(title.count) * ctx["stagger"] * 0.6,
                    response: ctx["response"]
                )
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .frame(height: 54)
            .background(Color(hex: 0x16161A), in: Capsule())
            .overlay {
                Capsule()
                    .fill(LinearGradient(colors: [Color.white.opacity(0.14), .clear], startPoint: .top, endPoint: .center))
                    .padding(1)
                    .allowsHitTesting(false)
            }
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
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
        rolled = true
        let settle = ctx["response"] * 2 + Double(title.count) * ctx["stagger"]
        Task {
            try? await Task.sleep(for: .seconds(settle))
            // Both copies are identical, so snapping back is invisible and the roll can repeat.
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { rolled = false }
        }
    }
}

/// A row of characters; each one is two stacked copies inside a clipped line.
private struct ButtonRollingLabel: View {
    let text: String
    let rolled: Bool
    let direction: CGFloat
    let stagger: Double
    let response: Double

    private let lineHeight: CGFloat = 24

    var body: some View {
        let glyphs = text.map { String($0) }
        HStack(spacing: 0) {
            ForEach(glyphs.indices, id: \.self) { index in
                ZStack {
                    Text(verbatim: glyphs[index])
                    Text(verbatim: glyphs[index])
                        .offset(y: lineHeight * direction)
                }
                .frame(height: lineHeight)
                .offset(y: rolled ? -lineHeight * direction : 0)
                .animation(
                    rolled ? .spring(response: response, dampingFraction: 0.85).delay(Double(index) * stagger) : nil,
                    value: rolled
                )
            }
        }
        .frame(height: lineHeight)
        .clipped()
    }
}

/// The arrow leaves to the right while a fresh one slides in from the left.
private struct ButtonRollingArrow: View {
    let rolled: Bool
    let delay: Double
    let response: Double

    var body: some View {
        let animation: Animation? = rolled ? .spring(response: response, dampingFraction: 0.85).delay(delay) : nil
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
