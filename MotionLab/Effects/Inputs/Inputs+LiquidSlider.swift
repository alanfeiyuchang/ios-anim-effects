import SwiftUI

extension Effect {
    static let inputsLiquidSlider = Effect(
        id: "inputs.liquid-slider",
        category: .inputs,
        interaction: .gesture,
        name: L("Liquid Level Slider", "液面滑块"),
        summary: L("A glass you fill by dragging; the surface sloshes with your speed and settles.", "拖动即可“倒水”的玻璃杯，液面随拖动速度晃荡后平息。"),
        prompt: L(
            "A vertical 96 × 220 pt glass with 28 pt continuous corners sits next to a daily-water readout. Dragging up or down anywhere on the glass sets the level relative to where the finger landed. The water surface is a living meniscus: two layered sine waves (front opaque sky-to-blue, back 45% lighter and phase-shifted) drift continuously with a 2 pt idle ripple. Drag velocity pumps the wave amplitude up to 12 pt; once the finger slows or lifts (80 ms debounce) it decays on an underdamped spring (response 0.8 s, damping 0.3), so the surface inverts a few times like sloshing water before calming. The litre readout rolls with numeric digits and a selection haptic ticks every 10%. Refreshing, physical, almost drinkable.",
            "一只 96 × 220pt、28pt 连续圆角的竖直玻璃杯，旁边是每日饮水读数。在杯身任意位置上下拖动，都会以手指落点为基准相对调整水位。水面是一道“活”的弯月面：两层正弦波叠加（前层为不透明的天蓝到湛蓝渐变，后层浅 45% 并错开相位），持续漂移并保留 2pt 的静态微波。拖动速度会把波幅推高到最多 12pt；手指减速或抬起（80 毫秒去抖）后，波幅以欠阻尼弹簧（响应 0.8 秒、阻尼 0.3）衰减，水面会像真的晃荡一样来回翻转几次才平息。升数读数以数字滚动更新，每跨 10% 给出一次选择触觉。清爽、有物理感，几乎能喝。"
        ),
        implementation: L(
            "A TimelineView advances the wave phase each frame while a custom Shape animates level and amplitude through AnimatablePair; DragGesture velocity sets the amplitude and a debounced Task releases it on an underdamped spring.",
            "TimelineView 每帧推进波相位，自定义 Shape 通过 AnimatablePair 对水位与波幅做插值；DragGesture 的速度设定波幅，去抖 Task 再以欠阻尼弹簧将其释放。"
        ),
        apis: ["TimelineView(.animation)", "Shape", "AnimatablePair", "DragGesture", "numericText"],
        tags: ["slider", "liquid", "wave", "water", "滑块", "液体", "波浪", "水位"],
        params: [
            .slider("amplitude", L("Max slosh", "最大晃动"), 4...20, default: 12, decimals: 0, unit: "pt"),
            .slider("damping", L("Settle damping", "平息阻尼"), 0.1...0.8, default: 0.3),
            .slider("speed", L("Wave speed", "波速"), 0.5...6, default: 2.4),
        ]
    ) { ctx in
        LiquidSliderDemo(ctx: ctx)
    }
}

private struct LiquidSliderDemo: View {
    let ctx: DemoContext
    @State private var level: Double = 0.45
    @State private var slosh: CGFloat = 0
    @State private var startLevel: Double = 0
    @State private var dragging = false
    @State private var settleTask: Task<Void, Never>?
    @State private var step = 0

