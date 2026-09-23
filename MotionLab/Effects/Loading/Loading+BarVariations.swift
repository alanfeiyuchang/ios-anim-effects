import SwiftUI

// MARK: - Helpers

/// Fake network progress in irregular chunks. `onStep` fires after every chunk.
@MainActor
private func barVarSimulate(
    speed: Double,
    set: @escaping (Double) -> Void,
    current: @escaping () -> Double,
    onStep: @escaping () -> Void = {}
) async -> Bool {
    withAnimation(.smooth(duration: 0.35)) { set(0) }
    try? await Task.sleep(for: .seconds(0.7))
    while current() < 1 {
        if Task.isCancelled { return false }
        let step: Double = Double.random(in: 0.04...0.14) * speed
        withAnimation(.smooth(duration: 0.45)) { set(min(1, current() + step)) }
        onStep()
        try? await Task.sleep(for: .seconds(Double.random(in: 0.22...0.42)))
    }
    return !Task.isCancelled
}

private struct BarVarHeader: View {
    let symbol: String
    let title: String
    let value: Double
    var done: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Label(title, systemImage: done ? "checkmark.circle.fill" : symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(done ? AnyShapeStyle(Palette.green) : AnyShapeStyle(.primary))
                .contentTransition(.symbolEffect(.replace))
            Spacer()
            Text("\(Int((value * 100).rounded()))%")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.secondary)
                .contentTransition(.numericText(value: value))
        }
    }
}

// MARK: - LED segment bar

extension Effect {
    static let loadingSegmentBar = Effect(
        id: "loading.segment-bar",
        category: .loading,
        interaction: .state,
        name: L("LED Segment Bar", "LED 分段进度条"),
        summary: L("Twenty discrete cells light up one by one with a springy pop and a tick.", "二十个独立格子逐个点亮，带弹性跳动与细微触感。"),
        prompt: L(
            "A backup card shows a title, a rolling percentage and a row of 20 rounded 10 × 24 pt cells with 3 pt gaps. Unlit cells sit at 8% label color and 55% height. As progress arrives in irregular chunks, each newly covered cell snaps to full height on an under-damped spring (response 0.32 s, damping 0.5) so it pops past 100% and settles, brightens into a mint → sky → indigo gradient across the row, and a selection haptic ticks for every cell. The last lit cell glows softly as the leading edge. On completion the whole row flashes once in green. Digital, countable, satisfying.",
            "备份卡片中有标题、滚动的百分比，以及一排 20 个 10 × 24 pt 的圆角格子，间距 3 pt。未点亮的格子为 8% 文字色、高度 55%。进度以不规则分段到达，每个新覆盖的格子以欠阻尼弹簧（响应 0.32 秒、阻尼 0.5）跳到满高度，先冲过 100% 再落定，同时亮起沿整排从薄荷绿 → 天蓝 → 靛蓝过渡的颜色，每亮一格伴随一次选择触感。最新点亮的格子作为前沿带柔光。完成时整排统一闪一次绿色。数字感强、可数、令人满足。"
        ),
        implementation: L(
            "Each cell compares its index with progress × count; the lit flag drives a spring on frame height and color, and onChange of the lit count plays Haptics.selection().",
            "每个格子比较自身序号与 进度 × 格数；点亮标志以弹簧驱动高度与颜色，onChange 监听点亮数并调用 Haptics.selection()。"
        ),
        apis: ["spring(response:dampingFraction:)", "onChange(of:)", "contentTransition(.numericText)", "UISelectionFeedbackGenerator"],
        tags: ["segmented", "led", "cells", "steps", "分段", "格子", "进度条", "备份"],
        params: [
            .slider("count", L("Cells", "格数"), 10...28, default: 20, step: 1, decimals: 0),
            .slider("speed", L("Speed", "速度"), 0.4...2.5, default: 1.0),
            .slider("damping", L("Pop damping", "跳动阻尼"), 0.3...1.0, default: 0.5),
        ]
    ) { ctx in
        SegmentBarDemo(ctx: ctx)
    }
}

