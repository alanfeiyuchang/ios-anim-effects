import SwiftUI

extension Effect {
    static let inputsThermostatDial = Effect(
        id: "inputs.thermostat-dial",
        category: .inputs,
        interaction: .gesture,
        name: L("Thermostat Ring", "温控环"),
        summary: L("A heavy bead chases your setpoint round the ring on an elastic leash as the dial warms or cools.", "沉甸甸的小珠像拴着弹性绳般追随设定点绕环移动，表盘随之变暖或变冷。"),
        prompt: L(
            "A thermostat ring: a 230 pt, 270° track with 54 hairline ticks, a white bead and a large rounded temperature in the centre (10–30 °C in 0.5° steps). Dragging near the ring moves a hollow setpoint ring along the arc instantly, with a selection haptic on every step, while the heavy bead follows on an elastic leash — an underdamped spring (response 0.55 s, damping 0.55) that lags, catches up and overshoots a little. The fill, a cool-blue-to-coral angular gradient, rides with the bead, and a soft glow crossfades blue to orange. The number rolls and the caption swaps between \"Cooling to\" and \"Heating to\" with a blur transition around 21 °C. On release, a highlight ripples outward through the ticks from the bead, each tick lengthening then settling with a 12 ms stagger. Weighty and warm.",
            "温控环：230pt、270° 轨道配 54 根细刻度，一颗白色小珠，中央是大号圆体温度（10–30 °C，步进 0.5°）。在圆环附近拖动，空心设定环即时沿弧移动，每跨一步一次选择触觉；沉甸甸的小珠像拴着弹性绳，以欠阻尼弹簧（响应 0.55 秒、阻尼 0.55）滞后追赶并略微冲过。冷蓝到珊瑚的角向渐变填充随小珠走，环境光蓝橙过渡。数字滚动，说明文字在 21 °C 附近以模糊过渡切换“制冷至/制热至”。松手后高光从小珠沿刻度向外涟漪，每根刻度以 12 毫秒错峰伸长再回落。"
        ),
        implementation: L(
            "atan2 maps the touch onto the 270° arc and quantises it into a setpoint that updates instantly, while a second bead value chases it inside a loose underdamped spring; Circle().trim draws the fill with an AngularGradient, two blurred circles crossfade for the glow, and a release counter drives per-tick keyframeAnimators delayed by their distance from the bead.",
            "atan2 把触点映射到 270° 弧上并量化为即时更新的设定值，另一份小珠数值在松弛的欠阻尼弹簧中追赶它；Circle().trim 配合 AngularGradient 绘制填充，两个模糊圆交叉淡化形成光晕；松手计数触发每根刻度的 keyframeAnimator，延迟取决于其与小珠的距离。"
        ),
        apis: ["atan2", "spring(response:dampingFraction:)", "Circle().trim", "AngularGradient", "keyframeAnimator"],
        tags: ["dial", "thermostat", "temperature", "ring", "旋钮", "温控", "温度", "圆环"],
        params: [
            .choice("step", L("Step", "步进"), [L("0.5°", "0.5°"), L("1°", "1°")], default: 0),
            .slider("glow", L("Glow intensity", "光晕强度"), 0...1, default: 0.6),
            .slider("stagger", L("Ripple stagger", "涟漪错峰"), 0...0.03, default: 0.012, decimals: 3, unit: "s"),
            .slider("leash", L("Leash spring", "牵引弹簧响应"), 0.2...1.0, default: 0.55, unit: "s"),
        ]
    ) { ctx in
        ThermostatDialDemo(ctx: ctx)
    }
}

private struct ThermostatDialDemo: View {
    let ctx: DemoContext
    /// The setpoint under the finger (readout, hollow ring).
    @State private var temperature: Double = 21.5
    /// Where the heavy bead is; it chases `temperature` on a loose spring.
    @State private var beadTemperature: Double = 21.5
    @State private var releases = 0
    @State private var step = 0
    /// Arc angle (0…270°) of the previous drag sample: keeps the setpoint continuous, so a finger that drifts
    /// through the bottom dead zone pins to the nearer end instead of flipping 10 ↔ 30 °C.
    @State private var lastAngle: Double?
    /// Resets on system cancellation too (page scroll takeover, Control Center pull), where `onEnded` never runs.
    @GestureState private var dialTouching = false

    private let size: CGFloat = 230
    private let range: ClosedRange<Double> = 10...30
    private let tickCount = 54
    private static let previewTargets: [Double] = [26, 17.5, 23, 14, 21.5]

