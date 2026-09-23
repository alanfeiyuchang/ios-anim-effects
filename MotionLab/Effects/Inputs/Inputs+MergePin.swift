import SwiftUI

extension Effect {
    static let inputsMergePin = Effect(
        id: "inputs.merge-pin",
        category: .inputs,
        interaction: .tap,
        name: L("Merging PIN Dots", "融合式 PIN 圆点"),
        summary: L("Four PIN dots fill, then slide together and fuse into a single success check.", "四个 PIN 圆点依次填满，随后滑向中心融合成一个成功对勾。"),
        prompt: L(
            "A compact unlock screen: four 16 pt PIN dots above a 3 × 4 keypad of rounded keys. Each key press dims the key to 88% and fills the next dot with an indigo core that springs from 30% to full size (response 0.28 s, damping 0.55). When the fourth digit lands and the PIN is right, the dots hold for 150 ms, then glide to the centre on a spring (response 0.45 s, damping 0.75) and fuse, and the single merged dot swells into a 44 pt green disc as a checkmark draws itself on — with a success haptic. A wrong PIN instead shakes the row ±10 pt with decaying amplitude, turns the dots red and empties them right-to-left with a 60 ms stagger. Satisfying closure: four separate taps become one confirmed whole.",
            "精简解锁界面：四个 16pt PIN 圆点，下方 3 × 4 圆角数字键盘。每次按键，按键缩到 88% 并变暗，下一个圆点的靛蓝内核以弹簧（响应 0.28 秒、阻尼 0.55）从 30% 放大填满。第四位输入正确时，圆点停留 150 毫秒，再以弹簧（响应 0.45 秒、阻尼 0.75）滑向中心融为一体，膨胀成 44pt 绿色圆盘，对勾随之描出，并触发成功触觉。若错误，圆点以衰减幅度左右抖动 ±10pt、变红，并以 60 毫秒错峰从右到左清空。四次点击合成一个确认。"
        ),
        implementation: L(
            "Dot x-offsets are derived from a merged flag so one spring collapses them to the centre; a Circle().trim checkmark and a scaled disc appear after a Task delay. Errors use a GeometryEffect shake and per-dot delayed animations.",
            "圆点的横向偏移由 merged 状态推导，一个弹簧即可把它们收拢到中心；延迟 Task 之后出现放大的圆盘与 trim 描绘的对勾。错误时使用 GeometryEffect 抖动与逐个延迟的动画。"
        ),
        apis: ["offset", "spring(response:dampingFraction:)", "Shape.trim", "GeometryEffect", "ButtonStyle"],
        tags: ["passcode", "PIN", "unlock", "merge", "密码", "解锁", "融合", "验证"],
        params: [
            .slider("response", L("Merge response", "融合响应"), 0.2...0.9, default: 0.45, unit: "s"),
            .slider("hold", L("Hold before merge", "融合前停顿"), 0...0.6, default: 0.15, unit: "s"),
            .slider("shake", L("Shake travel", "抖动幅度"), 4...20, default: 10, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        MergePinDemo(ctx: ctx)
    }
}

private enum MergePinPhase: Equatable {
    case entering
    case merging
    case done
    case error
}

private struct MergePinDemo: View {
    let ctx: DemoContext
    @State private var entered = ""
    @State private var phase: MergePinPhase = .entering
    @State private var shakes: CGFloat = 0
    @State private var scriptIndex = 0
    @State private var busy = false

    private let code = "2580"
    private let pitch: CGFloat = 30
    private static let script: [String] = ["1", "4", "7", "0", "", "", "", "", "", "2", "5", "8", "0", "", "", "", "", "", ""]

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)
            Text(phase == .done ? L("Unlocked", "已解锁") : L("Enter PIN", "输入密码"), ctx.language)
                .font(.headline)
                .foregroundStyle(.primary)
                .contentTransition(.opacity)
                .animation(.smooth, value: phase)
            dots
                .frame(height: 48)
            keypad
            Spacer(minLength: 0)
            DemoHint(text: L("PIN is 2 5 8 0", "密码为 2 5 8 0"), ctx: ctx)
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 0.3, delay: 0.4) { previewTick() }
    }

    private var dotColor: Color {
        phase == .error ? Palette.red : Palette.indigo
    }

    private var dots: some View {
        let merged = phase == .merging || phase == .done
        return ZStack {
            ForEach(0..<4, id: \.self) { index in
                dot(index: index, merged: merged)
            }
            successDisc
        }
        .modifier(MergePinShake(travel: ctx.cg("shake"), progress: shakes))
    }

    private func dot(index: Int, merged: Bool) -> some View {
        let filled = index < entered.count
        let slot: CGFloat = (CGFloat(index) - 1.5) * pitch
        return ZStack {
            Circle()
                .strokeBorder(dotColor.opacity(0.5), lineWidth: 1.5)
                .opacity(merged ? 0 : 1)
            Circle()
                .fill(dotColor)
                .scaleEffect(filled ? 1 : 0.3)
                .opacity(filled ? 1 : 0)
                .animation(.spring(response: 0.28, dampingFraction: 0.55), value: filled)
        }
        .frame(width: 16, height: 16)
        .offset(x: merged ? 0 : slot)
        .animation(.spring(response: ctx["response"], dampingFraction: 0.75), value: merged)
    }

    private var successDisc: some View {
        let done = phase == .done
        return ZStack {
            Circle().fill(Palette.green)
            MergePinCheck()
                .trim(from: 0, to: done ? 1 : 0)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
                .frame(width: 20, height: 16)
                .animation(.easeOut(duration: 0.3).delay(done ? 0.15 : 0), value: done)
        }
        .frame(width: 44, height: 44)
        .scaleEffect(done ? 1 : 0.36)
        .opacity(done ? 1 : 0)
        .shadow(color: Palette.green.opacity(done ? 0.45 : 0), radius: 12, y: 4)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: done)
    }

    private var keypad: some View {
        let keys: [String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "⌫"]
        let columns = Array(repeating: GridItem(.fixed(64), spacing: 12), count: 3)
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(keys.indices, id: \.self) { index in
                keyButton(keys[index])
            }
        }
        .frame(width: 216)
    }

    @ViewBuilder
    private func keyButton(_ key: String) -> some View {
        if key.isEmpty {
            Color.clear.frame(height: 36)
        } else {
            Button {
                press(key)
            } label: {
                Group {
                    if key == "⌫" {
                        Image(systemName: "delete.left")
                            .font(.system(size: 17, weight: .semibold))
                    } else {
                        Text(key)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                    }
                }
                .foregroundStyle(.primary)
                .frame(width: 64, height: 36)
                .background(Color.primary.opacity(key == "⌫" ? 0 : 0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(MergePinKeyStyle())
            .disabled(busy)
        }
    }

    private func press(_ key: String) {
        if phase == .done {
            reset()
            return
        }
        guard phase == .entering, !busy else { return }
        if key == "⌫" {
            if !entered.isEmpty { entered.removeLast() }
            return
        }
        if !ctx.isPreview { Haptics.tap() }
        entered.append(contentsOf: key)
        if entered.count == 4 { verify() }
    }

    private func verify() {
        busy = true
        let hold = ctx["hold"]
        if entered == code {
            Task {
                try? await Task.sleep(for: .seconds(hold))
                phase = .merging
                try? await Task.sleep(for: .seconds(ctx["response"] * 0.7))
                phase = .done
                busy = false
                if !ctx.isPreview { Haptics.success() }
            }
        } else {
            Task {
                try? await Task.sleep(for: .seconds(0.12))
                withAnimation(.snappy(duration: 0.15)) { phase = .error }
                withAnimation(.linear(duration: 0.45)) { shakes += 1 }
                if !ctx.isPreview { Haptics.error() }
                try? await Task.sleep(for: .seconds(0.5))
                for _ in 0..<4 {
                    if !entered.isEmpty { entered.removeLast() }
                    try? await Task.sleep(for: .seconds(0.06))
                }
                withAnimation(.smooth) { phase = .entering }
                busy = false
            }
        }
    }

    private func reset() {
        entered = ""
        phase = .entering
        busy = false
    }

    private func previewTick() {
        let key = Self.script[scriptIndex % Self.script.count]
        scriptIndex += 1
        if scriptIndex % Self.script.count == 0 {
            reset()
            return
        }
        guard !key.isEmpty else { return }
        press(key)
    }
}

private struct MergePinKeyStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

private struct MergePinCheck: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width * 0.38, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

/// Horizontal shake whose amplitude decays within each whole-number step of `progress`.
private struct MergePinShake: GeometryEffect {
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
