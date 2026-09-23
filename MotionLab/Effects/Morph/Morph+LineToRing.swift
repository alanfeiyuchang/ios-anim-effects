import SwiftUI

extension Effect {
    static let morphLineToRing = Effect(
        id: "morph.line-to-ring",
        category: .morph,
        interaction: .tap,
        name: L("Line to Ring", "直线卷成圆环"),
        summary: L(
            "A progress bar curls up into a ring without changing length, then unrolls back flat.",
            "进度条在保持长度不变的前提下卷成圆环，再舒展回直线。"
        ),
        prompt: L(
            "A 220 pt rounded stroke (10 pt, indigo-to-pink gradient) sits flat like a progress bar over a faint track. On tap it curls into a closed ring: its arc length stays exactly 220 pt while its curvature rises from zero to a full 360°, so the ends lift and wrap around until they meet as a ≈35 pt-radius circle centered where the bar was. The curl rides a spring (response ≈0.7 s, bounce ≈0.3); the overshoot winds the ends slightly past each other before they settle, and on the way back the line briefly bows the opposite way before lying flat. The whole stroke turns a quarter turn while curling, the track fades out and a caption swaps between \"Progress bar\" and \"Ring\". Elegant, continuous, like a ribbon.",
            "一条 220pt、10pt 粗、由靛蓝渐变到粉色的圆头线条平躺在淡色轨道上，像一根进度条。点击后它卷成闭合圆环：弧长始终保持 220pt，曲率从 0 逐渐增加到完整的 360°，两端抬起并向内卷，最终在原位置中心合成半径约 35pt 的圆。卷曲过程使用弹簧（响应约 0.7 秒、回弹约 0.3）：过冲时两端会略微交错卷过头再回落；展开时线条会先向反方向轻微弯一下再躺平。卷曲同时整条线旋转四分之一圈，底部轨道淡出，说明文字在「进度条」与「圆环」之间切换。优雅、连续，像一条缎带。"
        ),
        implementation: L(
            "A Shape parameterised by an animatable curl value lays out 120 points along an arc of constant length whose total angle is curl × 2π, falling back to a straight line near zero curvature and shifting vertically so the ring stays centred.",
            "以可动画的卷曲值为参数的自定义 Shape：沿总角度为 curl × 2π、长度恒定的圆弧排布 120 个点；曲率接近 0 时退化为直线，并在竖直方向补偿位移，使圆环保持居中。"
        ),
        apis: ["Shape", "animatableData", "stroke(_:style:)", "spring(response:dampingFraction:)", "rotationEffect"],
        tags: ["line", "ring", "curl", "path morph", "直线", "圆环", "卷曲", "路径形变"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.3...1.2, default: 0.7, unit: "s"),
            .slider("bounce", L("Bounce", "回弹"), 0.0...0.5, default: 0.3),
            .slider("width", L("Stroke width", "线宽"), 4...16, default: 10, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        LineToRingDemo(ctx: ctx)
    }
}

private struct LineToRingDemo: View {
    let ctx: DemoContext
    @State private var curled = false

    var body: some View {
        let curl: Double = curled ? 1 : 0
        let width = ctx.cg("width")
        return VStack(spacing: 30) {
            ZStack {
                Capsule()
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 220, height: width)
                    .opacity(curled ? 0 : 1)
                CurlLine(curl: curl, length: 220)
                    .stroke(
                        LinearGradient(colors: [Palette.indigo, Palette.violet, Palette.pink], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
                    )
                    .shadow(color: Palette.violet.opacity(0.35), radius: 10, y: 4)
                    .rotationEffect(.degrees(curl * 90))
            }
            .frame(width: 260, height: 200)
            .contentShape(Rectangle())
            .onTapGesture { toggle() }

            Text(curled ? L("Ring", "圆环") : L("Progress bar", "进度条"), ctx.language)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .id(curled)
                .transition(.blurReplace)
            DemoHint(text: L("Tap the line", "点击线条"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.6) { toggle() }
    }

    private func toggle() {
        if !ctx.isPreview { Haptics.tap(.soft) }
        withAnimation(.spring(response: ctx["response"], dampingFraction: 1 - ctx["bounce"])) {
            curled.toggle()
        }
    }
}

/// A stroke of fixed arc length whose total turning angle is `curl * 2π`.
private struct CurlLine: Shape {
    var curl: Double
    let length: Double

    var animatableData: Double {
        get { curl }
        set { curl = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let samples = 120
        let kappa: Double = curl * 2 * Double.pi / length
        let ringRadius: Double = length / (2 * Double.pi)
        let lift: Double = curl * ringRadius
        let cx: Double = Double(rect.midX)
        let cy: Double = Double(rect.midY)
        var path = Path()
        for i in 0...samples {
            let u: Double = (Double(i) / Double(samples) - 0.5) * length
            var x: Double = u
            var y: Double = 0
            if abs(kappa) > 0.0001 {
                let phi: Double = u * kappa
                x = sin(phi) / kappa
                y = (1 - cos(phi)) / kappa
            }
            let point = CGPoint(x: cx + x, y: cy - y + lift)
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        return path
    }
}
