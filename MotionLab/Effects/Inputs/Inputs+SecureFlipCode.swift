import SwiftUI

extension Effect {
    static let inputsSecureFlipCode = Effect(
        id: "inputs.secure-flip-code",
        category: .inputs,
        interaction: .state,
        name: L("Flip-to-Hide PIN", "翻转隐藏密码"),
        summary: L("Each digit flips in face-up, then turns over to a dot; the eye flips them all back.", "每位数字先正面翻入，稍后翻面成圆点；点眼睛可全部翻回。"),
        prompt: L(
            "A card-security PIN of four 54 × 64 pt tiles. Each typed digit arrives face-up by rotating in from 90° around the horizontal axis (ease-out, 220 ms), stays readable for 700 ms, then flips over like a card: the digit face turns to 90° on an ease-in (150 ms) and the back face — a solid indigo dot on a tinted tile — completes the turn on an ease-out (150 ms). An eye button beside the row flips every masked tile back to its digit, left to right with a 60 ms stagger, and flips them away again on the second tap. When all four are entered the tiles lift 6 pt in a wave and glow green. Private, readable in the moment, and physically satisfying.",
            "由四个 54 × 64pt 方块组成的银行卡密码。每输入一位数字，它先以正面绕水平轴从 90° 翻入（缓出，220 毫秒），保持可读 700 毫秒，随后像卡牌一样翻面：数字面在缓入的 150 毫秒内转到 90°，背面——浅色方块上的实心靛蓝圆点——再以缓出的 150 毫秒转完剩下的半圈。行尾的眼睛按钮会把所有已隐藏的方块从左到右以 60 毫秒错峰翻回数字面，再点一次则重新翻过去。四位输满时，方块以波浪依次上浮 6pt 并泛起绿色光晕。私密、当下可读，又有真实的翻牌手感。"
        ),
        implementation: L(
            "Each tile stacks a front and back face with rotation3DEffect around the x-axis; the two halves of the flip use separate animation(_:value:) curves and delays so the faces hand over at 90°. A hidden number-pad TextField owns input and per-digit Tasks mask tiles after the reveal delay.",
            "每个方块叠放正反两面，以绕 x 轴的 rotation3DEffect 翻转；翻转的前后两半使用不同的 animation(_:value:) 曲线与延迟，让两面在 90° 处交接。隐藏的数字键盘 TextField 负责输入，逐位的 Task 在展示延迟后遮住方块。"
        ),
        apis: ["rotation3DEffect(_:axis:)", "AnyTransition.modifier", "animation(_:value:)", "@FocusState", "keyframeAnimator"],
        tags: ["PIN", "secure", "flip", "passcode", "密码", "翻转", "隐藏", "安全"],
        params: [
            .slider("reveal", L("Visible time", "可见时长"), 0.2...1.5, default: 0.7, unit: "s"),
            .slider("flip", L("Half-flip time", "半程翻转时长"), 0.08...0.4, default: 0.15, unit: "s"),
            .slider("stagger", L("Reveal stagger", "翻回错峰"), 0...0.15, default: 0.06, unit: "s"),
        ]
    ) { ctx in
        SecureFlipCodeDemo(ctx: ctx)
    }
}

private struct SecureFlipCodeDemo: View {
    let ctx: DemoContext
    @State private var code = ""
    @State private var masked: Set<Int> = []
    @State private var peeking = false
    /// Only the eye button flips tiles in a staggered run; single tiles mask on their own timer.
    @State private var staggerFlips = false
    @State private var completions = 0
    @State private var scriptIndex = 0
    @FocusState private var focused: Bool