/// Interpolates evenly spaced hex colour stops at `f` (0…1) in sRGB.
private func segmentBarColor(_ stops: [UInt32], at f: Double) -> Color {
    let u: Double = min(max(f, 0), 1) * Double(stops.count - 1)
    let i: Int = min(Int(u), stops.count - 2)
    let t: Double = u - Double(i)
    let a: UInt32 = stops[i]
    let b: UInt32 = stops[i + 1]
    let r: Double = Double((a >> 16) & 0xFF) + (Double((b >> 16) & 0xFF) - Double((a >> 16) & 0xFF)) * t
    let g: Double = Double((a >> 8) & 0xFF) + (Double((b >> 8) & 0xFF) - Double((a >> 8) & 0xFF)) * t
    let bl: Double = Double(a & 0xFF) + (Double(b & 0xFF) - Double(a & 0xFF)) * t
    return Color(.sRGB, red: r / 255, green: g / 255, blue: bl / 255, opacity: 1)
}

private struct SegmentBarDemo: View {
    let ctx: DemoContext
    @State private var progress: Double
    @State private var run = 0
    @State private var flash = false

    init(ctx: DemoContext) {
        self.ctx = ctx
        // Still thumbnails never run `task`, so seed a representative filled frame.
        _progress = State(initialValue: ctx.isStill ? 0.65 : 0)
    }

    var body: some View {
        let count: Int = max(ctx.int("count"), 2)
        let lit: Int = Int((progress * Double(count)).rounded(.down))
        let zh = ctx.language == .zh
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                BarVarHeader(symbol: "externaldrive.fill", title: zh ? "正在备份" : "Backing up", value: progress, done: progress >= 1)
                SegmentRow(count: count, lit: lit, damping: ctx["damping"], flash: flash)
                Text(verbatim: "iPhone · 12.4 GB")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 262)
            .padding(20)
            .demoCard()
            DemoHint(text: L("Tap to restart", "点击重新开始"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { run += 1 }
        .onChange(of: lit) { old, new in
            // Only a run the user restarted ticks; the automatic first run stays silent.
            guard new > old && !ctx.isPreview && run > 0 else { return }
            // One tick per newly lit cell, 30 ms apart, even when a chunk lights several at once.
            Task {
                for step in 0..<(new - old) {
                    if step > 0 { try? await Task.sleep(for: .milliseconds(30)) }
                    Haptics.selection()
                }
            }
        }
        .task(id: run) { await play() }
    }

    private func play() async {
        let live: Bool = !ctx.isPreview && run > 0
        flash = false
        let done = await barVarSimulate(speed: ctx["speed"], set: { progress = $0 }, current: { progress })
        guard done else { return }
        try? await Task.sleep(for: .seconds(0.4))
        // A restart cancels this task; stop so the stale finale can't flash the new run.
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: 0.25)) { flash = true }
        if live { Haptics.success() }
        try? await Task.sleep(for: .seconds(0.35))
        guard !Task.isCancelled else { return }
        withAnimation(.easeIn(duration: 0.4)) { flash = false }
        try? await Task.sleep(for: .seconds(1.2))
        if ctx.isPreview && !Task.isCancelled { run += 1 }
    }
}

private struct SegmentRow: View {
    let count: Int
    let lit: Int
    let damping: Double
    let flash: Bool

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<count, id: \.self) { index in
                cell(index)
            }
        }
        .frame(height: 24)
    }

    /// Mint → sky → indigo, interpolated across the row.
    private func color(_ index: Int) -> Color {
        let f: Double = Double(index) / Double(max(count - 1, 1))
        return segmentBarColor([0x21D4A8, 0x3AC4FF, 0x6E7BFF], at: f)
    }

    private func cell(_ index: Int) -> some View {
        let on: Bool = index < lit
        let head: Bool = on && index == lit - 1
        let fill: Color = flash ? Palette.green : (on ? color(index) : Color.primary.opacity(0.08))
        return RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(fill)
            .frame(maxWidth: .infinity)
            .frame(height: on ? 24 : 13)
            .shadow(color: color(index).opacity(head ? 0.7 : 0), radius: 6)
            .animation(.spring(response: 0.32, dampingFraction: damping), value: on)
    }
}

// MARK: - Liquid wave bar

