import SwiftUI

extension Effect {
    static let backgroundsAurora = Effect(
        id: "backgrounds.aurora",
        category: .backgrounds,
        interaction: .loop,
        name: L("Aurora Ribbons", "极光飘带"),
        summary: L(
            "Luminous curtains of green and violet undulate over a starlit ridge.",
            "绿紫交织的光幕在星空与山脊之上缓缓起伏。"
        ),
        prompt: L(
            "A night-sky scene: a deep navy-to-teal vertical gradient scattered with ~70 pinpoint stars that twinkle independently on roughly 3–6 s cycles, and a dark mountain ridge silhouette along the bottom. Above it, four wide, heavily blurred aurora ribbons (mint, cyan-indigo, pale green, violet-pink) sway across the sky; each ribbon is a stroked sine curve built from two summed waves whose phases advance at slightly different rates (≈ 8–12 s periods), so the curtains ripple, cross and breathe in thickness. Ribbons use additive blending with horizontal fades at both ends; rising from each one, a curtain of thin vertical rays (every 6 pt, 10–30% of the sky tall) glows brightest at the ribbon's edge and fades upward, their lengths and brightness shimmering along the curtain, while a faint upper echo adds depth. The feeling is serene, cinematic and quietly awe-inspiring.",
            "夜空场景：由深海军蓝过渡到青绿的纵向渐变背景，点缀约 70 颗独立闪烁（周期约 3–6 秒）的细小星点，底部是一道深色山脊剪影。天空中四条宽幅、强模糊的极光飘带（薄荷绿、青蓝、浅绿、紫粉）横贯摇曳：每条飘带是由两组正弦波叠加而成的描边曲线，相位以略有差异的速率推进（周期约 8–12 秒），因此光幕不断起伏、交错，粗细也随之呼吸。飘带采用叠加混合，两端横向淡出；每条飘带上方升起一排细密的竖直光柱（间隔 6pt，高度为天空的 10%～30%），在飘带边缘最亮并向上渐隐，长短与明暗沿光幕闪烁流动，上方另有一层更淡的回声增加纵深。整体静谧、电影感十足，令人屏息。"
        ),
        implementation: L(
            "One Canvas per frame: stars in the base context; a lightly blurred .plusLighter layer strokes vertical rays (batched into three brightness bins per ribbon) with an upward-fading gradient; a heavily blurred layer strokes four sine-wave ribbons with fading linear gradients; a ridge path is filled last.",
            "每帧一个 Canvas：先在主上下文绘制星点；在轻度模糊的 .plusLighter 图层中以向上渐隐的渐变描边竖直光柱（每条飘带按亮度分三档批量绘制）；再在强模糊图层中描边四条渐隐线性渐变的正弦飘带；最后填充山脊。"
        ),
        apis: ["Canvas", "TimelineView(.animation)", "GraphicsContext.drawLayer", "GraphicsContext.Filter.blur", ".plusLighter"],
        tags: ["aurora", "northern lights", "night", "blur", "极光", "北极光", "夜空", "星空"],
        params: [
            .slider("speed", L("Flow speed", "流动速度"), 0.2...2.0, default: 0.7, unit: "×"),
            .slider("blur", L("Softness", "柔化程度"), 8...60, default: 26, decimals: 0, unit: "pt"),
            .slider("intensity", L("Intensity", "亮度"), 0.3...1.0, default: 0.85),
        ]
    ) { ctx in
        AuroraDemo(ctx: ctx)
    }
}

private struct AuroraDemo: View {
    let ctx: DemoContext
    @State private var clock = BackgroundClock()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x02040C), Color(hex: 0x071A2E), Color(hex: 0x0B2A3A)],
                startPoint: .top,
                endPoint: .bottom
            )
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let t = clock.advance(to: timeline.date.timeIntervalSinceReferenceDate, speed: ctx["speed"])
                AuroraCanvas(t: t, blur: ctx.cg("blur"), intensity: ctx["intensity"])
            }
            BackgroundSampleTitle(
                title: L("Tonight", "今夜"),
                subtitle: L("Aurora activity · High", "极光活跃度 · 高"),
                language: ctx.language,
                size: 26
            )
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 40)
        }
    }
}

private struct AuroraCanvas: View {
    let t: Double
    let blur: CGFloat
    let intensity: Double

    private static let ribbons: [(Color, Color)] = [
        (Color(hex: 0x21D4A8), Color(hex: 0x3AF2C0)),
        (Color(hex: 0x3AC4FF), Color(hex: 0x6E7BFF)),
        (Color(hex: 0x7CFFB2), Color(hex: 0x21D4A8)),
        (Color(hex: 0xA46BFF), Color(hex: 0xFF5FA2)),
    ]

    var body: some View {
        Canvas { context, size in
            AuroraCanvas.drawStars(&context, size: size, t: t)
            // Vertical ray curtains rising from each ribbon: lightly blurred so individual rays stay visible.
            context.drawLayer { layer in
                layer.addFilter(.blur(radius: max(1.5, blur * 0.12)))
                layer.blendMode = .plusLighter
                layer.opacity = intensity
                for index in 0..<AuroraCanvas.ribbons.count {
                    AuroraCanvas.drawRays(&layer, index: index, size: size, t: t)
                }
            }
            context.drawLayer { layer in
                layer.addFilter(.blur(radius: blur))
                layer.blendMode = .plusLighter
                layer.opacity = intensity
                for index in 0..<AuroraCanvas.ribbons.count {
                    AuroraCanvas.drawRibbon(&layer, index: index, size: size, t: t)
                }
            }
            AuroraCanvas.drawRidge(&context, size: size)
        }
    }

