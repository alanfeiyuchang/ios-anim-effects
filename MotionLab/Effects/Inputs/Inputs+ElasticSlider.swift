import SwiftUI

extension Effect {
    static let inputsElasticSlider = Effect(
        id: "inputs.elastic-slider",
        category: .inputs,
        interaction: .gesture,
        name: L("Stretchy Volume Slider", "弹性音量滑块"),
        summary: L("A thick slider that stretches like rubber when you drag past its ends.", "拖过两端时像橡皮一样被拉长的粗滑块。"),
        prompt: L(
            "A 56 pt-tall, 280 pt-wide rounded volume slider inside a Now Playing card, in the style of Control Center: a tinted track, a sky-to-blue fill and a speaker glyph whose waves light up with the level. Dragging is relative, so the fill follows the finger from wherever it lands, and the slider swells to 103% while touched. Pushing past either end no longer changes the value; instead the whole bar stretches along the drag axis with rubber-band resistance (up to ~24 pt), anchored at the opposite end, thinning slightly as it lengthens while the glyph grows. A medium haptic marks the moment you hit the limit. On release it snaps back on an underdamped spring (response 0.45 s, damping 0.55) with a visible wobble. Solid, physical and honest about its bounds.",
            "“正在播放”卡片里有一条 56pt 高、280pt 宽的圆角音量滑块，风格类似控制中心：浅色轨道、天蓝到湛蓝的填充，扬声器图标的声波随音量逐格点亮。拖动采用相对位移，手指落在哪里，填充就从那里跟随；按住时滑块整体膨胀到 103%。拖过任一端时数值不再变化，整条滑块改为沿拖动方向、以对侧为锚点被“拉长”，带橡皮筋阻尼（最多约 24pt），拉长的同时略微变细，图标同步放大；触及边界的瞬间给出一次中等触觉。松手后以欠阻尼弹簧（响应 0.45 秒、阻尼 0.55）弹回，带有明显的回弹晃动。扎实、有物理感，并诚实地表达边界。"
        ),
        implementation: L(
            "A DragGesture stores the value at touch-down and adds translation / width; any overflow beyond 0…1 goes through a rubber-band function into a stretch amount that drives scaleEffect(x:y:anchor:), released with a spring. The glyph uses Image(systemName:variableValue:).",
            "DragGesture 在按下时记录初始数值，再加上 位移 / 宽度；超出 0…1 的部分经橡皮筋函数换算为拉伸量，驱动 scaleEffect(x:y:anchor:)，松手时用弹簧复位。图标使用 Image(systemName:variableValue:)。"
        ),
        apis: ["DragGesture", "scaleEffect(x:y:anchor:)", "Image(systemName:variableValue:)", "spring(response:dampingFraction:)", "numericText"],
        tags: ["slider", "volume", "rubber band", "stretch", "滑块", "音量", "橡皮筋", "拉伸"],
        params: [
            .slider("limit", L("Stretch limit", "最大拉伸"), 8...40, default: 24, decimals: 0, unit: "pt"),
            .slider("response", L("Snap-back response", "回弹响应"), 0.2...0.8, default: 0.45, unit: "s"),
            .slider("damping", L("Snap-back damping", "回弹阻尼"), 0.3...1.0, default: 0.55),
        ]
    ) { ctx in
        InputElasticSliderDemo(ctx: ctx)
    }
}

private struct InputElasticSliderDemo: View {
    let ctx: DemoContext
    @State private var value: Double = 0.55
    @State private var stretch: CGFloat = 0
    @State private var pressing = false
    @State private var startValue: Double = 0
    @State private var atEdge = false
    /// Which end was hit. Stored (not derived from the sign of `stretch`) so the underdamped
    /// snap-back wobbles around the same fixed anchor instead of flipping to the opposite end.
    @State private var anchoredAtLeading = true
    @State private var step = 0

    private let width: CGFloat = 280
    private let height: CGFloat = 56

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            card
            Spacer()
            DemoHint(text: L("Drag past either end", "拖过任一端试试"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.1, delay: 0.4) { previewTick() }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "music.note")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(Palette.sunset, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("Midnight Drive", "午夜兜风"), ctx.language)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(verbatim: "Lumen · 3:42")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Text("\(Int((value * 100).rounded()))%")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText(value: value))
            }
            slider
        }
        .padding(16)
        .frame(width: width + 32)
        .demoCard(cornerRadius: 26)
    }

    private var slider: some View {
        let fillWidth = width * CGFloat(value)
        let magnitude = abs(stretch)
        // Signed along the stored edge: positive = stretched, negative = the spring's compression overshoot.
        let amount = anchoredAtLeading ? stretch : -stretch
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        return ZStack(alignment: .leading) {
            Color.primary.opacity(0.08)
            LinearGradient(colors: [Palette.sky, Palette.blue], startPoint: .leading, endPoint: .trailing)
                .frame(width: fillWidth)
            Image(systemName: "speaker.wave.3.fill", variableValue: value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(fillWidth > 46 ? Color.white : Color.secondary)
                .scaleEffect(1 + magnitude / 90)
                .padding(.leading, 16)
        }
        .frame(width: width, height: height)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Palette.stroke))
        .scaleEffect(
            x: 1 + amount / width,
            y: 1 - amount / height * 0.25,
            anchor: anchoredAtLeading ? .leading : .trailing
        )
        .scaleEffect(pressing ? 1.03 : 1)
        .shadow(color: Palette.blue.opacity(pressing ? 0.28 : 0.14), radius: pressing ? 16 : 10, y: 6)
        .contentShape(shape)
        .gesture(drag)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                if !pressing {
                    startValue = value
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { pressing = true }
                }
                let raw = startValue + Double(gesture.translation.width / width)
                value = raw.clamped(to: 0...1)
                let limit = ctx.cg("limit")
                if raw > 1 {
                    anchoredAtLeading = true
                    stretch = rubberBand(CGFloat(raw - 1) * width, limit: limit)
                } else if raw < 0 {
                    anchoredAtLeading = false
                    stretch = rubberBand(CGFloat(raw) * width, limit: limit)
                } else {
                    stretch = 0
                }
                let edge = raw >= 1 || raw <= 0
                if edge && !atEdge { Haptics.tap(.medium) }
                atEdge = edge
            }
            .onEnded { _ in release() }
    }

    private func release() {
        atEdge = false
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            stretch = 0
            pressing = false
        }
    }

    /// Preview: glide, then push past the top, glide back, push past the bottom.
    private func previewTick() {
        let phase = step % 4
        step += 1
        switch phase {
        case 0:
            withAnimation(.smooth(duration: 0.6)) { value = 0.7 }
        case 1:
            overshoot(to: 1, stretchBy: ctx.cg("limit") * 0.85)
        case 2:
            withAnimation(.smooth(duration: 0.6)) { value = 0.3 }
        default:
            overshoot(to: 0, stretchBy: -ctx.cg("limit") * 0.85)
        }
    }

    private func overshoot(to target: Double, stretchBy amount: CGFloat) {
        withAnimation(.smooth(duration: 0.35)) {
            value = target
            pressing = true
        }
        anchoredAtLeading = amount >= 0
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            withAnimation(.easeOut(duration: 0.18)) { stretch = amount }
            try? await Task.sleep(for: .seconds(0.25))
            release()
        }
    }
}
