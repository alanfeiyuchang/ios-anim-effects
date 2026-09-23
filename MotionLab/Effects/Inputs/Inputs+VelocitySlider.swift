import SwiftUI

extension Effect {
    static let inputsVelocitySlider = Effect(
        id: "inputs.velocity-slider",
        category: .inputs,
        interaction: .gesture,
        name: L("Elastic Value Slider", "惯性气泡滑块"),
        summary: L("A value bubble that swings and stretches with drag velocity.", "数值气泡随拖动速度摆动、拉伸。"),
        prompt: L(
            "A compact \"Layer opacity\" card, sized to its track, holding a slim 8 pt track with a sky-to-blue fill, a white 28 pt thumb and a row of fine ticks (every 10%) that light up as the fill passes them. While dragging, the thumb grows to 115% and a rounded value bubble with a small pointer rises 10 pt above it, showing the percentage in monospaced digits. The bubble hangs from its pointer like a pendulum: horizontal drag velocity tilts it against the motion (up to ±30°) and stretches it slightly wider and shorter, chased by a loose spring (response 0.3 s, damping 0.5). As the finger slows, pauses for ~80 ms or lifts, the bubble swings back upright with a visible wobble (damping 0.45) and settles; a selection haptic ticks every 10%. Playful and physical, yet the number stays perfectly legible.",
            "“图层不透明度”卡片里是一条 8pt 细轨道，天蓝到湛蓝填充，28pt 白色滑块，下方每 10% 一根刻度随填充点亮。拖动时滑块放大到 115%，上方升起一个带尖角的圆角数值气泡（上移 10pt），以等宽数字显示百分比。气泡像挂在尖角上的钟摆：水平速度让它逆着运动方向倾斜（最多 ±30°）并略微拉宽压扁，由较松的弹簧（响应 0.3 秒、阻尼 0.5）追随。手指减速、停约 80 毫秒或抬起时，气泡带着摇摆（阻尼 0.45）回正；每跨 10% 触发选择触觉。"
        ),
        implementation: L(
            "A DragGesture maps location to value and reads value.velocity to set a tilt/stretch state through a spring; rotationEffect and scaleEffect anchored at the bubble's pointer make it swing like a pendulum.",
            "DragGesture 将位置映射为数值，并读取 value.velocity 通过弹簧设置倾斜与拉伸状态；以气泡尖角为锚点的 rotationEffect 与 scaleEffect 让它像钟摆一样摆动。"
        ),
        apis: ["DragGesture", "velocity", "rotationEffect(anchor:)", "scaleEffect(x:y:anchor:)", "monospacedDigit"],
        tags: ["slider", "velocity", "bubble", "tooltip", "滑块", "气泡", "速度", "拖动"],
        params: [
            .slider("sensitivity", L("Swing sensitivity", "摆动灵敏度"), 0.2...2.0, default: 1.0),
            .slider("damping", L("Settle damping", "回正阻尼"), 0.2...1.0, default: 0.45),
            .toggle("stretch", L("Stretch bubble", "气泡拉伸"), default: true),
        ]
    ) { ctx in
        InputVelocitySliderDemo(ctx: ctx)
    }
}

private struct InputVelocitySliderDemo: View {
    let ctx: DemoContext
    @State private var value: Double = 0.4
    @State private var tilt: Double = 0
    @State private var dragging = false
    @State private var step = 0
    @State private var settleTask: Task<Void, Never>?

