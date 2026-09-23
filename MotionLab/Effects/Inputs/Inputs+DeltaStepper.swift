import SwiftUI

extension Effect {
    static let inputsDeltaStepper = Effect(
        id: "inputs.delta-stepper",
        category: .inputs,
        interaction: .tap,
        name: L("Floating Delta Stepper", "飘字增量步进器"),
        summary: L("Each tap squashes the number and floats a +1 chip; rapid taps merge into +3, +4…", "每次点击都会压扁数字并飘出 +1 气泡，连续快点会合并成 +3、+4……"),
        prompt: L(
            "A tip-jar card with a big rounded count between − and + buttons. Every tap squashes the number to 112% × 90% and springs it back (bouncy, ~350 ms) while a small capsule chip labelled +1 or −1 rises 44 pt from the number and fades out over 900 ms on an ease-out. Taps within a 500 ms window combine: the previous chip is replaced by a larger one showing the running total (+2, +3…) that pops in from 60% scale, so bursts of tapping read as a single growing gesture. Increments float up in mint, decrements drift down in coral, and the price total rolls with numeric digits. A light haptic accompanies each tap. Rewarding, game-like feedback that makes counting feel generous.",
            "一张打赏罐卡片：− 与 + 按钮之间是大号圆体计数。每次点击，数字先被压成 112% × 90% 再弹性回弹（约 350 毫秒），同时从数字处升起一枚写着 +1 或 −1 的小胶囊，在 900 毫秒内以缓出上浮 44pt 并淡出。500 毫秒内的连续点击会合并：旧气泡被一个更大的新气泡取代，显示累计值（+2、+3……），从 60% 缩放弹出，让一连串点击读起来像一个不断累积的动作。增加时气泡为薄荷绿并向上飘，减少时为珊瑚红并向下沉，金额以数字滚动更新。每次点击伴随一次轻触觉。像游戏一样的奖励感反馈，让计数显得慷慨。"
        ),
        implementation: L(
            "Chips are Identifiable values in an array; each one animates its own rise and fade in onAppear and is removed by a Task, while a combine window replaces the newest chip with a new id. A keyframeAnimator keyed on a tap counter squashes the number.",
            "气泡是数组中的 Identifiable 值，每个在 onAppear 中自行上浮淡出，并由 Task 移除；合并窗口内以新 id 替换最新的气泡。以点击计数为触发的 keyframeAnimator 负责压扁数字。"
        ),
        apis: ["keyframeAnimator", "onAppear + withAnimation", "transition(.scale)", "contentTransition(.numericText)", "Identifiable"],
        tags: ["stepper", "counter", "floating", "+1", "步进器", "计数", "飘字", "增量"],
        params: [
            .slider("window", L("Combine window", "合并窗口"), 0...1, default: 0.5, unit: "s"),
            .slider("rise", L("Rise distance", "上浮距离"), 16...80, default: 44, decimals: 0, unit: "pt"),
            .slider("squash", L("Squash", "压扁幅度"), 0...0.25, default: 0.12),
        ]
    ) { ctx in
        DeltaStepperDemo(ctx: ctx)
    }
}

private struct DeltaChip: Identifiable, Equatable {
    let id: Int
    let total: Int
}

private struct DeltaStepperDemo: View {
    let ctx: DemoContext
    @State private var count = 3
    @State private var chips: [DeltaChip] = []
    @State private var lastTap: Date = .distantPast
    @State private var runningTotal = 0
    @State private var nextID = 0
    @State private var taps = 0
    @State private var step = 0

    private static let script: [Int] = [1, 1, 1, 0, 0, 1, 0, 0, -1, -1, 0, 0]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            card
            Spacer()
            DemoHint(text: L("Tap + quickly several times", "快速连点 + 几次"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 0.28, delay: 0.4) { previewTick() }
    }

