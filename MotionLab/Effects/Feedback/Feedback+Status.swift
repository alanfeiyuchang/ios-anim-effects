import SwiftUI

// MARK: - Error shake

extension Effect {
    static let feedbackErrorShake = Effect(
        id: "feedback.error-shake",
        category: .feedback,
        interaction: .tap,
        name: L("Error Shake", "错误抖动"),
        summary: L("A passcode field that shakes 'no' with a decaying keyframe wiggle.", "密码框以衰减的关键帧左右摇头表示“不对”。"),
        prompt: L(
            "A passcode card with four filled dots inside a capsule field and an 'Unlock' button. On a wrong attempt the field shakes horizontally like a head saying no: −16 → +13 → −9 → +5 → −2 pt over roughly 360 ms of short cubic segments, then settles to 0 on a snappy spring, each swing smaller than the last. At the same moment the dots and hairline border flush to system red, an error haptic fires, and the 'Enter Passcode' heading gives way in place to a red 'Wrong passcode. Try again.' caption that drops in 6 pt from above (overlaid, so no empty row is reserved for it); everything eases back to neutral after 1.2 s. Firm but not alarming.",
            "密码卡片中，一条胶囊输入框里有四个实心圆点，下方是“解锁”按钮。输入错误时，输入框像“摇头说不”一样左右抖动：在约 360 毫秒内以数段短促的三次曲线经过 −16 → +13 → −9 → +5 → −2 pt，最后以利落的弹簧归零，每次摆幅都比上次更小。与此同时圆点与细描边变为系统红色，触发错误触感，“输入密码”标题原位让出，红色“密码错误，请重试”从上方 6 pt 处落入（两者叠放，不为错误文案预留空行）；1.2 秒后一切缓缓恢复常态。坚定而不惊吓。"
        ),
        implementation: L(
            "keyframeAnimator keyed on an attempt counter plays a decaying CubicKeyframe sequence on x-offset; a Boolean tints the field red for 1.2 s.",
            "以尝试次数为触发器的 keyframeAnimator 在 x 偏移上播放衰减的 CubicKeyframe 序列；布尔状态让输入框变红 1.2 秒。"
        ),
        apis: ["keyframeAnimator", "CubicKeyframe", "SpringKeyframe", "Haptics"],
        tags: ["shake", "error", "wrong password", "invalid", "抖动", "错误", "密码错误", "校验"],
        params: [
            .slider("amplitude", L("Amplitude", "幅度"), 4...30, default: 16, decimals: 0, unit: "pt"),
            .slider("speed", L("Duration scale", "时长倍率"), 0.5...2.0, default: 1.0, unit: "×"),
        ]
    ) { ctx in
        ErrorShakeDemo(ctx: ctx)
    }
}

private struct ShakeOffset {
    var x: CGFloat = 0
}

private struct ErrorShakeDemo: View {
    let ctx: DemoContext
    @State private var attempts = 0
    @State private var isError = false
    @State private var token = 0

