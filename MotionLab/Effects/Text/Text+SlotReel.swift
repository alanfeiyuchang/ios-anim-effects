import QuartzCore
import SwiftUI

extension Effect {
    static let textSlotReel = Effect(
        id: "text.slot-reel",
        category: .text,
        interaction: .tap,
        name: L("Tumbling Prism Digits", "翻滚棱柱数字"),
        summary: L("Each score digit is a 3D prism that tumbles forward face by face, slows down and rocks into place.", "每位分数都是一根 3D 棱柱，一面接一面向前翻滚，减速后轻轻摇摆着落定。"),
        prompt: L(
            "A five-digit arcade score (04825) sits in a floating card, each digit printed on the face of an indigo-to-violet prism 52×68 pt. Tapping the card adds points: every digit that changes tumbles forward about its horizontal axis, the old face tipping up and away while the next rises from below, foreshortened to cos θ, narrowing slightly with depth, lit on the upward face and shaded on the downward one. The tens and units prisms add one and two extra full cycles, whirling fastest, smeared by a blur that grows with speed. All start together on springs whose damping and duration are solved from their travel, so every digit overshoots by the same ~0.3 face and rocks back, landing left to right exactly 0.12 s apart, each with a selection tick, while a +points pill rolls its figure. Chunky, tactile, arcade-bright.",
            "悬浮卡片里是一组五位街机分数（04825），每位数字印在一根52×68 pt、靛蓝到紫色渐变的棱柱面上。点击卡片加分：发生变化的数位绕水平轴向前翻滚，旧面向上翻走，新面从下方翻起，高度按cos θ透视压缩、随纵深略微收窄，朝上的面受光、朝下的面变暗。十位和个位额外多转一圈和两圈，转得最快，速度越快模糊越重。各列同时起转，弹簧阻尼与时长按行程解算：每位都冲过约0.3个面再摇回，从左到右每隔0.12秒依次落定，各伴随一次选择触感，同时“+分数”胶囊滚动更新。厚实有手感，街机般明亮。"
        ),
        implementation: L(
            "Each digit is an Animatable view whose animatableData is an unbounded quarter-turn count; it draws only the leaving and arriving faces, placing each at y = h/2·sin θ with scaleEffect(y: cos θ) and a depth tint. A .spring(duration:bounce:) per column, with the bounce solved from the travel for a constant overshoot and the duration from the analytic first crossing so landings (and their ticks) fall a stagger apart, is applied through animation(_:value:); a speed-scaled blur hides strobing.",
            "每位数字是一个 Animatable 视图，animatableData 为无上限的四分之一圈计数；它只绘制离开与到来的两个面，分别放在 y = h/2·sin θ 处，并以 scaleEffect(y: cos θ) 和纵深明暗表现翻转。每列使用 .spring(duration:bounce:)：回弹量由行程反推以保持相同的过冲，时长由首次越过目标的解析时刻反推，使落定（及触感）按间隔排开，通过 animation(_:value:) 施加；随速度增强的模糊消除频闪。"
        ),
        apis: ["Animatable", "scaleEffect(x:y:anchor:)", "spring(duration:bounce:)", "animation(_:value:)", "contentTransition(.numericText())"],
        tags: ["tumble", "prism", "score", "counter", "翻滚", "棱柱", "计分", "数字滚动"],
        params: [
            .slider("duration", L("Tumble duration", "翻滚时长"), 0.6...2.0, default: 1.1, unit: "s"),
            .slider("stagger", L("Landing stagger", "落定间隔"), 0.05...0.3, default: 0.12, unit: "s"),
            .slider("settle", L("Settle overshoot", "落定过冲"), 0...0.5, default: 0.3),
        ]
    ) { ctx in
        TumblingPrismDemo(ctx: ctx)
    }
}

private struct TumblingPrismDemo: View {
    let ctx: DemoContext
    /// Unbounded quarter-turn counts, left to right; a prism shows `roll % 10` on its front face.
    @State private var rolls: [Int] = [0, 4, 8, 2, 5]
    @State private var gain = 0
    /// Quarter turns each column travels on the latest tap; the spring's damping is solved from it.
    @State private var travel: [Int] = [1, 1, 1, 1, 1]
    /// The landing ticks of the latest tap, cancelled by the next tap or when the demo leaves.
    @State private var ticks: Task<Void, Never>?

