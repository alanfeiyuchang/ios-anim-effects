import SwiftUI

extension Effect {
    static let inputsTokenField = Effect(
        id: "inputs.token-field",
        category: .inputs,
        interaction: .state,
        name: L("Token Field", "标签化输入框"),
        summary: L("Typed names snap into avatar chips that pop in, reflow and shrink away when removed.", "输入的名字会变成带头像的标签，弹入、重排，删除时缩小消失。"),
        prompt: L(
            "A \"Share with\" field on a collaboration sheet. As you type a name and press return or a comma, the draft text collapses and a chip springs into its place: a capsule with a gradient avatar initial, the name and a small × — scaling up from 40% anchored at its leading edge while fading in, on a bouncy spring (response 0.4 s, damping 0.62). Chips wrap onto new lines in a flow layout; when a chip is added or removed, every other chip and the input slide to their new positions on the same spring, so the field reflows as one fluid body. Removing a chip (tap ×) shrinks it to 40% and fades it in 180 ms with a light haptic. The \"Send\" button counts people with rolling digits. Organised, tactile and alive.",
            "协作面板上的“共享给”输入框。输入名字后按回车或逗号，草稿文字随即收起，一枚标签在原处弹出：胶囊形，带渐变头像首字母、名字与小小的 ×——以前缘为锚点从 40% 放大并淡入，采用弹性弹簧（响应 0.4 秒、阻尼 0.62）。标签在流式布局中自动换行；新增或删除标签时，其余标签与输入框以同一弹簧滑到新位置，整个输入框像一个流体般重新排布。点击 × 删除标签时，它缩小到 40% 并在 180 毫秒内淡出，伴随一次轻触觉。“发送”按钮以数字滚动显示人数。井井有条、可触、充满生气。"
        ),
        implementation: L(
            "A custom Layout wraps chips and the TextField into rows; tokens are Identifiable so insertion/removal transitions and the reflow are animated with animation(_:value:) keyed on the id list. onSubmit and a comma check in onChange commit the draft.",
            "自定义 Layout 把标签与 TextField 排成自动换行的多行；标签遵循 Identifiable，插入/删除过渡与重排通过以 id 列表为键的 animation(_:value:) 完成。onSubmit 与 onChange 中的逗号检测负责提交草稿。"
        ),
        apis: ["Layout", "TextField.onSubmit", "transition(.scale(scale:anchor:))", "animation(_:value:)", "numericText"],
        tags: ["text field", "tokens", "chips", "tags", "输入框", "标签", "联系人", "流式布局"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.8, default: 0.4, unit: "s"),
            .slider("damping", L("Spring damping", "弹簧阻尼"), 0.4...1.0, default: 0.62),
            .toggle("avatars", L("Avatars", "头像"), default: true),
        ]
    ) { ctx in
        TokenFieldDemo(ctx: ctx)
    }
}

private struct FieldToken: Identifiable, Equatable {
    let id: Int
    let name: String
}

private struct TokenFieldDemo: View {
    let ctx: DemoContext
    @State private var tokens: [FieldToken] = [FieldToken(id: 0, name: "Mia")]
    @State private var draft = ""
    @State private var nextID = 1
    @State private var scriptIndex = 0
    /// Detail-page intro: types and commits one name. It never focuses the field (no keyboard).
    @State private var introTask: Task<Void, Never>?
    @FocusState private var focused: Bool

    private static let names = ["Leo", "Ava", "Noah", "Zoe", "Kai"]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            card
            Spacer()
            DemoHint(text: L("Type a name, then press return", "输入名字后按回车"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 0.3, delay: 0.4) {
            if ctx.isPreview { previewTick() } else { playIntro() }
        }
        .onDisappear { stopIntro() }
        .onChange(of: focused) { _, isFocused in
            if isFocused { stopIntro() }
        }
    }