extension Effect {
    static let loadingLiquidBar = Effect(
        id: "loading.liquid-bar",
        category: .loading,
        interaction: .tap,
        name: L("Liquid Slosh Bar", "液体晃动进度条"),
        summary: L("A water-filled capsule whose wavy front sloshes every time you add more.", "装满水的胶囊进度条，每次加水前沿都会晃荡。"),
        prompt: L(
            "A 264 × 44 pt capsule in a hydration card holds sky-to-blue water whose leading edge is a living meniscus: a vertical sine wave with a 5 pt amplitude that drifts continuously. Tapping '+ 250 ml' moves the level 1/8 of the way on a spring (response 0.6 s, damping 0.7) and kicks 14 pt of extra amplitude into the wave, which decays exponentially over about 1.2 s — a slosh that settles. Small bubbles rise and wobble inside the water only. The liter readout rolls, and when the goal is reached the card's check fills green with a success haptic; the next tap drains it smoothly. Fresh, physical, rewarding.",
            "一张饮水卡片中有一枚 264 × 44 pt 的胶囊，装着天蓝到蓝色的水，水的前沿是一道活的弯液面：振幅 5 pt 的竖向正弦波持续漂移。点击“+ 250 ml”，水位以弹簧（响应 0.6 秒、阻尼 0.7）前进 1/8，同时给波浪额外注入 14 pt 振幅，再在约 1.2 秒内指数衰减——像水晃了一下又平静下来。小气泡只在水中上升、左右摇摆。升数读数滚动变化，达到目标时卡片上的对勾变成绿色并伴随成功触感；再次点击会平滑排空。清新、有物理感、令人满足。"
        ),
        implementation: L(
            "An Animatable Shape interpolates the fill level while a TimelineView supplies the wave phase and the decaying slosh amplitude (exp of time since the last tap); bubbles are masked by the same shape.",
            "Animatable Shape 插值水位，TimelineView 提供波浪相位与随上次点击时间指数衰减的晃动振幅；气泡用同一形状做遮罩。"
        ),
        apis: ["Shape", "animatableData", "TimelineView", "mask", "spring(response:dampingFraction:)"],
        tags: ["liquid", "water", "wave", "slosh", "液体", "水", "波浪", "进度条"],
        params: [
            .slider("slosh", L("Slosh amplitude", "晃动幅度"), 4...24, default: 14, decimals: 0, unit: "pt"),
            .slider("decay", L("Settle time", "平复时间"), 0.4...3.0, default: 1.2, decimals: 1, unit: "s"),
            .slider("wave", L("Resting wave", "静息波幅"), 0...10, default: 5, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        LiquidBarDemo(ctx: ctx)
    }
}

private struct LiquidBarDemo: View {
    let ctx: DemoContext
    @State private var glasses = 0
    @State private var kick = Date.distantPast

    private let goal = 8

    var body: some View {
        let zh = ctx.language == .zh
        let level: Double = Double(glasses) / Double(goal)
        let done = glasses >= goal
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 14) {
                header(zh: zh, level: level, done: done)
                LiquidBarTrack(
                    level: level,
                    kick: kick,
                    slosh: ctx.cg("slosh"),
                    decay: max(ctx["decay"], 0.1),
                    rest: ctx.cg("wave"),
                    preview: ctx.isPreview
                )
                .frame(width: 264, height: 44)
                Button(action: addGlass) {
                    Label(done ? (zh ? "重新开始" : "Start over") : "+ 250 ml", systemImage: done ? "arrow.counterclockwise" : "drop.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Palette.ocean, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .frame(width: 264)
            .padding(18)
            .demoCard()
            DemoHint(text: L("Tap + 250 ml", "点击 +250 ml"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.4, delay: 0.5) { addGlass() }
    }

    private func header(zh: Bool, level: Double, done: Bool) -> some View {
        let liters: Double = Double(glasses) * 0.25
        return HStack(alignment: .firstTextBaseline) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(done ? AnyShapeStyle(Palette.green) : AnyShapeStyle(Color.secondary))
                .contentTransition(.symbolEffect(.replace))
            Text(zh ? "今日饮水" : "Water today")
                .font(.subheadline.weight(.semibold))
            Spacer()
            Text(String(format: "%.2f / 2.00 L", liters))
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.secondary)
                .contentTransition(.numericText(value: liters))
        }
    }

    private func addGlass() {
        if glasses >= goal {
            withAnimation(.smooth(duration: 0.8)) { glasses = 0 }
            kick = .now
            return
        }
        kick = .now
        let next = glasses + 1
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { glasses = next }
        if next >= goal {
            if !ctx.isPreview { Haptics.success() }
        } else if !ctx.isPreview {
            Haptics.tap(.soft)
        }
    }
}

private struct LiquidBarTrack: View {
    let level: Double
    let kick: Date
    let slosh: CGFloat
    let decay: Double
    let rest: CGFloat
    let preview: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview))) { timeline in
            let now: Date = timeline.date
            let t: Double = now.timeIntervalSinceReferenceDate
            let since: Double = max(0, now.timeIntervalSince(kick))
            let extra: CGFloat = slosh * CGFloat(exp(-since * 3 / decay))
            let amplitude: CGFloat = rest + extra
            let shape = LiquidFrontShape(level: level, phase: t * 3.2, amplitude: amplitude)
            ZStack {
                Capsule().fill(Color.primary.opacity(0.07))
                shape
                    .fill(LinearGradient(colors: [Palette.sky, Palette.blue], startPoint: .top, endPoint: .bottom))
                LiquidBubbles(t: t)
                    .mask { shape }
            }
            .clipShape(Capsule())
            .overlay { Capsule().strokeBorder(Palette.stroke) }
        }
    }
}

