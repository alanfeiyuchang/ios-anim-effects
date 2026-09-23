import SwiftUI

extension Effect {
    static let inputsSegmentedSlider = Effect(
        id: "inputs.segmented-slider",
        category: .inputs,
        interaction: .gesture,
        name: L("LED Meter Slider", "LED 电平滑块"),
        summary: L("A staircase of LED segments that light up in a staggered run, with a peak-hold marker.", "阶梯状 LED 灯段依次点亮，并带峰值保持标记。"),
        prompt: L(
            "A microphone-gain control made of 20 rounded LED segments whose heights ramp from 14 to 46 pt like a volume staircase, coloured mint → amber → red along the scale. Dragging across the meter sets the level; segments switch on and off one at a time with a 15 ms stagger that runs away from the previous level, each lighting with a 120 ms ease-out, a 4% vertical pop and a coloured glow, while unlit segments recede to a faint tint. The highest level reached is held by a thin outlined peak segment that lingers 600 ms after the level falls and then fades out over 400 ms, like studio hardware. A selection haptic ticks per segment and the dB readout rolls with numeric digits. Precise, rhythmic and electronic.",
            "麦克风增益控件由 20 段圆角 LED 灯组成，高度从 14pt 递增到 46pt，像一道音量阶梯，颜色沿刻度由薄荷绿渐变到琥珀再到红色。在电平表上拖动即可设定音量；灯段以 15 毫秒错峰、从上一次的电平处向外逐段亮起或熄灭，每段以 120 毫秒缓出点亮，伴随 4% 的纵向弹起与同色辉光，未点亮的灯段退为淡淡底色。到达过的最高电平由一段细描边的峰值灯保持：电平回落后它仍停留 600 毫秒，再用 400 毫秒淡出，就像录音棚硬件。每跨一段触发一次选择触觉，dB 读数以数字滚动更新。精准、有节奏、电子感十足。"
        ),
        implementation: L(
            "Each segment has its own animation(_:value:) whose delay is its distance from the previous level times the stagger; the peak marker is a separate state that a debounced Task eases back down.",
            "每个灯段都有独立的 animation(_:value:)，延迟为它与上一电平的距离乘以错峰间隔；峰值标记是单独的状态，由去抖 Task 以缓动回落。"
        ),
        apis: ["animation(_:value:)", "DragGesture", "shadow(color:radius:)", "contentTransition(.numericText)"],
        tags: ["slider", "meter", "LED", "volume", "滑块", "电平", "音量", "分段"],
        params: [
            .slider("segments", L("Segments", "灯段数"), 10...24, default: 20, step: 1, decimals: 0),
            .slider("stagger", L("Stagger", "错峰间隔"), 0...0.05, default: 0.015, decimals: 3, unit: "s"),
            .toggle("peak", L("Peak hold", "峰值保持"), default: true),
        ]
    ) { ctx in
        SegmentedSliderDemo(ctx: ctx)
    }
}

private struct SegmentedSliderDemo: View {
    let ctx: DemoContext
    @State private var lit = 12
    @State private var previousLit = 12
    @State private var peak = 12
    @State private var peakTask: Task<Void, Never>?
    @State private var step = 0

    private let width: CGFloat = 280
    private static let previewLevels: [Double] = [0.9, 0.35, 0.7, 0.2, 1.0, 0.55]

    private var count: Int { max(ctx.int("segments"), 4) }
    private var segmentWidth: CGFloat { (width - CGFloat(count - 1) * 4) / CGFloat(count) }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            card
            Spacer()
            DemoHint(text: L("Drag across the meter", "在电平表上左右拖动"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: count) { _, newCount in
            lit = min(lit, newCount)
            previousLit = lit
            peak = lit
        }
        .autoplay(ctx.isPreview, every: 1.1, delay: 0.3) { previewTick() }
    }

    private var decibels: Int {
        let fraction = Double(lit) / Double(count)
        return Int((-60 + fraction * 60).rounded())
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "mic.fill")
                    .foregroundStyle(Palette.mint)
                Text(L("Mic gain", "麦克风增益"), ctx.language)
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
                Text("\(decibels) dB")
                    .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText(value: Double(decibels)))
                    .animation(.snappy, value: decibels)
            }
            .font(.subheadline.weight(.semibold))
            meter
        }
        .padding(18)
        .frame(width: width + 36)
        .demoCard(cornerRadius: 24)
    }

    private var meter: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(0..<count, id: \.self) { index in
                segment(index)
            }
        }
        .frame(width: width, height: 56, alignment: .bottom)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let fraction = Double(value.location.x / width).clamped(to: 0...1)
                    setLevel(Int((fraction * Double(count)).rounded(.up)))
                }
        )
    }

    private func segmentColor(_ index: Int) -> Color {
        let fraction = Double(index) / Double(max(count - 1, 1))
        if fraction > 0.82 { return Palette.red }
        if fraction > 0.6 { return Palette.amber }
        return Palette.mint
    }

    private func segment(_ index: Int) -> some View {
        let on = index < lit
        let isPeak = ctx.bool("peak") && index == peak - 1 && peak > lit
        let fraction = CGFloat(index) / CGFloat(max(count - 1, 1))
        let height: CGFloat = 14 + 32 * fraction
        let distance = on ? max(index - previousLit, 0) : max(previousLit - 1 - index, 0)
        let delay = Double(distance) * ctx["stagger"]
        let color = segmentColor(index)
        return RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(on ? color : Color.primary.opacity(0.08))
            .overlay {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .strokeBorder(Color.primary.opacity(isPeak ? 0.75 : 0), lineWidth: 1.5)
            }
            .frame(width: segmentWidth, height: height)
            .scaleEffect(y: on ? 1.04 : 1, anchor: .bottom)
            .shadow(color: color.opacity(on ? 0.55 : 0), radius: on ? 5 : 0)
            .animation(.easeOut(duration: 0.12).delay(delay), value: on)
            .animation(.easeInOut(duration: 0.4), value: isPeak)
    }

    private func setLevel(_ newValue: Int) {
        let clampedValue = newValue.clamped(to: 0...count)
        guard clampedValue != lit else { return }
        if !ctx.isPreview { Haptics.selection() }
        previousLit = lit
        lit = clampedValue
        if clampedValue > peak { peak = clampedValue }
        peakTask?.cancel()
        peakTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            peak = lit
        }
    }

    private func previewTick() {
        let target = Self.previewLevels[step % Self.previewLevels.count]
        step += 1
        setLevel(Int((target * Double(count)).rounded()))
    }
}
