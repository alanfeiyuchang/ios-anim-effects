import SwiftUI

extension Effect {
    static let chartsDonutToBars = Effect(
        id: "charts.donut-to-bars",
        category: .charts,
        interaction: .tap,
        name: L("Donut ⇄ Bars Morph", "环形图 ⇄ 柱状图形变"),
        summary: L("Each donut segment unrolls into its own bar — and curls back — on a staggered spring.", "每段圆环依次舒展成对应的柱子，再卷回圆环，错峰弹性形变。"),
        prompt: L(
            "A “Sessions by platform” card with five segments (indigo, pink, amber, mint, sky) that switches chart type in place. As a donut (≈ 6° gaps, inner radius 60% of the outer) each segment is an arc and the center shows the weekly total, 11.1k sessions; as bars each is a column with 6 pt rounded top corners whose height is its value. On tap every segment morphs along its own outline — the outer arc straightens into the bar’s rounded top while the inner arc becomes its base — so the eye can follow each value from slice to column. Segments start 60 ms apart on a spring (response ≈ 0.7 s, damping ≈ 0.78) with a hint of overshoot; the total fades out as per-bar values (4.2k, 2.7k…) and a baseline fade in, and the reverse curls them back. Clear, clever, continuous.",
            "一张“各平台会话”卡片，五个分段（靛蓝、粉、琥珀、薄荷、天蓝）可原位切换图表类型。环形图中每段是一段圆弧（段间约 6° 间隙，内半径为外半径的 60%），中心显示本周总数“11.1k 次会话”；柱状图中每段是一根顶部 6pt 圆角、高度等于数值的柱子。点击后每段沿自身轮廓形变：外弧拉直成柱顶，内弧展开成柱底。各段间隔 60ms 启动，乘弹簧（响应约 0.7 秒、阻尼约 0.78）并轻微过冲；总数淡出，各柱数值（4.2k、2.7k……）与基线淡入；反向操作再把柱子卷回圆环。"
        ),
        implementation: L(
            "Each segment is an Animatable Shape that samples 24 points along the arc outline and along the bar outline (its top edge bent into rounded corners) and linearly interpolates them by an animatable progress; per-segment .animation(spring.delay(i × stagger), value:) creates the cascade.",
            "每个分段是一个 Animatable Shape：分别沿圆弧轮廓与柱形轮廓（柱顶采样点弯成圆角）采样 24 个点，并按可动画的进度线性插值；每段使用 .animation(spring.delay(序号 × 间隔), value:) 形成错峰级联。"
        ),
        apis: ["Shape", "Animatable", "animation(_:value:)", "Path.addLines", "contentTransition(.numericText)"],
        tags: ["donut", "bar chart", "morph", "chart type", "环形图", "柱状图", "形变", "图表切换"],
        params: [
            .slider("stagger", L("Stagger", "错峰间隔"), 0...0.15, default: 0.06, unit: "s"),
            .slider("response", L("Spring response", "弹簧响应"), 0.3...1.2, default: 0.7, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.45...1.0, default: 0.78),
        ]
    ) { ctx in
        DonutBarsDemo(ctx: ctx)
    }
}

private struct MorphDatum {
    let name: LocalizedText
    let value: Double
    let color: Color
}

/// Weekly sessions, in thousands.
private let morphData: [MorphDatum] = [
    MorphDatum(name: L("iOS", "iOS"), value: 4.2, color: Palette.indigo),
    MorphDatum(name: L("Web", "网页"), value: 2.7, color: Palette.pink),
    MorphDatum(name: L("Android", "安卓"), value: 1.9, color: Palette.amber),
    MorphDatum(name: L("Mac", "Mac"), value: 1.4, color: Palette.mint),
    MorphDatum(name: L("Other", "其他"), value: 0.9, color: Palette.sky),
]

private struct DonutBarsDemo: View {
    let ctx: DemoContext
    @State private var isBars = false

    private let plot = CGSize(width: 264, height: 200)

