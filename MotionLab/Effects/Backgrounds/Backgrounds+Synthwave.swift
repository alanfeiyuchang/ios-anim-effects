import SwiftUI

extension Effect {
    static let backgroundsSynthwaveGrid = Effect(
        id: "backgrounds.synthwave-grid",
        category: .backgrounds,
        interaction: .loop,
        name: L("Synthwave Grid", "合成波网格"),
        summary: L(
            "An endless neon grid races toward a striped retro sun.",
            "霓虹网格无尽地奔向条纹复古落日。"
        ),
        prompt: L(
            "A retro-futurist 1980s horizon. Upper half: a violet-to-magenta dusk gradient with a large sun whose fill runs from butter yellow to hot pink; horizontal slits cut through its lower half, thin near the center and thicker toward the horizon, sliding steadily downward. Lower half: a near-black purple floor with a glowing magenta perspective grid — lines converge to a central vanishing point while horizontal rungs rush toward the viewer with correct 1/z spacing, looping seamlessly every rung. Every grid line has a blurred neon bloom beneath a crisp core, the far grid fades into horizon haze, and a hot pink horizon line glows. Speed is constant and hypnotic; the mood is nostalgic, cool and cinematic.",
            "八十年代复古未来主义的地平线。上半部分是紫到品红的黄昏渐变，中间一轮巨大的落日，由奶油黄过渡到亮粉；落日下半部分被数道水平缝隙切开，越靠近中心越细、越接近地平线越粗，并持续向下滑动。下半部分是近黑的紫色地面，铺着发光的品红透视网格：纵线汇聚于中央灭点，横线按正确的 1/z 间距朝观者疾驰而来，每经过一格便无缝循环。所有网格线都是清晰的线芯叠加模糊霓虹辉光，远处网格淡入地平线雾气，地平线本身是一道炽热的粉色光线。速度恒定、令人着迷，氛围怀旧、酷感且富有电影感。"
        ),
        implementation: L(
            "A single Canvas draws sky, a sun clipped by an inverse stripe path, the floor, then the grid path twice (a blurred drawLayer for bloom plus a crisp stroke) and a horizon haze gradient.",
            "单个 Canvas 依次绘制天空、以反向条纹路径裁剪的太阳、地面，再将网格路径绘制两次（模糊 drawLayer 做辉光 + 清晰描边），最后叠加地平线雾化渐变。"
        ),
        apis: ["Canvas", "TimelineView(.animation)", "GraphicsContext.clip(to:options: .inverse)", "GraphicsContext.drawLayer"],
        tags: ["synthwave", "retro", "neon", "grid", "合成波", "复古", "霓虹", "网格"],
        params: [
            .slider("speed", L("Speed", "速度"), 0.2...3.0, default: 1.0, unit: "×"),
            .slider("lines", L("Grid density", "网格密度"), 4...12, default: 8, step: 1, decimals: 0),
            .toggle("sun", L("Retro sun", "复古落日"), default: true),
        ]
    ) { ctx in
        SynthwaveDemo(ctx: ctx)
    }
}

private struct SynthwaveDemo: View {
    let ctx: DemoContext
    @State private var clock = BackgroundClock()

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
            let t = clock.advance(to: timeline.date.timeIntervalSinceReferenceDate, speed: ctx["speed"])
            Canvas { context, size in
                SynthwaveScene.draw(&context, size: size, t: t, lines: ctx.int("lines"), sun: ctx.bool("sun"))
            }
        }
        .overlay(alignment: .top) {
            Text(verbatim: ctx.language == .zh ? "午夜驾驶" : "NIGHT DRIVE")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .italic()
                .tracking(ctx.language == .zh ? 4 : 2)
                .foregroundStyle(.white)
                .shadow(color: SynthwaveScene.pink, radius: 10)
                .padding(.top, 34)
                .allowsHitTesting(false)
        }
    }
}

private enum SynthwaveScene {
    static let pink = Color(hex: 0xFF3CAC)
    static let floorTop = Color(hex: 0x1A0433)

