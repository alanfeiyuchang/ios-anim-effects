import SwiftUI

extension Effect {
    static let inputsOTPCode = Effect(
        id: "inputs.otp-code",
        category: .inputs,
        interaction: .state,
        name: L("One-Time Code Input", "验证码输入"),
        summary: L("Digits pop into boxes; a wrong code shakes, the right one waves.", "数字弹入格子，错误时抖动，正确时波浪跳动。"),
        prompt: L(
            "A row of six rounded code boxes (44 × 54 pt, 12 pt continuous corners). The active box is outlined in indigo, scaled to 106% and shows a blinking 2 pt caret (0.5 s ease-in-out fade). Each typed digit pops in from 40% scale with a bouncy spring (response 0.3 s, damping 0.6) and the caret hops to the next box. When all six are entered: a wrong code turns every border red, shakes the whole row horizontally ±10 pt three times with decaying amplitude over 450 ms, fires an error haptic and clears after 600 ms; the correct code turns the borders green and runs a wave — each box hops up 10 pt with a 50 ms stagger — plus a success haptic. Clear, forgiving and satisfying.",
            "一排六个圆角验证码格子（44 × 54pt，12pt 连续圆角）。当前格子描边为靛蓝色、放大到 106%，内部显示一根 2pt 闪烁光标（0.5 秒缓入缓出淡入淡出）。每输入一位数字，数字就以弹性弹簧（响应 0.3 秒、阻尼 0.6）从 40% 缩放弹入，光标跳到下一格。六位输满后：若错误，所有描边变红，整排在 450 毫秒内左右抖动三次（幅度 ±10pt 并逐渐衰减），触发错误触觉，600 毫秒后清空；若正确，描边变绿，格子以 50 毫秒错峰依次向上跳 10pt 形成波浪，并触发成功触觉。清晰、宽容又令人满足。"
        ),
        implementation: L(
            "A hidden numberPad TextField owns the input; boxes render its characters with an insertion transition. A GeometryEffect with animatable progress produces the decaying shake, and per-box keyframeAnimators with index delays create the success wave.",
            "隐藏的数字键盘 TextField 负责接收输入，格子以插入过渡展示字符。带可动画进度的 GeometryEffect 产生衰减抖动；每个格子的 keyframeAnimator 按索引延迟，形成成功波浪。"
        ),
        apis: ["GeometryEffect", "keyframeAnimator", "phaseAnimator", "textContentType(.oneTimeCode)", "@FocusState"],
        tags: ["otp", "verification", "passcode", "shake", "验证码", "输入", "抖动", "PIN"],
        params: [
            .choice("digits", L("Length", "位数"), [L("4 digits", "4 位"), L("6 digits", "6 位")], default: 1),
            .slider("shake", L("Shake travel", "抖动幅度"), 4...20, default: 10, decimals: 0, unit: "pt"),
            .slider("pop", L("Digit pop-in scale", "数字弹入起始缩放"), 0.1...0.9, default: 0.4),
        ]
    ) { ctx in
        InputOTPDemo(ctx: ctx)
    }
}

private enum InputOTPStatus {
    case idle
    case error
    case success
}

private struct InputOTPDemo: View {
    let ctx: DemoContext
    @State private var code = ""
    @State private var status: InputOTPStatus = .idle
    @State private var attempts: CGFloat = 0
    @State private var successes = 0
    @State private var scriptIndex = 0
    @State private var holdTicks = 0
    @FocusState private var focused: Bool

    private var length: Int { ctx.int("digits") == 0 ? 4 : 6 }
    private var expected: String { String("123456".prefix(length)) }
    private var spacedExpected: String { expected.map(String.init).joined(separator: " ") }
    private var wrongCode: String { String("123999".prefix(length - 1)) + "0" }