    var body: some View {
        let a = ctx.cg("amplitude")
        let s = ctx["speed"]
        VStack(spacing: 18) {
            // The error caption overlays the heading in place, so no empty row is reserved for it.
            ZStack {
                Text(ctx.language == .zh ? "输入密码" : "Enter Passcode")
                    .font(.headline)
                    .opacity(isError ? 0 : 1)
                    .offset(y: isError ? 6 : 0)
                Text(ctx.language == .zh ? "密码错误，请重试" : "Wrong passcode. Try again.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.red)
                    .fixedSize()
                    .opacity(isError ? 1 : 0)
                    .offset(y: isError ? 0 : -6)
            }
            PasscodeField(isError: isError)
                .keyframeAnimator(initialValue: ShakeOffset(), trigger: attempts) { content, value in
                    content.offset(x: value.x)
                } keyframes: { _ in
                    KeyframeTrack(\.x) {
                        CubicKeyframe(-a, duration: 0.06 * s)
                        CubicKeyframe(a * 0.8, duration: 0.09 * s)
                        CubicKeyframe(-a * 0.55, duration: 0.08 * s)
                        CubicKeyframe(a * 0.3, duration: 0.07 * s)
                        CubicKeyframe(-a * 0.12, duration: 0.06 * s)
                        SpringKeyframe(0, duration: 0.2 * s, spring: .snappy)
                    }
                }
            Button(action: fail) {
                Text(ctx.language == .zh ? "解锁" : "Unlock")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 48)
                    .background(Palette.primary, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .demoCard(cornerRadius: 26)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap Unlock", "点击“解锁”"), ctx: ctx)
                .fixedSize()
                .offset(y: 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.0, delay: 0.5) { fail() }
    }

    private func fail() {
        token += 1
        let current = token
        attempts += 1
        if !ctx.isPreview { Haptics.error() }
        withAnimation(.snappy(duration: 0.2)) { isError = true }
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            guard token == current else { return }
            withAnimation(.smooth(duration: 0.4)) { isError = false }
        }
    }
}

private struct PasscodeField: View {
    let isError: Bool

    var body: some View {
        HStack(spacing: 18) {
            ForEach(0..<4, id: \.self) { _ in
                Circle()
                    .fill(isError ? Palette.red : Color.primary)
                    .frame(width: 12, height: 12)
            }
        }
        .frame(width: 200, height: 50)
        .background(Palette.surface, in: Capsule())
        .overlay {
            Capsule().strokeBorder(isError ? Palette.red : Palette.stroke, lineWidth: isError ? 1.5 : 1)
        }
    }
}

// MARK: - Success check

extension Effect {
    static let feedbackSuccessCheck = Effect(
        id: "feedback.success-check",
        category: .feedback,
        interaction: .tap,
        name: L("Success Check", "成功对勾"),
        summary: L("A ring draws itself, fills with a bounce, then a checkmark is written in.", "圆环自绘、弹性填充，最后写出对勾。"),
        prompt: L(
            "A 110 pt success badge built in three beats. First a 4 pt green ring draws itself clockwise from 12 o'clock over 0.45 s (ease-in-out). As the ring closes, a solid green disc blooms from the center on a bouncy spring, overshooting past full size, while eight short sparks shoot outward 30 pt and fade. Finally a thick rounded white checkmark is stroked in 0.3 s with an ease-out, short leg first, and the caption 'Payment complete' fades up beneath it with a success haptic. The sequence is quick, celebratory and unmistakably final.",
            "一枚 110 pt 的成功徽章，分三拍完成。第一拍：4 pt 绿色圆环从 12 点方向顺时针自绘，历时 0.45 秒（缓入缓出）。第二拍：圆环闭合之际，实心绿色圆盘从中心以弹性曲线绽开，略微超出满尺寸，同时八道短火花向外射出 30 pt 并淡出。第三拍：粗圆头白色对勾在 0.3 秒内以缓出曲线写出，先短边后长边，下方的“支付成功”随之淡入，并伴随成功触感。整体迅速、喜悦、结论明确。"
        ),
        implementation: L(
            "A single keyframeAnimator with four tracks (ring trim, fill scale, check trim, spark burst) choreographs the timing; MoveKeyframe resets each replay.",
            "一个 keyframeAnimator 的四条轨道（圆环 trim、填充缩放、对勾 trim、火花扩散）编排整段节奏，MoveKeyframe 在每次重播时归零。"
        ),
        apis: ["keyframeAnimator", "MoveKeyframe", "trim(from:to:)", "Spring.bouncy"],
        tags: ["success", "checkmark", "done", "complete", "成功", "对勾", "完成", "支付成功"],
        params: [
            .slider("speed", L("Duration scale", "时长倍率"), 0.5...2.0, default: 1.0, unit: "×"),
            .toggle("sparks", L("Sparks", "火花"), default: true),
        ]
    ) { ctx in
        SuccessCheckDemo(ctx: ctx)
    }
}

private struct CheckValues {
    var ring: CGFloat = 1
    var fill: CGFloat = 1
    var check: CGFloat = 1
    var burst: CGFloat = 1
}

private struct SuccessCheckDemo: View {
    let ctx: DemoContext
    @State private var plays = 0

    var body: some View {
        let d = ctx["speed"]
        let sparks = ctx.bool("sparks")
        let caption = ctx.language == .zh ? "支付成功" : "Payment complete"
        VStack(spacing: 22) {
            Color.clear
                .frame(width: 110, height: 110)
                .keyframeAnimator(initialValue: CheckValues(), trigger: plays) { content, v in
                    content
                        .overlay { SuccessBadge(values: v, sparks: sparks) }
                        .overlay(alignment: .bottom) {
                            Text(caption)
                                .font(.headline)
                                .fixedSize()
                                .opacity(Double(v.check))
                                .offset(y: 44 + 8 * (1 - v.check))
                        }
                } keyframes: { _ in
                    KeyframeTrack(\.ring) {
                        MoveKeyframe(0)
                        LinearKeyframe(1, duration: 0.45 * d, timingCurve: .easeInOut)
                    }
                    KeyframeTrack(\.fill) {
                        MoveKeyframe(0)
                        LinearKeyframe(0, duration: 0.38 * d)
                        SpringKeyframe(1, duration: 0.5 * d, spring: .bouncy)
                    }
                    KeyframeTrack(\.check) {
                        MoveKeyframe(0)
                        LinearKeyframe(0, duration: 0.6 * d)
                        LinearKeyframe(1, duration: 0.3 * d, timingCurve: .easeOut)
                    }
                    KeyframeTrack(\.burst) {
                        MoveKeyframe(0)
                        LinearKeyframe(0, duration: 0.42 * d)
                        LinearKeyframe(1, duration: 0.5 * d, timingCurve: .easeOut)
                    }
                }
                .padding(.bottom, 30)
            DemoHint(text: L("Tap to replay", "点击重播"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { play() }
        .autoplay(ctx.isPreview, every: 2.4, delay: 0.3) { play() }
    }

    private func play() {
        plays += 1
        guard !ctx.isPreview else { return }
        let delay = 0.6 * ctx["speed"]
        Task {
            try? await Task.sleep(for: .seconds(delay))
            Haptics.success()
        }
    }
}

private struct SuccessBadge: View {
    let values: CheckValues
    let sparks: Bool

    var body: some View {
        ZStack {
            if sparks {
                ForEach(0..<8, id: \.self) { index in
                    Capsule()
                        .fill(Palette.green)
                        .frame(width: 4, height: 12)
                        .offset(y: -(62 + 30 * values.burst))
                        .rotationEffect(.degrees(Double(index) * 45))
                        .opacity(values.burst > 0 && values.burst < 1 ? Double(1 - values.burst) : 0)
                }
            }
            Circle()
                .trim(from: 0, to: values.ring)
                .stroke(Palette.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Circle()
                .fill(LinearGradient(colors: [Color(hex: 0x4BE08F), Palette.green], startPoint: .top, endPoint: .bottom))
                .scaleEffect(values.fill)
                .shadow(color: Palette.green.opacity(0.4), radius: 14, y: 6)
            SuccessCheckShape()
                .trim(from: 0, to: values.check)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                .frame(width: 46, height: 36)
        }
        .frame(width: 110, height: 110)
    }
}

private struct SuccessCheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.04, y: rect.minY + rect.height * 0.55))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.37, y: rect.maxY - rect.height * 0.04))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.03, y: rect.minY + rect.height * 0.06))
        return path
    }
}

