import SwiftUI

extension Effect {
    static let textOdometer = Effect(
        id: "text.odometer",
        category: .text,
        interaction: .tap,
        name: L("Odometer", "机械里程表"),
        summary: L("Mechanical digit drums roll with a staggered, weighty spring.", "机械数字滚轮以错落、有分量的弹簧滚动到位。"),
        prompt: L(
            "A mechanical odometer reading 4231.8 km on six dark, cylindrical digit drums — five whole-kilometre drums, an amber decimal point and an amber tenths drum. Each drum is an endlessly repeating 0–9 strip seen through one window, with top and bottom inner shading that fakes curvature. When the reading increases, every drum rolls forward only (9 carries on into 0, never back through 8…1) to its new digit on a slightly under-damped spring (≈0.8 s response, 0.78 damping) that is stiffened toward critical damping on long spins so the settle never overshoots by half a digit, staggered ~60 ms from right to left so the carry ripples like real gears catching; the tenths drum spins fastest. A light impact haptic accompanies each roll — tactile, analogue and satisfying.",
            "里程表以六个深色圆柱滚轮显示4231.8公里——五个整公里滚轮、一个琥珀色小数点和一个琥珀色的十分位滚轮。每个滚轮是无限循环的0–9数字带，只露一个窗口，上下内阴影模拟曲面。读数增加时，各滚轮只会向前滚动（9之后接着滚到0，绝不倒转经过8…1），以轻度欠阻尼弹簧（响应约0.8秒、阻尼0.78）停到新数字，长距离滚动时阻尼自动趋近临界，回弹不超过半格，并从右向左依次错开约60毫秒，进位如齿轮逐级咬合；十分位转得最快。每次滚动伴随轻触感，复古而令人满足。"
        ),
        implementation: L(
            "Each drum is an Animatable view whose animatableData is an unbounded step count (value ÷ 10^column); it draws only the two digits around the window, offset by the fractional part, and animates with .animation(.spring(...).delay(column × stagger), value: steps), raising the damping ratio on long travels so the overshoot stays below half a digit.",
            "每个滚轮是一个 Animatable 视图，其 animatableData 为无上限的累计步数（读数 ÷ 10^列）；它只绘制窗口附近的两个数字并按小数部分偏移，使用 .animation(.spring(...).delay(列序 × 错开), value: 步数) 动画，行程越长阻尼比越高，过冲始终小于半格。"
        ),
        apis: ["Animatable", "offset(y:)", "clipped()", "animation(_:value:)", "Animation.delay"],
        tags: ["odometer", "digits", "counter", "mechanical", "里程表", "数字滚轮", "计数", "机械"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.3...1.5, default: 0.8, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1, default: 0.78),
            .slider("stagger", L("Column stagger", "列间错开"), 0...0.15, default: 0.06, unit: "s"),
        ]
    ) { ctx in
        OdometerDemo(ctx: ctx)
    }
}

private struct OdometerDemo: View {
    let ctx: DemoContext
    /// Distance in tenths of a kilometre (42 318 → 4 231.8 km). Never wraps, so drums only roll forward.
    @State private var value = 42_318
    /// The reading before the last trip, so each drum knows how many digits it is travelling.
    @State private var previous = 42_318

    private let columns = 6
    private let cellHeight: CGFloat = 58

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(L("Total distance", "总里程"), ctx.language)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(L("km", "公里"), ctx.language)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .frame(width: 290)
            drums
            DemoHint(text: L("Tap to drive", "点击行驶"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { drive() }
        .autoplay(ctx.isPreview, every: 1.7) { drive() }
    }

    private var drums: some View {
        HStack(spacing: 6) {
            ForEach(0..<columns, id: \.self) { column in
                if column == columns - 1 {
                    // Decimal point before the tenths drum.
                    Circle()
                        .fill(Palette.amber)
                        .frame(width: 6, height: 6)
                        .padding(.bottom, 12)
                        .frame(height: cellHeight, alignment: .bottom)
                }
                OdometerDrum(
                    roll: Double(roll(at: column)),
                    height: cellHeight,
                    accent: column == columns - 1
                )
                .animation(drumAnimation(for: column), value: roll(at: column))
            }
        }
        .padding(10)
        .background(Color(white: 0.04), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(.white.opacity(0.08)))
        .shadow(color: .black.opacity(0.25), radius: 18, y: 10)
    }

    /// How many steps this drum has turned in total (unbounded). Its visible digit is `roll % 10`.
    private func roll(at column: Int, of reading: Int? = nil) -> Int {
        let reading = reading ?? value
        let power = columns - 1 - column
        var divisor = 1
        for _ in 0..<power { divisor *= 10 }
        return reading / divisor
    }

    private func drumAnimation(for column: Int) -> Animation {
        let fromRight = Double(columns - 1 - column)
        let travel = roll(at: column) - roll(at: column, of: previous)
        let damping = max(ctx["damping"], Self.requiredDamping(travel: travel))
        return .spring(response: ctx["response"], dampingFraction: damping)
            .delay(fromRight * ctx["stagger"])
    }

    /// The smallest damping ratio whose overshoot stays under 0.4 of a digit over `travel` digits,
    /// so long trips never visibly roll back through a digit (overshoot = e^(−πζ/√(1−ζ²))).
    private static func requiredDamping(travel: Int) -> Double {
        guard travel > 1 else { return 0 }
        let allowed = 0.4 / Double(travel)
        let logOS = -log(allowed)
        return min(logOS / (Double.pi * Double.pi + logOS * logOS).squareRoot(), 1)
    }

    private func drive() {
        // 0.4 – 9.6 km per trip.
        previous = value
        value += Int.random(in: 4...96)
        if !ctx.isPreview { Haptics.tap(.light) }
    }
}

/// One drum. `roll` is an unbounded, animatable step count: the view only ever draws the
/// two digits straddling the window (⌊roll⌋ and ⌊roll⌋ + 1, mod 10), so 9 → 0 keeps rolling
/// forward over the repeating strip instead of spinning back through 8…1.
private struct OdometerDrum: View, Animatable {
    var roll: Double
    let height: CGFloat
    let accent: Bool

    var animatableData: Double {
        get { roll }
        set { roll = newValue }
    }

    var body: some View {
        let base = roll.rounded(.down)
        let fraction = CGFloat(roll - base)
        let digit = ((Int(base) % 10) + 10) % 10
        VStack(spacing: 0) {
            face(digit)
            face((digit + 1) % 10)
        }
        .offset(y: -fraction * height)
        .frame(width: 40, height: height, alignment: .top)
        .clipped()
        .background(drumFill)
        .overlay(shading)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func face(_ n: Int) -> some View {
        Text(verbatim: "\(n)")
            .font(.system(size: 36, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(accent ? Palette.amber : Color(white: 0.95))
            .frame(width: 40, height: height)
    }

    private var drumFill: some View {
        LinearGradient(colors: [Color(white: 0.2), Color(white: 0.12)], startPoint: .top, endPoint: .bottom)
    }

    /// Top and bottom inner shading fakes the drum's curvature.
    private var shading: some View {
        LinearGradient(
            stops: [
                .init(color: .black.opacity(0.7), location: 0),
                .init(color: .clear, location: 0.3),
                .init(color: .clear, location: 0.7),
                .init(color: .black.opacity(0.7), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }
}
