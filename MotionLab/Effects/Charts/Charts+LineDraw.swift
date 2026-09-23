import SwiftUI

extension Effect {
    static let chartsLineDraw = Effect(
        id: "charts.line-draw",
        category: .charts,
        interaction: .tap,
        name: L("Line Draw-On with Area", "折线绘制与面积渐显"),
        summary: L("A smooth line sweeps in left to right, trailed by its gradient area and a glowing tip.", "平滑折线从左至右绘出，渐变面积与发光端点紧随其后。"),
        prompt: L(
            "A 290 × 170 pt revenue chart with four faint horizontal guides labeled $8k–$26k and month labels (Jan–Sep, every other month) beneath: a Catmull-Rom-smoothed line (3 pt, round caps and joins, indigo → violet → pink gradient) over an area fill that fades from 35% indigo at the line to transparent at the baseline. On appear and on tap the chart is revealed by a clip edge sweeping left to right over 1.6 s on an ease-in-out curve (0.65, 0, 0.35, 1); line and area share the same edge so they stay perfectly in sync. A 10 pt white-rimmed dot with a soft colored halo rides the exact curve position at the edge, carrying a small value pill that counts along. Replaying first rewinds the sweep in 250 ms, swaps in a new dataset, then draws again. Elegant and narrative, like a stock chart telling its story.",
            "一张 290 × 170pt 的营收折线图，带四条标注 $8k～$26k 的淡色参考线与月份标签（1 月～9 月）：Catmull-Rom 平滑曲线（3pt，圆角端点，靛蓝 → 紫 → 粉渐变），下方面积从 35% 靛蓝渐隐到基线透明。出现与点击时，一条从左向右扫过的裁切边在 1.6 秒内揭示图表（ease-in-out 0.65, 0, 0.35, 1），曲线与面积共用此裁切边。一个 10pt 白边圆点带柔和光晕，贴着裁切边处的曲线移动，并携带实时滚动的数值胶囊。重播时先在 250ms 内倒带收回，换入新数据重绘。"
        ),
        implementation: L(
            "An Animatable view interpolates progress; both line and area are masked by a rectangle of width progress × width, and the tip’s y is evaluated from the same cubic Bézier segments used to build the path.",
            "Animatable 视图插值 progress；曲线与面积都被宽度为 progress × 宽度 的矩形遮罩，端点的 y 值由构建路径时相同的三次贝塞尔分段计算得出。"
        ),
        apis: ["Animatable", "Path.addCurve", "mask(alignment:)", "LinearGradient", "timingCurve"],
        tags: ["line chart", "draw on", "area", "reveal", "折线图", "绘制", "面积图", "揭示"],
        params: [
            .slider("duration", L("Draw duration", "绘制时长"), 0.6...3.0, default: 1.6, unit: "s"),
            .toggle("smooth", L("Smooth curve", "平滑曲线"), default: true),
            .toggle("area", L("Area fill", "面积填充"), default: true),
        ]
    ) { ctx in
        LineDrawDemo(ctx: ctx)
    }
}

private enum LineGeometry {
    static let size = CGSize(width: 290, height: 170)
    static let inset: CGFloat = 14

    static func points(_ values: [Double]) -> [CGPoint] {
        guard values.count > 1 else { return [] }
        let step = size.width / CGFloat(values.count - 1)
        return values.enumerated().map { index, value in
            CGPoint(x: CGFloat(index) * step, y: inset + (1 - CGFloat(value)) * (size.height - inset * 2))
        }
    }

    /// Catmull-Rom → Bézier controls, with mirrored phantom end points so x stays linear in t.
    static func controls(_ pts: [CGPoint], _ i: Int) -> (CGPoint, CGPoint) {
        let p1 = pts[i]
        let p2 = pts[i + 1]
        let p0 = i > 0 ? pts[i - 1] : CGPoint(x: 2 * p1.x - p2.x, y: 2 * p1.y - p2.y)
        let p3 = i + 2 < pts.count ? pts[i + 2] : CGPoint(x: 2 * p2.x - p1.x, y: 2 * p2.y - p1.y)
        let c1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
        let c2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
        return (c1, c2)
    }

