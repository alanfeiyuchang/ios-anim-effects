import SwiftUI

extension Effect {
    static let textSlotReel = Effect(
        id: "text.slot-reel",
        category: .text,
        interaction: .tap,
        name: L("Slot-Machine Digits", "老虎机数字"),
        summary: L("Four reels whip downward with speed blur and stop one by one with a kickback.", "四个滚轮带着速度模糊向下飞转，逐个停下并轻轻回弹。"),
        prompt: L(
            "Four ivory digit reels sit in a dark cabinet behind a thin amber payline, each window showing the current digit plus slivers of its neighbours on a curved, shaded drum. Tapping Spin sends every reel rolling downward through at least two full cycles: while fast the digits blur (up to 5 pt) and stretch 12% vertically, and they sharpen as the reel slows. The reels stop left to right, each 0.22 s after the previous one, on a spring with ~20% bounce, so every digit overshoots the payline by about half a digit and kicks back into place. A rigid haptic tick marks each stop. It feels like a real one-armed bandit: suspense, then four decisive clunks.",
            "深色机箱里并排四个象牙白数字滚轮，中间横着一条细细的琥珀色中奖线；每个窗口显示当前数字，并在带明暗的弧面上露出上下相邻数字的一角。点击「转一下」，所有滚轮向下飞转至少两整圈：高速时数字模糊（最高5 pt）并纵向拉伸12%，减速时逐渐清晰。滚轮从左到右依次停下，每个比前一个晚0.22秒，停止使用约20%回弹的弹簧——数字先冲过中奖线约半格再回落到位，每次停轮伴随一次清脆的触感。像真正的老虎机：先吊足胃口，再「咔、咔、咔、咔」四声落定。"
        ),
        implementation: L(
            "Each reel is an Animatable view whose animatableData is an unbounded step count; it draws four digits around the window and derives blur and stretch from the distance still to travel, driven by .spring(duration:bounce:) delayed per column.",
            "每个滚轮是一个 Animatable 视图，animatableData 为无上限的累计步数；它只绘制窗口附近的四个数字，并根据剩余滚动距离推算模糊与拉伸，动画使用按列延迟的 .spring(duration:bounce:)。"
        ),
        apis: ["Animatable", "spring(duration:bounce:)", "blur(radius:)", "clipped()", "animation(_:value:)"],
        tags: ["slot machine", "reel", "jackpot", "counter", "老虎机", "滚轮", "抽奖", "数字滚动"],
        params: [
            .slider("duration", L("Spin duration", "旋转时长"), 0.6...2.0, default: 1.1, unit: "s"),
            .slider("stagger", L("Reel stagger", "停轮间隔"), 0.05...0.4, default: 0.22, unit: "s"),
            .slider("bounce", L("Stop kickback", "停止回弹"), 0...0.4, default: 0.2),
        ]
    ) { ctx in
        SlotReelDemo(ctx: ctx)
    }
}

private struct SlotReelDemo: View {
    let ctx: DemoContext
    /// Unbounded step counts; a reel's visible digit is `roll % 10`.
    @State private var rolls: [Int] = [3, 1, 4, 7]

    private let cell: CGFloat = 60

    var body: some View {
        VStack(spacing: 18) {
            Text(L("Lucky number", "今日幸运号"), ctx.language)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            cabinet
            spinButton
            DemoHint(text: L("Tap Spin", "点击「转一下」"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.8) { spin() }
    }

    private var cabinet: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { column in
                SlotReelColumn(roll: Double(rolls[column]), target: Double(rolls[column]), cell: cell)
                    .animation(reelAnimation(column), value: rolls[column])
            }
        }
        .padding(12)
        .overlay(payline)
        .background(Color(white: 0.08), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Palette.amber.opacity(0.35), lineWidth: 1.5))
        .shadow(color: .black.opacity(0.28), radius: 18, y: 10)
    }

    private var payline: some View {
        HStack(spacing: 0) {
            Image(systemName: "arrowtriangle.right.fill")
            Rectangle().frame(height: 2).opacity(0.7)
            Image(systemName: "arrowtriangle.left.fill")
        }
        .font(.system(size: 9))
        .foregroundStyle(Palette.amber)
        .padding(.horizontal, 2)
        .allowsHitTesting(false)
    }

    private var spinButton: some View {
        Button { spin() } label: {
            Label {
                Text(L("Spin", "转一下"), ctx.language)
            } icon: {
                Image(systemName: "arrow.triangle.2.circlepath")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 26)
            .frame(height: 46)
            .background(Palette.sunset, in: Capsule())
            .shadow(color: Palette.coral.opacity(0.35), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
    }

    private func reelAnimation(_ column: Int) -> Animation {
        let duration: Double = ctx["duration"] + Double(column) * ctx["stagger"]
        return .spring(duration: duration, bounce: ctx["bounce"])
    }

    private func spin() {
        var next = rolls
        for column in next.indices {
            let current = next[column]
            let digit = Int.random(in: 0...9)
            let delta = (digit - current % 10 + 10) % 10
            next[column] = current + 20 + column * 6 + delta
        }
        rolls = next
        guard !ctx.isPreview, !Haptics.isMuted else { return }
        Haptics.tap(.medium)
        for column in 0..<4 {
            let stop: Double = ctx["duration"] * 0.6 + Double(column) * ctx["stagger"]
            DispatchQueue.main.asyncAfter(deadline: .now() + stop) {
                Haptics.tap(.rigid)
            }
        }
    }
}

/// One reel. `roll` animates; `target` is the settled value, so `target - roll`
/// says how far the reel still has to travel and drives the speed blur.
private struct SlotReelColumn: View, Animatable {
    var roll: Double
    let target: Double
    let cell: CGFloat

    var animatableData: Double {
        get { roll }
        set { roll = newValue }
    }

    var body: some View {
        let base: Double = roll.rounded(.down)
        let fraction = CGFloat(roll - base)
        let digit: Int = ((Int(base) % 10) + 10) % 10
        let remaining: Double = min(abs(target - roll), 10)
        let speed = CGFloat(remaining / 10)
        // Top to bottom: digit+2, digit+1, digit, digit-1. Rolling forward moves the strip down.
        VStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { index in
                face((digit + 2 - index + 10) % 10)
            }
        }
        .blur(radius: speed * 5)
        .scaleEffect(x: 1, y: 1 + speed * 0.12)
        .offset(y: -cell * 0.5 + fraction * cell)
        .frame(width: 56, height: cell * 1.5)
        .clipped()
        .background(reelFill)
        .overlay(shading)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func face(_ n: Int) -> some View {
        Text(verbatim: "\(n)")
            .font(.system(size: 40, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(Color(white: 0.12))
            .frame(width: 56, height: cell)
    }

    private var reelFill: some View {
        LinearGradient(colors: [Color(hex: 0xFFF8EC), Color(hex: 0xF1E6D2)], startPoint: .top, endPoint: .bottom)
    }

    private var shading: some View {
        LinearGradient(
            stops: [
                .init(color: .black.opacity(0.75), location: 0),
                .init(color: .clear, location: 0.32),
                .init(color: .clear, location: 0.68),
                .init(color: .black.opacity(0.75), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }
}
