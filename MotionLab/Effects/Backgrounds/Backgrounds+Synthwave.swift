import SwiftUI

extension Effect {
    static let backgroundsSynthwaveGrid = Effect(
        id: "backgrounds.synthwave-grid",
        category: .backgrounds,
        interaction: .gesture,
        name: L("Synthwave Grid", "合成波网格"),
        summary: L(
            "An endless neon grid races toward a striped retro sun; drag sideways to steer and bank the horizon.",
            "霓虹网格无尽地奔向条纹复古落日；横向拖动即可转向，地平线随之倾斜。"
        ),
        prompt: L(
            "A retro-futurist 1980s horizon. Upper half: a violet-to-magenta dusk gradient with a large sun filled from butter yellow to hot pink, horizontal slits sliding down its lower half. Lower half: a near-black purple floor with a glowing magenta perspective grid whose rungs rush toward the viewer with correct 1/z spacing, looping seamlessly; every line is a crisp core over a blurred neon bloom, fading into horizon haze under a hot pink horizon line. Dragging sideways steers the drive: the vanishing point chases the finger with a ~180 ms exponential follow, the whole horizon banks up to ±6° opposite the turn, the grid verticals skew into the curve and the sun parallaxes at 0.4× of the shift. On release everything springs back level (response 0.6 s, damping 0.7) with a slight overshoot. Hypnotic, cinematic.",
            "八十年代复古未来主义地平线。上半部是紫到品红的黄昏渐变，中央巨大的落日由奶油黄过渡到亮粉，下半部被水平缝隙切开并持续下滑。下半部是近黑的紫色地面与发光的品红透视网格：横线按 1/z 间距朝观者疾驰、无缝循环，每条线都是清晰线芯叠加模糊霓虹辉光，远处淡入地平线雾气。横向拖动即可转向：灭点以约 180 毫秒的指数跟随追着手指，整条地平线朝转向反方向倾斜最多 ±6°，网格纵线随弯道斜切，落日以 0.4 倍位移形成视差。松手后一切以弹簧（响应 0.6 秒、阻尼 0.7）带轻微过冲回正。迷幻而富有电影感。"
        ),
        implementation: L(
            "A single Canvas banks its whole context around the horizon, then draws sky, a sun clipped by an inverse stripe path, the floor and the grid path twice (a blurred drawLayer bloom plus a crisp stroke). A scroll-safe horizontal drag feeds a steer value that exponentially follows the finger and integrates a damped spring back to level on release.",
            "单个 Canvas 先围绕地平线整体旋转画布，再绘制天空、以反向条纹路径裁剪的太阳、地面，并将网格路径绘制两次（模糊 drawLayer 辉光 + 清晰描边）。不妨碍页面滚动的横向拖动驱动转向值：按指数跟随手指，松手后以阻尼弹簧积分回正。"
        ),
        apis: ["Canvas", "TimelineView(.animation)", "GraphicsContext.rotate(by:)", "GraphicsContext.clip(to:options: .inverse)", "DragGesture"],
        tags: ["synthwave", "retro", "neon", "steer", "合成波", "复古", "霓虹", "转向"],
        params: [
            .slider("speed", L("Speed", "速度"), 0.2...3.0, default: 1.0, unit: "×"),
            .slider("lines", L("Grid density", "网格密度"), 4...12, default: 8, step: 1, decimals: 0),
            .slider("bank", L("Max bank", "最大倾斜"), 0...12, default: 6, decimals: 0, unit: "°"),
            .toggle("sun", L("Retro sun", "复古落日"), default: true),
        ]
    ) { ctx in
        SynthwaveDemo(ctx: ctx)
    }
}