    var body: some View {
        VStack(spacing: 26) {
            Spacer()
            boxes
            DemoHint(text: L("Tap the boxes · correct code is \(spacedExpected)", "点击格子输入 · 正确验证码为 \(spacedExpected)"), ctx: ctx)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { hiddenField }
        .onChange(of: length) { _, _ in reset() }
        .autoplay(ctx.isPreview, every: 0.32, delay: 0.5) { previewTick() }
    }

    private var boxes: some View {
        HStack(spacing: 8) {
            ForEach(0..<length, id: \.self) { index in
                InputOTPBox(
                    character: character(at: index),
                    isCurrent: (focused || ctx.isPreview) && status == .idle && index == code.count,
                    status: status,
                    index: index,
                    successes: successes,
                    pop: ctx.cg("pop")
                )
            }
        }
        .modifier(InputShakeEffect(travel: ctx.cg("shake"), progress: attempts))
        .contentShape(Rectangle())
        .onTapGesture {
            if status == .success { reset() }
            focused = true
        }
    }

    private var hiddenField: some View {
        TextField("", text: $code)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .focused($focused)
            .frame(width: 1, height: 1)
            .opacity(0.01)
            .allowsHitTesting(false)
            .onChange(of: code) { _, newValue in handle(newValue) }
    }

    private func character(at index: Int) -> String? {
        guard index < code.count else { return nil }
        return String(code[code.index(code.startIndex, offsetBy: index)])
    }

    private func handle(_ newValue: String) {
        let digits = String(newValue.filter(\.isNumber).prefix(length))
        if digits != newValue {
            code = digits
            return
        }
        if digits.count == length && status == .idle {
            verify(digits)
        }
    }

    private func verify(_ digits: String) {
        if digits == expected {
            withAnimation(.snappy) { status = .success }
            successes += 1
            holdTicks = 5
            focused = false
            if !ctx.isPreview { Haptics.success() }
        } else {
            withAnimation(.snappy) { status = .error }
            withAnimation(.linear(duration: 0.45)) { attempts += 1 }
            if !ctx.isPreview { Haptics.error() }
            Task {
                try? await Task.sleep(for: .seconds(0.6))
                withAnimation(.snappy) {
                    code = ""
                    status = .idle
                }
            }
        }
    }

    private func reset() {
        withAnimation(.snappy) {
            code = ""
            status = .idle
        }
    }

    private func previewTick() {
        if holdTicks > 0 {
            holdTicks -= 1
            if holdTicks == 0 { reset() }
            return
        }
        guard status == .idle, code.count < length else { return }
        let script = wrongCode + expected
        let chars = Array(script)
        let next = chars[scriptIndex % chars.count]
        scriptIndex += 1
        code.append(next)
    }
}

private struct InputOTPBox: View {
    let character: String?
    let isCurrent: Bool
    let status: InputOTPStatus
    let index: Int
    let successes: Int
    /// Scale a typed digit pops in from.
    let pop: CGFloat

    private var borderColor: Color {
        switch status {
        case .error: return Palette.red
        case .success: return Palette.green
        case .idle:
            if isCurrent { return Palette.indigo }
            return character == nil ? Color.primary.opacity(0.12) : Color.primary.opacity(0.3)
        }
    }

    var body: some View {
        let lead = 0.001 + Double(index) * 0.05
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Palette.elevated)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(borderColor, lineWidth: isCurrent || status != .idle ? 2 : 1)
            if let character {
                Text(character)
                    .font(.system(size: 24, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.primary)
                    .transition(.scale(scale: pop).combined(with: .opacity))
            } else if isCurrent {
                InputOTPCaret()
            }
        }
        .frame(width: 44, height: 54)
        .scaleEffect(isCurrent ? 1.06 : 1)
        .shadow(color: borderColor.opacity(isCurrent ? 0.25 : 0), radius: 8, y: 4)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: character)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCurrent)
        .keyframeAnimator(initialValue: 0.0, trigger: successes) { content, lift in
            content.offset(y: lift)
        } keyframes: { _ in
            KeyframeTrack(\.self) {
                LinearKeyframe(0, duration: lead)
                SpringKeyframe(-10, duration: 0.16, spring: .snappy)
                SpringKeyframe(0, duration: 0.45, spring: .bouncy)
            }
        }
    }
}

private struct InputOTPCaret: View {
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

/// Horizontal shake whose amplitude decays within each whole-number step of `progress`.
private struct InputShakeEffect: GeometryEffect {
    var travel: CGFloat
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let fraction = progress - progress.rounded(.down)
        let x = travel * sin(fraction * .pi * 6) * (1 - fraction)
        return ProjectionTransform(CGAffineTransform(translationX: x, y: 0))
    }
}