private struct LiquidFrontShape: Shape {
    var level: Double
    let phase: Double
    let amplitude: CGFloat

    var animatableData: Double {
        get { level }
        set { level = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let clamped: Double = min(max(level, 0), 1)
        guard clamped > 0.001 else { return Path() }
        let base: CGFloat = rect.width * CGFloat(clamped)
        // A full bar must cover the right edge even at the wave's trough.
        let reach: CGFloat = clamped >= 0.999 ? amplitude + 2 : 0
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        let steps = 24
        for step in 0...steps {
            let f: Double = Double(step) / Double(steps)
            let y: CGFloat = rect.minY + rect.height * CGFloat(f)
            let wave: CGFloat = amplitude * CGFloat(sin(f * 2 * .pi + phase))
            path.addLine(to: CGPoint(x: base + wave + reach, y: y))
        }
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct LiquidBubbles: View {
    let t: Double

    var body: some View {
        Canvas { context, size in
            for index in 0..<9 {
                let seed: Double = Double(index) * 0.618
                let rise: Double = (t * (0.35 + 0.1 * Double(index % 3)) + seed).truncatingRemainder(dividingBy: 1)
                let x: CGFloat = size.width * CGFloat((seed * 1.7).truncatingRemainder(dividingBy: 1)) + CGFloat(sin(t * 3 + seed * 6)) * 3
                let y: CGFloat = size.height * CGFloat(1 - rise)
                let r: CGFloat = 1.5 + CGFloat(index % 3)
                let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.45 * (1 - rise * 0.6))))
            }
        }
    }
}

// MARK: - Swinging tooltip bar

