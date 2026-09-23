import SwiftUI

extension Effect {
    static let chartsScatterHistogram = Effect(
        id: "charts.scatter-histogram",
        category: .charts,
        interaction: .tap,
        name: L("Scatter ⇄ Histogram", "散点图 ⇄ 直方图"),
        summary: L("Forty-two dots leave their scatter positions and pour into bins, stacking into a unit histogram.", "四十二个点离开散点位置，倾泻进各个区间，堆叠成单元直方图。"),
        prompt: L(
            "A 270 × 180 pt plot of 42 coffee shops as 9 pt dots, price on x and rating on y, coloured by price bin (six bins, mint → sky → indigo → violet). On tap every dot leaves its scatter position and drops into its price bin, stacking three abreast from the floor up into a unit histogram; dots move on a spring (response 0.6 s, damping 0.72) with a delay of 45 ms × their stack position plus 20 ms × their bin, so the columns fill like grain being poured. The y-axis caption cross-fades from “Rating” to “Count” and faint bin separators fade in. Tapping again lifts each dot back to its exact scatter coordinate in the same order. Analytical, tactile, clever.",
            "一张 270 × 180pt 的图表，把 42 家咖啡店画成 9pt 的圆点：横轴为价格，纵轴为评分，按价格区间着色（六个区间，薄荷绿 → 天蓝 → 靛蓝 → 紫色）。点击后，每个点离开散点位置，落入所属价格区间，从底部开始三个一排向上堆叠成单元直方图；圆点以弹簧（响应 0.6 秒、阻尼 0.72）移动，延迟为 45ms × 堆叠序号 + 20ms × 区间序号，于是各列像倾倒谷粒一样被逐渐填满。纵轴说明从“评分”交叉淡入为“数量”，淡淡的区间分隔线随之出现。再次点击，每个点按相同顺序回到精确的散点坐标。理性、可触、巧妙。"
        ),
        implementation: L(
            "Each dot stores its scatter point and a precomputed histogram slot (bin, stack index); a per-dot .animation(spring.delay(...), value: binned) moves its position, so a single Bool drives the whole pour.",
            "每个点保存其散点坐标与预先计算好的直方图槽位（区间、堆叠序号）；每个点各自带有 .animation(spring.delay(...), value: binned) 来移动位置，一个 Bool 即可驱动整场“倾倒”。"
        ),
        apis: ["animation(_:value:)", "Animation.delay", "position(x:y:)", "ForEach", "Color.mix(with:by:)"],
        tags: ["scatter plot", "histogram", "unit chart", "morph", "散点图", "直方图", "分布", "形变"],
        params: [
            .slider("stackDelay", L("Stack stagger", "堆叠错峰"), 0...0.1, default: 0.045, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.45...1.0, default: 0.72),
        ]
    ) { ctx in
        ScatterHistogramDemo(ctx: ctx)
    }
}

private struct ScatterDot: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let bin: Int
    let stack: Int
}

private let scatterBins = 6
private let scatterPlot = CGSize(width: 270, height: 180)

/// Deterministic dataset: price roughly bell-shaped, rating loosely correlated with price.
private let scatterDots: [ScatterDot] = {
    var state: UInt64 = 0x2545F4914F6CDD1D
    func next() -> CGFloat {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return CGFloat(Double((state >> 33) & 0xFFFFFF) / Double(0xFFFFFF))
    }
    var raw: [(x: CGFloat, y: CGFloat)] = []
    for _ in 0..<42 {
        let a: CGFloat = next()
        let b: CGFloat = next()
        let c: CGFloat = next()
        let x: CGFloat = min(max((a + b + c) / 3, 0.02), 0.98)
        let jitter: CGFloat = (next() - 0.5) * 0.45
        let trend: CGFloat = 0.25 + x * 0.45
        let y: CGFloat = min(max(trend + jitter, 0.05), 0.95)
        raw.append((x, y))
    }
    var counts = Array(repeating: 0, count: scatterBins)
    var dots: [ScatterDot] = []
    let order = raw.indices.sorted { raw[$0].y < raw[$1].y }
    for index in order {
        let bin = min(Int(raw[index].x * CGFloat(scatterBins)), scatterBins - 1)
        dots.append(ScatterDot(id: index, x: raw[index].x, y: raw[index].y, bin: bin, stack: counts[bin]))
        counts[bin] += 1
    }
    return dots.sorted { $0.id < $1.id }
}()