    static func line(_ pts: [CGPoint], smooth: Bool) -> Path {
        Path { path in
            guard let first = pts.first, pts.count > 1 else { return }
            path.move(to: first)
            for i in 0..<(pts.count - 1) {
                if smooth {
                    let (c1, c2) = controls(pts, i)
                    path.addCurve(to: pts[i + 1], control1: c1, control2: c2)
                } else {
                    path.addLine(to: pts[i + 1])
                }
            }
        }
    }

    static func area(_ pts: [CGPoint], smooth: Bool) -> Path {
        var path = line(pts, smooth: smooth)
        guard let first = pts.first, let last = pts.last else { return path }
        path.addLine(to: CGPoint(x: last.x, y: size.height))
        path.addLine(to: CGPoint(x: first.x, y: size.height))
        path.closeSubpath()
        return path
    }

    static func y(at x: CGFloat, _ pts: [CGPoint], smooth: Bool) -> CGFloat {
        guard pts.count > 1 else { return size.height / 2 }
        let step = pts[1].x - pts[0].x
        guard step > 0 else { return pts[0].y }
        let i = min(max(Int(x / step), 0), pts.count - 2)
        let t = min(max((x - pts[i].x) / step, 0), 1)
        let a = pts[i].y
        let d = pts[i + 1].y
        guard smooth else { return a + (d - a) * t }
        let (c1, c2) = controls(pts, i)
        let mt = 1 - t
        return mt * mt * mt * a + 3 * mt * mt * t * c1.y + 3 * mt * t * t * c2.y + t * t * t * d
    }
}

private let lineDatasets: [[Double]] = [
    [0.22, 0.35, 0.3, 0.52, 0.46, 0.68, 0.6, 0.82, 0.9],
    [0.55, 0.42, 0.6, 0.38, 0.5, 0.72, 0.66, 0.58, 0.86],
    [0.15, 0.28, 0.5, 0.44, 0.7, 0.62, 0.78, 0.74, 0.95],
]

private struct LineDrawDemo: View {
    let ctx: DemoContext
    /// Seeded fully drawn so still snapshots show the line; `onAppear` rewinds and draws it on.
    @State private var progress: Double = 1
    @State private var dataset = 0
    /// Bumped by every replay; an older pending redraw bails out so rapid taps never swap data mid-draw.
    @State private var generation = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(ctx.language == .zh ? "营收" : "Revenue")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(ctx.language == .zh ? "近 9 个月" : "Last 9 months")
                    .font(.headline)
            }
            LineChartCanvas(
                progress: progress,
                values: lineDatasets[dataset % lineDatasets.count],
                smooth: ctx.bool("smooth"),
                showArea: ctx.bool("area")
            )
            monthAxis
        }
        .padding(16)
        .demoCard()
        .contentShape(Rectangle())
        .onTapGesture { replay() }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap to redraw", "点击重新绘制"), ctx: ctx)
                .padding(.bottom, 8)
        }
        .onAppear {
            ChartEntrance.replay(reset: {
                progress = 0
            }, then: {
                draw()
            })
        }
        // The entrance already runs in onAppear, so the detail stage's one-shot intro is turned off.
        .autoplay(ctx.isPreview, every: ctx["duration"] + 1.6, delay: ctx["duration"] + 1.2, intro: false) {
            replay()
        }
    }

    /// Every other month under its data point (9 points: Jan…Sep).
    private var monthAxis: some View {
        let en = ["Jan", "Mar", "May", "Jul", "Sep"]
        let zh = ["1月", "3月", "5月", "7月", "9月"]
        let labels = ctx.language == .zh ? zh : en
        let step = LineGeometry.size.width / 8
        return ZStack(alignment: .topLeading) {
            ForEach(labels.indices, id: \.self) { index in
                Text(verbatim: labels[index])
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .fixedSize()
                    .frame(width: 40)
                    .position(x: (step * CGFloat(index * 2)).clamped(to: 12...(LineGeometry.size.width - 12)), y: 6)
            }
        }
        .frame(width: LineGeometry.size.width, height: 12)
        .padding(.top, -6)
    }

    private func draw() {
        withAnimation(.timingCurve(0.65, 0, 0.35, 1, duration: ctx["duration"])) { progress = 1 }
    }

    private func replay() {
        withAnimation(.easeIn(duration: 0.25)) { progress = 0 }
        generation += 1
        let current = generation
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.3))
            guard current == generation else { return }
            dataset += 1
            draw()
        }
    }
}

