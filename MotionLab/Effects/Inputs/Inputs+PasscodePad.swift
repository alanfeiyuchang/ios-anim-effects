import SwiftUI

extension Effect {
    static let inputsPasscodePad = Effect(
        id: "inputs.passcode-pad",
        category: .inputs,
        interaction: .tap,
        name: L("Passcode Keypad", "密码键盘"),
        summary: L("Keys glow on touch, dots pop in, a wrong code shakes, the right one unlocks.", "按键触碰发光、圆点弹入，输错会抖动，输对即解锁。"),
        prompt: L(
            "A lock-screen style passcode pad: a lock glyph and title above four 13 pt outline dots, then a 3 × 4 grid of 56 pt round keys with large digits and tiny letter captions. Touching a key flashes its fill instantly to 26% and releases it with a 350 ms ease-out fade, like backlit glass, with a light haptic. Each digit fills the next dot, which pops from 85% on a bouncy spring (response 0.3 s, damping 0.55). On the fourth digit a wrong code turns the dots red and shakes the row with a decaying horizontal keyframe wobble (±14 pt → 0 in ~450 ms) plus an error haptic, then clears; the right code turns the dots green, the lock springs open via a symbol replace and a success haptic fires. Familiar, precise and reassuring.",
            "锁屏风格的密码键盘：顶部是锁形图标与标题，下方四个 13pt 描边圆点，再往下是 3 × 4 的 56pt 圆形按键，大号数字下方配细小字母。手指触碰按键时底色瞬间提亮到 26%，松手后以 350 毫秒缓出淡回，像背光玻璃一样，并伴随轻触觉。每输入一位，下一个圆点被填满，并以弹性弹簧（响应 0.3 秒、阻尼 0.55）从 85% 弹入。输满四位后：若密码错误，圆点变红，整行以逐渐衰减的水平关键帧抖动（±14pt → 0，约 450 毫秒），并触发错误触觉后清空；若正确，圆点变绿，锁通过符号替换弹开，并触发成功触觉。熟悉、精准、令人安心。"
        ),
        implementation: L(
            "Keys are Buttons with a custom ButtonStyle whose fill animation is nil on press and ease-out on release; the dots read the entered string, and a keyframeAnimator on a shake counter wobbles the row. The lock glyph uses contentTransition(.symbolEffect(.replace)).",
            "按键是使用自定义 ButtonStyle 的 Button：按下时底色动画为 nil、松手时为缓出；圆点读取已输入字符串，以抖动计数为触发器的 keyframeAnimator 让整行抖动；锁形图标使用 contentTransition(.symbolEffect(.replace))。"
        ),
        apis: ["ButtonStyle", "keyframeAnimator", "contentTransition(.symbolEffect(.replace))", "LinearKeyframe", "spring(response:dampingFraction:)"],
        tags: ["passcode", "pin", "keypad", "lock", "密码", "键盘", "解锁", "抖动"],
        params: [
            .slider("shake", L("Shake distance", "抖动幅度"), 4...24, default: 14, decimals: 0, unit: "pt"),
            .slider("damping", L("Dot pop damping", "圆点弹性阻尼"), 0.3...0.9, default: 0.55),
            .toggle("letters", L("Letter captions", "字母标注"), default: true),
        ]
    ) { ctx in
        InputPasscodePadDemo(ctx: ctx)
    }
}

private enum InputPasscodeState {
    case idle, error, success
}

private struct InputPasscodePadDemo: View {
    let ctx: DemoContext
    @State private var entered = ""
    @State private var status = InputPasscodeState.idle
    @State private var busy = false
    @State private var shakes = 0
    @State private var flashed: String?
    @State private var step = 0

