import SwiftUI

extension Effect {
    static let inputsDialKnob = Effect(
        id: "inputs.dial-knob",
        category: .inputs,
        interaction: .gesture,
        name: L("Detent Dial", "刻度旋钮"),
        summary: L("A rotary knob that clicks into detents with haptic ticks.", "带刻度吸附与触觉反馈的旋转旋钮。"),
        prompt: L(
            "A 170 pt hardware-style rotary knob: a softly shaded disc with a raised rim, a small glowing indicator dot, and a 270° scale of tick marks around it (from 7:30 to 4:30 o'clock). Dragging in a circle rotates the knob; the angle is quantized into detents so the indicator snaps from tick to tick on a snappy spring (~180 ms) instead of sliding, with a crisp selection haptic on every click. Ticks up to the current value light up in the accent color, a gradient arc traces the covered range, and the centered percentage rolls with a numeric transition. The travel stops firmly at both ends. It feels like precision audio gear — weighty, clicky and exact.",
            "170pt 的硬件风旋转旋钮：带柔和明暗的圆盘、微微凸起的边缘、一个发光的小指示点，外圈环绕一段 270° 的刻度（从 7 点半到 4 点半方向）。手指绕圈拖动即可旋转；角度被量化为刻度档位，指示点以约 180 毫秒的利落弹簧从一格跳到下一格，而不是连续滑动，每跳一格伴随一次清脆的选择触觉。当前值以内的刻度被点亮为强调色，一段渐变圆弧描出已覆盖的范围，中央的百分比以数字滚动过渡更新。两端有明确的限位。手感如同精密音频设备——沉稳、清脆、精确。"
        ),
        implementation: L(
            "A DragGesture converts the touch point to an angle with atan2 relative to the knob center, clamps it to ±135°, and rounds to a detent index; rotationEffect snaps to the detent angle with a snappy spring while a trimmed Circle draws the arc.",
            "DragGesture 以 atan2 将触点相对旋钮中心换算为角度，限制在 ±135° 内并取整为档位索引；rotationEffect 以利落弹簧吸附到档位角度，裁剪的 Circle 绘制进度圆弧。"
        ),
        apis: ["DragGesture", "atan2", "rotationEffect", "trim(from:to:)", "numericText"],
        tags: ["dial", "knob", "rotary", "detent", "旋钮", "刻度", "旋转", "触觉"],
        params: [
            .slider("steps", L("Detents", "档位数"), 5...21, default: 11, step: 1, decimals: 0),
            .toggle("snap", L("Snap to detents", "吸附档位"), default: true),
        ]
    ) { ctx in
        InputDialKnobDemo(ctx: ctx)
    }
}

private struct InputDialKnobDemo: View {
    let ctx: DemoContext
    @State private var index = 3
    @State private var freeAngle: Double = -81
    @State private var lastRaw: Double?
    @State private var step = 0

    private let knobSize: CGFloat = 170
    private let padSize: CGFloat = 250
    private static let previewSteps = [7, 2, 9, 5, 10, 0]

    private var steps: Int { max(ctx.int("steps"), 2) }
    private var current: Int { min(index, steps - 1) }
    private var fraction: Double { Double(current) / Double(steps - 1) }

    private func tickAngle(_ i: Int) -> Double {
        -135 + 270 * Double(i) / Double(steps - 1)
    }

    var body: some View {
        ZStack {
            ticks
            arc
            InputDialKnobFace(size: knobSize)
                .overlay(alignment: .top) { indicator }
                .rotationEffect(.degrees(ctx.bool("snap") ? tickAngle(current) : freeAngle))
                .animation(.snappy(duration: 0.18), value: current)
            Text("\(Int((fraction * 100).rounded()))")
                .font(.system(size: 30, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(.primary)
                .contentTransition(.numericText(value: fraction))
                .animation(.snappy, value: current)
                .allowsHitTesting(false)
        }
        .frame(width: padSize, height: padSize)
        .contentShape(Circle())
        .gesture(dragGesture)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 0.9, delay: 0.4) { previewTick() }
    }

    private var ticks: some View {
        ZStack {
            ForEach(0..<steps, id: \.self) { i in
                Capsule()
                    .fill(i <= current ? Palette.blue : Color.primary.opacity(0.18))
                    .frame(width: 3, height: i == current ? 14 : 9)
                    .offset(y: -(knobSize / 2 + 30))
                    .rotationEffect(.degrees(tickAngle(i)))
                    .animation(.easeOut(duration: 0.15), value: current)
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
            .animation(.snappy(duration: 0.18), value: current)
    }

    private var indicator: some View {
        Circle()
            .fill(Palette.sky)
            .frame(width: 9, height: 9)
            .shadow(color: Palette.sky.opacity(0.9), radius: 5)
            .padding(.top, 16)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let center = padSize / 2
                let dx = Double(value.location.x - center)
                let dy = Double(value.location.y - center)
                guard hypot(dx, dy) > 14 else { return }
                let raw = atan2(dx, -dy) * 180 / .pi
                if let last = lastRaw, abs(raw - last) > 180 { return }
                lastRaw = raw
                let angle = raw.clamped(to: -135...135)
                freeAngle = angle
                let newIndex = Int(((angle + 135) / 270 * Double(steps - 1)).rounded())
                if newIndex != current {
                    Haptics.selection()
                    index = newIndex
                }
            }
            .onEnded { _ in lastRaw = nil }
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
