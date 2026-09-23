import SwiftUI

// MARK: - Helpers

/// A phase that advances at `rate` per second and stays continuous when the rate changes,
/// so dragging a speed slider speeds the loop up instead of teleporting it.
private struct ProgressPhaseClock {
    var anchorDate = Date()
    var anchorPhase: Double = 0

    func phase(at date: Date, rate: Double) -> Double {
        anchorPhase + date.timeIntervalSince(anchorDate) * rate
    }

    mutating func rebase(at date: Date, oldRate: Double) {
        anchorPhase = phase(at: date, rate: oldRate)
        anchorDate = date
    }
}

private func progEaseInOut(_ x: Double) -> Double {
    let u = min(max(x, 0), 1)
    return u < 0.5 ? 4 * u * u * u : 1 - pow(-2 * u + 2, 3) / 2
}

private func progEaseOut(_ x: Double) -> Double {
    let u = min(max(x, 0), 1)
    return 1 - pow(1 - u, 3)
}

private func progEaseIn(_ x: Double) -> Double {
    let u = min(max(x, 0), 1)
    return u * u * u
}

/// Fake network progress: irregular chunks, smooth interpolation, then a hold.
@MainActor
private func simulateProgress(
    speed: Double,
    set: @escaping (Double) -> Void,
    current: @escaping () -> Double
) async -> Bool {
    withAnimation(.smooth(duration: 0.35)) { set(0) }
    try? await Task.sleep(for: .seconds(0.6))
    while current() < 1 {
        if Task.isCancelled { return false }
        let step = Double.random(in: 0.03...0.13) * speed
        withAnimation(.smooth(duration: 0.45)) { set(min(1, current() + step)) }
        try? await Task.sleep(for: .seconds(Double.random(in: 0.16...0.36)))
    }
    return !Task.isCancelled
}

// MARK: - Glowing gradient bar

extension Effect {
    static let loadingGlowBar = Effect(
        id: "loading.glow-bar",
        category: .loading,
        interaction: .state,
        name: L("Glowing Progress Bar", "辉光进度条"),
        summary: L("A gradient bar with a soft bloom and a traveling sheen.", "带柔和辉光与流动高光的渐变进度条。"),
        prompt: L(
            "A 250 × 8 pt capsule track at 8% label-color opacity inside a floating card, with a title on the left and a percentage on the right. Progress arrives in irregular network-like chunks; each step glides with a 0.45 s smooth, bounce-free curve while the percentage rolls digit by digit. The fill is a mint → sky → violet gradient with a blurred duplicate beneath it that blooms like a neon glow, and a white 55% sheen sweeps across the fill every 1.6 s. On completion a success haptic fires and the bar holds full. Calm, precise and quietly luxurious.",
            "悬浮卡片中有一条 250 × 8 pt 的胶囊轨道（8% 文字色），左侧为标题、右侧为百分比。进度以不规则的“网络式”分段到达，每一段以 0.45 秒无回弹的平滑曲线滑行，百分比数字逐位滚动。填充为薄荷绿 → 天蓝 → 紫罗兰渐变，下方叠一层模糊副本，像霓虹一样晕出辉光；一道 55% 白色高光每 1.6 秒扫过填充区。完成时触发成功触感并保持满格。沉静、精准，透着克制的高级感。"
        ),
        implementation: L(
            "Fill width animates with .smooth; a blurred copy provides the glow, a TimelineView-driven LinearGradient is clipped to the fill as the sheen, and the label uses numericText.",
            "填充宽度用 .smooth 动画；模糊副本提供辉光，TimelineView 驱动的线性渐变裁切在填充内作为高光，数字使用 numericText 过渡。"
        ),
        apis: ["frame(width:)", "blur(radius:)", "TimelineView", "contentTransition(.numericText)"],
        tags: ["progress bar", "upload", "glow", "neon", "进度条", "上传", "辉光", "霓虹"],
        params: [
            .slider("speed", L("Speed", "速度"), 0.4...2.5, default: 1.0),
            .slider("height", L("Thickness", "粗细"), 4...16, default: 8, decimals: 0, unit: "pt"),
            .slider("glow", L("Glow radius", "辉光半径"), 0...16, default: 8, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        GlowBarDemo(ctx: ctx)
    }
}

private struct GlowBarDemo: View {
    let ctx: DemoContext
    @State private var progress: Double
    @State private var run = 0

    init(ctx: DemoContext) {
        self.ctx = ctx
        // Still thumbnails never run `task`, so seed a representative filled frame.
        _progress = State(initialValue: ctx.isStill ? 0.68 : 0)
    }

    private let width: CGFloat = 250

    var body: some View {
        VStack(spacing: 22) {
            VStack(alignment: .leading, spacing: 14) {
                header
                GlowBarTrack(progress: progress, width: width, height: ctx.cg("height"), glow: ctx.cg("glow"), preview: ctx.isPreview)
            }
            .frame(width: width)
            .padding(22)
            .demoCard()
            DemoHint(text: L("Tap to restart", "点击重新开始"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { run += 1 }
        .task(id: run) { await play() }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Label(ctx.language == .zh ? "正在上传" : "Uploading", systemImage: "icloud.and.arrow.up")
                .font(.subheadline.weight(.semibold))
            Spacer()
            Text("\(Int((progress * 100).rounded()))%")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.secondary)
                .contentTransition(.numericText(value: progress))
        }
    }

    private func play() async {
        // Only a run the user restarted buzzes; the automatic first run stays silent.
        let live: Bool = !ctx.isPreview && run > 0
        let finished = await simulateProgress(speed: ctx["speed"], set: { progress = $0 }, current: { progress })
        guard finished else { return }
        if live { Haptics.success() }
        try? await Task.sleep(for: .seconds(1.4))
        if ctx.isPreview && !Task.isCancelled { run += 1 }
    }
}

private struct GlowBarTrack: View {
    let progress: Double
    let width: CGFloat
    let height: CGFloat
    let glow: CGFloat
    let preview: Bool

    var body: some View {
        let fillWidth = max(height, width * CGFloat(progress))
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.primary.opacity(0.08))
            Capsule()
                .fill(Palette.aurora)
                .frame(width: fillWidth)
                .blur(radius: glow)
                .opacity(0.75)
            Capsule()
                .fill(Palette.aurora)
                .overlay { BarSheen(preview: preview) }
                .clipShape(Capsule())
                .frame(width: fillWidth)
        }
        .frame(width: width, height: height)
        .opacity(progress > 0.001 ? 1 : 0.6)
    }
}

private struct BarSheen: View {
    let preview: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview))) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let x = (t / 1.6).truncatingRemainder(dividingBy: 1) * 3 - 1
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0), location: 0),
                    .init(color: .white.opacity(0.55), location: 0.5),
                    .init(color: .white.opacity(0), location: 1),
                ],
                startPoint: UnitPoint(x: x - 0.5, y: 0.5),
                endPoint: UnitPoint(x: x + 0.5, y: 0.5)
            )
        }
    }
}

