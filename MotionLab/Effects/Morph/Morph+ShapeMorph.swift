import SwiftUI

extension Effect {
    static let morphShapeMorph = Effect(
        id: "morph.shape-morph",
        category: .morph,
        interaction: .tap,
        name: L("Shape Morph", "形状形变"),
        summary: L(
            "Circle → squircle → blob → flower, interpolated point by point.",
            "圆形 → 超椭圆 → 液滴 → 花瓣，逐点插值的形状变形。"
        ),
        prompt: L(
            "A 200 pt gradient shape floats at center over a blurred glow of the same silhouette that breathes on its own slow loop (opacity 40% ↔ 70%, scale 92% ↔ 104%, 1.6 s ease-in-out each way). Each tap morphs its outline to the next form in a loop — circle, squircle, organic blob, six-petal flower — by interpolating 180 radial sample points between the two silhouettes, so edges flow continuously instead of cross-fading. The morph rides a spring (≈0.8 s, bounce ≈0.25) that lets the outline slightly overshoot into the next form before settling; simultaneously the shape rotates 45° and its hue drifts 40°, the glow following the outline. All four forms share the same mean radius so no step pops in size. A small caption naming the current shape swaps with a blur-replace transition. It should feel liquid, sculptural and alive.",
            "画面中央悬浮一个约 200pt 的渐变图形，下方是同形状的模糊辉光，按自己的节奏缓慢呼吸（透明度 40% ↔ 70%、缩放 92% ↔ 104%，单程 1.6 秒缓入缓出）。每次点击，轮廓会按「圆形 → 超椭圆 → 有机液滴 → 六瓣花」循环变形到下一个形态：在两种轮廓之间对 180 个径向采样点逐点插值，边缘连续流动而非交叉淡入。形变采用弹簧曲线（约 0.8 秒、回弹约 0.25），轮廓会略微冲过目标形态再回落；同时图形旋转 45°、色相偏移 40°，辉光随轮廓一起变形。四种形态的平均半径一致，切换时不会忽大忽小。下方标注当前形状名称的小字以模糊替换方式切换。整体应当流动、有雕塑感、充满生命力。"
        ),
        implementation: L(
            "A custom Shape exposes a continuous morph progress as animatableData and builds its path from a blend of polar radius functions; rotation and hueRotation are driven by the same value, and a blurred copy breathes underneath with phaseAnimator.",
            "自定义 Shape 将连续的形变进度暴露为 animatableData，用多个极坐标半径函数的混合生成路径；旋转与色相偏移由同一数值驱动，下层模糊副本用 phaseAnimator 呼吸。"
        ),
        apis: ["Shape", "animatableData", "Path", "spring(duration:bounce:)", "hueRotation", "phaseAnimator"],
        tags: ["shape", "morph", "blob", "path animation", "形状", "变形", "路径动画", "液态"],
        params: [
            .slider("duration", L("Duration", "时长"), 0.3...1.5, default: 0.8, unit: "s"),
            .slider("bounce", L("Bounce", "回弹"), 0.0...0.5, default: 0.25),
            .toggle("spin", L("Rotate while morphing", "形变时旋转"), default: true),
        ]
    ) { ctx in
        ShapeMorphDemo(ctx: ctx)
    }
}

private let morphShapeNames: [LocalizedText] = [
    L("Circle", "圆形"), L("Squircle", "超椭圆"), L("Blob", "液滴"), L("Flower", "花瓣"),
]

private struct ShapeMorphDemo: View {
    let ctx: DemoContext
    @State private var step = 0

    private var progress: Double { Double(step) }

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                MorphingBlob(progress: progress)
                    .fill(Palette.primary)
                    .blur(radius: 28)
                    // The glow breathes on its own slow loop, independent of the morph spring.
                    .phaseAnimator([false, true]) { content, inhale in
                        content
                            .opacity(inhale ? 0.7 : 0.4)
                            .scaleEffect(inhale ? 1.04 : 0.92)
                    } animation: { _ in
                        .easeInOut(duration: 1.6)
                    }
                MorphingBlob(progress: progress)
                    .fill(
                        LinearGradient(colors: [Palette.pink, Palette.violet, Palette.indigo],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .overlay {
                        MorphingBlob(progress: progress)
                            .stroke(.white.opacity(0.35), lineWidth: 1)
                    }
            }
            .frame(width: 200, height: 200)
            .rotationEffect(.degrees(ctx.bool("spin") ? progress * 45 : 0))
            .hueRotation(.degrees(progress * 40))
            .contentShape(Rectangle())
            .onTapGesture { advance() }

            Text(morphShapeNames[step % morphShapeNames.count], ctx.language)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .id(step)
                .transition(.blurReplace)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap the shape", "点击图形"), ctx: ctx)
                .padding(.bottom, 14)
        }
        .autoplay(ctx.isPreview, every: 1.4) { advance() }
    }

    private func advance() {
        if !ctx.isPreview { Haptics.tap(.soft) }
        withAnimation(.spring(duration: ctx["duration"], bounce: ctx["bounce"])) {
            step += 1
        }
    }
}

/// Blends between four radial silhouettes. `progress` 0,1,2,3 are the pure shapes; it wraps every 4.
private struct MorphingBlob: Shape {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let count = 4
        let p = max(progress, 0)
        let base = p.rounded(.down)
        let t = p - base
        let from = Int(base) % count
        let to = (from + 1) % count
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let scale = Double(min(rect.width, rect.height)) / 2
        let samples = 180

        var path = Path()
        for i in 0..<samples {
            let theta = Double(i) / Double(samples) * 2 * Double.pi
            let r = (1 - t) * radius(from, theta) + t * radius(to, theta)
            let point = CGPoint(
                x: center.x + CGFloat(cos(theta) * r * scale),
                y: center.y + CGFloat(sin(theta) * r * scale)
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }

    private func radius(_ kind: Int, _ theta: Double) -> Double {
        switch kind {
        case 0:
            // Same mean radius as the other silhouettes, so the circle doesn't pop larger.
            return 0.84
        case 1:
            let n = 5.0
            let denom = pow(abs(cos(theta)), n) + pow(abs(sin(theta)), n)
            return 0.8 / pow(denom, 1 / n)
        case 2:
            return 0.84 + 0.09 * sin(3 * theta + 0.6) + 0.05 * cos(5 * theta - 0.4)
        default:
            return 0.8 + 0.14 * cos(6 * theta)
        }
    }
}
