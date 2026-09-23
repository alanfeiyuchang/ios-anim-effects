import SwiftUI

extension Effect {
    static let inputsFloatingLabel = Effect(
        id: "inputs.floating-label",
        category: .inputs,
        interaction: .state,
        name: L("Floating Label Field", "浮动标签输入框"),
        summary: L("The placeholder lifts into a label and the underline grows from center.", "占位文字上浮为标签，下划线从中间向两侧展开。"),
        prompt: L(
            "A minimal text field on a card: a 17 pt placeholder sits on a 1 pt hairline. On focus the placeholder lifts 24 pt and shrinks to 78% (anchored left), shifting from secondary gray to the indigo accent, while a 2 pt gradient underline grows outward from the center to full width — all on one spring (response 0.35 s, damping 0.8). The label stays floated while text is present. When the email becomes valid, a green checkmark scales in at the trailing edge with a bounce. On blur with an empty value, everything settles back. Calm, precise and clear about state.",
            "卡片上的极简输入框：17pt 的占位文字停在 1pt 细线之上。获得焦点时，占位文字以左侧为锚点上移 24pt 并缩小到 78%，颜色从次级灰变为靛蓝强调色；同时一条 2pt 的渐变下划线从中心向两侧展开至全宽——全部由同一条弹簧（响应 0.35 秒、阻尼 0.8）驱动。只要输入框有内容，标签就保持上浮。邮箱格式有效时，右侧弹性缩放出现一个绿色对勾。失焦且内容为空时一切回到初始状态。沉静、精确、状态清晰。"
        ),
        implementation: L(
            "@FocusState and the text value derive an active flag; the label uses scaleEffect(anchor: .leading) and offset instead of a font change so it animates smoothly, and the underline is a scaleEffect(x:) from center.",
            "由 @FocusState 与文本内容推导激活状态；标签用 scaleEffect(anchor: .leading) 与 offset 代替字号变化以保证平滑，下划线使用从中心开始的 scaleEffect(x:)。"
        ),
        apis: ["@FocusState", "TextField", "scaleEffect(anchor:)", "transition"],
        tags: ["text field", "floating label", "form", "focus", "输入框", "浮动标签", "表单", "聚焦"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.15...0.8, default: 0.35, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.4...1.0, default: 0.8),
            .slider("lift", L("Label scale", "标签缩放"), 0.6...0.95, default: 0.78),
            .slider("rise", L("Label rise", "标签上移"), 16...32, default: 24, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        InputFloatingLabelDemo(ctx: ctx)
    }
}

private enum InputFloatingFieldID: Hashable {
    case name
    case email
}

private struct InputFloatingLabelDemo: View {
    let ctx: DemoContext
    @FocusState private var focus: InputFloatingFieldID?
    @State private var name = ""
    @State private var email = ""
    @State private var previewFocus: InputFloatingFieldID?
    @State private var previewStep = 0

    private var spring: Animation { .spring(response: ctx["response"], dampingFraction: ctx["damping"]) }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 18) {
                InputFloatingField(
                    title: ctx.language == .zh ? "姓名" : "Full name",
                    text: $name,
                    id: .name,
                    focus: $focus,
                    forcedFocus: previewFocus == .name,
                    isValid: false,
                    scale: ctx.cg("lift"),
                    rise: ctx.cg("rise"),
                    spring: spring
                )
                InputFloatingField(
                    title: ctx.language == .zh ? "邮箱" : "Email",
                    text: $email,
                    id: .email,
                    focus: $focus,
                    forcedFocus: previewFocus == .email,
                    isValid: email.contains("@") && email.contains("."),
                    scale: ctx.cg("lift"),
                    rise: ctx.cg("rise"),
                    spring: spring
                )
            }
            .padding(22)
            .frame(width: 300)
            .demoCard()
            Spacer()
            DemoHint(text: L("Tap a field and start typing", "点击输入框开始输入"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { focus = nil }
        .autoplay(ctx.isPreview, every: 1.4, delay: 0.4) { previewTick() }
    }

    private func previewTick() {
        let step = previewStep % 4
        previewStep += 1
        withAnimation(spring) {
            switch step {
            case 0:
                previewFocus = .name
            case 1:
                name = "Ada Lovelace"
                previewFocus = .email
            case 2:
                email = "ada@motion.dev"
                previewFocus = nil
            default:
                name = ""
                email = ""
            }
        }
    }
}

private struct InputFloatingField: View {
    let title: String
    @Binding var text: String
    let id: InputFloatingFieldID
    var focus: FocusState<InputFloatingFieldID?>.Binding
    let forcedFocus: Bool
    let isValid: Bool
    let scale: CGFloat
    let rise: CGFloat
    let spring: Animation

    private var focused: Bool { focus.wrappedValue == id || forcedFocus }
    private var floated: Bool { focused || !text.isEmpty }

    var body: some View {
        ZStack(alignment: .leading) {
            Text(title)
                .font(.system(size: 17))
                .foregroundStyle(focused ? Palette.indigo : Color.secondary)
                .scaleEffect(floated ? scale : 1, anchor: .leading)
                .offset(y: floated ? -rise : 0)
                .allowsHitTesting(false)
            HStack {
                TextField("", text: $text)
                    .font(.system(size: 17))
                    .focused(focus, equals: id)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(id == .email ? .emailAddress : .default)
                if isValid {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Palette.green)
                        .transition(.scale(scale: 0.2).combined(with: .opacity))
                }
            }
        }
        .padding(.top, 18)
        .padding(.bottom, 10)
        .overlay(alignment: .bottom) { underline }
        .animation(spring, value: floated)
        .animation(spring, value: focused)
        .animation(.spring(response: 0.35, dampingFraction: 0.55), value: isValid)
    }

    private var underline: some View {
        ZStack {
            Rectangle()
                .fill(Color.primary.opacity(0.15))
                .frame(height: 1)
            Capsule()
                .fill(LinearGradient(colors: [Palette.indigo, Palette.violet], startPoint: .leading, endPoint: .trailing))
                .frame(height: 2)
                .scaleEffect(x: focused ? 1 : 0.001, anchor: .center)
                .opacity(focused ? 1 : 0)
        }
    }
}