    private let length = 4
    private static let script: [String] = ["7", "", "3", "", "9", "", "1", "", "", "", "👁", "", "", "", "👁", "", "", "⌧", ""]

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Text(L("Card PIN", "银行卡密码"), ctx.language)
                .font(.headline)
                .foregroundStyle(.primary)
            HStack(spacing: 10) {
                ForEach(0..<length, id: \.self) { index in
                    FlipTile(
                        digit: character(at: index),
                        showsBack: masked.contains(index) && !peeking,
                        halfFlip: ctx["flip"],
                        delay: staggerFlips ? Double(index) * ctx["stagger"] : 0,
                        isCurrent: index == code.count && (focused || ctx.isPreview),
                        complete: code.count == length,
                        index: index,
                        completions: completions
                    )
                }
                eyeButton
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if code.count == length { reset() }
                focused = true
            }
            Spacer()
            DemoHint(text: L("Tap the tiles and type", "点击方块开始输入"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { hiddenField }
        .autoplay(ctx.isPreview, every: 0.35, delay: 0.4) { previewTick() }
    }

    private var eyeButton: some View {
        Button {
            if !ctx.isPreview { Haptics.tap() }
            staggerFlips = true
            peeking.toggle()
        } label: {
            Image(systemName: peeking ? "eye.fill" : "eye.slash.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(peeking ? Palette.indigo : Color.secondary)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 40, height: 40)
                .background(Color.primary.opacity(0.06), in: Circle())
        }
        .buttonStyle(.plain)
    }

    private var hiddenField: some View {
        TextField("", text: $code)
            .keyboardType(.numberPad)
            .focused($focused)
            .frame(width: 1, height: 1)
            .opacity(0.01)
            .allowsHitTesting(false)
            .onChange(of: code) { oldValue, newValue in handle(old: oldValue, new: newValue) }
    }

    private func character(at index: Int) -> String? {
        guard index < code.count else { return nil }
        return String(code[code.index(code.startIndex, offsetBy: index)])
    }

    private func handle(old: String, new: String) {
        let digits = String(new.filter(\.isNumber).prefix(length))
        if digits != new {
            code = digits
            return
        }
        if digits.count < old.count {
            masked = masked.filter { $0 < digits.count }
            return
        }
        guard digits.count > old.count else { return }
        let index = digits.count - 1
        if !ctx.isPreview { Haptics.selection() }
        let reveal = ctx["reveal"]
        Task {
            try? await Task.sleep(for: .seconds(reveal))
            guard index < code.count else { return }
            staggerFlips = false
            masked.insert(index)
        }
        if digits.count == length {
            completions += 1
            if !ctx.isPreview { Haptics.success() }
        }
    }

    private func reset() {
        code = ""
        masked = []
        peeking = false
    }

    private func previewTick() {
        let key = Self.script[scriptIndex % Self.script.count]
        scriptIndex += 1
        switch key {
        case "":
            break
        case "👁":
            staggerFlips = true
            peeking.toggle()
        case "⌧":
            reset()
        default:
            if code.count < length { code.append(contentsOf: key) }
        }
    }
}

private struct FlipTile: View {
    let digit: String?
    let showsBack: Bool
    let halfFlip: Double
    let delay: Double
    let isCurrent: Bool
    let complete: Bool
    let index: Int
    let completions: Int

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        let lead: Double = 0.001 + Double(index) * 0.06
        ZStack {
            shape.fill(Palette.elevated)
            if let digit {
                ZStack {
                    front(digit)
                    back
                }
                .transition(
                    .modifier(
                        active: FlipInModifier(angle: 90, opacity: 0),
                        identity: FlipInModifier(angle: 0, opacity: 1)
                    )
                    .animation(.easeOut(duration: 0.22))
                )
            }
        }
        .frame(width: 54, height: 64)
        .overlay(shape.strokeBorder(borderColor, lineWidth: isCurrent || complete ? 2 : 1))
        .shadow(color: complete ? Palette.green.opacity(0.35) : .clear, radius: 10, y: 4)
        .animation(.smooth(duration: 0.25), value: isCurrent)
        .animation(.smooth(duration: 0.3), value: complete)
        .keyframeAnimator(initialValue: 0.0, trigger: completions) { content, lift in
            content.offset(y: lift)
        } keyframes: { _ in
            KeyframeTrack(\.self) {
                LinearKeyframe(0, duration: lead)
                SpringKeyframe(-6, duration: 0.16, spring: .snappy)
                SpringKeyframe(0, duration: 0.45, spring: .bouncy)
            }
        }
    }

    private var borderColor: Color {
        if complete { return Palette.green }
        return isCurrent ? Palette.indigo : Color.primary.opacity(0.14)
    }

    private func front(_ digit: String) -> some View {
        Text(digit)
            .font(.system(size: 28, weight: .semibold, design: .rounded).monospacedDigit())
            .foregroundStyle(.primary)
            .rotation3DEffect(.degrees(showsBack ? 90 : 0), axis: (x: 1, y: 0, z: 0))
            .opacity(showsBack ? 0 : 1)
            .animation(
                showsBack
                    ? .easeIn(duration: halfFlip).delay(delay)
                    : .easeOut(duration: halfFlip).delay(delay + halfFlip),
                value: showsBack
            )
    }

    private var back: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Palette.indigo.opacity(0.1))
            .overlay(Circle().fill(Palette.indigo).frame(width: 14, height: 14))
            .padding(4)
            .rotation3DEffect(.degrees(showsBack ? 0 : -90), axis: (x: 1, y: 0, z: 0))
            .opacity(showsBack ? 1 : 0)
            .animation(
                showsBack
                    ? .easeOut(duration: halfFlip).delay(delay + halfFlip)
                    : .easeIn(duration: halfFlip).delay(delay),
                value: showsBack
            )
    }
}

private struct FlipInModifier: ViewModifier {
    let angle: Double
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(angle), axis: (x: 1, y: 0, z: 0))
            .opacity(opacity)
    }
}
