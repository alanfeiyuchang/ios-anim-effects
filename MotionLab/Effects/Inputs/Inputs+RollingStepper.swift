import SwiftUI

extension Effect {
    static let inputsRollingStepper = Effect(
        id: "inputs.rolling-stepper",
        category: .inputs,
        interaction: .tap,
        name: L("Rolling Stepper", "滚动数字步进器"),
        summary: L("Digits roll in the direction you step and resist at the limits.", "数字按步进方向滚动，到达边界时产生阻力回弹。"),
        prompt: L(
            "A booking card for a lakeside cabin (photo thumbnail, dates, a guests row and a total) whose guest count is a compact capsule stepper: circular minus and plus buttons flanking a large rounded, monospaced number. Each tap presses its button to 88% and springs back, and the number rolls vertically in the direction of change — incoming digits slide up and blur-in when incrementing, down when decrementing — on a snappy spring (~300 ms); the number also nudges 4 pt toward the tapped side. The card's total price rolls to its new value with the same numeric transition. At a limit (1 guest, or the maximum) the disabled button dims, and further taps make the number lurch 8 pt toward that side and bounce back with a keyframed wobble, tinting red briefly, with a rigid haptic. Precise, tactile and honest about boundaries.",
            "湖畔小屋预订卡片（缩略图、日期、入住人数与总价）里，人数由紧凑的胶囊步进器控制：圆形减号与加号夹着大号圆体等宽数字。每次点击，对应按钮压到 88% 后弹回，数字按变化方向纵向滚动——增加时新数字自下而上模糊入场，减少时自上而下——由约 300 毫秒的利落弹簧驱动，同时朝被点一侧轻推 4pt。总价以同样的数字滚动更新。到达上下限时对应按钮变暗，继续点击会让数字朝该侧冲出 8pt 再以关键帧摆回，短暂泛红，并伴随硬朗触觉。诚实地表达边界。"
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
            .slider("nudge", L("Nudge distance", "推移距离"), 0...10, default: 4, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        InputRollingStepperDemo(ctx: ctx)
    }
}

private struct InputRollingStepperDemo: View {
    let ctx: DemoContext
    @State private var value = 2
    private let minimum = 1
    @State private var nudge: CGFloat = 0
    @State private var limitHits = 0
    @State private var limitSide: Double = 1
    @State private var flash = false
    @State private var direction = 1

    private var maximum: Int { max(ctx.int("max"), 1) }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            card
            Spacer(minLength: 0)
            DemoHint(text: L("Tap + or −, then push past the limits", "点击加减，再试试超出上下限"), ctx: ctx)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: maximum) { _, newMax in
            if value > newMax { value = newMax }
        }
        .autoplay(ctx.isPreview, every: 0.7, delay: 0.4) { previewTick() }
    }

    private var zh: Bool { ctx.language == .zh }
    private var total: Int { zh ? 1_680 + value * 320 : 240 + value * 45 }

    private var card: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                LandscapeArt(seed: 2)
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("Lakeside Cabin", "湖畔小木屋"), ctx.language)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(L("2 nights · Jul 8 – 10", "2 晚 · 7月8日 – 10日"), ctx.language)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("Guests", "入住人数"), ctx.language)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(zh ? "最多 \(maximum) 人" : "Up to \(maximum)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                stepper
            }
            Divider()
            HStack(alignment: .firstTextBaseline) {
                Text(L("Total", "总价"), ctx.language)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Text(verbatim: (zh ? "¥" : "$") + total.formatted())
                    .font(.system(.title3, design: .rounded).weight(.bold).monospacedDigit())
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText(value: Double(total)))
            }
        }
        .padding(18)
        .frame(width: 310)
        .demoCard(cornerRadius: 24)
    }

    private var stepper: some View {
        HStack(spacing: 8) {
            stepButton(symbol: "minus", enabled: value > minimum) { change(-1) }
            number
            stepButton(symbol: "plus", enabled: value < maximum) { change(1) }
        }
        .padding(5)
        .background(Color.primary.opacity(0.05), in: Capsule())
        .overlay(Capsule().strokeBorder(Palette.stroke))
    }

    private var number: some View {
        let side = limitSide
        return Text("\(value)")
            .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
            .foregroundStyle(flash ? Palette.red : Color.primary)
            .contentTransition(.numericText(value: Double(value)))
            .frame(width: 48)
            .offset(x: nudge)
            .keyframeAnimator(initialValue: 0.0, trigger: limitHits) { content, shift in
                content.offset(x: shift * side)
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
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(enabled ? Color.white : Color.secondary)
                .frame(width: 40, height: 40)
                .background {
                    Circle().fill(enabled ? AnyShapeStyle(Palette.ocean) : AnyShapeStyle(Color.primary.opacity(0.08)))
                }
        }
        .buttonStyle(InputStepperPressStyle())
        .animation(.easeOut(duration: 0.2), value: enabled)
    }

    private func change(_ delta: Int) {
        let target = value + delta
        guard (minimum...maximum).contains(target) else {
            hitLimit(side: Double(delta))
            return
        }
        if !ctx.isPreview { Haptics.tap() }
        withAnimation(.spring(response: ctx["response"], dampingFraction: 0.8)) {
            value = target
            nudge = CGFloat(delta) * ctx.cg("nudge")
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
        let atBottom = value <= minimum
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