private struct LineChartCanvas: View, Animatable {
    var progress: Double
    let values: [Double]
    let smooth: Bool
    let showArea: Bool

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    private var lineGradient: LinearGradient {
        LinearGradient(colors: [Palette.indigo, Palette.violet, Palette.pink], startPoint: .leading, endPoint: .trailing)
    }

    var body: some View {
        let size = LineGeometry.size
        let pts = LineGeometry.points(values)
        let p = CGFloat(min(max(progress, 0), 1))
        let tipX = p * size.width
        let tipY = LineGeometry.y(at: tipX, pts, smooth: smooth)

        ZStack(alignment: .topLeading) {
            guides
            if showArea {
                LineGeometry.area(pts, smooth: smooth)
                    .fill(LinearGradient(colors: [Palette.indigo.opacity(0.35), Palette.indigo.opacity(0)], startPoint: .top, endPoint: .bottom))
                    .mask(alignment: .leading) { Rectangle().frame(width: tipX) }
            }
            LineGeometry.line(pts, smooth: smooth)
                .stroke(lineGradient, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .mask(alignment: .leading) { Rectangle().frame(width: tipX) }
            tip(x: tipX, y: tipY)
                .opacity(p > 0.01 ? 1 : 0)
        }
        .frame(width: size.width, height: size.height)
    }

    /// Four guides from the top (value 26k) to the bottom (8k) of the plot, each labeled just above its line.
    private var guides: some View {
        VStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { index in
                Rectangle()
                    .fill(Color.primary.opacity(0.07))
                    .frame(height: 1)
                    .overlay(alignment: .bottomTrailing) {
                        Text(verbatim: "$\(26 - index * 6)k")
                            .font(.system(size: 9, weight: .semibold, design: .rounded).monospacedDigit())
                            .foregroundStyle(.tertiary)
                            .offset(y: -2)
                    }
                if index < 3 { Spacer(minLength: 0) }
            }
        }
        .padding(.vertical, LineGeometry.inset)
    }

    private func tip(x: CGFloat, y: CGFloat) -> some View {
        let normalized = 1 - (y - LineGeometry.inset) / (LineGeometry.size.height - LineGeometry.inset * 2)
        let value = 8 + normalized * 18
        // Keep the value pill (~52 pt wide) inside the chart so it never spills past the card edge.
        let pillHalf: CGFloat = 26
        let pillShift = max(0, pillHalf - x) + min(0, LineGeometry.size.width - pillHalf - x)
        return ZStack {
            Circle()
                .fill(Palette.violet.opacity(0.25))
                .frame(width: 26, height: 26)
            Circle()
                .fill(Palette.violet)
                .frame(width: 10, height: 10)
                .overlay(Circle().strokeBorder(.white, lineWidth: 2))
            Text(String(format: "$%.1fk", Double(value)))
                .font(.system(size: 10, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Palette.violet, in: Capsule())
                .fixedSize()
                .offset(x: pillShift, y: -22)
        }
        .position(x: x, y: y)
    }
}