extension Effect {
    static let loadingTooltipBar = Effect(
        id: "loading.tooltip-bar",
        category: .loading,
        interaction: .state,
        name: L("Swinging Tooltip Bar", "摆动气泡进度条"),
        summary: L("A percentage bubble rides the knob and swings like a pendulum on each jump.", "百分比气泡骑在滑块上，每次跃进都像钟摆一样摆动。"),
        prompt: L(
            "Under a 16:9 video thumbnail, a 6 pt export bar carries a 16 pt white knob, and above the knob hangs an indigo 54 × 30 pt speech bubble with a small caret, showing the rolling percentage. Each progress chunk glides over 0.45 s, and because the bubble is pinned at its caret it swings like a pendulum: first tilting 12° back against the motion over 0.12 s, then swinging 6° forward and settling through a spring in about 0.5 s. The fill uses the sunset gradient. At 100% the bubble inflates to 115%, turns green and shows a check, with a success haptic. Playful yet readable.",
            "一张 16:9 视频缩略图下方，是一条 6 pt 的导出进度条和一颗 16 pt 白色滑块；滑块上方悬挂着一枚 54 × 30 pt 的靛蓝气泡，带小尖角，显示滚动的百分比。每段进度用 0.45 秒滑行，由于气泡以尖角为支点，它会像钟摆一样摆动：先在 0.12 秒内逆着运动方向后仰 12°，再向前摆 6°，并在约 0.5 秒内经弹簧落定。填充使用日落渐变。到达 100% 时气泡膨胀到 115%、变成绿色并显示对勾，伴随成功触感。俏皮又清晰易读。"
        ),
        implementation: L(
            "Progress animates with .smooth; a keyframeAnimator keyed on the step counter rotates the bubble around its bottom anchor with cubic and spring keyframes.",
            "进度用 .smooth 动画；以步数为触发器的 keyframeAnimator 用三次曲线与弹簧关键帧让气泡绕底部锚点旋转。"
        ),
        apis: ["keyframeAnimator(initialValue:trigger:)", "SpringKeyframe", "rotationEffect(_:anchor:)", "contentTransition(.numericText)"],
        tags: ["tooltip", "pendulum", "swing", "export", "气泡", "钟摆", "摆动", "导出"],
        params: [
            .slider("swing", L("Swing angle", "摆动角度"), 0...24, default: 12, decimals: 0, unit: "°"),
            .slider("speed", L("Speed", "速度"), 0.4...2.5, default: 1.0),
        ]
    ) { ctx in
        TooltipBarDemo(ctx: ctx)
    }
}

private struct TooltipBarDemo: View {
    let ctx: DemoContext
    @State private var progress: Double
    @State private var steps = 0
    @State private var run = 0

    init(ctx: DemoContext) {
        self.ctx = ctx
        // Still thumbnails never run `task`, so seed a representative filled frame.
        _progress = State(initialValue: ctx.isStill ? 0.62 : 0)
    }

    private let width: CGFloat = 250

    var body: some View {
        let zh = ctx.language == .zh
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 12) {
                thumbnail
                Text(zh ? "正在导出 · 4K 60fps" : "Exporting · 4K 60fps")
                    .font(.subheadline.weight(.semibold))
                    .padding(.bottom, 40)
                TooltipTrack(progress: progress, steps: steps, width: width, swing: ctx["swing"])
            }
            .frame(width: width)
            .padding(18)
            .demoCard()
            DemoHint(text: L("Tap to restart", "点击重新开始"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { run += 1 }
        .task(id: run) { await play() }
    }

    private var thumbnail: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Palette.sunset)
            .frame(height: 110)
            .overlay {
                Image(systemName: "film.stack")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
    }

    private func play() async {
        let live: Bool = !ctx.isPreview && run > 0
        steps = 0
        let done = await barVarSimulate(speed: ctx["speed"], set: { progress = $0 }, current: { progress }, onStep: { steps += 1 })
        guard done else { return }
        if live { Haptics.success() }
        try? await Task.sleep(for: .seconds(1.6))
        if ctx.isPreview && !Task.isCancelled { run += 1 }
    }
}

private struct TooltipTrack: View {
    let progress: Double
    let steps: Int
    let width: CGFloat
    let swing: Double

    var body: some View {
        let done = progress >= 1
        let x: CGFloat = width * CGFloat(min(max(progress, 0), 1))
        ZStack(alignment: .leading) {
            Capsule().fill(Color.primary.opacity(0.08))
            Capsule().fill(Palette.sunset).frame(width: max(6, x))
            Circle()
                .fill(.white)
                .frame(width: 16, height: 16)
                .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
                .offset(x: x - 8)
            // Clamp the bubble inside the card; the caret keeps pointing at the knob.
            let bx: CGFloat = min(max(x, 18), width - 18)
            bubble(done: done, caretShift: x - bx)
                .offset(x: bx - 27, y: -30)
        }
        .frame(width: width, height: 6)
    }