// MARK: - Gradient progress ring

extension Effect {
    static let loadingProgressRing = Effect(
        id: "loading.progress-ring",
        category: .loading,
        interaction: .state,
        name: L("Gradient Progress Ring", "渐变进度环"),
        summary: L("A glowing gradient ring with a rolling percentage in the center.", "中心数字滚动、带辉光的渐变进度环。"),
        prompt: L(
            "A 170 pt ring with a 14 pt stroke on a faint track. The progress arc starts at 12 o'clock with round caps; its angular gradient (mint → sky → blue → violet) is always compressed to the filled sweep so the full spectrum is visible at every percentage, and a small white knob with a soft shadow rides the leading edge. Each progress chunk animates over 0.45 s with a smooth, non-overshooting curve while the large rounded, tabular percentage in the center rolls digit by digit and the caption switches from 'Syncing' to 'Complete'. An optional sky-blue bloom glows beneath the stroke.",
            "直径 170 pt、线宽 14 pt 的圆环，底部为淡色轨道。进度弧从 12 点方向出发、两端圆头；角向渐变（薄荷绿 → 天蓝 → 蓝 → 紫罗兰）始终压缩在已填充的弧段内，因此任何百分比下都能看到完整色谱；弧线前端骑着一颗带柔和投影的白色小圆点。每段进度用 0.45 秒无过冲的平滑曲线推进，中心的大号圆体等宽数字逐位滚动，副标题从“同步中”切换为“已完成”。可选在描边下方叠一层天蓝色辉光。"
        ),
        implementation: L(
            "An Animatable view interpolates progress each frame so the trim, the compressed AngularGradient and the knob rotation stay perfectly in sync.",
            "自定义 Animatable 视图逐帧插值进度，使 trim、压缩的角向渐变与小圆点旋转完全同步。"
        ),
        apis: ["Animatable", "AngularGradient", "trim(from:to:)", "contentTransition(.numericText)"],
        tags: ["progress ring", "circular", "percent", "sync", "进度环", "圆形进度", "百分比", "同步"],
        params: [
            .slider("speed", L("Speed", "速度"), 0.4...2.5, default: 1.0),
            .slider("width", L("Stroke", "线宽"), 6...22, default: 14, decimals: 0, unit: "pt"),
            .toggle("glow", L("Glow", "辉光"), default: true),
        ]
    ) { ctx in
        ProgressRingDemo(ctx: ctx)
    }
}