// MARK: - Copy to clipboard

extension Effect {
    static let feedbackCopy = Effect(
        id: "feedback.copy-confirm",
        category: .feedback,
        interaction: .tap,
        name: L("Copy Confirmation", "复制确认"),
        summary: L("The copy icon morphs into a check and a floating 'Copied' tag rises.", "复制图标形变为对勾，“已复制”标签轻轻上浮。"),
        prompt: L(
            "A share-link field in a rounded card: a link glyph, a monospaced URL and a trailing capsule button labeled 'Copy' with a doc icon. On tap the button presses to 94%, the doc icon morphs into a checkmark via a symbol replace transition, the label cross-fades to 'Copied' while the capsule's width re-flows on a snappy spring, and its fill shifts from a neutral tint to green. Simultaneously a small dark tooltip reading 'Link copied' rises 10 pt above the button and fades in, then everything reverts after about 1.6 s. Clear, reassuring confirmation without a modal.",
            "圆角卡片中的分享链接栏：左侧链接图标、中间等宽字体网址，右侧是带文档图标的“复制”胶囊按钮。点击时按钮先压缩到 94%，文档图标通过符号替换过渡形变为对勾，文字交叉淡变为“已复制”，胶囊宽度随之以利落弹簧重新伸缩，底色从中性色转为绿色。与此同时，一枚写着“链接已复制”的深色小气泡从按钮上方上浮 10 pt 并淡入；约 1.6 秒后全部复原。无需弹窗，也能给出清晰、安心的确认。"
        ),
        implementation: L(
            "contentTransition(.symbolEffect(.replace)) swaps the SF Symbol; a tokenized Task reverts the state; the tooltip is an overlay driven by offset and opacity.",
            "contentTransition(.symbolEffect(.replace)) 切换 SF Symbol，带令牌的 Task 负责复原，提示气泡是由位移与透明度驱动的 overlay。"
        ),
        apis: ["contentTransition(.symbolEffect(.replace))", "contentTransition(.interpolate)", "snappy", "overlay(alignment:content:)"],
        tags: ["copy", "clipboard", "link", "confirmation", "复制", "剪贴板", "链接", "确认"],
        params: [
            .slider("hold", L("Hold time", "停留时长"), 0.8...3.0, default: 1.6, decimals: 1, unit: "s"),
            .toggle("tooltip", L("Tooltip", "提示气泡"), default: true),
        ]
    ) { ctx in
        CopyDemo(ctx: ctx)
    }
}