    private let glassSize = CGSize(width: 96, height: 220)
    private static let previewTargets: [Double] = [0.8, 0.3, 0.62, 0.15, 0.9]

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            HStack(spacing: 26) {
                glass
                readout
            }
            Spacer(minLength: 0)
            DemoHint(text: L("Drag the glass up or down quickly", "在杯子上快速上下拖动"), ctx: ctx)
                .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.7, delay: 0.3) { previewPour() }
    }

    private var litres: Double { (level * 20).rounded() / 10 }

    private var readout: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "drop.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Palette.ocean)
            Text(L("Water today", "今日饮水"), ctx.language)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(String(format: "%.1f L", litres))
                .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.primary)
                .contentTransition(.numericText(value: litres))
                .animation(.snappy, value: litres)
            Text(L("Goal 2.0 L", "目标 2.0 L"), ctx.language)
                .font(.caption.weight(.medium))
                .foregroundStyle(.tertiary)
        }
        .frame(width: 130, alignment: .leading)
    }

    private var glass: some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)
        let maxAmp: CGFloat = ctx.cg("amplitude")
        let amp: CGFloat = 2 + slosh.clamped(to: -maxAmp...maxAmp)
        let speed: Double = ctx["speed"]
        return ZStack {
            shape.fill(Color.primary.opacity(0.05))
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let t: Double = timeline.date.timeIntervalSinceReferenceDate * speed
                ZStack {
                    LiquidLevelShape(level: CGFloat(level), amplitude: amp * 0.8, phase: t + 1.7, waves: 1.3)
                        .fill(Palette.sky.opacity(0.45))
                    LiquidLevelShape(level: CGFloat(level), amplitude: amp, phase: t, waves: 1.0)
                        .fill(LinearGradient(colors: [Palette.sky, Palette.blue], startPoint: .top, endPoint: .bottom))
                }
            }
            LinearGradient(colors: [.white.opacity(0.35), .clear], startPoint: .leading, endPoint: .center)
                .frame(width: 18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
                .padding(.vertical, 18)
                .allowsHitTesting(false)
        }
        .frame(width: glassSize.width, height: glassSize.height)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Color.primary.opacity(0.15), lineWidth: 1.5))
        .scaleEffect(dragging ? 1.03 : 1)
        .shadow(color: Palette.blue.opacity(0.18), radius: 14, y: 8)
        .contentShape(shape)
        .gesture(drag)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                if !dragging {
                    startLevel = level
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { dragging = true }
                }
                let raw: Double = startLevel - Double(gesture.translation.height / glassSize.height)
                let newLevel = raw.clamped(to: 0...1)
                if Int(newLevel * 10) != Int(level * 10) { Haptics.selection() }
                level = newLevel
                let speed: CGFloat = abs(gesture.velocity.height)
                let target: CGFloat = min(speed / 60, ctx.cg("amplitude"))
                if target > abs(slosh) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) { slosh = target }
                }
                scheduleSettle()
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { dragging = false }
                settle()
            }
    }

    private func scheduleSettle() {
        settleTask?.cancel()
        settleTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(80))
            guard !Task.isCancelled else { return }
            settle()
        }
    }

    private func settle() {
        withAnimation(.spring(response: 0.8, dampingFraction: ctx["damping"])) { slosh = 0 }
    }

    private func previewPour() {
        let target = Self.previewTargets[step % Self.previewTargets.count]
        step += 1
        withAnimation(.smooth(duration: 0.6)) { level = target }
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) { slosh = ctx.cg("amplitude") * 0.8 }
        Task {
            try? await Task.sleep(for: .seconds(0.45))
            settle()
        }
    }
}

/// Filled water body whose top edge is a sine wave.
private struct LiquidLevelShape: Shape {
    var level: CGFloat
    var amplitude: CGFloat
    var phase: Double
    var waves: Double

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(level, amplitude) }
        set {
            level = newValue.first
            amplitude = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let surface: CGFloat = rect.maxY - rect.height * level
        let step: CGFloat = 4
        var x: CGFloat = rect.minX
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        while x <= rect.maxX + step {
            let clampedX: CGFloat = min(x, rect.maxX)
            let angle: Double = Double(clampedX / rect.width) * waves * 2 * .pi + phase
            let y: CGFloat = surface + CGFloat(sin(angle)) * amplitude
            path.addLine(to: CGPoint(x: clampedX, y: y))
            x += step
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
