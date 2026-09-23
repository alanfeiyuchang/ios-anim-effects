import SwiftUI

extension Effect {
    static let feedbackReactionPicker = Effect(
        id: "feedback.reaction-picker",
        category: .feedback,
        interaction: .tap,
        name: L("Reaction Picker", "表情回应"),
        summary: L(
            "A tapback bar blooms from a message and the chosen emoji flies onto the bubble.",
            "回应栏从消息气泡上绽开，选中的表情飞落到气泡一角。"
        ),
        prompt: L(
            "A short chat thread. Tapping the incoming message lifts it to 103% with a deeper shadow while the neighboring bubbles blur to 3 pt and fade to 45%, putting it in focus. A frosted capsule of six emoji reactions blooms from the bubble's top-leading corner — scaling from 40% on a lively spring (response 0.4 s, damping 0.72) — and each emoji pops in from 20% scale and 8 pt lower, staggered 30 ms left to right. Pressing an emoji swells it to 135% and lifts it 6 pt. Choosing one fires a success haptic, collapses the bar, and the emoji itself flies along a shared-element path onto the bubble's top-trailing corner, landing in a small elevated badge; reopening sends it back into the bar. Expressive, precise and warm.",
            "一段简短的聊天记录。点击对方发来的消息，它会被抬起到 103% 并加深投影，相邻气泡同时模糊到 3 pt、淡到 45%，让焦点落在这条消息上。一枚磨砂胶囊回应栏从气泡左上角“绽开”——以活泼的弹簧（响应 0.4 秒、阻尼 0.72）从 40% 放大——六个表情从 20% 大小、下方 8 pt 处依次弹出，从左到右错开 30 毫秒。按住某个表情时它放大到 135% 并上浮 6 pt。选中后触发成功触感、回应栏收起，表情本身沿共享元素路径飞到气泡右上角，落进一枚小小的浮起徽章；再次打开时它又飞回栏中。富有表现力、精准而温暖。"
        ),
        implementation: L(
            "The bar and the corner badge are mutually exclusive views sharing matchedGeometryEffect ids per emoji, so selecting (or reopening) animates the glyph between them; the bar's items reveal via onAppear with per-index delayed springs and a ButtonStyle handles the press swell.",
            "回应栏与角标徽章互斥显示，并为每个表情共享 matchedGeometryEffect ID，因此选择（或再次打开）时表情会在两者之间飞行；栏内表情通过 onAppear 与逐项延迟弹簧依次出现，按压放大由 ButtonStyle 处理。"
        ),
        apis: ["matchedGeometryEffect", "transition(.scale(scale:anchor:))", "ButtonStyle", "blur(radius:)"],
        tags: ["reaction", "tapback", "emoji", "chat", "表情回应", "点赞", "表情", "聊天"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.8, default: 0.4, unit: "s"),
            .slider("stagger", L("Emoji stagger", "表情错开"), 0.0...0.08, default: 0.03, decimals: 3, unit: "s"),
            .toggle("focus", L("Focus blur", "聚焦虚化"), default: true),
        ]
    ) { ctx in
        ReactionPickerDemo(ctx: ctx)
    }
}

private let reactionEmojis: [String] = ["❤️", "👍", "😂", "😮", "😢", "🔥"]

private struct ReactionPickerDemo: View {
    let ctx: DemoContext
    @Namespace private var ns
    @State private var open = false
    @State private var chosen: Int?
    @State private var previewStep = 0

    private var spring: Animation { .spring(response: ctx["response"], dampingFraction: 0.72) }
    private var zh: Bool { ctx.language == .zh }

    var body: some View {
        let focus = open && ctx.bool("focus")
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 12) {
                outgoing(zh ? "新的引导流程刚上线 🚀" : "Just shipped the new onboarding 🚀")
                    .blur(radius: focus ? 3 : 0)
                    .opacity(focus ? 0.45 : 1)
                focusBubble
                    .padding(.top, 8)
                outgoing(zh ? "谢谢！调了好久的弹簧 😄" : "Thanks! Tuned those springs forever 😄")
                    .blur(radius: focus ? 3 : 0)
                    .opacity(focus ? 0.45 : 1)
            }
            .frame(width: 300)
            DemoHint(text: L("Tap the incoming message", "点击对方发来的消息"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { if open { setOpen(false) } }
        .autoplay(ctx.isPreview, every: 0.8, delay: 0.5) { previewAdvance() }
    }

    private func outgoing(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Palette.primary, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var focusBubble: some View {
        Text(zh ? "太惊艳了，转场丝滑得不像话！" : "It looks incredible — those transitions are so smooth!")
            .font(.subheadline)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: 230, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Palette.stroke))
            .scaleEffect(open ? 1.03 : 1, anchor: .leading)
            .shadow(color: .black.opacity(open ? 0.18 : 0), radius: open ? 16 : 0, y: open ? 8 : 0)
            .onTapGesture { setOpen(!open) }
            .overlay(alignment: .topTrailing) { badge }
            .overlay(alignment: .topLeading) {
                if open {
                    ReactionBar(ns: ns, returning: chosen, stagger: ctx["stagger"], onSelect: select)
                        .fixedSize()
                        .offset(x: -6, y: -60)
                        .transition(.scale(scale: 0.4, anchor: .bottomLeading).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .zIndex(1)
    }

    @ViewBuilder private var badge: some View {
        if let chosen, !open {
            Text(reactionEmojis[chosen])
                .font(.system(size: 17))
                .matchedGeometryEffect(id: "reaction-\(chosen)", in: ns)
                .frame(width: 32, height: 32)
                .background(Palette.elevated, in: Circle())
                .overlay(Circle().strokeBorder(Palette.stroke))
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                .offset(x: 12, y: -14)
                .transition(.opacity)
        }
    }

    private func setOpen(_ value: Bool) {
        if value && !ctx.isPreview { Haptics.tap(.medium) }
        withAnimation(spring) { open = value }
    }

    private func select(_ index: Int) {
        if !ctx.isPreview { Haptics.success() }
        withAnimation(spring) {
            chosen = index
            open = false
        }
    }

    private func previewAdvance() {
        let targets = [0, 2, 5, 1]
        switch previewStep % 4 {
        case 0: setOpen(true)
        case 1: break
        case 2: select(targets[(previewStep / 4) % targets.count])
        default: break
        }
        previewStep += 1
    }
}

private struct ReactionBar: View {
    let ns: Namespace.ID
    let returning: Int?
    let stagger: Double
    let onSelect: (Int) -> Void
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<reactionEmojis.count, id: \.self) { index in
                let visible = appeared || index == returning
                Button { onSelect(index) } label: {
                    Text(reactionEmojis[index])
                        .font(.system(size: 26))
                        .matchedGeometryEffect(id: "reaction-\(index)", in: ns)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(ReactionPressStyle())
                .scaleEffect(visible ? 1 : 0.2)
                .offset(y: visible ? 0 : 8)
                .opacity(visible ? 1 : 0)
                .animation(.spring(response: 0.36, dampingFraction: 0.62).delay(0.05 + Double(index) * stagger), value: appeared)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
        .onAppear { appeared = true }
    }
}

private struct ReactionPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.35 : 1, anchor: .bottom)
            .offset(y: configuration.isPressed ? -6 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
