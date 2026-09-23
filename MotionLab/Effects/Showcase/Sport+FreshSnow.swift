import SwiftUI

extension Effect {
    static let showcaseFreshSnow = Effect(
        id: "showcase.fresh-snow",
        category: .showcase,
        interaction: .tap,
        name: L("Fresh Snow Bars", "新雪柱状图"),
        summary: L("Staggered spring bars and a counting total under softly drifting snowflakes; tap to refresh.", "柱子错峰弹起、总量数字递增，背景雪花轻轻飘落；点击刷新数据。"),
        prompt: L(
            "A dark FRESH SNOW widget: a big rounded \"46 cm\" total above seven rounded day bars, today's bar filled with the orange gradient, the rest translucent white, while tiny snowflakes (1–3 pt, 25–70% opacity) drift down and sway ±8 pt behind the content. On tap the refresh glyph spins 360°, every bar first drops to a stub in 180 ms ease-in, then rises to its new height one after another (≈60 ms stagger, spring response 0.55 s, damping ≈0.6, visible overshoot), while the total counts through intermediate values with a rolling-digit transition and a soft haptic lands. Cold, crisp and alive.",
            "深色“新雪”小组件：上方是圆体大号“46 cm”总量，下方七根圆角日柱，今日柱为橙色渐变，其余为半透明白色；卡片背景中 1–3pt、透明度 25%–70% 的细小雪花缓缓飘落并左右摆动约 8pt。点击后刷新图标旋转 360°，所有柱子先在 180 毫秒内 ease-in 缩成短桩，再依次弹升到新高度（错峰约 60 毫秒，弹簧响应 0.55 秒、阻尼约 0.6，带明显过冲）；总量数字以逐位滚动的方式经过中间值递增到新数值，并伴随一次柔和触感。清冽、干脆、充满生气。"
        ),
        implementation: L(
            "Each bar height animates with its own delayed spring from a single loop; the total steps through values inside withAnimation for numericText, and a TimelineView-driven Canvas draws the snowfall.",
            "在一个循环里为每根柱子设置带延迟的弹簧动画；总量在 withAnimation 中逐步赋值以触发 numericText，雪花由 TimelineView 驱动的 Canvas 绘制。"
        ),
        apis: ["spring(response:dampingFraction:).delay", "contentTransition(.numericText(value:))", "Canvas", "TimelineView", "task(id:)"],
        tags: ["bar chart", "stagger", "snow", "weather", "柱状图", "错峰", "下雪", "天气"],
        params: [
            .slider("stagger", L("Stagger", "错峰间隔"), 0...0.15, default: 0.06, unit: "s"),
            .slider("damping", L("Bar bounce damping", "弹跳阻尼"), 0.4...1.0, default: 0.6),
            .slider("snow", L("Snowflakes", "雪花数量"), 0...60, default: 26, step: 1, decimals: 0),
        ]
    ) { ctx in
        SportSnowDemo(ctx: ctx)
    }
}

private struct SportSnowDemo: View {
    let ctx: DemoContext
    @State private var bars: [CGFloat] = Array(repeating: 0.05, count: 7)
    @State private var total = 0
    @State private var spin = 0.0
    @State private var runID = 0

    private static let preset: [CGFloat] = [0.32, 0.55, 0.22, 0.7, 0.48, 0.82, 1.0]

