import SwiftUI

extension Effect {
    static let inputsDialKnob = Effect(
        id: "inputs.dial-knob",
        category: .inputs,
        interaction: .gesture,
        name: L("Detent Dial", "刻度旋钮"),
        summary: L("A rotary knob that clicks into detents with haptic ticks.", "带刻度吸附与触觉反馈的旋转旋钮。"),
        prompt: L(
            "A 170 pt hardware-style rotary knob: a softly shaded disc with a raised rim whose top-left highlight and drop shadow stay fixed like a lit object, a small glowing indicator dot, and a 270° scale of tick marks around it (from 7:30 to 4:30 o'clock). Dragging in a circle turns only the indicator; the angle is quantized into detents so it snaps from tick to tick on a snappy spring (~180 ms) with a crisp selection haptic per click — or, with snapping off, follows the finger continuously. Ticks up to the value light up, a gradient arc traces the covered range and the centered percentage rolls with a numeric transition. Pushing past either end rubber-bands the indicator ~10° with a rigid haptic, then it springs back. Weighty, clicky and exact, like precision audio gear.",
            "170pt 硬件风旋钮：柔和明暗的圆盘与微凸边缘，左上高光与投影始终固定，像被真实光源照亮；一个发光指示点，外圈是 270° 刻度（7 点半到 4 点半）。绕圈拖动时只有指示点旋转，角度被量化为档位，以约 180 毫秒的利落弹簧逐格跳动，每格一次清脆的选择触觉；关闭吸附则连续跟手。已达刻度点亮，渐变圆弧描出范围，中央百分比滚动更新。顶到两端时指示点以橡皮筋多转约 10° 并硬朗地触感一下，松手弹回。沉稳、清脆，如精密音频设备。"
        ),
        implementation: L(
            "A DragGesture converts the touch point to an angle with atan2, clamps it to ±135° (the excess feeds a rubberBand overshoot) and rounds to a detent index; only an indicator overlay is rotated, with a snappy spring per detent, while the shaded face stays static and a trimmed Circle draws the arc.",
            "DragGesture 以 atan2 将触点换算为角度，限制在 ±135° 内（超出部分经 rubberBand 形成回弹过冲）并取整为档位索引；只旋转指示点图层，每档以利落弹簧吸附，带明暗的表盘保持静止，裁剪的 Circle 绘制进度圆弧。"
        ),
        apis: ["DragGesture", "atan2", "rotationEffect", "trim(from:to:)", "numericText"],
        tags: ["dial", "knob", "rotary", "detent", "旋钮", "刻度", "旋转", "触觉"],
        params: [
            .slider("steps", L("Detents", "档位数"), 5...21, default: 11, step: 1, decimals: 0),
            .toggle("snap", L("Snap to detents", "吸附档位"), default: true),
            .slider("response", L("Detent snap", "档位吸附时长"), 0.08...0.5, default: 0.18, unit: "s"),
            .slider("stretch", L("End-stop give", "限位回弹量"), 0...24, default: 10, decimals: 0, unit: "°"),
        ]
    ) { ctx in
        InputDialKnobDemo(ctx: ctx)
    }
}

private struct InputDialKnobDemo: View {
    let ctx: DemoContext
    @State private var index = 3
    /// Continuous knob angle, clamped to the ±135° travel.
    @State private var freeAngle: Double = -81
    /// Rubber-band rotation past an end stop (decays to 0 on release).
    @State private var overshoot: Double = 0
    @State private var atStop = false
    @State private var lastRaw: Double?
    @State private var step = 0
    /// Resets on system cancellation too (Control Center pull, incoming call), so a cancelled touch still releases.
    @GestureState private var touching = false

    private let knobSize: CGFloat = 170
    private let padSize: CGFloat = 250
    private static let previewSteps = [7, 2, 9, 5, 10, 0]

    private var snaps: Bool { ctx.bool("snap") }
    private var steps: Int { max(ctx.int("steps"), 2) }
    private var current: Int { min(index, steps - 1) }
    /// 0…1 value shown by the arc and the readout: detent-quantized with snap on, continuous with it off.
    private var fraction: Double {
        snaps ? Double(current) / Double(steps - 1) : ((freeAngle + 135) / 270).clamped(to: 0...1)
    }
    private var indicatorAngle: Double {
        (snaps ? tickAngle(current) : freeAngle) + overshoot
    }
    private var detentAnimation: Animation? {
        snaps ? .snappy(duration: ctx["response"]) : nil
    }

