import SwiftUI

extension Effect {
    static let inputsDrumSlider = Effect(
        id: "inputs.drum-slider",
        category: .inputs,
        interaction: .gesture,
        name: L("3D Drum Ruler", "3D 滚筒刻度尺"),
        summary: L("A ruler wrapped around a cylinder that you spin and fling, landing on whole values.", "包裹在圆柱上的刻度尺，可拨动、甩动，最终停在整数上。"),
        prompt: L(
            "A target-weight picker: a horizontal ruler printed on a 3D drum under a fixed coral index line. Each 1 kg tick sits 6° apart on a 150 pt-radius cylinder, so ticks are spaced ~16 pt at the centre and compress, narrow (cosine foreshortening) and fade toward the edges where the surface curves away; 5 kg ticks are taller and 10 kg ticks carry labels. Dragging rotates the drum 1:1 under the finger with a selection haptic per kilogram; releasing flings it using the gesture's predicted end translation, and the drum decelerates and lands exactly on a whole value on a spring (response 0.7 s, damping 0.82). The big readout counts every value the drum passes. Mechanical, dimensional, satisfying to spin.",
            "目标体重选择器：一把横向刻度尺印在一只 3D 滚筒上，上方是固定的珊瑚色指针线。每 1 kg 一格，在半径 150pt 的圆柱上间隔 6°，因此中心处刻度间距约 16pt，越往两侧越密、越窄（余弦透视压缩）并逐渐淡出，仿佛表面向后弯去；5 kg 刻度更长，10 kg 刻度带数字。拖动时滚筒随手指 1:1 转动，每过 1 kg 触发一次选择触觉；松手后按手势预测的终点位移甩出，滚筒减速并以弹簧（响应 0.7 秒、阻尼 0.82）精确停在整数上。大号读数会逐一数过滚筒经过的每个值。机械、立体，转起来很过瘾。"
        ),
        implementation: L(
            "An Animatable view receives the value as animatableData and positions each visible tick at x = R·sin θ with cos θ scale and opacity; DragGesture.predictedEndTranslation picks the landing value, animated with a spring so every frame re-lays the drum.",
            "Animatable 视图以 animatableData 接收数值，把每个可见刻度放在 x = R·sin θ 处，并以 cos θ 设置缩放与透明度；DragGesture.predictedEndTranslation 决定落点，用弹簧动画让每一帧重新排布滚筒。"
        ),
        apis: ["Animatable", "DragGesture.predictedEndTranslation", "scaleEffect(x:y:)", "mask", "spring(response:dampingFraction:)"],
        tags: ["slider", "ruler", "drum", "3D", "滑块", "刻度尺", "滚筒", "惯性"],
        params: [
            .slider("curve", L("Degrees per tick", "每格角度"), 3...10, default: 6, decimals: 1, unit: "°"),
            .toggle("momentum", L("Fling momentum", "惯性甩动"), default: true),
            .slider("damping", L("Landing damping", "落定阻尼"), 0.4...1.0, default: 0.82),
        ]
    ) { ctx in
        DrumSliderDemo(ctx: ctx)
    }
}

private struct DrumSliderDemo: View {
    let ctx: DemoContext
    @State private var value: Double = 68
    @State private var startValue: Double = 68
    @State private var dragging = false
    @State private var step = 0

    private let radius: CGFloat = 150
    private let range: ClosedRange<Double> = 40...120
    private static let previewTargets: [Double] = [82, 57, 74, 63, 91]

    private var pointsPerTick: CGFloat {
        radius * CGFloat(sin(ctx["curve"] * .pi / 180))
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 14) {
                Text(L("Target weight", "目标体重"), ctx.language)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                DrumRuler(value: value, degreesPerTick: ctx["curve"], radius: radius, range: range)
                    .frame(width: 300, height: 130)
                    .contentShape(Rectangle())
                    .gesture(drag)
            }
            .padding(.vertical, 18)
            .demoCard(cornerRadius: 26)
            Spacer()
            DemoHint(text: L("Drag or fling the ruler", "拖动或甩动刻度尺"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.9, delay: 0.3) { previewFling() }
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                if !dragging {
                    dragging = true
                    startValue = value
                }
                let raw: Double = startValue - Double(gesture.translation.width / pointsPerTick)
                let newValue = raw.clamped(to: range)
                if Int(newValue.rounded()) != Int(value.rounded()) { Haptics.selection() }
                value = newValue
            }
            .onEnded { gesture in
                dragging = false
                let travel: CGFloat = ctx.bool("momentum") ? gesture.predictedEndTranslation.width : gesture.translation.width
                let projected: Double = startValue - Double(travel / pointsPerTick)
                let target: Double = projected.rounded().clamped(to: range)
                withAnimation(.spring(response: 0.7, dampingFraction: ctx["damping"])) { value = target }
            }
    }

    private func previewFling() {
        let target = Self.previewTargets[step % Self.previewTargets.count]
        step += 1
        withAnimation(.spring(response: 0.9, dampingFraction: ctx["damping"])) { value = target }
    }
}

/// The drum re-lays its ticks for every interpolated value, so flings roll along the cylinder.
private struct DrumRuler: View, Animatable {
    var value: Double
    let degreesPerTick: Double
    let radius: CGFloat
    let range: ClosedRange<Double>

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    private var visibleTicks: [Int] {
        let span: Double = 88 / degreesPerTick
        let lo = Int((value - span).rounded(.down)).clamped(to: Int(range.lowerBound)...Int(range.upperBound))
        let hi = Int((value + span).rounded(.up)).clamped(to: Int(range.lowerBound)...Int(range.upperBound))
        return lo <= hi ? Array(lo...hi) : []
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(value.rounded()))")
                    .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.primary)
                Text(verbatim: "kg")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            ZStack {
                ForEach(visibleTicks, id: \.self) { index in
                    tick(index)
                }
                Capsule()
                    .fill(Palette.coral)
                    .frame(width: 3, height: 52)
                    .shadow(color: Palette.coral.opacity(0.5), radius: 4)
            }
            .frame(width: 300, height: 62)
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.22),
                        .init(color: .black, location: 0.78),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
    }

    private func tick(_ index: Int) -> some View {
        let theta: Double = (Double(index) - value) * degreesPerTick * .pi / 180
        let facing: Double = max(cos(theta), 0)
        let x: CGFloat = radius * CGFloat(sin(theta))
        let major = index % 5 == 0
        let labelled = index % 10 == 0
        return VStack(spacing: 4) {
            Capsule()
                .fill(Color.primary.opacity(major ? 0.7 : 0.35))
                .frame(width: major ? 2.5 : 1.5, height: major ? 30 : 18)
            Text("\(index)")
                .font(.system(size: 12, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(.secondary)
                .opacity(labelled ? 1 : 0)
        }
        .frame(height: 52, alignment: .top)
        .scaleEffect(x: CGFloat(max(facing, 0.05)), y: 1)
        .opacity(facing * facing)
        .offset(x: x)
    }
}