private struct CopyDemo: View {
    let ctx: DemoContext
    @State private var copied = false
    @State private var token = 0

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "link")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.indigo)
                Text(verbatim: "motion.app/k7Qx")
                    .font(.system(.subheadline, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .layoutPriority(1)
                Spacer(minLength: 6)
                copyButton
                    .fixedSize()
            }
            .padding(.leading, 16)
            .padding(.trailing, 8)
            .frame(width: 316, height: 58)
            .demoCard(cornerRadius: 18)
            DemoHint(text: L("Tap Copy", "点击“复制”"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: ctx["hold"] + 1.0, delay: 0.5) { copy() }
    }

    private var copyButton: some View {
        Button(action: copy) {
            HStack(spacing: 6) {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .contentTransition(.symbolEffect(.replace))
                Text(copied ? (ctx.language == .zh ? "已复制" : "Copied") : (ctx.language == .zh ? "复制" : "Copy"))
                    .contentTransition(.interpolate)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(copied ? Color.white : Color.primary)
            .padding(.horizontal, 14)
            .frame(height: 40)
            .background(copied ? Palette.green : Color.primary.opacity(0.07), in: Capsule())
        }
        .buttonStyle(CopyPressStyle())
        .overlay(alignment: .top) {
            if ctx.bool("tooltip") {
                CopyTooltip(text: ctx.language == .zh ? "链接已复制" : "Link copied")
                    .offset(y: copied ? -44 : -34)
                    .opacity(copied ? 1 : 0)
                    .allowsHitTesting(false)
            }
        }
    }

    private func copy() {
        token += 1
        let current = token
        let hold = ctx["hold"]
        if !ctx.isPreview { Haptics.success() }
        withAnimation(.snappy(duration: 0.3, extraBounce: 0.15)) { copied = true }
        Task {
            try? await Task.sleep(for: .seconds(hold))
            guard token == current else { return }
            withAnimation(.snappy(duration: 0.3)) { copied = false }
        }
    }
}

private struct CopyTooltip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color(uiColor: .systemBackground))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.primary, in: Capsule())
            .fixedSize()
            .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
    }
}

private struct CopyPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