private struct SynthwaveDemo: View {
    let ctx: DemoContext
    @State private var clock = BackgroundClock()
    @State private var steer = SynthSteer()
    @State private var stageWidth: CGFloat = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
            let t = clock.advance(to: timeline.date.timeIntervalSinceReferenceDate, speed: ctx["speed"])
            // Previews cannot be touched: a slow sinusoidal steer stands in for the finger.
            let preview: Double? = ctx.isPreview ? 0.7 * sin(t * 0.9) : nil
            let s = steer.step(clock.delta, width: Double(stageWidth), preview: preview)
            Canvas { context, size in
                SynthwaveScene.draw(
                    &context, size: size, t: t, lines: ctx.int("lines"), sun: ctx.bool("sun"),
                    steer: s, bank: ctx["bank"]
                )
            }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            stageWidth = width
        }
        // Horizontal-first and simultaneous, so a vertical swipe still scrolls the page; a cancelled touch
        // releases through the modifier's @GestureState, so the horizon always springs back level.
        .backgroundsTouch(onChanged: { point in
            if steer.fingerX == nil && !ctx.isPreview { Haptics.tap(.soft) }
            steer.fingerX = Double(point.x)
        }, onEnded: {
            steer.fingerX = nil
        })
        .backgroundsHint(L("Drag sideways to steer", "横向拖动转向"), ctx)
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
        .onDisappear { steer.fingerX = nil }
    }
}

/// Steer value in −1…1: follows the finger exponentially (~180 ms) while touched, then a damped spring
/// (response 0.6 s, damping 0.7) carries it back to level with a slight overshoot.
private final class SynthSteer {
    var fingerX: Double?
    private var value = 0.0
    private var velocity = 0.0

    func step(_ dt: Double, width: Double, preview: Double?) -> Double {
        guard dt > 0 else { return value }
        let target: Double?
        if let preview {
            target = preview
        } else if let fingerX, width > 0 {
            target = min(max((fingerX / width - 0.5) * 2, -1), 1)
        } else {
            target = nil
        }
        if let target {
            let previous = value
            value += (target - value) * (1 - exp(-dt / 0.18))
            velocity = (value - previous) / dt
        } else {
            let omega: Double = 2 * .pi / 0.6
            let damping: Double = 0.7
            let accel: Double = -omega * omega * value - 2 * damping * omega * velocity
            velocity += accel * dt
            value += velocity * dt
            if abs(value) < 0.0005 && abs(velocity) < 0.001 {
                value = 0
                velocity = 0
            }
        }
        return value
    }
}

private enum SynthwaveScene {
    static let pink = Color(hex: 0xFF3CAC)
    static let floorTop = Color(hex: 0x1A0433)

    /// Overdraw so the banked (rotated) scene still covers the corners of the stage.
    private static let bleed: CGFloat = 80

