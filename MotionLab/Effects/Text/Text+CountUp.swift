import SwiftUI

extension Effect {
    static let textCountUp = Effect(
        id: "text.count-up",
        category: .text,
        interaction: .tap,
        name: L("Count-Up Tally", "累加计数"),
        summary: L("The number ticks through every value on an expo-out curve, then pops.", "数字按指数缓出曲线逐个累加，落定时轻轻一弹。"),
        prompt: L(
            "A revenue card shows a large rounded amount (e.g. $12,480) with a thin mint progress line beneath and a small delta chip. When new income arrives, the figure counts up through every intermediate integer rather than swapping digits: over 1.4 s on an exponential ease-out (cubic-bezier 0.16, 1, 0.3, 1), so it races at first and crawls into the final value. The progress line grows in lockstep with the count, the chip rolls to the new delta (e.g. +$2,140), and at the end the whole number pops to 108% and settles back on a bouncy spring. A success haptic confirms the landing. It feels like money arriving — fast, then satisfyingly final.",
            "收入卡片上显示一个大号圆体金额（如¥12,480），下方是一条细细的薄荷绿进度线和一个增量小标签。有新收入到账时，金额不是直接换数字，而是逐个经过所有中间整数累加：历时1.4秒、采用指数缓出（cubic-bezier 0.16, 1, 0.3, 1），开头飞快、结尾缓缓爬到终值。进度线与计数同步增长，小标签滚动到新的增量（如+¥2,140）；计数结束时整个数字弹到108%，再用有弹性的弹簧落回原大小，并伴随一次成功触感。就像钱真的到账了，先快后稳。"
        ),
        implementation: L(
            "An Animatable label interpolates a Double between the old and new totals and formats it every frame; the same value derives the progress line. A keyframeAnimator keyed to the run count holds scale 1 for the duration, then springs to 1.08 and back.",
            "Animatable 标签在新旧总额之间插值一个 Double，并在每一帧格式化显示；进度线也由同一个值推算。keyframeAnimator 以累加次数为触发器，在计数期间保持缩放 1，结束时弹到 1.08 再回落。"
        ),
        apis: ["Animatable", "timingCurve(_:_:_:_:duration:)", "keyframeAnimator", "SpringKeyframe", "contentTransition(.numericText)"],
        tags: ["count up", "counter", "revenue", "tally", "数字累加", "计数", "收入", "滚动数字"],
        params: [
            .slider("duration", L("Count duration", "计数时长"), 0.4...3.0, default: 1.4, unit: "s"),
            .choice("curve", L("Curve", "曲线"), [L("Expo out", "指数缓出"), L("Ease in-out", "缓入缓出"), L("Spring", "弹簧")], default: 0),
            .toggle("pop", L("Pop on finish", "结束弹跳"), default: true),
        ]
    ) { ctx in
        CountUpDemo(ctx: ctx)
    }
}

private struct CountUpDemo: View {
    let ctx: DemoContext
    @State private var from: Double = 10_340
    @State private var to: Double = 12_480
    @State private var shown: Double = 12_480
    @State private var runs = 0

    private var currency: String { ctx.language == .zh ? "¥" : "$" }
    private var delta: Int { Int(to - from) }

    var body: some View {
        VStack(spacing: 16) {
            card
            DemoHint(text: L("Tap the card", "点击卡片"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: max(ctx["duration"] + 1.0, 2.0)) { receive() }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L("Revenue this month", "本月收入"), ctx.language)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                deltaChip
            }
            countLabel
        }
        .padding(20)
        .frame(width: 290)
        .demoCard()
        .contentShape(Rectangle())
        .onTapGesture { receive() }
    }

    /// Holds scale 1 while counting, then pops to 1.08 and springs back.
    private var countLabel: some View {
        let hold: Double = ctx["duration"]
        let peak: CGFloat = ctx.bool("pop") ? 1.08 : 1
        return CountUpLabel(value: shown, from: from, to: to, currency: currency)
            .keyframeAnimator(initialValue: CGFloat(1), trigger: runs) { content, scale in
                content.scaleEffect(scale, anchor: .leading)
            } keyframes: { _ in
                KeyframeTrack(\.self) {
                    LinearKeyframe(CGFloat(1), duration: hold)
                    SpringKeyframe(peak, duration: 0.12, spring: .snappy)
                    SpringKeyframe(CGFloat(1), duration: 0.5, spring: .bouncy)
                }
            }
    }

    private var deltaChip: some View {
        HStack(spacing: 3) {
            Image(systemName: "arrow.up.right")
                .font(.caption2.weight(.heavy))
            Text(verbatim: "+" + currency + groupedNumber(delta))
                .font(.caption.weight(.bold))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(delta)))
        }
        .foregroundStyle(Palette.green)
        .padding(.horizontal, 8)
        .frame(height: 24)
        .background(Palette.green.opacity(0.14), in: Capsule())
    }

    private var countAnimation: Animation {
        let duration: Double = ctx["duration"]
        switch ctx.int("curve") {
        case 1: return .easeInOut(duration: duration)
        case 2: return .spring(duration: duration, bounce: 0.2)
        default: return .timingCurve(0.16, 1, 0.3, 1, duration: duration)
        }
    }

    private func receive() {
        let start = to
        let end = start + Double(Int.random(in: 8...42) * 50 + Int.random(in: 0...9) * 10)
        withAnimation(.snappy) {
            from = start
            to = end > 90_000 ? 12_480 : end
            if to < from { from = to - 2_140 }
        }
        runs += 1
        withAnimation(countAnimation) {
            shown = to
        }
        guard !ctx.isPreview, !Haptics.isMuted else { return }
        Haptics.tap(.light)
        DispatchQueue.main.asyncAfter(deadline: .now() + ctx["duration"]) {
            Haptics.success()
        }
    }
}

/// "12480" → "12,480".
private func groupedNumber(_ value: Int) -> String {
    let digits = String(abs(value))
    var result = ""
    for (index, ch) in digits.enumerated() {
        let fromEnd = digits.count - index
        if index > 0 && fromEnd % 3 == 0 { result.append(",") }
        result.append(ch)
    }
    return value < 0 ? "-" + result : result
}

/// Formats the animated value every frame; the progress line derives from the same value.
private struct CountUpLabel: View, Animatable {
    var value: Double
    let from: Double
    let to: Double
    let currency: String

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    private var progress: CGFloat {
        let span = to - from
        guard span > 0 else { return 1 }
        let raw = (value - from) / span
        return CGFloat(raw.clamped(to: 0...1))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(verbatim: currency)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(verbatim: groupedNumber(Int(value.rounded())))
                    .font(.system(size: 50, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            }
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.08))
                Capsule()
                    .fill(LinearGradient(colors: [Palette.mint, Palette.green], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 250 * progress)
            }
            .frame(width: 250, height: 5)
        }
    }
}
