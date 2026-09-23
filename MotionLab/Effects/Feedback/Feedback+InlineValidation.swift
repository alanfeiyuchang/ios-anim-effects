import SwiftUI

extension Effect {
    static let feedbackInlineValidation = Effect(
        id: "feedback.inline-validation",
        category: .feedback,
        interaction: .tap,
        name: L("Inline Field Validation", "输入框即时校验"),
        summary: L(
            "An email field that shakes and slides out a hint when wrong, then pops a green check when right.",
            "邮箱输入框出错时抖动并滑出提示，填对后弹出绿色对勾。"
        ),
        prompt: L(
            "A sign-up card with an 'Email' label, a 52 pt rounded field and a Continue button. An invalid submit shakes the field −14 → +11 → −7 → +3 → 0 pt over ~330 ms, turns its 1.5 pt border and glyph red, pops a red exclamation in from 40% scale and slides a red 'Enter a valid email address' message 8 pt down from under the field on a spring (response 0.4 s, damping 0.8) as the card grows; an error haptic fires. Editing retracts it. A valid submit turns the border green, springs in a green check with slight overshoot and swaps the message to 'Looks good' with a success haptic. With live validation on, later keystrokes update the state without shaking. Clear, corrective, never scolding.",
            "注册卡片上是“邮箱”标签、52 pt 圆角输入框和“继续”按钮。提交无效地址，输入框在约 330 毫秒内按 −14 → +11 → −7 → +3 → 0 pt 摇头，1.5 pt 描边和图标转红，红色感叹号从 40% 弹入；一行红字“请输入有效的邮箱地址”以弹簧（响应 0.4 秒、阻尼 0.8）从框下滑出 8 pt，卡片随之长高，伴随错误触感。一旦修改，提示即刻收回。地址有效时描边变绿，绿色对勾带点过冲弹入，提示换成“看起来不错”，伴随成功触感。开启即时校验后，之后每次输入都实时更新，不再摇动。纠错清楚，语气从不责备。"
        ),
        implementation: L(
            "A three-state enum drives the border color, the trailing status symbol (inserted with a scale + opacity transition) and a message row inserted below the field with an offset + opacity transition; a keyframeAnimator keyed on a failed-attempt counter plays the shake. A custom Binding resets or re-validates the state as the user types.",
            "三态枚举驱动描边颜色、尾部状态图标（缩放加淡入转场插入）以及输入框下方以位移加淡入转场插入的提示行；以失败次数为触发器的 keyframeAnimator 播放抖动。自定义 Binding 在用户输入时重置或实时重新校验状态。"
        ),
        apis: ["TextField", "keyframeAnimator", "transition(.offset.combined(with: .opacity))", "Binding(get:set:)", "onSubmit"],
        tags: ["validation", "form", "text field", "error message", "表单校验", "输入框", "错误提示", "抖动"],
        params: [
            .slider("amplitude", L("Shake amplitude", "抖动幅度"), 4...24, default: 14, decimals: 0, unit: "pt"),
            .slider("response", L("Message spring", "提示弹簧"), 0.2...0.8, default: 0.4, unit: "s"),
            .toggle("live", L("Live validation after submit", "提交后即时校验"), default: true),
        ]
    ) { ctx in
        InlineValidationDemo(ctx: ctx)
    }
}

private enum FieldStatus: Equatable {
    case idle
    case invalid
    case valid
}

private struct FieldShake {
    var x: CGFloat = 0
}

private struct InlineValidationDemo: View {
    let ctx: DemoContext
    @State private var email = "alex@studio"
    @State private var status: FieldStatus = .idle
    @State private var failures = 0
    @State private var submitted = false
    @State private var previewStep = 0

    private var spring: Animation { .spring(response: ctx["response"], dampingFraction: 0.8) }