    static func draw(
        _ context: inout GraphicsContext, size: CGSize, t: Double, lines: Int, sun: Bool, steer: Double, bank: Double
    ) {
        let horizon: CGFloat = size.height * 0.58
        let s: CGFloat = CGFloat(steer)
        // The vanishing point chases the finger; the sun sits farther away, so it shifts at 0.4× of that.
        let shift: CGFloat = s * size.width * 0.28
        // Bank opposite the turn, pivoting on the horizon's centre.
        context.translateBy(x: size.width / 2, y: horizon)
        context.rotate(by: .degrees(-bank * steer))
        context.translateBy(x: -size.width / 2, y: -horizon)
        drawSky(&context, size: size, horizon: horizon)
        if sun {
            drawSun(&context, size: size, horizon: horizon, t: t, shift: shift * 0.4)
        }
        drawFloor(&context, size: size, horizon: horizon)
        let grid = gridPath(size: size, horizon: horizon, t: t, lines: max(lines, 2), shift: shift)
        let glow: CGFloat = abs(s)
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 4 + glow))
            layer.stroke(grid, with: .color(pink), lineWidth: 3 + glow)
        }
        context.stroke(grid, with: .color(Color(hex: 0xFF9AD5)), lineWidth: 1.1)
        drawHaze(&context, size: size, horizon: horizon)
    }

    private static func drawSky(_ context: inout GraphicsContext, size: CGSize, horizon: CGFloat) {
        let rect = CGRect(x: -bleed, y: -bleed, width: size.width + bleed * 2, height: horizon + bleed)
        let gradient = Gradient(colors: [Color(hex: 0x0D0221), Color(hex: 0x3B0A5E), Color(hex: 0xB0247A)])
        context.fill(Path(rect), with: .linearGradient(gradient, startPoint: .zero, endPoint: CGPoint(x: 0, y: horizon)))
    }

    private static func drawSun(_ context: inout GraphicsContext, size: CGSize, horizon: CGFloat, t: Double, shift: CGFloat) {
        let radius = min(size.width, size.height) * 0.27
        let center = CGPoint(x: size.width / 2 + shift, y: horizon - radius * 0.55)
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
        let rect = CGRect(x: -bleed, y: horizon, width: size.width + bleed * 2, height: size.height - horizon + bleed)
        let gradient = Gradient(colors: [floorTop, Color(hex: 0x07010F)])
        context.fill(Path(rect), with: .linearGradient(gradient, startPoint: CGPoint(x: 0, y: horizon), endPoint: CGPoint(x: 0, y: size.height)))
    }

    private static func gridPath(size: CGSize, horizon: CGFloat, t: Double, lines: Int, shift: CGFloat) -> Path {
        var path = Path()
        let cx: CGFloat = size.width / 2
        let depth: CGFloat = size.height - horizon
        let bottom: CGFloat = size.height + bleed
        // Verticals leave the shifted vanishing point and land skewed the other way, leaning into the curve.
        let top: CGFloat = cx + shift
        let foot: CGFloat = cx - shift * 0.5
        for i in -lines...lines {
            let fi = CGFloat(i)
            let spread: CGFloat = fi * size.width * 1.5 / CGFloat(lines)
            path.move(to: CGPoint(x: top + fi * size.width * 0.03, y: horizon))
            // Extend along the same line past the stage bottom so the banked floor stays covered.
            let end = CGPoint(x: foot + spread, y: size.height)
            let dx: CGFloat = end.x - (top + fi * size.width * 0.03)
            path.addLine(to: CGPoint(x: end.x + dx * (bottom - size.height) / depth, y: bottom))
        }
        let f = BackgroundMath.fract(t)
        for j in 0..<16 {
            let z = 1 + (Double(j) - f) * 0.55
            guard z > 0.2 else { continue }
            let y = horizon + depth * CGFloat(0.9 / z)
            guard y <= size.height + bleed else { continue }
            path.move(to: CGPoint(x: -bleed, y: y))
            path.addLine(to: CGPoint(x: size.width + bleed, y: y))
        }
        return path
    }

    private static func drawHaze(_ context: inout GraphicsContext, size: CGSize, horizon: CGFloat) {
        let fadeRect = CGRect(x: -bleed, y: horizon, width: size.width + bleed * 2, height: 46)
        let fade = Gradient(colors: [floorTop, floorTop.opacity(0)])
        context.fill(Path(fadeRect), with: .linearGradient(fade, startPoint: CGPoint(x: 0, y: horizon), endPoint: CGPoint(x: 0, y: horizon + 46)))

        let glowRect = CGRect(x: -bleed, y: horizon - 14, width: size.width + bleed * 2, height: 28)
        let glow = Gradient(stops: [
            .init(color: pink.opacity(0), location: 0),
            .init(color: pink.opacity(0.55), location: 0.5),
            .init(color: pink.opacity(0), location: 1),
        ])
        context.fill(Path(glowRect), with: .linearGradient(glow, startPoint: CGPoint(x: 0, y: horizon - 14), endPoint: CGPoint(x: 0, y: horizon + 14)))
        context.fill(Path(CGRect(x: -bleed, y: horizon - 0.75, width: size.width + bleed * 2, height: 1.5)), with: .color(Color(hex: 0xFFB3E0)))
    }
}