    static func draw(_ context: inout GraphicsContext, size: CGSize, t: Double, lines: Int, sun: Bool) {
        let horizon = size.height * 0.58
        drawSky(&context, size: size, horizon: horizon)
        if sun {
            drawSun(&context, size: size, horizon: horizon, t: t)
        }
        drawFloor(&context, size: size, horizon: horizon)
        let grid = gridPath(size: size, horizon: horizon, t: t, lines: max(lines, 2))
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 4))
            layer.stroke(grid, with: .color(pink), lineWidth: 3)
        }
        context.stroke(grid, with: .color(Color(hex: 0xFF9AD5)), lineWidth: 1.1)
        drawHaze(&context, size: size, horizon: horizon)
    }

    private static func drawSky(_ context: inout GraphicsContext, size: CGSize, horizon: CGFloat) {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: horizon)
        let gradient = Gradient(colors: [Color(hex: 0x0D0221), Color(hex: 0x3B0A5E), Color(hex: 0xB0247A)])
        context.fill(Path(rect), with: .linearGradient(gradient, startPoint: .zero, endPoint: CGPoint(x: 0, y: horizon)))
    }

    private static func drawSun(_ context: inout GraphicsContext, size: CGSize, horizon: CGFloat, t: Double) {
        let radius = min(size.width, size.height) * 0.27
        let center = CGPoint(x: size.width / 2, y: horizon - radius * 0.55)
        let sunRect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)

        let haloRadius = radius * 1.8
        let halo = Gradient(colors: [pink.opacity(0.45), pink.opacity(0)])
        let haloRect = CGRect(x: center.x - haloRadius, y: center.y - haloRadius, width: haloRadius * 2, height: haloRadius * 2)
        context.fill(Path(ellipseIn: haloRect), with: .radialGradient(halo, center: center, startRadius: radius * 0.8, endRadius: haloRadius))

        var stripes = Path()
        for k in 0..<6 {
            let f = BackgroundMath.fract((Double(k) + t * 0.6) / 6)
            let y = center.y + radius * CGFloat(f)
            let thickness = radius * CGFloat(0.015 + 0.09 * f)
            stripes.addRect(CGRect(x: center.x - radius, y: y, width: radius * 2, height: thickness))
        }
        context.drawLayer { layer in
            layer.clip(to: stripes, options: .inverse)
            let fill = Gradient(colors: [Color(hex: 0xFFE45E), Color(hex: 0xFF8A5B), pink])
            layer.fill(
                Path(ellipseIn: sunRect),
                with: .linearGradient(fill, startPoint: CGPoint(x: 0, y: sunRect.minY), endPoint: CGPoint(x: 0, y: sunRect.maxY))
            )
        }
    }

    private static func drawFloor(_ context: inout GraphicsContext, size: CGSize, horizon: CGFloat) {
        let rect = CGRect(x: 0, y: horizon, width: size.width, height: size.height - horizon)
        let gradient = Gradient(colors: [floorTop, Color(hex: 0x07010F)])
        context.fill(Path(rect), with: .linearGradient(gradient, startPoint: CGPoint(x: 0, y: horizon), endPoint: CGPoint(x: 0, y: size.height)))
    }

    private static func gridPath(size: CGSize, horizon: CGFloat, t: Double, lines: Int) -> Path {
        var path = Path()
        let cx = size.width / 2
        let depth = size.height - horizon
        for i in -lines...lines {
            let fi = CGFloat(i)
            path.move(to: CGPoint(x: cx + fi * size.width * 0.03, y: horizon))
            path.addLine(to: CGPoint(x: cx + fi * size.width * 1.5 / CGFloat(lines), y: size.height))
        }
        let f = BackgroundMath.fract(t)
        for j in 0..<16 {
            let z = 1 + (Double(j) - f) * 0.55
            guard z > 0.2 else { continue }
            let y = horizon + depth * CGFloat(0.9 / z)
            guard y <= size.height else { continue }
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
        }
        return path
    }

    private static func drawHaze(_ context: inout GraphicsContext, size: CGSize, horizon: CGFloat) {
        let fadeRect = CGRect(x: 0, y: horizon, width: size.width, height: 46)
        let fade = Gradient(colors: [floorTop, floorTop.opacity(0)])
        context.fill(Path(fadeRect), with: .linearGradient(fade, startPoint: CGPoint(x: 0, y: horizon), endPoint: CGPoint(x: 0, y: horizon + 46)))

        let glowRect = CGRect(x: 0, y: horizon - 14, width: size.width, height: 28)
        let glow = Gradient(stops: [
            .init(color: pink.opacity(0), location: 0),
            .init(color: pink.opacity(0.55), location: 0.5),
            .init(color: pink.opacity(0), location: 1),
        ])
        context.fill(Path(glowRect), with: .linearGradient(glow, startPoint: CGPoint(x: 0, y: horizon - 14), endPoint: CGPoint(x: 0, y: horizon + 14)))
        context.fill(Path(CGRect(x: 0, y: horizon - 0.75, width: size.width, height: 1.5)), with: .color(Color(hex: 0xFFB3E0)))
    }
}