    private func bubble(done: Bool, caretShift: CGFloat) -> some View {
        let pivot = UnitPoint(x: 0.5 + caretShift / 54, y: 1)
        return bubbleBody(done: done, caretShift: caretShift)
            .scaleEffect(done ? 1.15 : 1, anchor: pivot)
            .animation(.spring(response: 0.4, dampingFraction: 0.55), value: done)
            .keyframeAnimator(initialValue: 0.0, trigger: steps) { content, angle in
                content.rotationEffect(.degrees(angle), anchor: pivot)
            } keyframes: { _ in
                KeyframeTrack(\.self) {
                    CubicKeyframe(-swing, duration: 0.12)
                    CubicKeyframe(swing * 0.5, duration: 0.2)
                    SpringKeyframe(0.0, duration: 0.5, spring: .bouncy)
                }
            }
    }

    private func bubbleBody(done: Bool, caretShift: CGFloat) -> some View {
        VStack(spacing: 0) {
            ZStack {
                if done {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.heavy))
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text("\(Int((progress * 100).rounded()))%")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .contentTransition(.numericText(value: progress))
                }
            }
            .foregroundStyle(.white)
            .frame(width: 54, height: 30)
            .background(done ? Palette.successStrong : Palette.indigo, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 9))
                .foregroundStyle(done ? Palette.successStrong : Palette.indigo)
                .offset(x: caretShift, y: -3)
        }
        .frame(width: 54)
    }
}

// MARK: - Candy stripes

extension Effect {
    static let loadingCandyStripes = Effect(
        id: "loading.candy-stripes",
        category: .loading,
        interaction: .state,
        name: L("Barber-Pole Bar", "糖果条纹进度条"),
        summary: L("Diagonal stripes march inside the fill, then freeze and turn solid when done.", "斜条纹在填充内持续行进，完成时定格并变为纯色。"),
        prompt: L(
            "An installer window card — a 44 pt gradient app tile, 'Installing Motion Pro' and a step caption — holds a 250 × 14 pt capsule bar. The fill is an indigo → violet gradient overlaid with 45° white stripes at 22% opacity, 8 pt wide every 16 pt, marching right at one stripe period per 0.5 s like a barber pole while each progress chunk glides in over 0.45 s. The step caption cross-fades through 'Verifying', 'Moving files', 'Cleaning up'. At 100% the stripes pause, fade out over 0.4 s into solid green, the bar pulses to 1.08× height once, and a success haptic plays. Classic, honest, busy-looking.",
            "一张安装器窗口卡片——44 pt 渐变应用图标、“正在安装 Motion Pro”以及步骤说明——里面是一条 250 × 14 pt 的胶囊进度条。填充为靛蓝 → 紫罗兰渐变，叠加 45° 的白色条纹（透明度 22%，宽 8 pt、间隔 16 pt），像理发店旋转灯一样每 0.5 秒向右行进一个条纹周期；每段进度以 0.45 秒滑入。步骤说明在“正在验证”“正在移动文件”“正在清理”之间交叉淡换。到达 100% 时条纹停止，在 0.4 秒内淡出为纯绿色，进度条高度脉冲一次到 1.08 倍，并伴随成功触感。经典、诚实、看起来很忙碌。"
        ),
        implementation: L(
            "A stripes Shape offset by a TimelineView(.animation(paused:)) phase is clipped into the fill capsule; completion pauses the timeline and cross-fades a solid fill.",
            "条纹 Shape 由 TimelineView(.animation(paused:)) 的相位驱动偏移并裁切在填充胶囊内；完成时暂停时间线并交叉淡入纯色填充。"
        ),
        apis: ["Shape", "TimelineView(.animation(minimumInterval:paused:))", "clipShape", "contentTransition(.opacity)"],
        tags: ["stripes", "barber pole", "installer", "determinate", "条纹", "理发灯", "安装", "进度条"],
        params: [
            .slider("speed", L("Progress speed", "进度速度"), 0.4...2.5, default: 1.0),
            .slider("march", L("Stripe period", "条纹周期"), 0.2...1.5, default: 0.5, decimals: 1, unit: "s"),
            .slider("height", L("Thickness", "粗细"), 8...22, default: 14, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        CandyStripesDemo(ctx: ctx)
    }
}

private struct CandyStripesDemo: View {
    let ctx: DemoContext
    @State private var progress: Double
    @State private var run = 0
    @State private var pulse = false

    init(ctx: DemoContext) {
        self.ctx = ctx
        // Still thumbnails never run `task`, so seed a representative filled frame.
        _progress = State(initialValue: ctx.isStill ? 0.6 : 0)
    }

    private let width: CGFloat = 250

    var body: some View {
        let zh = ctx.language == .zh
        let done = progress >= 1
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(Palette.primary)
                        .frame(width: 44, height: 44)
                        .overlay { Image(systemName: "sparkles").font(.title3.weight(.bold)).foregroundStyle(.white) }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(zh ? "正在安装 Motion Pro" : "Installing Motion Pro")
                            .font(.subheadline.weight(.semibold))
                        Text(stepText(zh: zh))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .contentTransition(.opacity)
                            .animation(.easeInOut(duration: 0.25), value: stepText(zh: zh))
                    }
                }
                CandyTrack(
                    progress: progress,
                    done: done,
                    width: width,
                    height: ctx.cg("height"),
                    march: max(ctx["march"], 0.1),
                    pulse: pulse,
                    preview: ctx.isPreview
                )
            }
            .frame(width: width)
            .padding(20)
            .demoCard()
            DemoHint(text: L("Tap to restart", "点击重新开始"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { run += 1 }
        .task(id: run) { await play() }
    }

    private func stepText(zh: Bool) -> String {
        if progress >= 1 { return zh ? "安装完成" : "Installed" }
        if progress < 0.3 { return zh ? "正在验证…" : "Verifying…" }
        if progress < 0.8 { return zh ? "正在移动文件…" : "Moving files…" }
        return zh ? "正在清理…" : "Cleaning up…"
    }

    private func play() async {
        let live: Bool = !ctx.isPreview && run > 0
        pulse = false
        let done = await barVarSimulate(speed: ctx["speed"], set: { progress = $0 }, current: { progress })
        guard done else { return }
        try? await Task.sleep(for: .seconds(0.3))
        // A restart cancels this task; stop so the stale finale can't pulse the new run.
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { pulse = true }
        if live { Haptics.success() }
        try? await Task.sleep(for: .seconds(0.25))
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { pulse = false }
        try? await Task.sleep(for: .seconds(1.6))
        if ctx.isPreview && !Task.isCancelled { run += 1 }
    }
}

private struct CandyTrack: View {
    let progress: Double
    let done: Bool
    let width: CGFloat
    let height: CGFloat
    let march: Double
    let pulse: Bool
    let preview: Bool

