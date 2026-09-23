import SwiftUI

extension Effect {
    static let textSevenSegment = Effect(
        id: "text.seven-segment",
        category: .text,
        interaction: .loop,
        name: L("LED Segment Timer", "LED 数码管计时"),
        summary: L("Segments ignite in a scan order and fade out with a phosphor afterglow.", "数码管笔画按扫描顺序点亮，熄灭时留下荧光余辉。"),
        prompt: L(
            "A kitchen-timer display counts down from 10:00 in slanted seven-segment digits on a near-black panel, each built from seven rounded bars, with unlit bars faintly visible at 7% so the grid reads as hardware. When a digit changes, bars that switch on ignite fast (80 ms ease-out, scanning a→g with 25 ms between bars) and gain a 6 pt coloured glow, while bars that switch off fade over 350 ms like cooling phosphor, so the old numeral briefly ghosts under the new one. The colon blinks at 1 Hz, and tapping resets the timer with a light haptic. Retro, precise and warm.",
            "近乎纯黑的面板上，厨房计时器以倾斜的七段数码管从 10:00 开始倒数；每个数字由七根圆角笔画组成，未点亮的笔画保留 7% 的微光，看起来就像真实硬件。数字变化时，要点亮的笔画迅速亮起（80 毫秒缓出，按 a→g 顺序扫描，间隔 25 毫秒），并带上 6 pt 彩色辉光；要熄灭的笔画则像冷却的荧光粉，在 350 毫秒内慢慢暗下，旧数字会在新数字下短暂残留。冒号每秒闪一次，点击即重置计时并伴随轻触感。复古、精准又有温度。"
        ),
        implementation: L(
            "Each digit maps to a 7-bit mask; every segment is a Capsule whose opacity and glow animate with .animation(_:value:) — a delayed ease-out when turning on, a long ease-out when turning off. A TimelineView derives the countdown from elapsed time × speed.",
            "每个数字对应一个 7 位掩码；每根笔画是一个 Capsule，其透明度与辉光通过 .animation(_:value:) 动画——点亮时用带延迟的缓出，熄灭时用较长的缓出。TimelineView 根据经过时间 × 速度推算倒计时。"
        ),
        apis: ["TimelineView", "Capsule", "animation(_:value:)", "shadow(color:radius:)", "transformEffect"],
        tags: ["seven segment", "LED", "timer", "digital", "数码管", "计时器", "倒计时", "复古"],
        params: [
            .slider("speed", L("Time scale", "时间倍速"), 1...20, default: 6, step: 1, decimals: 0, unit: "×"),
            .slider("decay", L("Afterglow", "余辉时长"), 0.05...1.0, default: 0.35, unit: "s"),
            .choice("tint", L("Phosphor", "荧光色"), [L("Amber", "琥珀"), L("Mint", "薄荷"), L("Red", "红色")], default: 0),
        ]
    ) { ctx in
        SevenSegmentDemo(ctx: ctx)
    }
}

/// Segment order a, b, c, d, e, f, g (top, top-right, bottom-right, bottom, bottom-left, top-left, middle).
private let segmentMasks: [[Bool]] = [
    [true, true, true, true, true, true, false],      // 0
    [false, true, true, false, false, false, false],  // 1
    [true, true, false, true, true, false, true],     // 2
    [true, true, true, true, false, false, true],     // 3
    [false, true, true, false, false, true, true],    // 4
    [true, false, true, true, false, true, true],     // 5
    [true, false, true, true, true, true, true],      // 6
    [true, true, true, false, false, false, false],   // 7
    [true, true, true, true, true, true, true],       // 8
    [true, true, true, true, false, true, true],      // 9
]

private struct SevenSegmentDemo: View {
    let ctx: DemoContext
    @State private var start = Date()

