import SwiftUI

extension Effect {
    static let chartsSparklineStream = Effect(
        id: "charts.sparkline-stream",
        category: .charts,
        interaction: .loop,
        name: L("Live Sparkline Stream", "实时流动迷你图"),
        summary: L("System-monitor sparklines that scroll continuously as new samples stream in.", "系统监控式迷你折线，随新数据流入连续平滑滚动。"),
        prompt: L(
            "Three stacked monitor rows (CPU, Memory, Network) in rounded cards, each with a caption, a live percentage in rounded tabular digits and a 54 pt-tall sparkline in its own hue (indigo, mint, coral) over a soft vertical gradient fill. New samples arrive every 0.4 s from a mean-reverting random walk, but the chart never jumps: the whole series scrolls left continuously at one sample-width per interval, and the newest point enters from beyond the right edge while the leading dot — a 7 pt core inside a 14 pt translucent halo — stays pinned to the right edge, its height interpolated between the last two samples. The percentage label reads the same interpolated value so it glides rather than ticks. Calm, continuous, ‘always live’ — like Activity Monitor rendered by a motion designer.",
            "三行纵向排列的监控卡片（CPU、内存、网络），每行包含说明文字、以圆体等宽数字显示的实时百分比，以及一条高 54pt 的迷你折线，分别使用靛蓝、薄荷绿、珊瑚色，下方配柔和的竖向渐变填充。新样本每 0.4 秒由均值回归的随机游走产生，但图表从不跳动：整条序列以“每个间隔移动一个样本宽度”的速度持续左移，最新数据点从右边界外滑入；领头圆点（7pt 实心圆 + 14pt 半透明光晕）固定在右边缘，高度在最后两个样本之间插值。百分比读数使用同一插值结果，因此平滑滑动而非跳变。沉静、连续、始终在线——像由动效设计师重绘的活动监视器。"
        ),
        implementation: L(
            "TimelineView(.animation) advances a reference-type buffer; the fractional phase since the last sample offsets every x by −phase × step inside a Canvas, and the head value is lerped with the same phase.",
            "TimelineView(.animation) 推进引用类型的数据缓冲；距上次采样的小数相位让 Canvas 中每个点的 x 偏移 −相位 × 步长，领头值用同一相位插值。"
        ),
        apis: ["TimelineView(.animation)", "Canvas", "GraphicsContext.Shading.linearGradient", "Path", "monospacedDigit"],
        tags: ["sparkline", "live", "stream", "real-time", "monitor", "迷你图", "实时", "数据流", "监控"],
        params: [
            .slider("interval", L("Sample interval", "采样间隔"), 0.15...1.0, default: 0.4, unit: "s"),
            .slider("volatility", L("Volatility", "波动幅度"), 0.02...0.3, default: 0.1),
            .toggle("fill", L("Gradient fill", "渐变填充"), default: true),
        ]
    ) { ctx in
        SparklineStreamDemo(ctx: ctx)
    }
}

private final class StreamModel {
    static let visible = 24
    var series: [[Double]]
    private var lastTick: Date?

    init() {
        series = (0..<3).map { index in
            var value = 0.35 + 0.15 * Double(index)
            return (0..<(StreamModel.visible + 2)).map { _ in
                value = min(max(value + Double.random(in: -0.08...0.08), 0.05), 0.95)
                return value
            }
        }
    }

    /// Returns the fractional progress (0…1) toward the next sample.
    func advance(to date: Date, interval: Double, volatility: Double) -> Double {
        guard let last = lastTick else {
            lastTick = date
            return 0
        }
        var elapsed = date.timeIntervalSince(last)
        if elapsed > 2 {
            lastTick = date
            return 0
        }
        var tick = last
        while elapsed >= interval {
            push(volatility: volatility)
            tick = tick.addingTimeInterval(interval)
            elapsed -= interval
        }
        lastTick = tick
        return min(max(elapsed / interval, 0), 1)
    }

    private func push(volatility: Double) {
        for index in series.indices {
            let last = series[index].last ?? 0.5
            let next = last + Double.random(in: -volatility...volatility) + (0.5 - last) * 0.08
            series[index].append(min(max(next, 0.04), 0.96))
            if series[index].count > StreamModel.visible + 2 {
                series[index].removeFirst(series[index].count - (StreamModel.visible + 2))
            }
        }
    }
}

private struct StreamStyle {
    let title: LocalizedText
    let color: Color
}

private let streamStyles: [StreamStyle] = [
    StreamStyle(title: L("CPU", "CPU"), color: Palette.indigo),
    StreamStyle(title: L("Memory", "内存"), color: Palette.mint),
    StreamStyle(title: L("Network", "网络"), color: Palette.coral),
]

private struct SparklineStreamDemo: View {
    let ctx: DemoContext
    @State private var model = StreamModel()

    var body: some View {
        let interval = ctx["interval"]
        let volatility = ctx["volatility"]
        let showFill = ctx.bool("fill")
        TimelineView(.animation) { timeline in
            let phase = model.advance(to: timeline.date, interval: interval, volatility: volatility)
            VStack(spacing: 10) {
                ForEach(streamStyles.indices, id: \.self) { index in
                    StreamRow(
                        style: streamStyles[index],
                        values: model.series[index],
                        phase: phase,
                        showFill: showFill,
                        language: ctx.language
                    )
                }
            }
        }
        .frame(width: 300)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct StreamRow: View {
    let style: StreamStyle
    let values: [Double]
    let phase: Double
    let showFill: Bool
    let language: AppLanguage

    private var head: Double {
        let n = values.count
        guard n >= 2 else { return values.last ?? 0 }
        return values[n - 2] + (values[n - 1] - values[n - 2]) * phase
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(style.title, language)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("\(Int((head * 100).rounded()))%")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .frame(width: 76, alignment: .leading)
            Canvas { context, size in
                drawSparkline(in: context, size: size)
            }
            .frame(height: 54)
        }
        .padding(12)
        .demoCard(cornerRadius: 18)
    }

    private func drawSparkline(in context: GraphicsContext, size: CGSize) {
        let n = values.count
        guard n > 2 else { return }
        let plotWidth = size.width - 8
        var plot = context
        plot.clip(to: Path(CGRect(x: 0, y: 0, width: plotWidth, height: size.height)))
        let step = plotWidth / CGFloat(n - 2)
        let shift = CGFloat(phase)
        let points: [CGPoint] = values.indices.map { i in
            CGPoint(x: (CGFloat(i) - shift) * step, y: size.height - 4 - CGFloat(values[i]) * (size.height - 8))
        }
        var line = Path()
        line.addLines(points)

        if showFill, let first = points.first, let last = points.last {
            var area = line
            area.addLine(to: CGPoint(x: last.x, y: size.height))
            area.addLine(to: CGPoint(x: first.x, y: size.height))
            area.closeSubpath()
            plot.fill(
                area,
                with: .linearGradient(
                    Gradient(colors: [style.color.opacity(0.3), style.color.opacity(0)]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: size.height)
                )
            )
        }
        plot.stroke(line, with: .color(style.color), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

        let headPoint = CGPoint(x: plotWidth, y: size.height - 4 - CGFloat(head) * (size.height - 8))
        context.fill(Path(ellipseIn: CGRect(x: headPoint.x - 7, y: headPoint.y - 7, width: 14, height: 14)), with: .color(style.color.opacity(0.25)))
        context.fill(Path(ellipseIn: CGRect(x: headPoint.x - 3.5, y: headPoint.y - 3.5, width: 7, height: 7)), with: .color(style.color))
    }
}