    private var emailBinding: Binding<String> {
        Binding(
            get: { email },
            set: { newValue in
                email = newValue
                if ctx.bool("live") && submitted {
                    let next: FieldStatus = Self.isValid(newValue) ? .valid : .invalid
                    if next != status { withAnimation(spring) { status = next } }
                } else if status != .idle {
                    withAnimation(.easeOut(duration: 0.15)) { status = .idle }
                }
            }
        )
    }

    var body: some View {
        VStack(spacing: 16) {
            card
            DemoHint(text: L("Tap Continue, then fix the address", "点击“继续”，再改正邮箱地址"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.8, delay: 0.6) { previewAdvance() }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(ctx.language == .zh ? "邮箱" : "Email")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            field
            if status != .idle {
                message
                    .transition(.offset(y: -8).combined(with: .opacity))
            }
            Button(action: submit) {
                Text(ctx.language == .zh ? "继续" : "Continue")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Palette.primary, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .padding(20)
        .frame(width: 300)
        .demoCard(cornerRadius: 26)
    }

    private var field: some View {
        let a = ctx.cg("amplitude")
        let tint: Color = status == .invalid ? Palette.red : (status == .valid ? Palette.green : Color.secondary)
        return HStack(spacing: 10) {
            Image(systemName: "envelope.fill")
                .font(.subheadline)
                .foregroundStyle(tint)
            TextField(text: emailBinding, prompt: Text(verbatim: "name@example.com")) { Text(ctx.language == .zh ? "邮箱" : "Email") }
                .font(.body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
                .submitLabel(.continue)
                .onSubmit(submit)
                .disabled(ctx.isPreview)
            statusIcon
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(status == .idle ? Palette.stroke : tint, lineWidth: status == .idle ? 1 : 1.5)
        }
        .keyframeAnimator(initialValue: FieldShake(), trigger: failures) { content, value in
            content.offset(x: value.x)
        } keyframes: { _ in
            KeyframeTrack(\.x) {
                CubicKeyframe(-a, duration: 0.06)
                CubicKeyframe(a * 0.78, duration: 0.08)
                CubicKeyframe(-a * 0.5, duration: 0.07)
                CubicKeyframe(a * 0.22, duration: 0.06)
                SpringKeyframe(0, duration: 0.18, spring: .snappy)
            }
        }
    }

    @ViewBuilder private var statusIcon: some View {
        switch status {
        case .idle:
            EmptyView()
        case .invalid:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.title3)
                .foregroundStyle(Palette.red)
                .transition(.scale(scale: 0.4).combined(with: .opacity))
        case .valid:
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(Palette.green)
                .transition(.scale(scale: 0.4).combined(with: .opacity))
        }
    }

    private var message: some View {
        let valid = status == .valid
        return Label {
            Text(valid
                 ? (ctx.language == .zh ? "看起来不错" : "Looks good")
                 : (ctx.language == .zh ? "请输入有效的邮箱地址" : "Enter a valid email address"))
        } icon: {
            Image(systemName: valid ? "checkmark" : "exclamationmark.triangle.fill")
        }
        .font(.footnote.weight(.medium))
        .foregroundStyle(valid ? Palette.green : Palette.red)
        .contentTransition(.interpolate)
    }

    private func submit() {
        submitted = true
        if Self.isValid(email) {
            if !ctx.isPreview { Haptics.success() }
            withAnimation(.spring(response: ctx["response"], dampingFraction: 0.62)) { status = .valid }
        } else {
            if !ctx.isPreview { Haptics.error() }
            failures += 1
            withAnimation(spring) { status = .invalid }
        }
    }

    /// Previews alternate a failed submit and a corrected, successful one.
    private func previewAdvance() {
        if previewStep % 2 == 0 {
            email = "alex@studio"
        } else {
            email = "alex@studio.com"
        }
        submit()
        previewStep += 1
    }

    static func isValid(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.contains(" ") else { return false }
        let parts = trimmed.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty else { return false }
        let domain = parts[1]
        guard let dot = domain.lastIndex(of: ".") else { return false }
        return dot != domain.startIndex && domain.distance(from: dot, to: domain.endIndex) > 2
    }
}
