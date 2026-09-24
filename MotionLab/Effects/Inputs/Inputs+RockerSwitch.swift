import SwiftUI

extension Effect {
    static let inputsRockerSwitch = Effect(
        id: "inputs.rocker-switch",
        category: .inputs,
        interaction: .tap,
        name: L("Rocker Switch", "翘板开关"),
        summary: L("A physical rocker that tips over with a mechanical snap and a flickering pilot light.", "实体翘板开关：机械式利落翻转，指示灯随之闪亮。"),
        prompt: L(
            "A hardware-style rocker switch (132 × 72 pt paddle, marked O and I) seated in a recessed bezel on a device card. Tapping presses the whole housing to 97%, then the paddle tips 12° around its vertical axis with strong perspective on a very stiff, nearly critically damped spring (response 0.18 s, damping 0.9) — no wobble, just a decisive clack with a rigid haptic. Lighting follows the tilt: the raised half catches a highlight gradient while the pressed half falls into shadow, and the bezel's inner shadow shifts sides. A pilot LED then flickers on (0 → 100% → 40% → 100% over 260 ms) and blooms a soft amber glow; switching off fades it out within the 180 ms spring. Mechanical, weighty, satisfying.",
            "设备面板上嵌着一枚硬件风翘板开关（132 × 72pt 按板，标有 O 与 I），四周是下凹边框。点击时外壳先压到 97%，按板再以强透视绕竖轴翻转 12°，弹簧极硬、接近临界阻尼（响应 0.18 秒、阻尼 0.9）——不晃，只有一声干脆的“咔嗒”与一次硬朗触觉。光影随倾角变化：翘起的一半出现高光渐变，按下的一半落入阴影，边框内阴影随之换边。随后指示灯闪烁点亮（260 毫秒内 0 → 100% → 40% → 100%），晕开琥珀光；关闭时在 180 毫秒弹簧内迅速熄灭。机械而厚重。"
        ),
        implementation: L(
            "rotation3DEffect tilts the paddle around the y-axis with a stiff spring while two gradient overlays swap opacity for the lighting; a keyframeAnimator keyed on a switch counter flickers the LED.",
            "rotation3DEffect 以硬弹簧让按板绕 y 轴倾斜，两层渐变叠加通过透明度互换模拟光影；以开关计数为触发的 keyframeAnimator 让指示灯闪烁点亮。"
        ),
        apis: ["rotation3DEffect(_:axis:perspective:)", "keyframeAnimator", "spring(response:dampingFraction:)", "shadow"],
        tags: ["toggle", "rocker", "switch", "hardware", "开关", "翘板", "机械", "拟物"],
        params: [
            .slider("tilt", L("Tilt angle", "倾斜角度"), 4...22, default: 12, decimals: 0, unit: "°"),
            .slider("response", L("Snap response", "吸合响应"), 0.08...0.5, default: 0.18, unit: "s"),
            .toggle("flicker", L("LED flicker", "指示灯闪烁"), default: true),
        ]
    ) { ctx in
        RockerSwitchDemo(ctx: ctx)
    }
}

private struct RockerSwitchDemo: View {
    let ctx: DemoContext
    @State private var isOn = false
    @State private var pressed = false
    @State private var flips = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            panel
            Spacer()
            DemoHint(text: L("Tap the rocker", "点击翘板"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.4, delay: 0.4) { flip() }
    }

    private var panel: some View {
        VStack(spacing: 18) {
            HStack {
                Text(L("Studio Heater", "工作室暖风机"), ctx.language)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
                led
            }
            bezel
            Text(isOn ? L("Running · 1,200 W", "运行中 · 1,200 W") : L("Standby", "待机"), ctx.language)
                .font(.caption.weight(.medium).monospacedDigit())
                .foregroundStyle(.secondary)
                .contentTransition(.opacity)
                .animation(.easeOut(duration: 0.2), value: isOn)
        }
        .padding(20)
        .frame(width: 260)
        .demoCard(cornerRadius: 26)
    }

    private var led: some View {
        let flicker = ctx.bool("flicker")
        let low: Double = flicker ? 0 : 1
        let dip: Double = flicker ? 0.4 : 1
        let lit = isOn
        return Circle()
            .fill(lit ? Palette.amber : Color.primary.opacity(0.15))
            .frame(width: 10, height: 10)
            .keyframeAnimator(initialValue: 1.0, trigger: flips) { content, level in
                content
                    .opacity(lit ? level : 1)
                    .shadow(color: Palette.amber.opacity(lit ? 0.9 * level : 0), radius: 8)
            } keyframes: { _ in
                KeyframeTrack(\.self) {
                    LinearKeyframe(low, duration: 0.04)
                    LinearKeyframe(1, duration: 0.06)
                    LinearKeyframe(dip, duration: 0.06)
                    LinearKeyframe(1, duration: 0.1)
                }
            }
    }

    private var bezel: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        return ZStack {
            shape
                .fill(Color.primary.opacity(0.1))
                .overlay(shape.strokeBorder(Color.black.opacity(0.12), lineWidth: 1))
            paddle
                .padding(8)
        }
        .frame(width: 148, height: 88)
        .scaleEffect(pressed ? 0.97 : 1)
        .contentShape(shape)
        .onTapGesture { flip() }
    }

    private var paddle: some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        let angle: Double = isOn ? ctx["tilt"] : -ctx["tilt"]
        return ZStack {
            shape.fill(Palette.elevated)
            HStack(spacing: 0) {
                LinearGradient(colors: [.black.opacity(0.18), .clear], startPoint: .leading, endPoint: .trailing)
                    .opacity(isOn ? 0 : 1)
                LinearGradient(colors: [.clear, .black.opacity(0.18)], startPoint: .leading, endPoint: .trailing)
                    .opacity(isOn ? 1 : 0)
            }
            .clipShape(shape)
            LinearGradient(colors: [.white.opacity(0.35), .clear], startPoint: .top, endPoint: .center)
                .clipShape(shape)
            HStack {
                Text(verbatim: "O")
                    .foregroundStyle(isOn ? Color.secondary : Color.primary)
                Spacer(minLength: 0)
                Text(verbatim: "I")
                    .foregroundStyle(isOn ? Palette.amber : Color.secondary)
            }
            .font(.system(size: 22, weight: .heavy, design: .rounded))
            .padding(.horizontal, 26)
        }
        .overlay(shape.strokeBorder(Palette.stroke))
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
        .shadow(color: .black.opacity(0.2), radius: 5, x: isOn ? -3 : 3, y: 3)
    }

    private func flip() {
        withAnimation(.easeOut(duration: 0.08)) { pressed = true }
        let muted = ctx.isPreview || Haptics.isMuted
        Task {
            try? await Task.sleep(for: .seconds(0.08))
            if !muted { Haptics.tap(.rigid) }
            withAnimation(.spring(response: ctx["response"], dampingFraction: 0.9)) {
                isOn.toggle()
                pressed = false
            }
            if isOn { flips += 1 }
        }
    }
}