    private let face = CGSize(width: 52, height: 68)
    /// Extra full cycles for the tens and units prisms, so the right side whirls longest.
    private let extraTurns: [Int] = [0, 0, 0, 10, 20]

    var body: some View {
        VStack(spacing: 18) {
            Button { addPoints() } label: { scoreCard }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: score))
            DemoHint(text: L("Tap the score", "点击分数"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.8) { addPoints() }
        .onDisappear { ticks?.cancel() }
    }

    private var score: String {
        rolls.map { String((($0 % 10) + 10) % 10) }.joined()
    }

    private var scoreCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text(L("High score", "最高分"), ctx.language)
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                Spacer()
                gainPill
            }
            HStack(spacing: 6) {
                ForEach(0..<rolls.count, id: \.self) { column in
                    TumblingPrismDigit(roll: Double(rolls[column]), face: face)
                        .animation(tumble(column), value: rolls[column])
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(width: 330)
        .demoCard(cornerRadius: 24)
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var gainPill: some View {
        Text(verbatim: "+\(gain)")
            .font(.caption.weight(.bold).monospacedDigit())
            .contentTransition(.numericText(value: Double(gain)))
            .foregroundStyle(Palette.violetText)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Palette.violet.opacity(0.14), in: Capsule())
            .opacity(gain > 0 ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: gain)
    }

    /// Damping solved from the travel, so every prism overshoots by the same `settle` faces:
    /// overshoot fraction p = e^(−πζ/√(1−ζ²)) ⇒ ζ = L/√(1+L²) with L = −ln p / π; SwiftUI's bounce is 1 − ζ.
    private func bounce(travel: Int) -> Double {
        let settle: Double = ctx["settle"]
        guard settle > 0.001 else { return 0 }
        let fraction = min(settle / Double(max(travel, 1)), 0.3)
        let l = -log(fraction) / Double.pi
        let zeta = l / (1 + l * l).squareRoot()
        return (1 - zeta).clamped(to: 0...0.6)
    }

    /// When a spring of `.spring(duration: d, bounce: b)` (ω₀ = 2π / d, ζ = 1 − b) first reaches its target, as a
    /// fraction of d. Underdamped: the first zero crossing, ω_d·t = π − atan(√(1−ζ²)/ζ). Critically damped (it never
    /// crosses): the moment the remaining travel drops below half a face, (1 + u)·e^(−u) = 0.5 / travel, u = ω₀·t.
    private static func landingFraction(bounce: Double, travel: Int) -> Double {
        let zeta = 1 - bounce
        if zeta < 0.999 {
            let root = (1 - zeta * zeta).squareRoot()
            return (Double.pi - atan(root / zeta)) / (2 * Double.pi * root)
        }
        let goal = 0.5 / Double(max(travel, 1))
        var low = 0.0
        var high = 30.0
        for _ in 0..<40 {
            let u = (low + high) / 2
            if (1 + u) * exp(-u) > goal { low = u } else { high = u }
        }
        return (low + high) / 4 / Double.pi
    }

    /// Landing time of a column after the tap: a one-face prism on a `duration` spring lands first, then each
    /// column follows exactly `stagger` later.
    private func landingTime(_ column: Int) -> Double {
        let first: Double = ctx["duration"] * Self.landingFraction(bounce: bounce(travel: 1), travel: 1)
        return first + Double(column) * ctx["stagger"]
    }

    /// All prisms start together; each column's spring duration is solved from its damping so its first landing
    /// falls on `landingTime(column)`, however far it spins.
    private func tumble(_ column: Int) -> Animation {
        let distance = travel[column]
        let b = bounce(travel: distance)
        let duration = landingTime(column) / max(Self.landingFraction(bounce: b, travel: distance), 0.05)
        return .spring(duration: duration, bounce: b)
    }

    private func addPoints() {
        let current = Int(score) ?? 0
        let points = Int.random(in: 12...96) * 25
        let target = (current + points) % 100_000
        let count = rolls.count
        let digits: [Int] = (0..<count).map { column in
            var place = 1
            for _ in 0..<(count - 1 - column) { place *= 10 }
            return (target / place) % 10
        }
        var next = rolls
        var distances = travel
        var landing: [Int] = []
        for column in next.indices {
            let delta = (digits[column] - ((next[column] % 10) + 10) % 10 + 10) % 10
            let extra = extraTurns[column]
            guard delta > 0 || extra > 0 else { continue }
            next[column] += delta + extra
            distances[column] = delta + extra
            landing.append(column)
        }
        gain = points
        travel = distances
        rolls = next
        ticks?.cancel()
        ticks = nil
        guard !ctx.isPreview, !Haptics.isMuted else { return }
        Haptics.tap(.light)
        // One selection tick per prism, at the moment it first reaches its digit.
        let times: [Double] = landing.map { landingTime($0) }
        ticks = Task { @MainActor in
            let clock = ContinuousClock()
            let start = clock.now
            for time in times {
                try? await Task.sleep(until: start.advanced(by: .seconds(time)), clock: clock)
                guard !Task.isCancelled else { return }
                Haptics.selection()
            }
        }
    }
}