    private var increment: Double { ctx.int("step") == 0 ? 0.5 : 1 }
    private var fraction: Double { (beadTemperature - range.lowerBound) / (range.upperBound - range.lowerBound) }
    private var setFraction: Double { (temperature - range.lowerBound) / (range.upperBound - range.lowerBound) }
    private var heating: Bool { temperature >= 21 }
    private var leash: Animation { .spring(response: ctx["leash"], dampingFraction: 0.55) }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            dial
                .scaleEffect(ctx.isPreview ? 0.9 : 1)
            Spacer(minLength: 0)
            DemoHint(text: L("Drag around the ring", "沿圆环拖动"), ctx: ctx)
                .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.6, delay: 0.3) { previewTick() }
    }

    private var dial: some View {
        ZStack {
            glow
            ticks
            track
            setpointRing
            bead
            readout
        }
        .frame(width: size + 40, height: size + 40)
        .contentShape(Circle())
        .gesture(drag)
        .onChange(of: dialTouching) { _, down in
            if !down { endDrag() }
        }
    }

    private var glow: some View {
        let intensity = ctx["glow"]
        return ZStack {
            Circle().fill(Palette.sky).opacity(heating ? 0 : intensity)
            Circle().fill(Palette.coral).opacity(heating ? intensity : 0)
        }
        .frame(width: size * 0.7, height: size * 0.7)
        .blur(radius: 50)
        .animation(.easeInOut(duration: 0.6), value: heating)
    }

    private var track: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Color.primary.opacity(0.1), style: StrokeStyle(lineWidth: 14, lineCap: .round))
            Circle()
                .trim(from: 0, to: 0.75 * fraction)
                .stroke(
                    AngularGradient(
                        colors: [Palette.sky, Palette.blue, Palette.violet, Palette.coral],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
        }
        .rotationEffect(.degrees(135))
        .frame(width: size, height: size)
    }

    private var bead: some View {
        let angle: Double = 135 + 270 * fraction
        return Circle()
            .fill(Color.white)
            .frame(width: 24, height: 24)
            .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
            .offset(x: size / 2)
            .rotationEffect(.degrees(angle))
    }

    /// Hollow ring marking the setpoint; it jumps with the finger while the bead lags behind.
    private var setpointRing: some View {
        let angle: Double = 135 + 270 * setFraction
        return Circle()
            .strokeBorder(Color.primary.opacity(0.45), lineWidth: 2)
            .frame(width: 20, height: 20)
            .offset(x: size / 2)
            .rotationEffect(.degrees(angle))
            .allowsHitTesting(false)
    }

    private var ticks: some View {
        let beadTick = Int((fraction * Double(tickCount - 1)).rounded())
        let stagger = ctx["stagger"]
        return ZStack {
            ForEach(0..<tickCount, id: \.self) { index in
                ThermostatTick(
                    lit: index <= beadTick,
                    delay: Double(abs(index - beadTick)) * stagger,
                    trigger: releases
                )
                .offset(x: size / 2 + 24)
                .rotationEffect(.degrees(135 + 270 * Double(index) / Double(tickCount - 1)))
            }
        }
    }

    private var readout: some View {
        VStack(spacing: 2) {
            Text(heating ? L("Heating to", "制热至") : L("Cooling to", "制冷至"), ctx.language)
                .font(.caption.weight(.semibold))
                .foregroundStyle(heating ? Palette.coral : Palette.blue)
                .id(heating)
                .transition(.blurReplace)
            Text(String(format: "%.1f°", temperature))
                .font(.system(size: 46, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(.primary)
                .contentTransition(.numericText(value: temperature))
        }
        .animation(.snappy, value: temperature)
        .animation(.smooth, value: heating)
        .allowsHitTesting(false)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($dialTouching) { _, state, _ in state = true }
            .onChanged { value in
                let center: CGFloat = (size + 40) / 2
                let dx = Double(value.location.x - center)
                let dy = Double(value.location.y - center)
                guard hypot(dx, dy) > 30 else { return }
                var angle: Double = atan2(dy, dx) * 180 / .pi - 135
                while angle < 0 { angle += 360 }
                if angle > 270 {
                    // Dead zone: stay at the end the finger came from (a first touch splits it down the middle).
                    if let last = lastAngle {
                        angle = last > 135 ? 270 : 0
                    } else {
                        angle = angle > 315 ? 0 : 270
                    }
                }
                // Continuity: a jump of more than half the arc is the finger crossing the gap, not a turn.
                if let last = lastAngle, abs(angle - last) > 180 { return }
                lastAngle = angle
                let raw: Double = range.lowerBound + angle / 270 * (range.upperBound - range.lowerBound)
                let snapped: Double = (raw / increment).rounded() * increment
                let newValue = snapped.clamped(to: range)
                guard newValue != temperature else { return }
                Haptics.selection()
                withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.85)) { temperature = newValue }
                withAnimation(leash) { beadTemperature = newValue }
            }
            .onEnded { _ in endDrag() }
    }

    /// Single cleanup for a lifted or system-cancelled drag: clears the continuity anchor, plays the tick ripple.
    private func endDrag() {
        guard lastAngle != nil else { return }
        lastAngle = nil
        releases += 1
    }

    private func previewTick() {
        let target = Self.previewTargets[step % Self.previewTargets.count]
        step += 1
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { temperature = target }
        withAnimation(leash) { beadTemperature = target }
        Task {
            try? await Task.sleep(for: .seconds(0.6))
            releases += 1
        }
    }
}

private struct ThermostatTick: View {
    let lit: Bool
    let delay: Double
    let trigger: Int

    var body: some View {
        Capsule()
            .fill(lit ? Color.primary.opacity(0.55) : Color.primary.opacity(0.15))
            .frame(width: 10, height: 2)
            .keyframeAnimator(initialValue: 1.0, trigger: trigger) { content, stretch in
                content.scaleEffect(x: stretch, y: 1, anchor: .leading)
            } keyframes: { _ in
                KeyframeTrack(\.self) {
                    LinearKeyframe(1, duration: 0.001 + delay)
                    CubicKeyframe(1.8, duration: 0.12)
                    SpringKeyframe(1, duration: 0.4, spring: .bouncy)
                }
            }
    }
}