    var body: some View {
        let total = morphData.reduce(0) { $0 + $1.value }
        let maxValue = morphData.map(\.value).max() ?? 1
        VStack(alignment: .leading, spacing: 12) {
            header
            ZStack {
                baseline
                ForEach(morphData.indices, id: \.self) { index in
                    segment(index, total: total, maxValue: maxValue)
                }
                centerTotal(total)
                valueLabels(maxValue: maxValue)
            }
            .frame(width: plot.width, height: plot.height)
        }
        .padding(18)
        .demoCard()
        .contentShape(Rectangle())
        .onTapGesture { toggle() }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            ChartTapCue(text: L("Tap to switch chart type", "点击切换图表类型"), ctx: ctx)
                .padding(.bottom, 8)
        }
        .autoplay(ctx.isPreview, every: 2.4, delay: 1.0) { toggle() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(ctx.language == .zh ? "各平台会话" : "Sessions by platform")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(ctx.language == .zh ? (isBars ? "柱状图" : "环形图") : (isBars ? "Bars" : "Donut"))
                    .font(.headline)
                    .contentTransition(.opacity)
            }
            Spacer()
            Image(systemName: isBars ? "chart.bar.fill" : "chart.pie.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Palette.indigo)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 34, height: 34)
                .background(Palette.indigo.opacity(0.12), in: Circle())
        }
        .frame(width: plot.width)
    }

    private func segment(_ index: Int, total: Double, maxValue: Double) -> some View {
        var start = 0.0
        for i in 0..<index { start += morphData[i].value / total }
        let fraction = morphData[index].value / total
        let delay = Double(isBars ? index : morphData.count - 1 - index) * ctx["stagger"]
        return MorphSegment(
            progress: isBars ? 1 : 0,
            start: start,
            end: start + fraction,
            slot: index,
            slots: morphData.count,
            height: morphData[index].value / maxValue
        )
        .fill(morphData[index].color.gradient)
        .animation(.spring(response: ctx["response"], dampingFraction: ctx["damping"]).delay(delay), value: isBars)
    }

    private var baseline: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.12))
            .frame(height: 1)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, plot.height * (1 - MorphSegment.baselineRatio))
            .opacity(isBars ? 1 : 0)
            .animation(.easeInOut(duration: 0.3).delay(isBars ? 0.25 : 0), value: isBars)
    }

    private func centerTotal(_ total: Double) -> some View {
        VStack(spacing: 0) {
            Text(String(format: "%.1fk", total))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text(ctx.language == .zh ? "本周会话" : "sessions this week")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .scaleEffect(isBars ? 0.7 : 1)
        .opacity(isBars ? 0 : 1)
        .animation(.spring(response: 0.4, dampingFraction: 0.85).delay(isBars ? 0 : 0.3), value: isBars)
    }

    private func valueLabels(maxValue: Double) -> some View {
        let slotWidth = plot.width / CGFloat(morphData.count)
        return ZStack(alignment: .topLeading) {
            ForEach(morphData.indices, id: \.self) { index in
                let top = MorphSegment.barTop(height: morphData[index].value / maxValue, in: plot.height)
                let labelDelay: Double = isBars ? 0.3 + Double(index) * ctx["stagger"] : 0
                let labelX: CGFloat = slotWidth * CGFloat(index)
                let labelY: CGFloat = top - 30
                VStack(spacing: 1) {
                    Text(String(format: "%.1fk", morphData[index].value))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text(morphData[index].name, ctx.language)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(width: slotWidth)
                .offset(x: labelX, y: labelY)
                .opacity(isBars ? 1 : 0)
                .offset(y: isBars ? 0 : 8)
                .animation(.spring(response: 0.45, dampingFraction: 0.8).delay(labelDelay), value: isBars)
            }
        }
        .frame(width: plot.width, height: plot.height, alignment: .topLeading)
    }

    private func toggle() {
        isBars.toggle()
        if !ctx.isPreview { Haptics.tap(.light) }
    }
}

/// One data segment that interpolates between a donut arc (progress 0) and a bar (progress 1)
/// by sampling both outlines with the same number of points.
private struct MorphSegment: Shape {
    var progress: Double
    let start: Double
    let end: Double
    let slot: Int
    let slots: Int
    let height: Double

    static let baselineRatio: CGFloat = 0.94
    static let cornerRadius: CGFloat = 6
    private static let samples = 24

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    static func barTop(height: Double, in plotHeight: CGFloat) -> CGFloat {
        let bottom = plotHeight * baselineRatio
        return bottom - CGFloat(height) * plotHeight * 0.72
    }

    func path(in rect: CGRect) -> Path {
        let t = CGFloat(min(max(progress, -0.08), 1.08))
        let n = MorphSegment.samples
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerR = min(rect.width, rect.height) * 0.46
        let innerR = outerR * 0.6
        // A small angular gap between slices, in turns.
        let gap = 0.008
        let a0 = (start + gap) * 2 * Double.pi - Double.pi / 2
        let a1 = (end - gap) * 2 * Double.pi - Double.pi / 2

        let slotWidth = rect.width / CGFloat(max(slots, 1))
        let barWidth = slotWidth * 0.58
        let x0 = rect.minX + slotWidth * CGFloat(slot) + (slotWidth - barWidth) / 2
        let bottom = rect.minY + rect.height * MorphSegment.baselineRatio
        let top = rect.minY + MorphSegment.barTop(height: height, in: rect.height)

        // Rounded top corners: points near either side of the top edge drop onto a quarter circle.
        let corner = min(MorphSegment.cornerRadius, barWidth / 2, max(bottom - top, 0))

        var points: [CGPoint] = []
        points.reserveCapacity((n + 1) * 2)
        for k in 0...n {
            let u = Double(k) / Double(n)
            let angle = a0 + (a1 - a0) * u
            let arc = CGPoint(x: center.x + outerR * CGFloat(cos(angle)), y: center.y + outerR * CGFloat(sin(angle)))
            let x = barWidth * CGFloat(u)
            let edge = min(x, barWidth - x)
            let drop = edge < corner ? corner - (corner * corner - (corner - edge) * (corner - edge)).squareRoot() : 0
            let bar = CGPoint(x: x0 + x, y: top + drop)
            points.append(MorphSegment.lerp(arc, bar, t))
        }
        for k in stride(from: n, through: 0, by: -1) {
            let u = Double(k) / Double(n)
            let angle = a0 + (a1 - a0) * u
            let arc = CGPoint(x: center.x + innerR * CGFloat(cos(angle)), y: center.y + innerR * CGFloat(sin(angle)))
            let bar = CGPoint(x: x0 + barWidth * CGFloat(u), y: bottom)
            points.append(MorphSegment.lerp(arc, bar, t))
        }
        var path = Path()
        path.addLines(points)
        path.closeSubpath()
        return path
    }

    private static func lerp(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }
}