    private let width: CGFloat = 260
    private static let previewTargets: [Double] = [0.82, 0.22, 0.64, 0.1, 0.5]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            card
            Spacer()
            DemoHint(text: L("Drag fast, then stop", "快速拖动后停下"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.5, delay: 0.3) { previewMove() }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "circle.lefthalf.filled")
                    .foregroundStyle(Palette.blue)
                Text(L("Layer opacity", "图层不透明度"), ctx.language)
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
            }
            .font(.subheadline.weight(.semibold))
            slider
                .padding(.top, 62)
            HStack(spacing: 0) {
                ForEach(0..<11, id: \.self) { tick in
                    Capsule()
                        .fill(Double(tick) / 10 <= value + 0.001 ? Palette.blue.opacity(0.5) : Color.primary.opacity(0.14))
                        .frame(width: 1.5, height: tick % 5 == 0 ? 8 : 4)
                    if tick < 10 { Spacer(minLength: 0) }
                }
            }
            .frame(width: width, height: 8, alignment: .top)
            .padding(.top, 2)
            HStack {
                Text(verbatim: "0%")
                Spacer(minLength: 0)
                Text(verbatim: "100%")
            }
            .font(.caption2.weight(.medium).monospacedDigit())
            .foregroundStyle(.tertiary)
            .frame(width: width)
            .padding(.top, 4)
        }
        // Constrain the column to the track so the card hugs the slider instead of the stage width.
        .frame(width: width, alignment: .leading)
        .padding(18)
        .demoCard(cornerRadius: 24)
    }

    private var slider: some View {
        let x = width * CGFloat(value)
        // Keep the bubble body inside the card (18 pt padding either side); the pointer keeps aiming at the thumb.
        let bubbleX = x.clamped(to: 22...(width - 22))
        return ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.primary.opacity(0.1))
                .frame(height: 8)
            Capsule()
                .fill(LinearGradient(colors: [Palette.sky, Palette.blue], startPoint: .leading, endPoint: .trailing))
                .frame(width: max(8, x), height: 8)
            Circle()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
                .frame(width: 28, height: 28)
                .scaleEffect(dragging ? 1.15 : 1)
                .offset(x: x - 14)
            InputValueBubble(
                percent: Int((value * 100).rounded()),
                tilt: tilt,
                stretch: ctx.bool("stretch") ? min(abs(tilt) / 30, 1) * 0.12 : 0,
                raised: dragging,
                pointerShift: x - bubbleX
            )
            .offset(x: bubbleX - 32, y: -52)
        }
        .frame(width: width, height: 44)
        .contentShape(Rectangle())
        .gesture(drag)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                let newValue = Double(gesture.location.x / width).clamped(to: 0...1)
                if Int(newValue * 10) != Int(value * 10) { Haptics.selection() }
                value = newValue
                let swing = -Double(gesture.velocity.width) / 40 * ctx["sensitivity"]
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    dragging = true
                    tilt = swing.clamped(to: -30...30)
                }
                scheduleRest()
            }
            .onEnded { _ in
                settleTask?.cancel()
                settle()
            }
    }

    /// DragGesture only reports movement, so a finger that stops keeps its last velocity.
    /// An ~80 ms debounce treats "no new events" as "stopped" and swings the bubble upright.
    private func scheduleRest() {
        settleTask?.cancel()
        settleTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(80))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: ctx["damping"])) {
                tilt = 0
            }
        }
    }

    private func settle() {
        withAnimation(.spring(response: 0.5, dampingFraction: ctx["damping"])) {
            tilt = 0
            dragging = false
        }
    }

    private func previewMove() {
        let target = Self.previewTargets[step % Self.previewTargets.count]
        step += 1
        let direction: Double = target > value ? 1 : -1
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            dragging = true
            tilt = -direction * 22 * ctx["sensitivity"].clamped(to: 0.2...1.3)
        }
        withAnimation(.smooth(duration: 0.7)) { value = target }
        Task {
            try? await Task.sleep(for: .seconds(0.6))
            settle()
        }
    }
}

private struct InputValueBubble: View {
    let percent: Int
    let tilt: Double
    let stretch: Double
    let raised: Bool
    /// Horizontal distance from the bubble's centre to the thumb (non-zero near the track ends).
    var pointerShift: CGFloat = 0

    var body: some View {
        let shift = pointerShift.clamped(to: -24...24)
        let pivot = UnitPoint(x: 0.5 + shift / 64, y: 1)
        VStack(spacing: -1) {
            Text("\(percent)%")
                .font(.system(size: 16, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
                .frame(width: 64, height: 34)
                .background(Palette.blue, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            InputBubblePointer()
                .fill(Palette.blue)
                .frame(width: 14, height: 8)
                .offset(x: shift)
        }
        .scaleEffect(x: 1 + stretch, y: 1 - stretch * 0.6, anchor: pivot)
        .rotationEffect(.degrees(tilt), anchor: pivot)
        .scaleEffect(raised ? 1 : 0.85, anchor: pivot)
        .offset(y: raised ? -10 : 0)
        .shadow(color: Palette.blue.opacity(0.3), radius: 10, y: 6)
    }
}

private struct InputBubblePointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