/// One prism. `roll` animates through quarter turns: face k sits at θ = (k − roll) × 90°, so the current face tips
/// up and away while the next one rises from below. Only those two faces are ever visible.
private struct TumblingPrismDigit: View, Animatable {
    var roll: Double
    let face: CGSize
    /// Frame-to-frame spin speed, for the motion blur.
    @State private var speed = PrismSpinSpeed()

    var animatableData: Double {
        get { roll }
        set { roll = newValue }
    }

    var body: some View {
        let base: Double = roll.rounded(.down)
        let fraction: Double = roll - base
        let index = Int(base)
        // Near one face per frame only two drawn faces would strobe; a blur that grows with the speed (from
        // 8 faces/s, full 2.4 pt at 40 faces/s) turns the fast whirl into a smear and clears as the prism slows.
        let facesPerSecond: Double = speed.update(roll)
        let blur = CGFloat(((facesPerSecond - 8) / 32).clamped(to: 0...1)) * 2.4
        ZStack {
            prismFace(index: index, degrees: -fraction * 90)
            prismFace(index: index + 1, degrees: (1 - fraction) * 90)
        }
        .blur(radius: blur)
        // A turning square prism reaches √2 × its face height at 45°.
        .frame(width: face.width, height: face.height * 1.42)
    }

    private func prismFace(index: Int, degrees: Double) -> some View {
        let radians = degrees * Double.pi / 180
        let c = CGFloat(cos(radians))
        let s = CGFloat(sin(radians))
        let digit = ((index % 10) + 10) % 10
        // Upward-tilted faces (s < 0) catch the top light; downward ones fall into shade.
        let shade: Double = s > 0 ? 0.65 * Double(s) : 0.2 * Double(1 - c)
        let glint: Double = s < 0 ? 0.18 * Double(-s) : 0
        return TumblingPrismFace(digit: digit, size: face, shade: shade, glint: glint)
            .scaleEffect(x: 1 - 0.1 * (1 - c), y: max(c, 0.001), anchor: .center)
            .offset(y: s * face.height / 2)
            .opacity(c > 0.02 ? 1 : 0)
    }
}

/// Measures how fast a prism's `roll` changes between rendered frames (faces per second). A plain reference kept
/// in `@State`: updating it from `body` never invalidates the view.
private final class PrismSpinSpeed {
    private var lastRoll: Double?
    private var lastTime: CFTimeInterval = 0
    private var value: Double = 0

    func update(_ roll: Double) -> Double {
        let now = CACurrentMediaTime()
        defer {
            lastRoll = roll
            lastTime = now
        }
        guard let lastRoll else { return 0 }
        let dt = now - lastTime
        // A second body pass in the same frame keeps the last reading; a long gap means the prism was at rest.
        if dt < 0.004 { return value }
        value = dt > 0.1 ? 0 : abs(roll - lastRoll) / dt
        return value
    }
}

private struct TumblingPrismFace: View {
    let digit: Int
    let size: CGSize
    let shade: Double
    let glint: Double

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 10, style: .continuous) }

    var body: some View {
        Text(verbatim: "\(digit)")
            .font(.system(size: 42, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
            .frame(width: size.width, height: size.height)
            .background(Palette.primaryStrong, in: shape)
            .overlay {
                shape.fill(Color.black.opacity(shade))
            }
            .overlay {
                shape.fill(Color.white.opacity(glint))
            }
            .overlay {
                shape.strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
            }
    }
}