    private var card: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "cup.and.saucer.fill")
                    .foregroundStyle(Palette.amber)
                Text(L("Buy the team coffee", "请团队喝咖啡"), ctx.language)
                    .foregroundStyle(.primary)
            }
            .font(.headline)
            HStack(spacing: 22) {
                tapButton("minus", delta: -1)
                number
                tapButton("plus", delta: 1)
            }
            Text(ctx.language == .zh ? "¥\(count * 25)" : "$\(count * 4)")
                .font(.system(.title3, design: .rounded).weight(.bold).monospacedDigit())
                .foregroundStyle(.secondary)
                .contentTransition(.numericText(value: Double(count)))
                .animation(.snappy, value: count)
        }
        .padding(20)
        .frame(width: 300)
        .demoCard(cornerRadius: 26)
    }

    private var number: some View {
        let squash: CGFloat = ctx.cg("squash")
        return ZStack {
            Text("\(count)")
                .font(.system(size: 52, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.primary)
                .contentTransition(.numericText(value: Double(count)))
                .keyframeAnimator(initialValue: CGSize(width: 1, height: 1), trigger: taps) { content, scale in
                    content.scaleEffect(x: scale.width, y: scale.height, anchor: .bottom)
                } keyframes: { _ in
                    KeyframeTrack(\.width) {
                        CubicKeyframe(1 + squash, duration: 0.07)
                        SpringKeyframe(1, duration: 0.3, spring: .bouncy)
                    }
                    KeyframeTrack(\.height) {
                        CubicKeyframe(1 - squash * 0.8, duration: 0.07)
                        SpringKeyframe(1, duration: 0.3, spring: .bouncy)
                    }
                }
            ForEach(chips) { chip in
                FloatingDeltaChip(total: chip.total, rise: ctx.cg("rise"))
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
        }
        .frame(width: 96, height: 70)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: chips)
    }

    private func tapButton(_ symbol: String, delta: Int) -> some View {
        Button {
            tap(delta)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(delta > 0 ? Color.white : Palette.indigo)
                .frame(width: 52, height: 52)
                .background {
                    Circle().fill(delta > 0 ? AnyShapeStyle(Palette.primary) : AnyShapeStyle(Palette.indigo.opacity(0.12)))
                }
        }
        .buttonStyle(DeltaPressStyle())
    }

    private func tap(_ delta: Int) {
        let target = max(count + delta, 0)
        guard target != count else { return }
        if !ctx.isPreview { Haptics.tap() }
        withAnimation(.snappy(duration: 0.25)) { count = target }
        taps += 1
        let now = Date.now
        let sameDirection = (runningTotal > 0) == (delta > 0) && runningTotal != 0
        if now.timeIntervalSince(lastTap) <= ctx["window"] && sameDirection {
            runningTotal += delta
        } else {
            runningTotal = delta
        }
        lastTap = now
        let chip = DeltaChip(id: nextID, total: runningTotal)
        nextID += 1
        chips = [chip]
        Task {
            try? await Task.sleep(for: .seconds(0.95))
            chips.removeAll { $0.id == chip.id }
        }
    }

    private func previewTick() {
        let action = Self.script[step % Self.script.count]
        step += 1
        if action != 0 { tap(action) }
    }
}

/// Rises (or sinks, for negative totals) and fades on its own once inserted.
private struct FloatingDeltaChip: View {
    let total: Int
    let rise: CGFloat
    @State private var launched = false

    var body: some View {
        let up = total > 0
        Text(verbatim: (up ? "+" : "−") + "\(abs(total))")
            .font(.system(size: abs(total) > 1 ? 17 : 14, weight: .heavy, design: .rounded).monospacedDigit())
            .foregroundStyle(.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(up ? Palette.mint : Palette.coral, in: Capsule())
            .shadow(color: (up ? Palette.mint : Palette.coral).opacity(0.4), radius: 6, y: 3)
            .offset(x: 30, y: launched ? (up ? -rise - 20 : rise + 10) : (up ? -20 : 10))
            .opacity(launched ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 0.9)) { launched = true }
            }
            .allowsHitTesting(false)
    }
}

private struct DeltaPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.55), value: configuration.isPressed)
    }
}
