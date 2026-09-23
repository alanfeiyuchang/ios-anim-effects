import SwiftUI

extension Effect {
    static let morphCornerCascade = Effect(
        id: "morph.corner-cascade",
        category: .morph,
        interaction: .tap,
        name: L("Corner Cascade", "圆角接力"),
        summary: L(
            "Each corner of a tile re-rounds on its own, one after another clockwise, so the new silhouette rolls around the shape.",
            "方块的四个圆角依次独立变化，沿顺时针接力，新轮廓像绕着图形滚过一圈。"
        ),
        prompt: L(
            "A 180 pt gradient tile cycles through five silhouettes — square, circle, leaf, drop and tab — on each tap. Instead of all four corners changing together, the corners animate one after another clockwise from top-left, each starting ≈12% of the duration (≈110 ms at 0.9 s) after the previous one and each easing out with its own back-overshoot, so a rounded corner briefly bulges past its target before settling. The result reads as a wave of curvature rolling around the outline. A thin white rim follows the edge, the glyph in the middle swaps with a symbol replace, and the shape's name below swaps with a blur-replace. Crafted, rhythmic and quietly playful.",
            "一块约 180pt 的渐变方块，每次点击依次变为五种轮廓：方形、圆形、叶片、水滴与标签。四个圆角并非同时变化，而是从左上角开始顺时针逐一启动，每个角比前一个晚约 12% 的时长（0.9 秒时约 110 毫秒），并各自带有回拉式过冲缓出——圆角会先略微鼓过目标再回落。视觉上就像一道曲率之波绕着轮廓滚过一圈。细白描边贴合边缘，中间图标以符号替换动画切换，下方形状名称以模糊替换切换。精致、有节奏，又带一点俏皮。"
        ),
        implementation: L(
            "A Shape with a single animatable step value computes a staggered, back-eased local progress for each corner and builds its path from UnevenRoundedRectangle with the four interpolated radii.",
            "自定义 Shape 只暴露一个可动画的步进值，为每个角计算带错峰与回拉缓动的局部进度，再用四个插值后的半径生成 UnevenRoundedRectangle 路径。"
        ),
        apis: ["UnevenRoundedRectangle", "Shape", "animatableData", "smooth(duration:)", "transition(.blurReplace)"],
        tags: ["corner radius", "shape", "stagger", "morph", "圆角", "形状", "错峰", "形变"],
        params: [
            .slider("duration", L("Duration", "时长"), 0.4...1.6, default: 0.9, unit: "s"),
            .slider("stagger", L("Corner stagger", "角间错峰"), 0.0...0.25, default: 0.12),
            .slider("overshoot", L("Overshoot", "过冲"), 0.0...2.5, default: 1.2),
        ]
    ) { ctx in
        CornerCascadeDemo(ctx: ctx)
    }
}

/// Corner radii as fractions of the half side: top-leading, top-trailing, bottom-trailing, bottom-leading (clockwise).
private let cascadeShapes: [[Double]] = [
    [0.14, 0.14, 0.14, 0.14],
    [1, 1, 1, 1],
    [1, 0.1, 1, 0.1],
    [1, 1, 0.08, 1],
    [0.62, 0.62, 0.1, 0.1],
]

private let cascadeNames: [LocalizedText] = [
    L("Square", "方形"), L("Circle", "圆形"), L("Leaf", "叶片"), L("Drop", "水滴"), L("Tab", "标签"),
]

private let cascadeSymbols: [String] = ["square.fill", "circle.fill", "leaf.fill", "drop.fill", "folder.fill"]

private struct CornerCascadeDemo: View {
    let ctx: DemoContext
    @State private var step: Double = 0

    private var index: Int { Int(step) % cascadeShapes.count }

    var body: some View {
        VStack(spacing: 26) {
            tile
            Text(cascadeNames[index], ctx.language)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .id(index)
                .transition(.blurReplace)
            DemoHint(text: L("Tap the tile", "点击方块"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.5) { advance() }
    }

    private var tile: some View {
        let shape = CascadeShape(step: step, stagger: ctx["stagger"], overshoot: ctx["overshoot"])
        return ZStack {
            shape
                .fill(LinearGradient(colors: [Palette.sky, Palette.indigo, Palette.violet], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: Palette.indigo.opacity(0.35), radius: 20, y: 10)
            shape
                .stroke(.white.opacity(0.5), lineWidth: 1.5)
            Image(systemName: cascadeSymbols[index])
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .contentTransition(.symbolEffect(.replace))
        }
        .frame(width: 180, height: 180)
        .contentShape(Rectangle())
        .onTapGesture { advance() }
    }

    private func advance() {
        if !ctx.isPreview { Haptics.tap(.soft) }
        withAnimation(.smooth(duration: ctx["duration"])) {
            step += 1
        }
    }
}

private struct CascadeShape: Shape {
    var step: Double
    let stagger: Double
    let overshoot: Double

    var animatableData: Double {
        get { step }
        set { step = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let count = cascadeShapes.count
        let base: Double = max(step, 0).rounded(.down)
        let t: Double = max(step, 0) - base
        let from: [Double] = cascadeShapes[Int(base) % count]
        let to: [Double] = cascadeShapes[(Int(base) + 1) % count]
        let half: Double = Double(min(rect.width, rect.height)) / 2
        let span: Double = max(1 - 3 * stagger, 0.1)
        var radii: [CGFloat] = []
        for corner in 0..<4 {
            let local: Double = min(max((t - Double(corner) * stagger) / span, 0), 1)
            let eased: Double = backOut(local)
            let value: Double = from[corner] + (to[corner] - from[corner]) * eased
            radii.append(CGFloat(min(max(value, 0), 1) * half))
        }
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: radii[0],
            bottomLeadingRadius: radii[3],
            bottomTrailingRadius: radii[2],
            topTrailingRadius: radii[1],
            style: .continuous
        )
        return shape.path(in: rect)
    }

    /// Ease-out with an overshoot ("back") of strength `overshoot`.
    private func backOut(_ x: Double) -> Double {
        let c1: Double = overshoot
        let c3: Double = c1 + 1
        let u: Double = x - 1
        return 1 + c3 * u * u * u + c1 * u * u
    }
}
