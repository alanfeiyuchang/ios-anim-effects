import SwiftUI

extension Effect {
    static let inputsPasscodePad = Effect(
        id: "inputs.passcode-pad",
        category: .inputs,
        interaction: .tap,
        name: L("Passcode Keypad", "密码键盘"),
        summary: L("Keys glow on touch, dots pop in, a wrong code drops the dots, the right one unlocks.", "按键触碰发光、圆点弹入，输错圆点坠落，输对即解锁。"),
        prompt: L(
            "A lock-screen style passcode pad: a lock glyph and title over four 13 pt outline dots and a 3 × 4 grid of 54 pt round keys (12 pt row gap) with digits and tiny letter captions. Touching a key flashes its fill instantly to 26% and releases it with a 350 ms ease-out fade, like backlit glass. Each digit fills the next dot, which pops from 85% on a bouncy spring (response 0.3 s, damping 0.55). On the fourth digit a wrong code turns the dots red and lets gravity take them: each filled core falls ~44 pt on an ease-in curve over 420 ms, tipping and fading, 50 ms apart, while the empty rings stay behind, plus an error haptic; the right code turns the dots green, the lock springs open via a symbol replace and a success haptic fires. Familiar, reassuring.",
            "锁屏风格密码键盘：锁形图标与标题下是四个 13pt 描边圆点，再下是 3 × 4 的 54pt 圆形按键。触碰按键时底色瞬间提亮到 26%，松手后 350 毫秒缓出淡回，像背光玻璃。每输入一位，下一个圆点以弹性弹簧（响应 0.3 秒、阻尼 0.55）从 85% 弹入。输满四位：错误则圆点变红，实心圆点如受重力以缓入曲线在 420 毫秒内下坠约 44pt，边倾斜边淡出，间隔 50 毫秒，只留下空心圆环，并触发错误触觉；正确则圆点变绿，锁经符号替换弹开并触发成功触觉。"
        ),
        implementation: L(
            "Keys are Buttons with a custom ButtonStyle whose fill animation is nil on press and ease-out on release; each dot is an outline ring plus a filled core, and a dropping flag sends every core down with an ease-in, index-delayed animation. The lock glyph uses contentTransition(.symbolEffect(.replace)).",
            "按键是使用自定义 ButtonStyle 的 Button：按下时底色动画为 nil、松手时为缓出；每个圆点由描边圆环与实心内核组成，dropping 状态让各内核以按索引延迟的缓入动画下坠；锁形图标使用 contentTransition(.symbolEffect(.replace))。"
        ),
        apis: ["ButtonStyle", "easeIn(duration:)", "contentTransition(.symbolEffect(.replace))", "rotationEffect", "spring(response:dampingFraction:)"],
        tags: ["passcode", "pin", "keypad", "lock", "密码", "键盘", "解锁", "坠落"],
        params: [
            .slider("fall", L("Drop distance", "坠落距离"), 16...80, default: 44, decimals: 0, unit: "pt"),
            .slider("damping", L("Dot pop damping", "圆点弹性阻尼"), 0.3...0.9, default: 0.55),
            .slider("fade", L("Key glow fade", "按键光晕淡出"), 0.1...0.8, default: 0.35, unit: "s"),
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
    /// Wrong code: the filled cores fall out of their rings.
    @State private var dropping = false
    @State private var flashed: String?
    @State private var step = 0
    /// Detail-page intro: types a wrong code, then the right one.
    @State private var introTask: Task<Void, Never>?
    /// True while the intro script types, so its keystrokes stay silent.
    @State private var scripted = false

    private static let code = "2580"
    private static let wrongCode = "1379"
    /// Preview script: a wrong attempt, a pause, then the right code (nil = wait a beat).
    private static let script: [String?] = ["1", "3", "7", "9", nil, nil, nil, "2", "5", "8", "0", nil, nil, nil, nil]
    private static let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "del"]
    private static let letters = ["", "ABC", "DEF", "GHI", "JKL", "MNO", "PQRS", "TUV", "WXYZ", "", "", ""]

    private let keySize: CGFloat = 54

    private var silent: Bool { ctx.isPreview || scripted }

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
        // Breathing room above the lock header so it never kisses the stage edge.
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 0.32, delay: 0.5) {
            if ctx.isPreview { previewTick() } else { playIntro() }
        }
        .onDisappear { stopIntro() }
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
        HStack(spacing: 18) {
            ForEach(0..<4, id: \.self) { index in
                dot(index)
            }
        }
    }

    private func dot(_ index: Int) -> some View {
        let filled = index < entered.count
        let fall: CGFloat = dropping ? ctx.cg("fall") : 0
        let tip: Double = dropping ? Double(index % 2 == 0 ? -40 : 34) : 0
        let delay = Double(index) * 0.05
        return ZStack {
            Circle()
                .strokeBorder(dotColor.opacity(0.8), lineWidth: 1.5)
            Circle()
                .fill(dotColor)
                .scaleEffect(filled ? 1 : 0.85)
                .opacity(filled ? 1 : 0)
                .animation(.spring(response: 0.3, dampingFraction: ctx["damping"]), value: filled)
                .rotationEffect(.degrees(tip), anchor: .bottom)
                .offset(y: fall)
                .opacity(dropping ? 0 : 1)
                .animation(.easeIn(duration: 0.42).delay(delay), value: dropping)
        }
        .frame(width: 13, height: 13)
    }

    private var keypad: some View {
        let columns = Array(repeating: GridItem(.fixed(keySize), spacing: 18), count: 3)
        return LazyVGrid(columns: columns, spacing: 12) {
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
            Button {
                stopIntro()
                deleteLast()
            } label: {
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
                stopIntro()
                press(label)
            } label: {
                keyLabel(index, label)
            }
            .buttonStyle(InputKeyStyle(forced: flashed == label, fade: ctx["fade"]))
        }
    }

    private func keyLabel(_ index: Int, _ label: String) -> some View {
        VStack(spacing: 0) {
            Text(verbatim: label)
                .font(.system(size: 26, weight: .regular, design: .rounded))
            if !Self.letters[index].isEmpty {
                Text(verbatim: Self.letters[index])
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(.primary)
        .frame(width: keySize, height: keySize)
    }

    private func press(_ digit: String) {
        guard !busy, entered.count < 4 else { return }
        if !silent { Haptics.tap() }
        entered.append(digit)
        if entered.count == 4 { evaluate() }
    }

    private func deleteLast() {
        guard !busy, !entered.isEmpty else { return }
        if !silent { Haptics.selection() }
        entered.removeLast()
    }

    private func evaluate() {
        busy = true
        let correct = entered == Self.code
        let quiet = silent
        Task {
            try? await Task.sleep(for: .seconds(0.18))
            if correct {
                if !quiet { Haptics.success() }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { status = .success }
                try? await Task.sleep(for: .seconds(1.3))
            } else {
                if !quiet { Haptics.error() }
                withAnimation(.easeOut(duration: 0.15)) { status = .error }
                dropping = true
                try? await Task.sleep(for: .seconds(0.75))
            }
            var settle = Transaction()
            settle.disablesAnimations = true
            withTransaction(settle) {
                dropping = false
                entered = ""
            }
            withAnimation(.smooth(duration: 0.3)) { status = .idle }
            busy = false
        }
    }

    /// One full sequence on detail arrival: a wrong code (dots fall), then the right one (unlock).
    private func playIntro() {
        introTask?.cancel()
        scripted = true
        introTask = Task {
            await typeScripted(Self.wrongCode)
            try? await Task.sleep(for: .seconds(1.2))
            await typeScripted(Self.code)
            try? await Task.sleep(for: .seconds(1.8))
            guard !Task.isCancelled else { return }
            scripted = false
            introTask = nil
        }
    }

    private func typeScripted(_ text: String) async {
        for character in text {
            try? await Task.sleep(for: .seconds(0.3))
            guard !Task.isCancelled, !busy else { return }
            flash(String(character))
        }
    }

    /// The first real touch takes over from the intro and clears its partial input.
    private func stopIntro() {
        guard let task = introTask else { return }
        task.cancel()
        introTask = nil
        scripted = false
        flashed = nil
        if !busy { entered = "" }
    }

    private func flash(_ digit: String) {
        flashed = digit
        press(digit)
        Task {
            try? await Task.sleep(for: .seconds(0.14))
            if flashed == digit { flashed = nil }
        }
    }

    private func previewTick() {
        let item = Self.script[step % Self.script.count]
        step += 1
        guard let digit = item else { return }
        flash(digit)
    }
}

/// Backlit-glass key: fill jumps up instantly on touch and fades out slowly on release.
private struct InputKeyStyle: ButtonStyle {
    let forced: Bool
    let fade: Double

    func makeBody(configuration: Configuration) -> some View {
        let lit = configuration.isPressed || forced
        return configuration.label
            .background {
                Circle().fill(Color.primary.opacity(lit ? 0.26 : 0.07))
            }
            .animation(lit ? nil : Animation.easeOut(duration: fade), value: lit)
    }
}
