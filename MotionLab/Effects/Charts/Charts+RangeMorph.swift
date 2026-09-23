import SwiftUI

extension Effect {
    static let chartsRangeMorph = Effect(
        id: "charts.range-morph",
        category: .charts,
        interaction: .tap,
        name: L("Range Switch Morph", "区间切换形变"),
        summary: L("Switching 1D / 1W / 1M / 1Y springs the price line into its new shape, colour and baseline.", "切换 1天/1周/1月/1年时，价格折线连同颜色与基准线弹性形变为新形状。"),
        prompt: L(
            "A stock card: ticker and price on top, a pill showing the period change (▲ green / ▼ red), a 150 pt smooth line chart with a gradient area fill, a dashed previous-close baseline and a glowing end dot, and a segmented control (1D · 1W · 1M · 1Y) whose thumb slides between options with matched geometry. Choosing a range morphs every one of the 36 points from the old series to the new one on a single spring (response ≈ 0.6 s, damping ≈ 0.8) — the line, area, baseline and end dot are all computed from the same interpolated values, so nothing drifts apart, and re-tapping mid-flight redirects smoothly. The stroke colour blends green ⇄ red in the same spring, and the change figure rolls with a numeric transition and a selection haptic. Confident, fluid and data-honest.",
            "一张股票卡片：顶部为代码与价格，胶囊标签显示区间涨跌（▲ 绿 / ▼ 红），下方是 150pt 高的平滑折线图——渐变面积填充、虚线昨收基准线与发光端点，最底部是分段控件（1天 · 1周 · 1月 · 1年），滑块借助几何匹配在选项间滑动。切换区间时，36 个数据点在同一个弹簧（响应约 0.6 秒、阻尼约 0.8）中由旧序列形变为新序列——折线、面积、基准线与端点都由同一组插值数值计算，彼此绝不脱节；动画途中再次点击也会平滑转向。线条颜色在同一弹簧中于绿 ⇄ 红之间过渡，涨跌数字以数字转场滚动，并伴随选择触感。自信、流畅，忠于数据。"
        ),
        implementation: L(
            "The chart is an Animatable view whose animatableData pairs a custom VectorArithmetic series (an array of Doubles) with a colour tone, so SwiftUI interpolates every point in one interruptible spring; a Canvas draws line, area, baseline and dot.",
            "图表是一个 Animatable 视图，其 animatableData 将自定义 VectorArithmetic 序列（Double 数组）与颜色色调组合在一起，SwiftUI 因此在同一个可打断的弹簧中插值所有数据点；Canvas 负责绘制折线、面积、基准线与端点。"
        ),
        apis: ["VectorArithmetic", "Animatable", "Canvas", "matchedGeometryEffect", "contentTransition(.numericText)"],
        tags: ["stock", "line chart", "morph", "range", "time range", "股票", "折线图", "形变", "区间", "行情"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.25...1.2, default: 0.6, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.4...1.0, default: 0.8),
            .toggle("baseline", L("Previous-close line", "昨收基准线"), default: true),
        ]
    ) { ctx in
        RangeMorphDemo(ctx: ctx)
    }
}

// MARK: - Series vector

/// An array of Doubles that SwiftUI can interpolate point by point.
private struct SeriesVector: VectorArithmetic {
    var values: [Double]

    static var zero: SeriesVector { SeriesVector(values: []) }

    static func + (lhs: SeriesVector, rhs: SeriesVector) -> SeriesVector {
        combine(lhs, rhs) { $0 + $1 }
    }

    static func - (lhs: SeriesVector, rhs: SeriesVector) -> SeriesVector {
        combine(lhs, rhs) { $0 - $1 }
    }

    mutating func scale(by rhs: Double) {
        for index in values.indices { values[index] *= rhs }
    }

    var magnitudeSquared: Double {
        values.reduce(0) { $0 + $1 * $1 }
    }

    private static func combine(_ a: SeriesVector, _ b: SeriesVector, _ op: (Double, Double) -> Double) -> SeriesVector {
        let count = max(a.values.count, b.values.count)
        var out = [Double](repeating: 0, count: count)
        for index in 0..<count {
            let x = index < a.values.count ? a.values[index] : 0
            let y = index < b.values.count ? b.values[index] : 0
            out[index] = op(x, y)
        }
        return SeriesVector(values: out)
    }
}

// MARK: - Data

private struct RangeData {
    let label: LocalizedText
    let values: [Double]
    let change: Double
}

private func makeSeries(seed: Double, trend: Double, wiggle: Double) -> [Double] {
    let count = 36
    let raw: [Double] = (0..<count).map { index in
        let x = Double(index) / Double(count - 1)
        let noise = sin(x * 9 + seed) * 0.6 + sin(x * 23 + seed * 2.1) * 0.25 + sin(x * 47 + seed * 0.7) * 0.12
        return trend * x + wiggle * noise
    }
    let low = raw.min() ?? 0
    let high = raw.max() ?? 1
    let span = max(high - low, 0.0001)
    return raw.map { 0.08 + 0.84 * ($0 - low) / span }
}

private let rangeData: [RangeData] = [
    RangeData(label: L("1D", "1天"), values: makeSeries(seed: 1.3, trend: 0.5, wiggle: 0.55), change: 1.26),
    RangeData(label: L("1W", "1周"), values: makeSeries(seed: 4.1, trend: -0.9, wiggle: 0.45), change: -2.14),
    RangeData(label: L("1M", "1月"), values: makeSeries(seed: 2.7, trend: 1.3, wiggle: 0.5), change: 8.72),
    RangeData(label: L("1Y", "1年"), values: makeSeries(seed: 5.9, trend: 2.2, wiggle: 0.6), change: 41.3),
]