private struct ProgressRingDemo: View {
    let ctx: DemoContext
    @State private var progress: Double
    @State private var run = 0

    init(ctx: DemoContext) {
        self.ctx = ctx
        // Still thumbnails never run `task`, so seed a representative filled frame.
        _progress = State(initialValue: ctx.isStill ? 0.72 : 0)
    }

    private let size: CGFloat = 170

    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                GradientRing(progress: progress, size: size, lineWidth: ctx.cg("width"), glow: ctx.bool("glow"))
                centerLabel
            }
            .frame(width: size, height: size)
            DemoHint(text: L("Tap to restart", "点击重新开始"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { run += 1 }
        .task(id: run) { await play() }
    }

    private var centerLabel: some View {
        let done = progress >= 1
        return VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text("\(Int((progress * 100).rounded()))")
                    .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                    .contentTransition(.numericText(value: progress))
                Text("%")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Text(done ? (ctx.language == .zh ? "已完成" : "Complete") : (ctx.language == .zh ? "同步中" : "Syncing"))
                .font(.footnote.weight(.medium))
                .foregroundStyle(done ? AnyShapeStyle(Palette.green) : AnyShapeStyle(.secondary))
                .contentTransition(.opacity)
        }
    }

    private func play() async {
        // Only a run the user restarted buzzes; the automatic first run stays silent.
        let live: Bool = !ctx.isPreview && run > 0
        let finished = await simulateProgress(speed: ctx["speed"], set: { progress = $0 }, current: { progress })
        guard finished else { return }
        if live { Haptics.success() }
        try? await Task.sleep(for: .seconds(1.4))
        if ctx.isPreview && !Task.isCancelled { run += 1 }
    }
}

private struct GradientRing: View, Animatable {
    var progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    let glow: Bool

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    private let colors: [Color] = [Palette.mint, Palette.sky, Palette.blue, Palette.violet]

    var body: some View {
        let clamped = min(max(progress, 0), 1)
        let sweep = max(clamped, 0.002) * 360
        let radius = size / 2
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    AngularGradient(colors: colors, center: .center, startAngle: .degrees(0), endAngle: .degrees(sweep)),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: Palette.sky.opacity(glow ? 0.55 : 0), radius: lineWidth * 0.9)
            // Round caps drawn as dots so the gradient never wraps around the seam.
            Circle()
                .fill(colors[0])
                .frame(width: lineWidth, height: lineWidth)
                .offset(y: -radius)
                .opacity(clamped > 0.001 ? 1 : 0)
            Circle()
                .fill(colors[colors.count - 1])
                .frame(width: lineWidth, height: lineWidth)
                .overlay {
                    Circle()
                        .fill(Color.white)
                        .padding(lineWidth * 0.25)
                        .shadow(color: .black.opacity(0.25), radius: 2)
                }
                .offset(y: -radius)
                .rotationEffect(.degrees(sweep))
                .opacity(clamped > 0.001 ? 1 : 0)
        }
    }
}

// MARK: - Indeterminate linear bar

