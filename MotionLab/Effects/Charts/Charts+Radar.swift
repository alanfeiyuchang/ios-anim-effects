import SwiftUI

extension Effect {
    static let chartsRadarMorph = Effect(
        id: "charts.radar-morph",
        category: .charts,
        interaction: .tap,
        name: L("Radar Chart Morph", "雷达图形变"),
        summary: L("A six-axis radar polygon that springs between datasets while its color cross-fades.", "六轴雷达多边形在数据集之间弹性形变，颜色同步渐变。"),
        prompt: L(
            "A 196 pt six-axis radar chart: four concentric hexagonal guides and six spokes in 8–12% primary, axis labels in caption type just outside the rim, and a data polygon filled with its dataset color at 25% plus a 2 pt stroke and 7 pt vertex dots with a soft colored glow. A segmented control of three pills (v1.0, v2.0, v3.0) sits below, its selection capsule sliding between pills via matched geometry. Choosing a dataset morphs every vertex simultaneously to its new radius on one spring (response ≈ 0.6 s, damping ≈ 0.65), so the shape swells, pinches and overshoots slightly like an elastic membrane, while fill and stroke cross-fade to the new color over the same timing. A selection haptic confirms each switch. Organic, comparative and instantly readable.",
            "一张 196pt 的六轴雷达图：四圈同心六边形参考线与六条辐射轴为 8–12% 主色，轴标签以说明字号置于外圈之外；数据多边形以所属数据集颜色 25% 填充，配 2pt 描边与带柔和同色光晕的 7pt 顶点圆点。下方是由三个胶囊组成的分段控件（v1.0、v2.0、v3.0），选中胶囊借助几何匹配在选项间滑动。切换数据集时，所有顶点在同一个弹簧（响应约 0.6 秒、阻尼约 0.65）中同时移动到新半径，图形像弹性薄膜一样膨胀、收缩并轻微过冲；填充与描边在同一节奏中渐变到新颜色。每次切换伴随选择触感。有机、便于对比、一目了然。"
        ),
        implementation: L(
            "A custom VectorArithmetic type wraps the array of radii so a Shape can animate all vertices at once through animatableData; the segmented pills use matchedGeometryEffect for the sliding selection.",
            "自定义 VectorArithmetic 类型包装半径数组，使 Shape 能通过 animatableData 同时为所有顶点做动画；分段胶囊使用 matchedGeometryEffect 实现选中态滑动。"
        ),
        apis: ["VectorArithmetic", "Shape.animatableData", "matchedGeometryEffect", "spring(response:dampingFraction:)"],
        tags: ["radar chart", "spider chart", "morph", "compare", "雷达图", "蜘蛛图", "形变", "对比"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.3...1.2, default: 0.6, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.3...1.0, default: 0.65),
            .toggle("dots", L("Vertex dots", "顶点圆点"), default: true),
        ]
    ) { ctx in
        RadarDemo(ctx: ctx)
    }
}

/// Animatable vector of Doubles; lengths are padded with zeros when they differ.
private struct AnimatableVector: VectorArithmetic {
    var values: [Double]

    static var zero: AnimatableVector { AnimatableVector(values: []) }