    var body: some View {
        SignatureStage {
            VStack(spacing: 0) {
                Spacer()
                card
                Spacer()
                DemoHint(text: L("Tap the card to refresh", "点击卡片刷新"), ctx: ctx)
                    .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task(id: runID) { await refresh() }
        .autoplay(ctx.isPreview, every: 3.4, delay: 3.4) { runID += 1 }
        // The first refresh already runs on appear, so the detail stage skips its one-shot intro replay.
        .environment(\.demoIntroPlay, false)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SportEyebrowRow(title: L("Fresh snow", "新雪")(ctx.language), symbol: "snowflake")
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Signature.textSecondary)
                    .rotationEffect(.degrees(spin))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color.white.opacity(0.07)))
            }
            SnowTotal(total: total, language: ctx.language)
            SnowBars(bars: bars, language: ctx.language)
        }
        .padding(20)
        .frame(width: 292)
        .background {
            SnowfallLayer(count: ctx.int("snow"), preview: ctx.isPreview)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .signatureCard()
        .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .onTapGesture { runID += 1 }
    }

    private func refresh() async {
        let isFirst = runID == 0
        let next: [CGFloat] = isFirst ? Self.preset : (0..<7).map { _ in CGFloat.random(in: 0.18...1) }
        let target = isFirst ? 46 : Int((next.reduce(0, +) * 10.5).rounded())
        let from = total

        withAnimation(.easeInOut(duration: 0.6)) { spin += 360 }
        withAnimation(.easeIn(duration: 0.18)) { bars = Array(repeating: 0.05, count: 7) }
        try? await Task.sleep(for: .milliseconds(200))
        guard !Task.isCancelled else { return }

        let stagger = ctx["stagger"]
        let damping = ctx["damping"]
        for i in 0..<7 {
            withAnimation(.spring(response: 0.55, dampingFraction: damping).delay(Double(i) * stagger)) {
                bars[i] = next[i]
            }
        }
        // Only user refreshes buzz; the arrival run and preview loops stay silent.
        if !ctx.isPreview && !isFirst { Haptics.tap(.soft) }

        let steps = 10
        for step in 1...steps {
            guard !Task.isCancelled else { return }
            let value = from + (target - from) * step / steps
            withAnimation(.snappy(duration: 0.18)) { total = value }
            try? await Task.sleep(for: .milliseconds(45))
        }
    }
}

private struct SnowTotal: View {
    let total: Int
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(total)")
                    .font(Signature.number(50))
                    .foregroundStyle(Color.white)
                    .contentTransition(.numericText(value: Double(total)))
                Text(L("cm fresh", "厘米新雪"), language)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Signature.textSecondary)
            }
            Text(L("Nordkette · last 7 days", "Nordkette · 近 7 天"), language)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Signature.textSecondary)
        }
    }
}

private struct SnowBars: View {
    let bars: [CGFloat]
    let language: AppLanguage

    private var labels: [String] {
        language == .zh ? ["一", "二", "三", "四", "五", "六", "日"] : ["M", "T", "W", "T", "F", "S", "S"]
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(0..<7, id: \.self) { index in
                SnowBar(height: bars[index], isToday: index == 6, label: labels[index])
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct SnowBar: View {
    let height: CGFloat
    let isToday: Bool
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isToday ? AnyShapeStyle(Signature.accentGradient) : AnyShapeStyle(Color.white.opacity(0.16)))
                .frame(width: 24, height: max(8, 84 * height))
                .shadow(color: isToday ? Signature.accent.opacity(0.5) : .clear, radius: 8, y: 2)
                .frame(height: 84, alignment: .bottom)
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(isToday ? Signature.accent : Signature.textSecondary)
        }
    }
}

/// Procedural snowfall: each flake has a hashed speed, size, column and sway phase.
private struct SnowfallLayer: View {
    let count: Int
    let preview: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview))) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let w = Double(size.width)
                let h = Double(size.height)
                guard count > 0, w > 0, h > 0 else { return }
                for i in 0..<count {
                    let seed = Double(i) * 3.17
                    let speed = 8 + sportHash(seed + 1) * 16
                    let r = 0.6 + sportHash(seed + 2) * 1.0
                    let baseX = sportHash(seed + 3) * w
                    let y = (t * speed + sportHash(seed + 4) * h).truncatingRemainder(dividingBy: h + 10) - 5
                    let x = baseX + sin(t * 0.8 + seed) * 8
                    let alpha = 0.25 + sportHash(seed + 5) * 0.45
                    let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(alpha)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