private struct ScatterHistogramDemo: View {
    let ctx: DemoContext
    @State private var binned = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack(alignment: .leading) {
                    Text(ctx.language == .zh ? "评分" : "Rating").opacity(binned ? 0 : 1)
                    Text(ctx.language == .zh ? "数量" : "Count").opacity(binned ? 1 : 0)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                Spacer()
                Text(ctx.language == .zh ? "价格 →" : "Price →")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(width: scatterPlot.width)
            ZStack(alignment: .topLeading) {
                separators
                ForEach(scatterDots) { dot in
                    DotView(
                        dot: dot,
                        binned: binned,
                        stackDelay: ctx["stackDelay"],
                        damping: ctx["damping"]
                    )
                }
            }
            .frame(width: scatterPlot.width, height: scatterPlot.height)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.primary.opacity(0.2))
                    .frame(height: 1)
            }
        }
        .padding(15)
        .demoCard()
        .contentShape(Rectangle())
        .onTapGesture { toggle(haptic: true) }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap to bin the dots", "点击将散点分箱"), ctx: ctx)
                .padding(.bottom, 8)
        }
        .autoplay(ctx.isPreview, every: 2.8, delay: 1.0) { toggle(haptic: false) }
    }

    private var separators: some View {
        HStack(spacing: 0) {
            ForEach(0..<scatterBins, id: \.self) { index in
                Rectangle()
                    .fill(Color.primary.opacity(index % 2 == 0 ? 0.04 : 0))
            }
        }
        .opacity(binned ? 1 : 0)
        .animation(.easeInOut(duration: 0.4), value: binned)
    }

    private func toggle(haptic: Bool) {
        withAnimation(.easeInOut(duration: 0.35)) { binned.toggle() }
        if haptic && !ctx.isPreview { Haptics.tap(.light) }
    }
}

private struct DotView: View {
    let dot: ScatterDot
    let binned: Bool
    let stackDelay: Double
    let damping: Double

    var body: some View {
        let target = binned ? histogramPoint : scatterPoint
        let delay = Double(dot.stack) * stackDelay + Double(dot.bin) * 0.02
        Circle()
            .fill(color)
            .overlay(Circle().strokeBorder(.white.opacity(0.5), lineWidth: 1))
            .frame(width: 9, height: 9)
            .position(target)
            .animation(.spring(response: 0.6, dampingFraction: damping).delay(delay), value: binned)
    }

    private var scatterPoint: CGPoint {
        CGPoint(x: dot.x * scatterPlot.width, y: scatterPlot.height * (1 - dot.y))
    }

    private var histogramPoint: CGPoint {
        let binWidth = scatterPlot.width / CGFloat(scatterBins)
        let column = CGFloat(dot.stack % 3) - 1
        let row = CGFloat(dot.stack / 3)
        let x: CGFloat = binWidth * (CGFloat(dot.bin) + 0.5) + column * 11
        let y: CGFloat = scatterPlot.height - 6 - row * 11
        return CGPoint(x: x, y: y)
    }

    private var color: Color {
        let t = Double(dot.bin) / Double(scatterBins - 1)
        if t < 0.5 {
            return Palette.mint.mix(with: Palette.sky, by: t * 2)
        }
        return Palette.indigo.mix(with: Palette.violet, by: (t - 0.5) * 2)
    }
}
