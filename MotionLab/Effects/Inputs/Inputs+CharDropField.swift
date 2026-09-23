import SwiftUI

extension Effect {
    static let inputsCharDropField = Effect(
        id: "inputs.char-drop-field",
        category: .inputs,
        interaction: .state,
        name: L("Dropping Letters Field", "字符掉落输入框"),
        summary: L("Every typed character drops in with a tilt and a bounce; deleted ones float away.", "每个输入的字符都带着倾斜弹跳落下，删除的字符则向上飘走。"),
        prompt: L(
            "A username field on a sign-up card: a label, a 52 pt rounded field and a gradient underline that sweeps in from the left on focus. Each typed character is its own glyph that falls into place from 22 pt above, tilted −14° and transparent, landing on a bouncy spring (response 0.38 s, damping 0.55) so it overshoots the baseline and rights itself; neighbours stay still. Deleting lifts the last character 14 pt, shrinks it to 60% and fades it out in 200 ms, as if it floated away. A 2 pt indigo caret blinks after the last glyph and glides with it, and a small character count in the corner rolls with numeric digits. Light, playful type that makes every keystroke feel physical.",
            "注册卡片上的用户名输入框：一个标签、一个 52pt 高的圆角输入框，以及聚焦时从左侧扫入的渐变下划线。每个输入的字符都是独立字形：从上方 22pt 处、倾斜 −14° 且透明地落下，以弹性弹簧（响应 0.38 秒、阻尼 0.55）着陆，先越过基线再回正；相邻字符保持不动。删除时，最后一个字符上浮 14pt、缩小到 60%，并在 200 毫秒内淡出，好像飘走了。2pt 的靛蓝光标在最后一个字形后闪烁并随之滑动，角落里的小字数统计以数字滚动更新。轻盈俏皮的文字，让每一次按键都有实体感。"
        ),
        implementation: L(
            "A hidden TextField owns the text; the visible row is an HStack of per-character Text views keyed by index with an asymmetric .modifier transition (drop in, float out) animated by a spring via animation(_:value:).",
            "隐藏的 TextField 负责文本输入；可见的一行是按索引标识的逐字符 Text 组成的 HStack，使用非对称 .modifier 过渡（落入、飘出），并通过 animation(_:value:) 施加弹簧动画。"
        ),
        apis: ["AnyTransition.modifier(active:identity:)", "asymmetric", "@FocusState", "phaseAnimator", "animation(_:value:)"],
        tags: ["text field", "typing", "letters", "bounce", "输入框", "打字", "字符", "弹跳"],
        params: [
            .slider("drop", L("Drop height", "掉落高度"), 6...44, default: 22, decimals: 0, unit: "pt"),
            .slider("response", L("Landing response", "着陆响应"), 0.2...0.8, default: 0.38, unit: "s"),
            .slider("damping", L("Landing damping", "着陆阻尼"), 0.3...1.0, default: 0.55),
            .toggle("tilt", L("Tilt", "倾斜"), default: true),
        ]
    ) { ctx in
        CharDropFieldDemo(ctx: ctx)
    }
}

private struct CharDropFieldDemo: View {
    let ctx: DemoContext
    @State private var text = ""
    @State private var scriptIndex = 0
    @FocusState private var focused: Bool

    private let limit = 16
    private static let script: [String] = ["m", "o", "t", "i", "o", "n", "_", "k", "i", "d", "⌫", "⌫", "⌫", "l", "a", "b", "⏸", "⏸", "⌧"]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            card
            Spacer()
            DemoHint(text: L("Tap the field and type", "点击输入框开始输入"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { hiddenField }
        .autoplay(ctx.isPreview, every: 0.22, delay: 0.4) { previewType() }
    }

    private var active: Bool { focused || ctx.isPreview }

    private var hiddenField: some View {
        TextField("", text: $text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($focused)
            .frame(width: 1, height: 1)
            .opacity(0.01)
            .allowsHitTesting(false)
            .onChange(of: text) { _, newValue in
                if newValue.count > limit { text = String(newValue.prefix(limit)) }
            }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(L("Username", "用户名"), ctx.language)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Text("\(text.count)/\(limit)")
                    .font(.caption.weight(.medium).monospacedDigit())
                    .foregroundStyle(.tertiary)
                    .contentTransition(.numericText(value: Double(text.count)))
                    .animation(.snappy, value: text.count)
            }
            field
        }
        .padding(18)
        .frame(width: 310)
        .demoCard(cornerRadius: 24)
    }

    private var field: some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        return ZStack(alignment: .leading) {
            shape.fill(Color.primary.opacity(0.05))
            HStack(spacing: 0) {
                Text(verbatim: "@")
                    .foregroundStyle(.tertiary)
                    .padding(.trailing, 2)
                letters
                if active {
                    CharDropCaret()
                        .padding(.leading, 2)
                }
                if text.isEmpty && !active {
                    Text(L("your-name", "你的名字"), ctx.language)
                        .foregroundStyle(.tertiary)
                }
                Spacer(minLength: 0)
            }
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .padding(.horizontal, 14)
        }
        .frame(height: 52)
        .overlay(alignment: .bottom) { underline }
        .clipShape(shape)
        .contentShape(shape)
        .onTapGesture { focused = true }
    }

    private var letters: some View {
        let characters = Array(text)
        let drop: CGFloat = ctx.cg("drop")
        let tilt: Double = ctx.bool("tilt") ? -14 : 0
        let insertion = AnyTransition.modifier(
            active: CharDropModifier(y: -drop, angle: tilt, scale: 1, opacity: 0),
            identity: CharDropModifier(y: 0, angle: 0, scale: 1, opacity: 1)
        )
        let removal = AnyTransition.modifier(
            active: CharDropModifier(y: -14, angle: 0, scale: 0.6, opacity: 0),
            identity: CharDropModifier(y: 0, angle: 0, scale: 1, opacity: 1)
        )
        return HStack(spacing: 0.5) {
            ForEach(characters.indices, id: \.self) { index in
                Text(String(characters[index]))
                    .foregroundStyle(.primary)
                    .transition(.asymmetric(insertion: insertion, removal: removal.animation(.easeOut(duration: 0.2))))
            }
        }
        .animation(.spring(response: ctx["response"], dampingFraction: ctx["damping"]), value: text)
    }

    private var underline: some View {
        Rectangle()
            .fill(LinearGradient(colors: [Palette.indigo, Palette.violet, Palette.pink], startPoint: .leading, endPoint: .trailing))
            .frame(height: 2.5)
            .scaleEffect(x: active ? 1 : 0, anchor: .leading)
            .animation(.smooth(duration: 0.45), value: active)
    }

    private func previewType() {
        let key = Self.script[scriptIndex % Self.script.count]
        scriptIndex += 1
        switch key {
        case "⌫":
            if !text.isEmpty { text.removeLast() }
        case "⌧":
            text = ""
        case "⏸":
            break
        default:
            if text.count < limit { text.append(contentsOf: key) }
        }
    }
}

private struct CharDropModifier: ViewModifier {
    let y: CGFloat
    let angle: Double
    let scale: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(angle), anchor: .bottom)
            .scaleEffect(scale)
            .offset(y: y)
            .opacity(opacity)
    }
}

private struct CharDropCaret: View {
    var body: some View {
        Capsule()
            .fill(Palette.indigo)
            .frame(width: 2, height: 24)
            .phaseAnimator([1.0, 0.0]) { content, phase in
                content.opacity(phase)
            } animation: { _ in
                .easeInOut(duration: 0.5)
            }
    }
}