    var body: some View {
        let fillWidth: CGFloat = max(height, width * CGFloat(min(max(progress, 0), 1)))
        ZStack(alignment: .leading) {
            Capsule().fill(Color.primary.opacity(0.08))
            ZStack {
                Rectangle().fill(Palette.primary)
                TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview), paused: done)) { timeline in
                    let t: Double = timeline.date.timeIntervalSinceReferenceDate
                    let phase: CGFloat = CGFloat((t / march).truncatingRemainder(dividingBy: 1))
                    CandyStripeShape(phase: phase, spacing: 16)
                        .fill(.white.opacity(0.22))
                }
                .opacity(done ? 0 : 1)
                Rectangle().fill(Palette.green).opacity(done ? 1 : 0)
            }
            .frame(width: fillWidth)
            .clipShape(Capsule())
            .animation(.easeInOut(duration: 0.4), value: done)
        }
        .frame(width: width, height: height)
        .scaleEffect(x: 1, y: pulse ? 1.08 : 1)
    }
}

private struct CandyStripeShape: Shape {
    let phase: CGFloat
    let spacing: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let h: CGFloat = rect.height
        let stripe: CGFloat = spacing / 2
        var x: CGFloat = rect.minX - h - spacing + phase * spacing
        while x < rect.maxX + h {
            path.move(to: CGPoint(x: x, y: rect.maxY))
            path.addLine(to: CGPoint(x: x + stripe, y: rect.maxY))
            path.addLine(to: CGPoint(x: x + stripe + h, y: rect.minY))
            path.addLine(to: CGPoint(x: x + h, y: rect.minY))
            path.closeSubpath()
            x += spacing
        }
        return path
    }
}