// MARK: - Demo

private struct RangeMorphDemo: View {
    let ctx: DemoContext
    @State private var selection = 0
    @Namespace private var ns

    var body: some View {
        let data = rangeData[selection]
        VStack(alignment: .leading, spacing: 12) {
            header(data)
            RangeChart(
                series: SeriesVector(values: data.values),
                tone: data.change >= 0 ? 1 : 0,
                showBaseline: ctx.bool("baseline")
            )
            .frame(height: 150)
            picker
        }
        .padding(18)
        .frame(width: 300)
        .demoCard()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Switch the time range", "切换时间区间"), ctx: ctx)
                .padding(.bottom, 8)
        }
        .sensoryFeedback(.selection, trigger: selection) { _, _ in !ctx.isPreview }
        .autoplay(ctx.isPreview, every: 1.8, delay: 0.8) { select((selection + 1) % rangeData.count) }
    }

    private func header(_ data: RangeData) -> some View {
        let up = data.change >= 0
        let tint = up ? Palette.green : Palette.red
        return HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(ctx.language == .zh ? "动效科技 · MLX" : "Motion Labs · MLX")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("$182.40")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            Spacer()
            HStack(spacing: 3) {
                Image(systemName: up ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                    .font(.system(size: 9, weight: .bold))
                    .contentTransition(.symbolEffect(.replace))
                Text(String(format: "%.2f%%", abs(data.change)))
                    .contentTransition(.numericText(value: data.change))
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded).monospacedDigit())
            .foregroundStyle(tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(tint.opacity(0.14), in: Capsule())
        }
    }

    private var picker: some View {
        HStack(spacing: 4) {
            ForEach(rangeData.indices, id: \.self) { index in
                Button {
                    select(index)
                } label: {
                    Text(rangeData[index].label, ctx.language)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(index == selection ? Color.primary : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .background {
                            if index == selection {
                                Capsule()
                                    .fill(Palette.elevated)
                                    .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                                    .matchedGeometryEffect(id: "thumb", in: ns)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.primary.opacity(0.06), in: Capsule())
    }

    private func select(_ index: Int) {
        guard index != selection else { return }
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            selection = index
        }
    }
}

// MARK: - Chart

private struct RangeChart: View, Animatable {
    var series: SeriesVector
    var tone: Double
    let showBaseline: Bool

    var animatableData: AnimatablePair<SeriesVector, Double> {
        get { AnimatablePair(series, tone) }
        set {
            series = newValue.first
            tone = newValue.second
        }
    }

    /// Green (1) ⇄ red (0), blended in sRGB so the colour travels with the spring.
    private var color: Color {
        let t = min(max(tone, 0), 1)
        let up = (r: 0x34 / 255.0, g: 0xC7 / 255.0, b: 0x7B / 255.0)
        let down = (r: 0xFF / 255.0, g: 0x4D / 255.0, b: 0x5E / 255.0)
        return Color(
            .sRGB,
            red: down.r + (up.r - down.r) * t,
            green: down.g + (up.g - down.g) * t,
            blue: down.b + (up.b - down.b) * t,
            opacity: 1
        )
    }

    var body: some View {
        let values = series.values
        let tint = color
        let baseline = showBaseline
        Canvas { context, size in
            guard values.count > 1 else { return }
            // Plot inside an inset so the end dot's halo is drawn fully within the Canvas (a Canvas clips to its bounds).
            let plot = CGRect(x: 0, y: RangeChart.inset, width: size.width - RangeChart.inset, height: size.height - RangeChart.inset * 2)
            let points = RangeChart.points(values, in: plot)
            let line = RangeChart.smoothPath(points)

            var area = line
            area.addLine(to: CGPoint(x: plot.maxX, y: size.height))
            area.addLine(to: CGPoint(x: 0, y: size.height))
            area.closeSubpath()
            context.fill(
                area,
                with: .linearGradient(
                    Gradient(colors: [tint.opacity(0.28), tint.opacity(0)]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: size.height)
                )
            )

            if baseline, let first = points.first {
                var dash = Path()
                dash.move(to: CGPoint(x: 0, y: first.y))
                dash.addLine(to: CGPoint(x: size.width, y: first.y))
                context.stroke(dash, with: .color(.secondary.opacity(0.6)), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
            }

            context.stroke(line, with: .color(tint), style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))

            if let last = points.last {
                let halo: CGFloat = 9
                context.fill(Path(ellipseIn: CGRect(x: last.x - halo, y: last.y - halo, width: halo * 2, height: halo * 2)), with: .color(tint.opacity(0.22)))
                let dot: CGFloat = 4
                context.fill(Path(ellipseIn: CGRect(x: last.x - dot, y: last.y - dot, width: dot * 2, height: dot * 2)), with: .color(tint))
            }
        }
    }

    /// Room for the 9 pt halo around the end dot.
    private static let inset: CGFloat = 10

    private static func points(_ values: [Double], in plot: CGRect) -> [CGPoint] {
        let step = plot.width / CGFloat(max(values.count - 1, 1))
        return values.enumerated().map { index, value in
            CGPoint(x: plot.minX + CGFloat(index) * step, y: plot.minY + plot.height * CGFloat(1 - value))
        }
    }

    /// Quadratic curves through midpoints: smooth, never overshoots the data.
    private static func smoothPath(_ points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let mid = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2)
            path.addQuadCurve(to: mid, control: previous)
        }
        if let last = points.last { path.addLine(to: last) }
        return path
    }
}
