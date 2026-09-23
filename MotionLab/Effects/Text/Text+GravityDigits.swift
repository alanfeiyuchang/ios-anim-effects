import SwiftUI

extension Effect {
    static let textGravityDigits = Effect(
        id: "text.gravity-digits",
        category: .text,
        interaction: .tap,
        name: L("Gravity Drop Digits", "重力坠落数字"),
        summary: L("Only the digits that change fall in from above and bounce; old ones tumble out.", "只有变化的数字从上方坠落并弹跳，旧数字翻滚着掉出。"),
        prompt: L(
            "A step counter shows a large rounded number such as 18,452 above a small caption. When the value increases, only the digits that changed are replaced: each old digit drops 60 pt out of its clipped slot, tilting 14° as it fades, while the new one falls in from 60 pt above on a bouncy spring (0.55 s, 45% bounce) that overshoots the baseline and settles in a couple of rebounds. Changed digits land right to left 50 ms apart, so a carry reads like objects stacking up, and unchanged digits never move. A medium haptic fires on tap. Physical and playful: numbers with weight.",
            "步数卡片上是一个大号圆体数字（如18,452）和一行小标题。数值增加时只替换真正变化的数位：旧数字在裁切槽里向下掉出60 pt，倾斜14°并淡出；新数字从上方60 pt处坠入，由高回弹弹簧（0.55秒、45%回弹）驱动，冲过基线后再弹两下才停稳。变化的数位从右到左错开50毫秒落下，进位像物体一个个叠上去，没变的数位纹丝不动。点击时伴随中等触感。俏皮而有分量，数字仿佛真的有了重量。"
        ),
        implementation: L(
            "Each digit sits in its own clipped slot and is keyed with .id(digit), so a change swaps the view; a custom Transition offsets, tilts and fades it by TransitionPhase, and AnyTransition.animation adds a per-column delayed bouncy spring.",
            "每个数位位于独立的裁切槽位中，并以 .id(数字) 标识，数值变化即替换视图；自定义 Transition 根据 TransitionPhase 设置位移、倾斜与透明度，再用 AnyTransition.animation 为每一列加上带延迟的高回弹弹簧。"
        ),
        apis: ["Transition", "TransitionPhase", "AnyTransition.asymmetric", "id(_:)", "spring(duration:bounce:)"],
        tags: ["counter", "digits", "bounce", "gravity", "数字", "计数", "弹跳", "重力"],
        params: [
            .slider("bounce", L("Landing bounce", "落地回弹"), 0...0.7, default: 0.45),
            .slider("duration", L("Fall duration", "坠落时长"), 0.3...1.2, default: 0.55, unit: "s"),
            .slider("stagger", L("Column stagger", "列间错开"), 0...0.15, default: 0.05, unit: "s"),
        ]
    ) { ctx in
        GravityDigitsDemo(ctx: ctx)
    }
}

/// Falls in from above; on removal drops out of the bottom while tilting.
private struct GravityFallTransition: Transition {
    var distance: CGFloat
    var tilt: Double

    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .rotationEffect(.degrees(phase == .didDisappear ? tilt : 0))
            .offset(y: offset(for: phase))
            .opacity(phase.isIdentity ? 1 : 0)
    }

    private func offset(for phase: TransitionPhase) -> CGFloat {
        switch phase {
        case .willAppear: return -distance
        case .didDisappear: return distance
        default: return 0
        }
    }
}

private struct GravityDigitsDemo: View {
    let ctx: DemoContext
    @State private var value = 18_452

    private let slotHeight: CGFloat = 72

    /// "18,452" → ["1", "8", ",", "4", "5", "2"].
    private var characters: [String] {
        let digits = String(value)
        var result: [String] = []
        for (index, ch) in digits.enumerated() {
            let fromEnd = digits.count - index
            if index > 0 && fromEnd % 3 == 0 { result.append(",") }
            result.append(String(ch))
        }
        return result
    }

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "figure.walk")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Palette.mint)
            number
            Text(L("steps today", "今日步数"), ctx.language)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            DemoHint(text: L("Tap to walk", "点击走几步"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { walk() }
        .autoplay(ctx.isPreview, every: 1.6) { walk() }
    }

    private var number: some View {
        let chars = characters
        return HStack(spacing: 0) {
            ForEach(Array(chars.enumerated()), id: \.offset) { index, ch in
                ZStack {
                    Text(verbatim: ch)
                        .font(.system(size: 64, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                        .id(ch)
                        .transition(transition(column: index, count: chars.count))
                }
                .frame(width: ch == "," ? 18 : 40, height: slotHeight)
                .clipped()
            }
        }
    }

    private func transition(column: Int, count: Int) -> AnyTransition {
        let delay: Double = Double(count - 1 - column) * ctx["stagger"]
        let tilt: Double = column % 2 == 0 ? -14 : 14
        let fall = GravityFallTransition(distance: 60, tilt: tilt)
        return .asymmetric(
            insertion: AnyTransition(fall).animation(.spring(duration: ctx["duration"], bounce: ctx["bounce"]).delay(delay)),
            removal: AnyTransition(fall).animation(.easeIn(duration: ctx["duration"] * 0.5).delay(delay))
        )
    }

    private func walk() {
        if !ctx.isPreview { Haptics.tap(.medium) }
        withAnimation(.spring(duration: ctx["duration"], bounce: ctx["bounce"])) {
            let next = value + Int.random(in: 37...420)
            value = next > 99_000 ? 10_000 + Int.random(in: 0...900) : next
        }
    }
}