    private func tickAngle(_ i: Int) -> Double {
        -135 + 270 * Double(i) / Double(steps - 1)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            pad
                .scaleEffect(ctx.isPreview ? 0.84 : 1)
            Spacer(minLength: 0)
            DemoHint(text: L("Drag around the knob; push past the ends", "绕着旋钮拖动，试试顶到两端"), ctx: ctx)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 0.9, delay: 0.4) { previewTick() }
    }

    private var pad: some View {
        ZStack {
            ticks
            arc
            // The face (shading, rim, drop shadow) stays still like a lit physical object;
            // only the indicator layer rotates.
            InputDialKnobFace(size: knobSize)
            indicatorLayer
                .rotationEffect(.degrees(indicatorAngle))
                .animation(detentAnimation, value: current)
            Text("\(Int((fraction * 100).rounded()))")
                .font(.system(size: 30, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(.primary)
                .contentTransition(.numericText(value: fraction))
                .animation(snaps ? .snappy : nil, value: current)
                .allowsHitTesting(false)
        }
        .frame(width: padSize, height: padSize)
        .contentShape(Circle())
        .gesture(dragGesture)
        .onChange(of: touching) { _, isTouching in
            if !isTouching { endTurn() }
        }
    }

    private var ticks: some View {
        let lit = Int((fraction * Double(steps - 1)).rounded())
        return ZStack {
            ForEach(0..<steps, id: \.self) { i in
                Capsule()
                    .fill(i <= lit ? Palette.blue : Color.primary.opacity(0.18))
                    .frame(width: 3, height: i == lit ? 14 : 9)
                    .offset(y: -(knobSize / 2 + 30))
                    .rotationEffect(.degrees(tickAngle(i)))
                    .animation(.easeOut(duration: 0.15), value: lit)
            }
        }
    }

    private var arc: some View {
        Circle()
            .trim(from: 0, to: 0.75 * fraction)
            .stroke(
                AngularGradient(
                    gradient: Gradient(colors: [Palette.sky, Palette.blue]),
                    center: .center,
                    startAngle: .degrees(0),
                    endAngle: .degrees(270)
                ),
                style: StrokeStyle(lineWidth: 4, lineCap: .round)
            )
            .rotationEffect(.degrees(135))
            .frame(width: knobSize + 32, height: knobSize + 32)
            .animation(detentAnimation, value: current)
    }

    private var indicatorLayer: some View {
        Color.clear
            .frame(width: knobSize, height: knobSize)
            .overlay(alignment: .top) {
                VStack(spacing: 5) {
                    Circle()
                        .fill(Palette.sky)
                        .frame(width: 9, height: 9)
                        .shadow(color: Palette.sky.opacity(0.9), radius: 5)
                    Capsule()
                        .fill(Color.primary.opacity(0.12))
                        .frame(width: 2, height: 10)
                }
                .padding(.top, 16)
            }
            .allowsHitTesting(false)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($touching) { _, state, _ in state = true }
            .onChanged { value in
                let center = padSize / 2
                let dx = Double(value.location.x - center)
                let dy = Double(value.location.y - center)
                guard hypot(dx, dy) > 14 else { return }
                let raw = atan2(dx, -dy) * 180 / .pi
                // Ignore the jump across the dead zone at the bottom (±180°).
                if let last = lastRaw, abs(raw - last) > 180 { return }
                lastRaw = raw
                let angle = raw.clamped(to: -135...135)
                freeAngle = angle
                applyEndStop(raw: raw, clamped: angle)
                let newIndex = Int(((angle + 135) / 270 * Double(steps - 1)).rounded())
                if newIndex != current {
                    if snaps { Haptics.selection() }
                    index = newIndex
                }
            }
            .onEnded { _ in endTurn() }
    }

    /// Single cleanup for a lifted or cancelled finger: the indicator springs back off the end stop.
    private func endTurn() {
        guard lastRaw != nil || atStop || overshoot != 0 else { return }
        lastRaw = nil
        atStop = false
        withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) { overshoot = 0 }
    }

    /// Past either end the indicator follows with rubber-band resistance and a rigid haptic marks the stop.
    private func applyEndStop(raw: Double, clamped: Double) {
        let beyond = raw - clamped
        overshoot = Double(rubberBand(CGFloat(beyond), limit: ctx.cg("stretch")))
        let pinned = abs(beyond) > 0.5
        if pinned && !atStop { Haptics.tap(.rigid) }
        atStop = pinned
    }

    private func previewTick() {
        let target = Self.previewSteps[step % Self.previewSteps.count]
        step += 1
        index = min(target, steps - 1)
        withAnimation(.snappy(duration: 0.3)) { freeAngle = tickAngle(current) }
    }
}

private struct InputDialKnobFace: View {
    let size: CGFloat
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let light = scheme == .light
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: light
                            ? [Color.white, Color(hex: 0xDADDE6)]
                            : [Color(hex: 0x3A3D48), Color(hex: 0x1B1D24)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(light ? 0.18 : 0.5), radius: 18, x: 6, y: 12)
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(light ? 0.9 : 0.18), Color.black.opacity(light ? 0.08 : 0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
            Circle()
                .fill(
                    LinearGradient(
                        colors: light
                            ? [Color(hex: 0xE9EBF1), Color.white]
                            : [Color(hex: 0x22242C), Color(hex: 0x33363F)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(22)
        }
        .frame(width: size, height: size)
    }
}
