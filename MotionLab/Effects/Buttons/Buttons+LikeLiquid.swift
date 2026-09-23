import SwiftUI

extension Effect {
    static let buttonsLikeLiquid = Effect(
        id: "buttons.like-liquid",
        category: .buttons,
        interaction: .tap,
        name: L("Liquid Heart Fill", "液态爱心注满"),
        summary: L("Liquid rises inside the heart with a sloshing wave, then the heart gulps.", "液体在爱心里带着波浪上涨，注满时爱心“咕嘟”一跳。"),
        prompt: L(
            "A 96 pt outlined heart sits in a soft circular well above a track title. On tap, pink-to-coral liquid rises inside the heart from the bottom to the brim over 0.7 s (ease-in-out). Its surface is a travelling sine wave (two crests across, 1.4 s per cycle) whose height is 5 pt mid-fill and flattens to about 1 pt as the heart empties or brims, so the liquid sloshes while moving and calms when still. When the heart is full it \"gulps\": it swells to 112%, dips to 96% and settles on a spring, the count rolls up and a success haptic fires. Tapping again drains the liquid back down on the same curve with a light haptic. Juicy, satisfying and tactile.",
            "一枚 96pt 的空心爱心放在柔和圆形凹槽中，下方是歌曲标题。点击后，粉到珊瑚色的液体在 0.7 秒内（ease-in-out）从心底涨到心口。液面是一道行进的正弦波（横向两个波峰，每 1.4 秒一个周期），波高在半满时为 5pt，接近空或满时压平到约 1pt，所以液体在涨落时晃荡、静止时平复。注满后爱心“咕嘟”一下：放大到 112%、回落到 96%，再以弹簧落定，同时计数上滚并触发成功触感。再次点击，液体沿同一曲线回落，伴随轻触感。多汁、满足、很有触感。"
        ),
        implementation: L(
            "A custom Shape whose animatableData is the fill level draws the wave surface; its amplitude is scaled by sin(π·level) inside path(in:), so it calms at the ends. A TimelineView advances the wave phase, a heart.fill symbol masks the liquid, and a delayed keyframeAnimator plays the gulp.",
            "自定义 Shape 以液面高度为 animatableData 绘制波浪液面，并在 path(in:) 内用 sin(π·高度) 调节波幅，使两端趋于平静。TimelineView 推进波浪相位，heart.fill 符号作为液体遮罩，带延迟的 keyframeAnimator 播放“咕嘟”效果。"
        ),
        apis: ["Shape.animatableData", "TimelineView", "mask", "keyframeAnimator", "numericText"],
        tags: ["like", "liquid", "fill", "wave", "点赞", "液体", "注满", "波浪"],
        params: [
            .slider("duration", L("Fill duration", "注满时长"), 0.3...1.5, default: 0.7, unit: "s"),
            .slider("amplitude", L("Wave height", "波浪高度"), 0...10, default: 5, decimals: 0, unit: "pt"),
            .slider("speed", L("Wave speed", "波浪速度"), 0.3...2.0, default: 1.0),
        ]
    ) { ctx in
        ButtonLikeLiquidDemo(ctx: ctx)
    }
}

private struct ButtonLiquidWave: Shape {
    var level: CGFloat
    var phase: CGFloat
    var amplitude: CGFloat

    var animatableData: CGFloat {
        get { level }
        set { level = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard level > 0.001 else { return path }
        let calm = CGFloat(sin(Double(level) * .pi))
        let height: CGFloat = amplitude * calm + 1
        let surface: CGFloat = rect.maxY - rect.height * level
        let steps = 40
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        for step in 0...steps {
            let t = CGFloat(step) / CGFloat(steps)
            let angle: Double = Double(t) * 4 * Double.pi + Double(phase)
            let y = surface + CGFloat(sin(angle)) * height
            path.addLine(to: CGPoint(x: rect.minX + rect.width * t, y: y))
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct ButtonLikeLiquidDemo: View {
    let ctx: DemoContext
    @State private var liked = false
    @State private var level: CGFloat = 0
    /// Set once the heart is full, so the count only rolls when the liquid reaches the brim.
    @State private var counted = false
    @State private var gulps = 0
    /// The wave clock only runs while there is liquid (or it is still draining), saving idle redraws.
    @State private var waveActive = false
    /// Bumped on every toggle so delayed follow-ups from an earlier tap are ignored.
    @State private var generation = 0

    private var count: Int { 2_318 + (counted ? 1 : 0) }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 18) {
                heartButton
                VStack(spacing: 4) {
                    Text(L("Midnight Drive", "午夜兜风"), ctx.language)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(L("\(count) likes", "\(count) 人喜欢"), ctx.language)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText(value: Double(count)))
                }
            }
            Spacer()
            DemoHint(text: L("Tap the heart", "点击爱心"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.9, delay: 0.4) { toggle() }
    }

    private var heartButton: some View {
        let fill = ctx["duration"]
        return Button(action: toggle) {
            ZStack {
                TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview), paused: !waveActive)) { timeline in
                    let t: Double = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1400)
                    let cycles: Double = t / 1.4 * ctx["speed"]
                    let phase = CGFloat(cycles * 2 * Double.pi)
                    ButtonLiquidWave(level: level, phase: phase, amplitude: ctx.cg("amplitude"))
                        .fill(LinearGradient(colors: [Palette.pink, Palette.coral], startPoint: .top, endPoint: .bottom))
                }
                .mask {
                    Image(systemName: "heart.fill")
                        .resizable()
                        .scaledToFit()
                }
                Image(systemName: "heart")
                    .resizable()
                    .scaledToFit()
                    .fontWeight(.medium)
                    .foregroundStyle(liked ? Palette.pink : Color.secondary)
            }
            .frame(width: 96, height: 96)
            .keyframeAnimator(initialValue: CGFloat(1), trigger: gulps) { content, scale in
                content.scaleEffect(scale)
            } keyframes: { _ in
                KeyframeTrack(\.self) {
                    LinearKeyframe(1, duration: fill * 0.9)
                    CubicKeyframe(1.12, duration: 0.12)
                    CubicKeyframe(0.96, duration: 0.12)
                    SpringKeyframe(1, duration: 0.4, spring: .bouncy)
                }
            }
            .frame(width: 150, height: 150)
            .background(Color.primary.opacity(0.05), in: Circle())
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(liked ? L("Unlike", "取消喜欢") : L("Like", "喜欢"), ctx.language))
    }

    private func toggle() {
        let duration = ctx["duration"]
        liked.toggle()
        generation += 1
        let current = generation
        waveActive = true
        withAnimation(.easeInOut(duration: duration)) {
            level = liked ? 1 : 0
        }
        if liked {
            gulps += 1
            let muted = Haptics.isMuted
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(duration * 0.9))
                guard generation == current, liked else { return }
                withAnimation(.snappy) { counted = true }
                if !muted { Haptics.success() }
            }
        } else {
            withAnimation(.snappy) { counted = false }
            Haptics.tap()
            // Stop the wave clock once the heart has fully drained.
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(duration + 0.1))
                guard generation == current, !liked else { return }
                waveActive = false
            }
        }
    }
}