    private var spring: Animation {
        .spring(response: ctx["response"], dampingFraction: ctx["damping"])
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L("Share with", "共享给"), ctx.language)
                .font(.headline)
                .foregroundStyle(.primary)
            TokenFlowLayout(spacing: 6) {
                ForEach(tokens) { token in
                    chip(token)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.4, anchor: .leading).combined(with: .opacity),
                                removal: .scale(scale: 0.4).combined(with: .opacity).animation(.easeIn(duration: 0.18))
                            )
                        )
                }
                input
            }
            .padding(10)
            .frame(width: 282, alignment: .topLeading)
            .frame(minHeight: 96, alignment: .topLeading)
            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .animation(spring, value: tokens)
            sendButton
        }
        .padding(18)
        .frame(width: 318)
        .demoCard(cornerRadius: 24)
    }

    private var input: some View {
        TextField(L("Add people", "添加成员")(ctx.language), text: $draft)
            .font(.subheadline)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .focused($focused)
            .submitLabel(.done)
            .onSubmit { commit(userInitiated: true) }
            .onChange(of: draft) { _, newValue in
                if newValue.contains(",") { commit(userInitiated: introTask == nil) }
            }
            .frame(width: 104, height: 30)
    }

    private func chip(_ token: FieldToken) -> some View {
        let hue = Palette.spectrum[token.name.count % Palette.spectrum.count]
        return HStack(spacing: 6) {
            if ctx.bool("avatars") {
                Text(String(token.name.prefix(1)))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(
                        LinearGradient(colors: [hue, hue.opacity(0.7)], startPoint: .top, endPoint: .bottom),
                        in: Circle()
                    )
            }
            Text(token.name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
            Button {
                stopIntro()
                remove(token, silent: false)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 18, height: 18)
                    .background(Color.primary.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, ctx.bool("avatars") ? 4 : 10)
        .padding(.trailing, 5)
        .frame(height: 30)
        .background(Palette.elevated, in: Capsule())
        .overlay(Capsule().strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
    }

    private var sendButton: some View {
        HStack(spacing: 6) {
            Image(systemName: "paperplane.fill")
            Text(ctx.language == .zh ? "发送给 \(tokens.count) 人" : "Send to \(tokens.count)")
                .contentTransition(.numericText(value: Double(tokens.count)))
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(Palette.primaryStrong, in: Capsule())
        .animation(.snappy, value: tokens.count)
    }

    /// Only a real return keeps the keyboard up; simulated commits never touch focus.
    private func commit(userInitiated: Bool) {
        let name = draft
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        draft = ""
        guard !name.isEmpty else { return }
        let live = userInitiated && !ctx.isPreview
        if live { Haptics.tap() }
        let token = FieldToken(id: nextID, name: name)
        nextID += 1
        tokens.append(token)
        if live { focused = true }
    }

    private func remove(_ token: FieldToken, silent: Bool) {
        if !silent && !ctx.isPreview { Haptics.tap() }
        tokens.removeAll { $0.id == token.id }
    }

    /// One full sequence on detail arrival: type a name letter by letter, then commit it as a chip.
    private func playIntro() {
        introTask?.cancel()
        let name = "Leo"
        introTask = Task {
            for character in name {
                try? await Task.sleep(for: .seconds(0.24))
                guard !Task.isCancelled else { return }
                draft.append(character)
            }
            try? await Task.sleep(for: .seconds(0.4))
            guard !Task.isCancelled else { return }
            commit(userInitiated: false)
            introTask = nil
        }
    }

    /// The first real touch takes over from the intro and clears its half-typed draft.
    private func stopIntro() {
        guard let task = introTask else { return }
        task.cancel()
        introTask = nil
        draft = ""
    }

    /// Preview: type a name letter by letter, commit, repeat; trim the list when it gets long.
    private func previewTick() {
        let name = Self.names[scriptIndex % Self.names.count]
        if tokens.count >= 4 {
            if let first = tokens.first { remove(first, silent: true) }
            return
        }
        if draft.count < name.count {
            draft.append(name[name.index(name.startIndex, offsetBy: draft.count)])
        } else {
            commit(userInitiated: false)
            scriptIndex += 1
        }
    }
}

/// Wraps subviews into left-aligned rows.
private struct TokenFlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth: CGFloat = proposal.width ?? 260
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