    static func + (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector {
        combine(lhs, rhs) { $0 + $1 }
    }

    static func - (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector {
        combine(lhs, rhs) { $0 - $1 }
    }

    mutating func scale(by rhs: Double) {
        values = values.map { $0 * rhs }
    }

    var magnitudeSquared: Double {
        values.reduce(0) { $0 + $1 * $1 }
    }

    private static func combine(_ a: AnimatableVector, _ b: AnimatableVector, _ op: (Double, Double) -> Double) -> AnimatableVector {
        let count = max(a.values.count, b.values.count)
        var result = [Double](repeating: 0, count: count)
        for i in 0..<count {
            let x = i < a.values.count ? a.values[i] : 0
            let y = i < b.values.count ? b.values[i] : 0
            result[i] = op(x, y)
        }
        return AnimatableVector(values: result)
    }
}

private enum RadarGeometry {
    static func point(index: Int, count: Int, radius: CGFloat, center: CGPoint) -> CGPoint {
        let angle = -Double.pi / 2 + 2 * Double.pi * Double(index) / Double(count)
        return CGPoint(x: center.x + CGFloat(cos(angle)) * radius, y: center.y + CGFloat(sin(angle)) * radius)
    }

    static func polygon(_ values: [Double], in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        for (index, value) in values.enumerated() {
            let p = point(index: index, count: values.count, radius: radius * CGFloat(max(value, 0)), center: center)
            if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }
}

private struct RadarShape: Shape {
    var values: AnimatableVector

    var animatableData: AnimatableVector {
        get { values }
        set { values = newValue }
    }

    func path(in rect: CGRect) -> Path {
        RadarGeometry.polygon(values.values, in: rect)
    }
}

private struct RadarDots: Shape {
    var values: AnimatableVector

    var animatableData: AnimatableVector {
        get { values }
        set { values = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        for (index, value) in values.values.enumerated() {
            let p = RadarGeometry.point(index: index, count: values.values.count, radius: radius * CGFloat(max(value, 0)), center: center)
            path.addEllipse(in: CGRect(x: p.x - 3.5, y: p.y - 3.5, width: 7, height: 7))
        }
        return path
    }
}

private struct RadarDataset {
    let name: String
    let color: Color
    let values: [Double]
}

private let radarDatasets: [RadarDataset] = [
    RadarDataset(name: "v1.0", color: Palette.indigo, values: [0.55, 0.4, 0.7, 0.45, 0.6, 0.35]),
    RadarDataset(name: "v2.0", color: Palette.pink, values: [0.75, 0.68, 0.5, 0.82, 0.55, 0.62]),
    RadarDataset(name: "v3.0", color: Palette.mint, values: [0.92, 0.85, 0.88, 0.7, 0.95, 0.9]),
]

private let radarAxes: [LocalizedText] = [
    L("Speed", "速度"), L("Craft", "质感"), L("Motion", "动效"),
    L("Clarity", "清晰"), L("Delight", "愉悦"), L("Access", "无障碍"),
]

private struct RadarDemo: View {
    let ctx: DemoContext
    @State private var selection = 0
    @Namespace private var pillSpace

    private let size: CGFloat = 196

    var body: some View {
        let dataset = radarDatasets[selection]
        VStack(spacing: 20) {
            ZStack {
                RadarGrid(axes: radarAxes.count)
                RadarShape(values: AnimatableVector(values: dataset.values))
                    .fill(dataset.color.opacity(0.25))
                RadarShape(values: AnimatableVector(values: dataset.values))
                    .stroke(dataset.color, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
                if ctx.bool("dots") {
                    RadarDots(values: AnimatableVector(values: dataset.values))
                        .fill(dataset.color)
                        .shadow(color: dataset.color.opacity(0.5), radius: 3)
                }
                axisLabels
            }
            .frame(width: size, height: size)
            .padding(24)
            pills
            ChartTapCue(text: L("Pick a product to compare", "选择产品进行对比"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.8) { select((selection + 1) % radarDatasets.count) }
    }

    private var axisLabels: some View {
        ForEach(radarAxes.indices, id: \.self) { index in
            let p = RadarGeometry.point(
                index: index,
                count: radarAxes.count,
                radius: size / 2 + 18,
                center: CGPoint(x: size / 2, y: size / 2)
            )
            Text(radarAxes[index], ctx.language)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .fixedSize()
                .position(p)
        }
    }

    private var pills: some View {
        HStack(spacing: 4) {
            ForEach(radarDatasets.indices, id: \.self) { index in
                Button {
                    select(index)
                } label: {
                    Text(radarDatasets[index].name)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(selection == index ? Color.white : Color.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background {
                            if selection == index {
                                Capsule()
                                    .fill(radarDatasets[index].color.gradient)
                                    .matchedGeometryEffect(id: "pill", in: pillSpace)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Palette.surface, in: Capsule())
        .overlay(Capsule().strokeBorder(Palette.stroke, lineWidth: 1))
    }

    /// Pills and autoplay share this; the haptic is muted inside autoplay, so only real taps tick.
    private func select(_ index: Int) {
        if index != selection { Haptics.selection() }
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            selection = index
        }
    }
}

private struct RadarGrid: View {
    let axes: Int

    var body: some View {
        ZStack {
            ForEach(1...4, id: \.self) { level in
                RadarShape(values: AnimatableVector(values: Array(repeating: Double(level) / 4, count: axes)))
                    .stroke(Color.primary.opacity(level == 4 ? 0.12 : 0.08), lineWidth: 1)
            }
            SpokesShape(count: axes)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct SpokesShape: Shape {
    let count: Int

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        for index in 0..<count {
            path.move(to: center)
            path.addLine(to: RadarGeometry.point(index: index, count: count, radius: radius, center: center))
        }
        return path
    }
}