extension Effect {
    static let loadingIndeterminateBar = Effect(
        id: "loading.indeterminate-bar",
        category: .loading,
        interaction: .loop,
        name: L("Indeterminate Bar", "不确定进度条"),
        summary: L("Two segments race across a track with offset easing.", "两段色条以错位缓动在轨道上追逐。"),
        prompt: L(
            "A 240 × 5 pt capsule track sits in a card under a Wi-Fi tile whose arcs light one by one and a 'Connecting…' caption. In each 1.8 s cycle a first segment sweeps from off-track left to off-track right over 80% of the cycle, head and tail on staggered cubic ease-in-out curves, so it stretches to about a third of the track mid-flight and compresses at the edges. Half a cycle later a second segment, also 80% long, shoots out with an ease-out head and ease-in tail into a streak spanning nearly the whole track before its tail whips after it. Both use the brand gradient with a soft glow, clipped to the track, and one is always entering as the other leaves. Busy, without implying a duration.",
            "卡片里，Wi-Fi 图块的信号弧逐格点亮，下方写着“正在连接…”，再下面是一条 240 × 5 pt 的胶囊轨道。每个 1.8 秒周期里，第一段色条用 80% 的时间从轨道左外扫到右外，头尾走错开的三次缓入缓出，行至中段拉长到约三分之一、到两端又被压扁。半个周期后第二段出发，同样历时 80%：头部缓出、尾部缓入，先猛地拉成几乎横贯轨道的长光带，尾巴再“嗖”地追上。两段都填品牌渐变、带柔和辉光并裁切在轨道内，总有一段在进、一段在出。只说“在忙”，不暗示时长。"
        ),
        implementation: L(
            "A TimelineView computes eased head/tail fractions for two segments and positions capsules inside a clipped track; the Wi-Fi glyph runs symbolEffect(.variableColor.iterative).",
            "TimelineView 为两段色条计算缓动后的头尾位置，并在裁切后的轨道内摆放胶囊；Wi-Fi 图标使用 symbolEffect(.variableColor.iterative)。"
        ),
        apis: ["TimelineView", "clipShape(Capsule())", "offset(x:)", "symbolEffect(.variableColor)"],
        tags: ["indeterminate", "linear", "progress", "material", "不确定", "线性进度", "连接中", "加载条"],
        params: [
            .slider("period", L("Cycle", "周期"), 1.0...3.5, default: 1.8, decimals: 1, unit: "s"),
            .slider("height", L("Thickness", "粗细"), 3...12, default: 5, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        IndeterminateDemo(ctx: ctx)
    }
}

private struct IndeterminateDemo: View {
    let ctx: DemoContext
    private let width: CGFloat = 240

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "wifi")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .symbolEffect(.variableColor.iterative, isActive: true)
                    .frame(width: 42, height: 42)
                    .background(Palette.primary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: Palette.indigo.opacity(0.3), radius: 8, y: 4)
                VStack(alignment: .leading, spacing: 2) {
                    Text(ctx.language == .zh ? "加入 “Studio 5G”" : "Joining “Studio 5G”")
                        .font(.subheadline.weight(.semibold))
                    Text(ctx.language == .zh ? "正在连接…" : "Connecting…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            IndeterminateTrack(period: ctx["period"], width: width, height: ctx.cg("height"), preview: ctx.isPreview)
        }
        .frame(width: width)
        .padding(22)
        .demoCard()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct IndeterminateTrack: View {
    let period: Double
    let width: CGFloat
    let height: CGFloat
    let preview: Bool
    @State private var clock = ProgressPhaseClock()

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview))) { timeline in
            let u = clock.phase(at: timeline.date, rate: 1 / max(period, 0.1)).truncatingRemainder(dividingBy: 1)
            let first = IndeterminateTrack.first(u)
            let second = IndeterminateTrack.second(u)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.08))
                segment(first)
                segment(second)
            }
            .frame(width: width, height: height)
            .clipShape(Capsule())
            .shadow(color: Palette.violet.opacity(0.35), radius: 6)
        }
        .onChange(of: period) { old, _ in clock.rebase(at: .now, oldRate: 1 / max(old, 0.1)) }
    }

    private func segment(_ span: (tail: Double, head: Double)) -> some View {
        let x = CGFloat(span.tail) * width
        let w = max(0, CGFloat(span.head - span.tail) * width)
        return Capsule()
            .fill(Palette.primary)
            .frame(width: w, height: height)
            .offset(x: x)
    }

    /// Both segments run for 80% of the cycle, half a cycle apart, so their windows overlap
    /// and the track is never empty (the second segment of the previous cycle is still
    /// leaving on the right while the next first segment enters on the left).
    static func first(_ u: Double) -> (tail: Double, head: Double) {
        let v = u / 0.8
        guard v <= 1 else { return (1.2, 1.2) }
        let head = -0.1 + 1.3 * progEaseInOut(v)
        let tail = -0.1 + 1.3 * progEaseInOut((v - 0.2) / 0.8)
        return (tail, head)
    }

    static func second(_ u: Double) -> (tail: Double, head: Double) {
        let shifted = u - 0.5
        let w = (shifted - floor(shifted)) / 0.8
        guard w <= 1 else { return (-0.2, -0.2) }
        let head = -0.1 + 1.3 * progEaseOut(w)
        let tail = -0.1 + 1.3 * progEaseIn(w)
        return (tail, head)
    }
}

// MARK: - Liquid fill