    private static func drawStars(_ context: inout GraphicsContext, size: CGSize, t: Double) {
        for i in 0..<70 {
            let x = BackgroundMath.unit(i, 1) * size.width
            let y = BackgroundMath.unit(i, 2) * size.height * 0.8
            let r = 0.4 + BackgroundMath.unit(i, 3) * 1.1
            let rate = 1.5 + BackgroundMath.rand(i, 4) * 2
            let twinkle = 0.3 + 0.7 * (0.5 + 0.5 * sin(t * rate + Double(i)))
            let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
            context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(twinkle * 0.8)))
        }
    }

    /// The ribbon's center line at `x`.
    private static func ribbonY(index i: Int, x: CGFloat, size: CGSize, t: Double) -> CGFloat {
        let h = size.height
        let di = Double(i)
        let base = h * (0.3 + 0.09 * CGFloat(i))
        let u = Double(x / max(size.width, 1))
        let wave1 = sin(u * (3.2 + di * 0.7) + t * (0.6 + di * 0.17) + di * 1.9)
        let wave2 = sin(u * 7.1 - t * (0.9 + di * 0.11))
        return base + CGFloat(wave1) * h * 0.08 + CGFloat(wave2) * h * 0.025
    }

    private static func ribbonPath(index i: Int, size: CGSize, t: Double) -> Path {
        let w = size.width
        var path = Path()
        var x: CGFloat = -40
        while x <= w + 40 {
            let y = ribbonY(index: i, x: x, size: size, t: t)
            if x == -40 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
            x += 10
        }
        return path
    }

    private static func drawRibbon(_ context: inout GraphicsContext, index i: Int, size: CGSize, t: Double) {
        let path = ribbonPath(index: i, size: size, t: t)
        let pair = ribbons[i % ribbons.count]
        let h = size.height
        let lineWidth = h * (0.1 + 0.04 * CGFloat(sin(t * 0.5 + Double(i))))
        let gradient = Gradient(stops: [
            .init(color: pair.0.opacity(0), location: 0),
            .init(color: pair.0.opacity(0.9), location: 0.3),
            .init(color: pair.1.opacity(0.8), location: 0.7),
            .init(color: pair.1.opacity(0), location: 1),
        ])
        let shading = GraphicsContext.Shading.linearGradient(
            gradient,
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: size.width, y: 0)
        )
        context.stroke(path, with: shading, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))

        // A fainter, thinner echo above gives the curtain vertical depth.
        let echo = path.applying(CGAffineTransform(translationX: 0, y: -lineWidth * 0.9))
        var faint = context
        faint.opacity = 0.35
        faint.stroke(echo, with: shading, style: StrokeStyle(lineWidth: lineWidth * 0.6, lineCap: .round, lineJoin: .round))
    }

    /// Thin vertical rays hanging above a ribbon, bright at its edge and fading upward. Ray length and
    /// brightness shimmer with two drifting sines; rays are batched into three brightness bins.
    private static func drawRays(_ context: inout GraphicsContext, index i: Int, size: CGSize, t: Double) {
        let h = size.height
        let di = Double(i)
        var bins = [Path(), Path(), Path()]
        var x: CGFloat = 4 + CGFloat(i) * 1.7
        while x < size.width {
            let dx = Double(x)
            let shimmer = (0.5 + 0.5 * sin(dx * 0.09 + t * 1.3 + di * 2.1)) * (0.55 + 0.45 * sin(dx * 0.023 - t * 0.4 + di))
            let y = ribbonY(index: i, x: x, size: size, t: t) + h * 0.03
            let length = h * CGFloat(0.1 + 0.2 * shimmer)
            let bin = min(Int(shimmer * 3), 2)
            bins[bin].move(to: CGPoint(x: x, y: y))
            bins[bin].addLine(to: CGPoint(x: x, y: y - length))
            x += 6
        }
        let color = ribbons[i % ribbons.count].0
        let base = h * (0.3 + 0.09 * CGFloat(i))
        let shading = GraphicsContext.Shading.linearGradient(
            Gradient(colors: [color.opacity(0.9), color.opacity(0.35), color.opacity(0)]),
            startPoint: CGPoint(x: 0, y: base + h * 0.1),
            endPoint: CGPoint(x: 0, y: base - h * 0.32)
        )
        let alphas: [Double] = [0.25, 0.5, 0.85]
        for bin in 0..<3 {
            var layer = context
            layer.opacity = alphas[bin]
            layer.stroke(bins[bin], with: shading, style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
        }
    }

    private static func drawRidge(_ context: inout GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let peaks: [CGFloat] = [0.86, 0.79, 0.84, 0.73, 0.81, 0.77, 0.88]
        var path = Path()
        path.move(to: CGPoint(x: 0, y: h))
        for (index, peak) in peaks.enumerated() {
            let x = w * CGFloat(index) / CGFloat(peaks.count - 1)
            path.addLine(to: CGPoint(x: x, y: h * peak))
        }
        path.addLine(to: CGPoint(x: w, y: h))
        path.closeSubpath()
        context.fill(
            path,
            with: .linearGradient(
                Gradient(colors: [Color(hex: 0x0A1624), Color(hex: 0x02050A)]),
                startPoint: CGPoint(x: 0, y: h * 0.72),
                endPoint: CGPoint(x: 0, y: h)
            )
        )
    }
}
