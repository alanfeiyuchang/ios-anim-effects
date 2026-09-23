import SwiftUI

extension Effect {
    static let inputsRollingStepper = Effect(
        id: "inputs.rolling-stepper",
        category: .inputs,
        interaction: .tap,
        name: L("Rolling Stepper", "滚动数字步进器"),
        summary: L("Digits roll in the direction you step and resist at the limits.", "数字按步进方向滚动，到达边界时产生阻力回弹。"),
        prompt: L(
            "A compact capsule stepper with circular minus and plus buttons flanking a large rounded, monospaced number. Each tap presses its button to 88% and springs back, and the number rolls vertically in the direction of change — incoming digits slide up and blur-in when incrementing, down when decrementing — on a snappy spring (~300 ms); the number also nudges 4 pt toward the tapped side. At a limit the disabled button dims, and further taps make the number lurch 8 pt toward that side and bounce back with a keyframed wobble, tinting red briefly, with a rigid haptic. Precise, tactile and honest about boundaries.",
            "紧凑的胶囊步进器，左右是圆形的减号与加号按钮，中间是大号圆体等宽数字。每次点击，对应按钮压缩到 88% 后弹回，数字按变化方向纵向滚动——增加时新数字自下而上模糊入场，减少时自上而下——由约 300 毫秒的利落弹簧驱动，同时数字朝被点击的一侧轻推 4pt。到达上下限时，对应按钮变暗；继续点击会让数字朝该侧冲出 8pt 再以关键帧摆动弹回，短暂泛红，并伴随一次硬朗的触觉。精准、可触，并诚实地表达边界。"
        ),
        implementation: L(
            "contentTransition(.numericText(value:)) rolls digits in the right direction; a keyframeAnimator keyed on a limit-hit counter adds the rubber-band wobble, and a ButtonStyle provides the press scale.",
            "contentTransition(.numericText(value:)) 按正确方向滚动数字；以边界撞击计数为触发的 keyframeAnimator 添加橡皮筋摆动，ButtonStyle 提供按压缩放。"
        ),
        apis: ["contentTransition(.numericText(value:))", "keyframeAnimator", "ButtonStyle", "monospacedDigit"],
        tags: ["stepper", "counter", "quantity", "numeric", "步进器", "计数", "数量", "数字滚动"],
        params: [
            .slider("max", L("Maximum", "最大值"), 3...20, default: 8, step: 1, decimals: 0),
            .slider("response", L("Roll response", "滚动响应"), 0.15...0.8, default: 0.3, unit: "s"),
        ]
    ) { ctx in
        InputRollingStepperDemo(ctx: ctx)
    }
}

private struct InputRollingStepperDemo: View {
    let ctx: DemoContext
    @State private var value = 2
    @State private var nudge: CGFloat = 0
    @State private var limitHits = 0
    @State private var limitSide: Double = 1
    @State private var flash = false
    @State private var direction = 1

    private var maximum: Int { max(ctx.int("max"), 1) }

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Text(L("Guests", "入住人数"), ctx.language)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            stepper
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: maximum) { _, newMax in
            if value > newMax { value = newMax }
        }
        .autoplay(ctx.isPreview, every: 0.7, delay: 0.4) { previewTick() }
    }

    private var stepper: some View {
        HStack(spacing: 18) {
            stepButton(symbol: "minus", enabled: value > 0) { change(-1) }
            number
            stepButton(symbol: "plus", enabled: value < maximum) { change(1) }
        }
        .padding(8)
        .background(Palette.elevated, in: Capsule())
        .overlay(Capsule().strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(0.1), radius: 16, y: 8)
    }

    private var number: some View {
        Text("\(value)")
            .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
            .foregroundStyle(flash ? Palette.red : Color.primary)
            .contentTransition(.numericText(value: Double(value)))
            .frame(width: 84)
            .offset(x: nudge)
            .keyframeAnimator(initialValue: 0.0, trigger: limitHits) { content, shift in
                content.offset(x: shift * limitSide)
            } keyframes: { _ in
                KeyframeTrack(\.self) {
                    CubicKeyframe(8, duration: 0.08)
                    SpringKeyframe(-3, duration: 0.14, spring: .snappy)
                    SpringKeyframe(0, duration: 0.4, spring: .bouncy)
                }
            }
    }

    private func stepButton(symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(enabled ? Color.white : Color.secondary)
                .frame(width: 52, height: 52)
                .background {
                    Circle().fill(enabled ? AnyShapeStyle(Palette.ocean) : AnyShapeStyle(Color.primary.opacity(0.08)))
                }
        }
        .buttonStyle(InputStepperPressStyle())
        .animation(.easeOut(duration: 0.2), value: enabled)
    }

    private func change(_ delta: Int) {
        let target = value + delta
        guard (0...maximum).contains(target) else {
            hitLimit(side: Double(delta))
            return
        }
        if !ctx.isPreview { Haptics.tap() }
        withAnimation(.spring(response: ctx["response"], dampingFraction: 0.8)) {
            value = target
            nudge = CGFloat(delta) * 4
        }
        Task {
            try? await Task.sleep(for: .seconds(0.12))
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { nudge = 0 }
        }
    }

    private func hitLimit(side: Double) {
        if !ctx.isPreview { Haptics.tap(.rigid) }
        limitSide = side
        limitHits += 1
        withAnimation(.easeOut(duration: 0.1)) { flash = true }
        Task {
            try? await Task.sleep(for: .seconds(0.25))
            withAnimation(.easeIn(duration: 0.35)) { flash = false }
        }
    }

    private func previewTick() {
        let atTop = value >= maximum
        let atBottom = value <= 0
        if atTop && direction > 0 {
            hitLimit(side: 1)
            direction = -1
            return
        }
        if atBottom && direction < 0 {
            hitLimit(side: -1)
            direction = 1
            return
        }
        change(direction)
    }
}

private struct InputStepperPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: configuration.isPressed)
    }
}
