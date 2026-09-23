import SwiftUI

extension Effect {
    static let backgroundsGlowOrb = Effect(
        id: "backgrounds.glow-orb",
        category: .backgrounds,
        interaction: .gesture,
        name: L("Follow Orb", "追随光球"),
        summary: L(
            "A luminous gradient orb trails your finger and lights up a hidden dot grid.",
            "发光渐变光球追随手指，照亮隐藏的点阵网格。"
        ),
        prompt: L(
            "A near-black canvas covered by a barely visible 18 pt dot grid. A soft gradient orb — violet, pink and sky blended in a slowly breathing conic swirl, blurred to about a quarter of its diameter with a bright white core — floats over it with additive blending. Tapping or dragging sideways sends the orb after the finger on a spring with deliberate lag (response ≈ 0.45 s, damping ≈ 0.72), so fast swipes make it overshoot and settle, and wherever it passes a circular spotlight reveals the dot grid at full brightness, fading radially at the edge. At rest it breathes in scale by 8% over 2.2 s. A crisp headline sits above. It feels precise, magnetic and premium — like a Linear or Vercel hero section.",
            "近乎纯黑的画布上铺着一层几乎不可见的 18pt 点阵网格。一颗柔和的渐变光球——紫、粉、天蓝以缓慢呼吸的锥形渐变交融，模糊半径约为直径的四分之一，中心有一枚亮白光核——以叠加混合漂浮其上。点击或横向拖动时，光球以带明显滞后的弹簧跟随手指（响应约 0.45 秒、阻尼约 0.72），快速划动时会过冲再回稳；光球经过之处，圆形聚光以全亮度显现点阵，并在边缘径向淡出。静止时光球在 2.2 秒内以 8% 的幅度呼吸缩放。上方配一行利落的标题。精准、有磁性，犹如 Linear 官网首屏。"
        ),
        implementation: L(
            "Two Canvas dot grids stacked; the bright one is masked by a RadialGradient positioned at the orb. DragGesture retargets the orb position through withAnimation(.spring), and phaseAnimator adds the breathing.",
            "两层 Canvas 点阵叠放，亮层以跟随光球位置的 RadialGradient 作为遮罩。DragGesture 通过 withAnimation(.spring) 重定向光球位置，phaseAnimator 负责呼吸效果。"
        ),
        apis: ["DragGesture", "spring(response:dampingFraction:)", "mask", "blendMode(.plusLighter)", "phaseAnimator"],
        tags: ["orb", "cursor", "spotlight", "follow", "光球", "跟随", "聚光", "悬停"],
        params: [
            .slider("response", L("Follow lag", "跟随延迟"), 0.1...1.2, default: 0.45, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.4...1.0, default: 0.72),
            .slider("size", L("Orb size", "光球大小"), 80...240, default: 150, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        GlowOrbDemo(ctx: ctx)
    }
}

private struct GlowOrbDemo: View {
    let ctx: DemoContext
    @State private var size: CGSize = .zero
    @State private var position: CGPoint?
    @State private var step = 0

    private static let tour: [UnitPoint] = [
        UnitPoint(x: 0.25, y: 0.3), UnitPoint(x: 0.75, y: 0.35), UnitPoint(x: 0.7, y: 0.75),
        UnitPoint(x: 0.3, y: 0.7), UnitPoint(x: 0.5, y: 0.45),
    ]

    private var orbPosition: CGPoint {
        position ?? CGPoint(x: size.width / 2, y: size.height * 0.45)
    }

    var body: some View {
        ZStack {
            Color(hex: 0x07080F)
            OrbDotGrid(color: .white.opacity(0.1), radius: 1)
            OrbDotGrid(color: .white.opacity(0.85), radius: 1.5)
                .mask { spotlight }
            orb
            BackgroundSampleTitle(
                title: L("Move with intent", "专注而行"),
                subtitle: L("The workspace for focused teams", "为专注团队打造的工作空间"),
                language: ctx.language,
                size: 26
            )
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 38)
        }
        .backgroundsTouch { location in
            withAnimation(spring) { position = location }
        }
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newSize in
            size = newSize
        }
        .autoplay(ctx.isPreview, every: 1.3) { tourStep() }
        .backgroundsHint(L("Tap or drag sideways", "点击或横向拖动"), ctx)
    }

    private var spotlight: some View {
        let reach = ctx.cg("size") * 0.9
        return RadialGradient(colors: [.white, .white.opacity(0.4), .clear], center: .center, startRadius: 0, endRadius: reach)
            .frame(width: reach * 2, height: reach * 2)
            .position(orbPosition)
    }

    private var orb: some View {
        let diameter = ctx.cg("size")
        return ZStack {
            Circle()
                .fill(AngularGradient(gradient: Gradient(colors: [Palette.violet, Palette.pink, Palette.sky, Palette.indigo, Palette.violet]), center: .center, angle: .zero))
                .frame(width: diameter, height: diameter)
                .blur(radius: diameter * 0.25)
            Circle()
                .fill(.white.opacity(0.9))
                .frame(width: diameter * 0.16, height: diameter * 0.16)
                .blur(radius: 6)
        }
        .blendMode(.plusLighter)
        .phaseAnimator([false, true]) { content, expanded in
            content
                .scaleEffect(expanded ? 1.08 : 1)
                .rotationEffect(.degrees(expanded ? 40 : 0))
        } animation: { _ in
            .easeInOut(duration: 2.2)
        }
        .position(orbPosition)
        .allowsHitTesting(false)
    }

    private var spring: Animation {
        .spring(response: ctx["response"], dampingFraction: ctx["damping"])
    }


    private func tourStep() {
        guard size != .zero else { return }
        step += 1
        let point = Self.tour[step % Self.tour.count]
        withAnimation(spring) {
            position = CGPoint(x: size.width * point.x, y: size.height * point.y)
        }
    }
}

private struct OrbDotGrid: View {
    let color: Color
    let radius: CGFloat

    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 18
            var path = Path()
            var y = spacing / 2
            while y < size.height {
                var x = spacing / 2
                while x < size.width {
                    path.addEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
                    x += spacing
                }
                y += spacing
            }
            context.fill(path, with: .color(color))
        }
        .allowsHitTesting(false)
    }
}