    private var tint: Color {
        switch ctx.int("tint") {
        case 1: return Palette.mint
        case 2: return Palette.red
        default: return Palette.amber
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let real: Double = timeline.date.timeIntervalSince(start)
                let elapsed: Double = real * ctx["speed"]
                panel(elapsed: elapsed, real: real)
            }
            DemoHint(text: L("Tap to reset", "点击重置"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.tap(.light)
            start = Date()
        }
    }

    /// `elapsed` is scaled by the time-scale slider; `real` is wall-clock time, so the colon always blinks at 1 Hz.
    private func panel(elapsed: Double, real: Double) -> some View {
        let total = 600
        let remaining: Int = total - Int(elapsed) % (total + 1)
        let minutes = remaining / 60
        let seconds = remaining % 60
        let digits: [Int] = [minutes / 10, minutes % 10, seconds / 10, seconds % 10]
        let colonOn: Bool = real.truncatingRemainder(dividingBy: 1) < 0.5
        return VStack(spacing: 12) {
            HStack(spacing: 10) {
                SegmentDigit(digit: digits[0], tint: tint, decay: ctx["decay"])
                SegmentDigit(digit: digits[1], tint: tint, decay: ctx["decay"])
                colon(on: colonOn)
                SegmentDigit(digit: digits[2], tint: tint, decay: ctx["decay"])
                SegmentDigit(digit: digits[3], tint: tint, decay: ctx["decay"])
            }
            .transformEffect(CGAffineTransform(a: 1, b: 0, c: -0.08, d: 1, tx: 7, ty: 0))
            HStack(spacing: 6) {
                Image(systemName: "timer")
                Text(L("Pasta · al dente", "意面 · 弹牙口感"), ctx.language)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint.opacity(0.7))
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .background(Color(white: 0.05), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(.white.opacity(0.08)))
        .shadow(color: .black.opacity(0.3), radius: 18, y: 10)
    }

    private func colon(on: Bool) -> some View {
        VStack(spacing: 22) {
            Circle().frame(width: 8, height: 8)
            Circle().frame(width: 8, height: 8)
        }
        .foregroundStyle(tint)
        .opacity(on ? 1 : 0.12)
        .shadow(color: tint.opacity(on ? 0.8 : 0), radius: 5)
        .animation(.easeOut(duration: 0.15), value: on)
    }
}

private struct SegmentDigit: View {
    let digit: Int
    let tint: Color
    let decay: Double

    private let width: CGFloat = 44
    private let height: CGFloat = 82
    private let thickness: CGFloat = 8

    var body: some View {
        let mask = segmentMasks[min(max(digit, 0), 9)]
        ZStack {
            ForEach(0..<7, id: \.self) { index in
                segment(index, on: mask[index])
            }
        }
        .frame(width: width, height: height)
    }

    private func segment(_ index: Int, on: Bool) -> some View {
        let frame = segmentFrame(index)
        return Capsule()
            .fill(tint)
            .frame(width: frame.width, height: frame.height)
            .opacity(on ? 1 : 0.07)
            .shadow(color: tint.opacity(on ? 0.85 : 0), radius: 6)
            .animation(animation(index, on: on), value: on)
            .position(x: frame.midX, y: frame.midY)
    }

    private func animation(_ index: Int, on: Bool) -> Animation {
        if on {
            return .easeOut(duration: 0.08).delay(Double(index) * 0.025)
        }
        return .easeOut(duration: decay)
    }

    private func segmentFrame(_ index: Int) -> CGRect {
        let t = thickness
        let gap: CGFloat = 2
        let horizontalLength: CGFloat = width - t - gap * 2
        let verticalLength: CGFloat = height / 2 - t / 2 - gap * 2
        let left: CGFloat = t / 2
        let right: CGFloat = width - t / 2
        let top: CGFloat = t / 2
        let middle: CGFloat = height / 2
        let bottom: CGFloat = height - t / 2
        let upper: CGFloat = height / 4 + t / 8
        let lower: CGFloat = height * 3 / 4 - t / 8
        switch index {
        case 0: return rect(x: width / 2, y: top, w: horizontalLength, h: t)
        case 1: return rect(x: right, y: upper, w: t, h: verticalLength)
        case 2: return rect(x: right, y: lower, w: t, h: verticalLength)
        case 3: return rect(x: width / 2, y: bottom, w: horizontalLength, h: t)
        case 4: return rect(x: left, y: lower, w: t, h: verticalLength)
        case 5: return rect(x: left, y: upper, w: t, h: verticalLength)
        default: return rect(x: width / 2, y: middle, w: horizontalLength, h: t)
        }
    }

    private func rect(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) -> CGRect {
        CGRect(x: x - w / 2, y: y - h / 2, width: w, height: h)
    }
}