extension Effect {
    static let loadingLiquidFill = Effect(
        id: "loading.liquid-fill",
        category: .loading,
        interaction: .tap,
        name: L("Liquid Fill", "液体填充"),
        summary: L("Layered waves slosh inside a circle as the level springs to a new value.", "圆形容器内波浪叠层荡漾，液面弹性变化。"),
        prompt: L(
            "A 180 pt circle container with a thin sky-blue outer ring and a 6 pt gap. Inside, two sine waves at different frequencies and phase speeds drift in opposite rhythm — a translucent back wave and a solid sky-to-blue front wave — so the surface looks like real liquid. When the target level changes, the water line rises or drops on an under-damped spring (response 1.1 s, damping 0.7), overshooting and sloshing before settling, while the centered rounded percentage counts along. The number is two-tone: blue above the water, white where the liquid covers it.",
            "直径 180 pt 的圆形容器，外圈是一条细天蓝描边，与内部留 6 pt 间隙。容器内两道频率与相位速度不同的正弦波交错漂移——后层半透明，前层为天蓝到蓝的实色渐变——使液面宛如真实流体。目标液位变化时，水面以欠阻尼弹簧（响应 1.1 秒、阻尼 0.7）上涨或回落，先冲过头再晃荡着稳定，中心的圆体百分比同步计数。数字为双色：水面以上是蓝色，被液体淹没的部分变为白色。"
        ),
        implementation: L(
            "An Animatable view interpolates the level; a TimelineView advances wave phases; the white label is masked by the front wave shape.",
            "Animatable 视图插值液位，TimelineView 推进波浪相位，白色数字以前层波浪形状作遮罩。"
        ),
        apis: ["Shape", "Animatable", "TimelineView", "mask"],
        tags: ["liquid", "wave", "water", "fill", "液体", "波浪", "水位", "进度"],
        params: [
            .slider("amplitude", L("Wave height", "波高"), 2...16, default: 7, decimals: 0, unit: "pt"),
            .slider("speed", L("Wave speed", "波速"), 0.3...2.5, default: 1.0),
        ]
    ) { ctx in
        LiquidFillDemo(ctx: ctx)
    }
}

private struct LiquidFillDemo: View {
    let ctx: DemoContext
    @State private var step = 1
    @State private var clock = ProgressPhaseClock()

    private let levels: [Double] = [0.28, 0.64, 0.9, 0.46]

    var body: some View {
        let level = levels[step % levels.count]
        VStack(spacing: 20) {
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                LiquidOrb(
                    level: level,
                    time: clock.phase(at: timeline.date, rate: ctx["speed"]),
                    amplitude: ctx.cg("amplitude"),
                    size: 180
                )
            }
            DemoHint(text: L("Tap to change the level", "点击改变液位"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { advance() }
        .autoplay(ctx.isPreview, every: 2.4) { advance() }
        .onChange(of: ctx["speed"]) { old, _ in clock.rebase(at: .now, oldRate: old) }
    }

    private func advance() {
        withAnimation(.spring(response: 1.1, dampingFraction: 0.7)) { step += 1 }
        if !ctx.isPreview { Haptics.tap(.soft) }
    }
}

private struct LiquidOrb: View, Animatable {
    var level: Double
    let time: Double
    let amplitude: CGFloat
    let size: CGFloat

    var animatableData: Double {
        get { level }
        set { level = newValue }
    }

    var body: some View {
        let front = LiquidWave(level: level, phase: time * 2.3, amplitude: amplitude, frequency: 1.1)
        let percent = Int((min(max(level, 0), 1) * 100).rounded())
        ZStack {
            Circle().fill(Palette.sky.opacity(0.1))
            LiquidWave(level: level, phase: -time * 1.7 + 1.8, amplitude: amplitude * 0.8, frequency: 0.8)
                .fill(Palette.sky.opacity(0.45))
            front
                .fill(LinearGradient(colors: [Palette.sky, Palette.blue], startPoint: .top, endPoint: .bottom))
            label(percent)
                .foregroundStyle(Palette.blue)
            label(percent)
                .foregroundStyle(Color.white)
                .frame(width: size, height: size)
                .mask { front }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .padding(6)
        .overlay { Circle().stroke(Palette.sky.opacity(0.55), lineWidth: 2.5) }
    }

    private func label(_ value: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text("\(value)")
                .font(.system(size: 42, weight: .bold, design: .rounded).monospacedDigit())
            Text("%")
                .font(.system(size: 20, weight: .bold, design: .rounded))
        }
    }
}

private struct LiquidWave: Shape {
    var level: Double
    var phase: Double
    var amplitude: CGFloat
    var frequency: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let baseY = rect.maxY - rect.height * CGFloat(level)
        let steps = 48
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        for index in 0...steps {
            let rel = Double(index) / Double(steps)
            let x = rect.minX + rect.width * CGFloat(rel)
            let y = baseY + amplitude * CGFloat(sin(rel * 2 * .pi * frequency + phase))
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