    private static let code = "2580"
    /// Preview script: a wrong attempt, a pause, then the right code (nil = wait a beat).
    private static let script: [String?] = ["1", "3", "7", "9", nil, nil, nil, "2", "5", "8", "0", nil, nil, nil, nil]
    private static let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "del"]
    private static let letters = ["", "ABC", "DEF", "GHI", "JKL", "MNO", "PQRS", "TUV", "WXYZ", "", "", ""]

    private let keySize: CGFloat = 56

    private var dotColor: Color {
        switch status {
        case .idle: return .primary
        case .error: return Palette.red
        case .success: return Palette.green
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            header
            dots
                .padding(.top, 12)
                .padding(.bottom, 20)
            keypad
            Spacer(minLength: 0)
            DemoHint(text: L("Passcode is 2580", "密码是 2580"), ctx: ctx)
                .padding(.top, 10)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 0.32, delay: 0.5) { previewTick() }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: status == .success ? "lock.open.fill" : "lock.fill")
                .contentTransition(.symbolEffect(.replace))
                .foregroundStyle(status == .success ? Palette.green : Color.primary)
            Text(title, ctx.language)
                .contentTransition(.opacity)
        }
        .font(.headline)
        .foregroundStyle(.primary)
    }

    private var title: LocalizedText {
        switch status {
        case .idle: return L("Enter passcode", "输入密码")
        case .error: return L("Try again", "密码错误")
        case .success: return L("Unlocked", "已解锁")
        }
    }

    private var dots: some View {
        let d = ctx.cg("shake")
        return HStack(spacing: 18) {
            ForEach(0..<4, id: \.self) { index in
                let filled = index < entered.count
                Circle()
                    .fill(filled ? dotColor : Color.clear)
                    .overlay(Circle().strokeBorder(dotColor.opacity(0.8), lineWidth: 1.5))
                    .frame(width: 13, height: 13)
                    .scaleEffect(filled ? 1 : 0.85)
                    .animation(.spring(response: 0.3, dampingFraction: ctx["damping"]), value: filled)
            }
        }
        .keyframeAnimator(initialValue: CGFloat(0), trigger: shakes) { content, x in
            content.offset(x: x)
        } keyframes: { _ in
            KeyframeTrack(\.self) {
                LinearKeyframe(-d, duration: 0.06)
                LinearKeyframe(d * 0.85, duration: 0.08)
                LinearKeyframe(-d * 0.6, duration: 0.08)
                LinearKeyframe(d * 0.35, duration: 0.08)
                LinearKeyframe(-d * 0.15, duration: 0.07)
                SpringKeyframe(0, duration: 0.1)
            }
        }
    }

    private var keypad: some View {
        let columns = Array(repeating: GridItem(.fixed(keySize), spacing: 18), count: 3)
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Self.keys.indices, id: \.self) { index in
                key(index)
            }
        }
        .frame(width: keySize * 3 + 36)
    }

    @ViewBuilder
    private func key(_ index: Int) -> some View {
        let label = Self.keys[index]
        if label.isEmpty {
            Color.clear.frame(width: keySize, height: keySize)
        } else if label == "del" {
            Button(action: deleteLast) {
                Image(systemName: "delete.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: keySize, height: keySize)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .opacity(entered.isEmpty ? 0.3 : 1)
        } else {
            Button {
                press(label)
            } label: {
                VStack(spacing: 0) {
                    Text(verbatim: label)
                        .font(.system(size: 26, weight: .regular, design: .rounded))
                    if ctx.bool("letters") && !Self.letters[index].isEmpty {
                        Text(verbatim: Self.letters[index])
                            .font(.system(size: 8, weight: .bold))
                            .tracking(1.2)
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)
                .frame(width: keySize, height: keySize)
            }
            .buttonStyle(InputKeyStyle(forced: flashed == label))
        }
    }

    private func press(_ digit: String) {
        guard !busy, entered.count < 4 else { return }
        if !ctx.isPreview { Haptics.tap() }
        entered.append(digit)
        if entered.count == 4 { evaluate() }
    }

    private func deleteLast() {
        guard !busy, !entered.isEmpty else { return }
        if !ctx.isPreview { Haptics.selection() }
        entered.removeLast()
    }

    private func evaluate() {
        busy = true
        let correct = entered == Self.code
        let preview = ctx.isPreview
        Task {
            try? await Task.sleep(for: .seconds(0.18))
            if correct {
                if !preview { Haptics.success() }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { status = .success }
                try? await Task.sleep(for: .seconds(1.3))
            } else {
                if !preview { Haptics.error() }
                withAnimation(.easeOut(duration: 0.15)) { status = .error }
                shakes += 1
                try? await Task.sleep(for: .seconds(0.75))
            }
            withAnimation(.smooth(duration: 0.3)) {
                entered = ""
                status = .idle
            }
            busy = false
        }
    }

    private func previewTick() {
        let item = Self.script[step % Self.script.count]
        step += 1
        guard let digit = item else { return }
        flashed = digit
        press(digit)
        Task {
            try? await Task.sleep(for: .seconds(0.14))
            flashed = nil
        }
    }
}

/// Backlit-glass key: fill jumps up instantly on touch and fades out slowly on release.
private struct InputKeyStyle: ButtonStyle {
    let forced: Bool

    func makeBody(configuration: Configuration) -> some View {
        let lit = configuration.isPressed || forced
        return configuration.label
            .background {
                Circle().fill(Color.primary.opacity(lit ? 0.26 : 0.07))
            }
            .animation(lit ? nil : Animation.easeOut(duration: 0.35), value: lit)
    }
}
