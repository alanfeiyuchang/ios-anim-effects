import SwiftUI

extension Effect {
    static let textOdometer = Effect(
        id: "text.odometer",
        category: .text,
        interaction: .tap,
        name: L("Odometer", "机械里程表"),
        summary: L("Mechanical digit drums roll with a staggered, weighty spring.", "机械数字滚轮以错落、有分量的弹簧滚动到位。"),
        prompt: L(
            "A mechanical odometer made of six dark, cylindrical digit drums: each drum is a vertical 0–9 strip clipped to a single window, with top and bottom inner shading that fakes curvature and a hairline seam across the middle. When the reading increases, every drum rolls to its new digit on a slightly under-damped spring (≈0.8 s response, 0.78 damping), staggered ~60 ms from right to left so the change ripples like real gears catching; the last drum is tinted as the tenths wheel. A light impact haptic accompanies each roll — tactile, analogue and satisfying.",
            "由六个深色圆柱数字滚轮组成的机械里程表：每个滚轮是一条纵向 0–9 数字带，只露出一个窗口；上下内阴影模拟圆柱曲面，中间有一道细缝线。读数增加时，每个滚轮以轻度欠阻尼弹簧（响应约 0.8 秒、阻尼 0.78）滚到新数字，从右向左依次错开约 60 毫秒，像真实齿轮逐级咬合般传递；最后一个滚轮以强调色表示小数位。每次滚动伴随轻微冲击触感——触感真实、复古而令人满足。"
        ),
        implementation: L(
            "Each column is a VStack of 0–9 clipped to one digit's height and offset by −digit × height, animated with .animation(.spring(...).delay(column × stagger), value: digit).",
            "每一列是 0–9 的 VStack，裁剪为一个数字高度，并按 −数字 × 高度 偏移，使用 .animation(.spring(...).delay(列序 × 错开), value: digit) 动画。"
        ),
        apis: ["offset(y:)", "clipped()", "animation(_:value:)", "Animation.delay"],
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
    @State private var value = 42_318

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
            .frame(width: 280)
            HStack(spacing: 6) {
                ForEach(0..<columns, id: \.self) { column in
                    OdometerDrum(
                        digit: digit(at: column),
                        height: cellHeight,
                        accent: column == columns - 1
                    )
                    .animation(drumAnimation(for: column), value: digit(at: column))
                }
            }
            .padding(10)
            .background(Color(white: 0.04), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(.white.opacity(0.08)))
            .shadow(color: .black.opacity(0.25), radius: 18, y: 10)
            DemoHint(text: L("Tap to drive", "点击行驶"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { drive() }
        .autoplay(ctx.isPreview, every: 1.7) { drive() }
    }

    private func digit(at column: Int) -> Int {
        let power = columns - 1 - column
        var divisor = 1
        for _ in 0..<power { divisor *= 10 }
        return (value / divisor) % 10
    }

    private func drumAnimation(for column: Int) -> Animation {
        let fromRight = Double(columns - 1 - column)
        return .spring(response: ctx["response"], dampingFraction: ctx["damping"])
            .delay(fromRight * ctx["stagger"])
    }

    private func drive() {
        value = (value + Int.random(in: 37...1_280)) % 1_000_000
        if !ctx.isPreview { Haptics.tap(.light) }
    }
}

private struct OdometerDrum: View {
    let digit: Int
    let height: CGFloat
    let accent: Bool

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<10, id: \.self) { n in
                Text(verbatim: "\(n)")
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(accent ? Palette.amber : Color(white: 0.95))
                    .frame(width: 40, height: height)
            }
        }
        .offset(y: -CGFloat(digit) * height)
        .frame(width: 40, height: height, alignment: .top)
        .clipped()
        .background(drumFill)
        .overlay(shading)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var drumFill: some View {
        LinearGradient(colors: [Color(white: 0.2), Color(white: 0.12)], startPoint: .top, endPoint: .bottom)
    }

    private var shading: some View {
        ZStack {
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
            Rectangle()
                .fill(.black.opacity(0.35))
                .frame(height: 1)
        }
        .allowsHitTesting(false)
    }
}
