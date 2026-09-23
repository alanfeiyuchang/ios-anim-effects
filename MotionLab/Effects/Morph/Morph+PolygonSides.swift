import SwiftUI

extension Effect {
    static let morphPolygonSides = Effect(
        id: "morph.polygon-sides",
        category: .morph,
        interaction: .gesture,
        name: L("Polygon Scrub", "多边形拖拽形变"),
        summary: L(
            "Drag sideways to grow a triangle into an octagon — new corners bud out of the edges and snap into place.",
            "左右拖动，三角形逐步长成八边形：新的角从边上鼓出，松手后弹性吸附到整数边数。"
        ),
        prompt: L(
            "A 190 pt gradient polygon with softly rounded corners sits at center above a label such as \"Hexagon · 6\". Dragging horizontally scrubs its side count continuously from 3 to 8 (one side per 36 pt of travel): the outline blends between the neighbouring regular polygons, so a new vertex visibly swells out of the middle of an edge instead of popping in, while the whole form turns 30° per added side as if it were being wound open. A selection haptic ticks each time the rounded count changes. On release the count springs to the nearest whole number (damping ≈0.55) with a small overshoot that makes the edges wobble before they straighten. A tap adds one side. Tactile, mathematical, satisfying.",
            "画面中央是约 190pt、圆角柔和的渐变多边形，下方标注当前形状（如「六边形 · 6」）。左右拖动时边数在 3 到 8 之间连续变化（每 36pt 位移一条边）：轮廓在相邻两个正多边形之间插值，因此新顶点会从某条边的中点慢慢鼓出，而不是突然出现；同时整体每增加一条边旋转 30°，像被拧开一样。每当四舍五入后的边数变化，就触发一次选择触觉。松手后边数以弹簧（阻尼约 0.55）吸附到最近的整数，带轻微过冲，边线先晃动再拉直。点击则增加一条边。触感清晰、带数学美感、令人满足。"
        ),
        implementation: L(
            "A Shape with an animatable side count samples 240 polar points, blending the radius functions of the floor and ceiling regular polygons and mixing in a circle for roundness; a DragGesture scrubs the value and a spring snaps it.",
            "自定义 Shape 以可动画的边数为输入，采样 240 个极坐标点，在向下取整与向上取整的两个正多边形半径函数间插值，并混入圆形以柔化圆角；DragGesture 连续拖动数值，松手后用弹簧吸附。"
        ),
        apis: ["Shape", "animatableData", "DragGesture", "spring(response:dampingFraction:)", "sensoryFeedback"],
        tags: ["polygon", "shape", "scrub", "morph", "多边形", "形状", "拖动", "形变"],
        params: [
            .slider("damping", L("Snap damping", "吸附阻尼"), 0.3...1.0, default: 0.55),
            .slider("round", L("Roundness", "圆润度"), 0.0...0.6, default: 0.18),
            .toggle("spin", L("Turn with each side", "随边数旋转"), default: true),
        ]
    ) { ctx in
        PolygonSidesDemo(ctx: ctx)
    }
}

private let polygonNames: [LocalizedText] = [
    L("Triangle", "三角形"), L("Square", "四边形"), L("Pentagon", "五边形"),
    L("Hexagon", "六边形"), L("Heptagon", "七边形"), L("Octagon", "八边形"),
]

private struct PolygonSidesDemo: View {
    let ctx: DemoContext
    @State private var sides: Double = 3
    @State private var dragStart: Double?
    @State private var tick = 0

    private var rounded: Int { Int(sides.rounded()).clamped(to: 3...8) }

    var body: some View {
        VStack(spacing: 26) {
            shape
            label
            DemoHint(text: L("Drag sideways · tap to add a side", "左右拖动 · 点击加一条边"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(drag)
        .onTapGesture { step() }
        .sensoryFeedback(.selection, trigger: tick)
        .autoplay(ctx.isPreview, every: 1.1) { step() }
    }

    private var shape: some View {
        let turn: Double = ctx.bool("spin") ? (sides - 3) * 30 : 0
        let roundness: Double = ctx["round"]
        return ZStack {
            PolygonBlend(sides: sides, roundness: roundness)
                .fill(Palette.sunset)
                .blur(radius: 24)
                .opacity(0.5)
            PolygonBlend(sides: sides, roundness: roundness)
                .fill(LinearGradient(colors: [Palette.amber, Palette.coral, Palette.pink], startPoint: .top, endPoint: .bottom))
            PolygonBlend(sides: sides, roundness: roundness)
                .stroke(.white.opacity(0.45), lineWidth: 1.5)
        }
        .frame(width: 190, height: 190)
        .rotationEffect(.degrees(turn))
    }

    private var label: some View {
        HStack(spacing: 8) {
            Text(polygonNames[rounded - 3], ctx.language)
                .id(rounded)
                .transition(.blurReplace)
            Text(verbatim: "·").foregroundStyle(.tertiary)
            Text(verbatim: "\(rounded)")
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(rounded)))
        }
        .font(.headline)
        .foregroundStyle(.secondary)
        .animation(.snappy, value: rounded)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                let start = dragStart ?? sides
                if dragStart == nil { dragStart = sides }
                let before = rounded
                let raw = start + Double(value.translation.width) / 36
                withAnimation(.interactiveSpring(response: 0.18, dampingFraction: 0.86)) {
                    sides = raw.clamped(to: 3...8)
                }
                if rounded != before { tick += 1 }
            }
            .onEnded { _ in
                dragStart = nil
                snap(to: Double(rounded))
            }
    }

    private func step() {
        let next: Double = rounded >= 8 ? 3 : Double(rounded + 1)
        if !ctx.isPreview { tick += 1 }
        snap(to: next)
    }

    private func snap(to value: Double) {
        withAnimation(.spring(response: 0.5, dampingFraction: ctx["damping"])) {
            sides = value
        }
    }
}

/// Blends the radius functions of the two regular polygons around a fractional side count.
private struct PolygonBlend: Shape {
    var sides: Double
    var roundness: Double

    var animatableData: Double {
        get { sides }
        set { sides = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let clampedSides: Double = min(max(sides, 2.6), 8.6)
        let low: Double = max(clampedSides.rounded(.down), 3)
        let high: Double = low + 1
        let t: Double = min(max(clampedSides - low, -0.4), 1.4)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let scale: Double = Double(min(rect.width, rect.height)) / 2
        let samples = 240
        var path = Path()
        for i in 0..<samples {
            let theta: Double = Double(i) / Double(samples) * 2 * Double.pi
            let a: Double = radius(Int(low), theta)
            let b: Double = radius(Int(high), theta)
            let blended: Double = a + (b - a) * t
            let soft: Double = blended * (1 - roundness) + 0.86 * roundness
            let r: Double = soft * scale
            let angle: Double = theta - Double.pi / 2
            let point = CGPoint(x: center.x + CGFloat(cos(angle) * r), y: center.y + CGFloat(sin(angle) * r))
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }

    /// Distance from the centre to a regular n-gon's outline (circumradius 1, a vertex at theta = 0).
    private func radius(_ n: Int, _ theta: Double) -> Double {
        let segment: Double = 2 * Double.pi / Double(n)
        var local: Double = theta.truncatingRemainder(dividingBy: segment)
        if local < 0 { local += segment }
        let half: Double = segment / 2
        return cos(half) / cos(local - half)
    }
}
