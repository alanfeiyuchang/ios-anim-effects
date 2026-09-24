import SwiftUI

// Three more "Weather" variations, each with a different motion signature:
// Window Droplets (stick-slip runners + gravity), Rolling Fog (parallax banks that part on tap)
// and Autumn Wind (pendulum-flutter leaves with gusts).

extension Effect {
    static let backgroundsWindowDroplets = Effect(
        id: "backgrounds.window-droplets",
        category: .backgrounds,
        interaction: .tap,
        name: L("Rain on Glass", "玻璃雨滴"),
        summary: L(
            "Beads cling to a window at dusk over blurred street lamps; runners slip down in stick-slip bursts.",
            "黄昏的窗玻璃上挂满雨珠，背后是朦胧街灯；较大的水滴以“停—滑”节奏断续滑落。"
        ),
        prompt: L(
            "A rainy window at dusk: behind a faintly fogged pane, a blue-hour sky fades from slate blue through mauve to a warm apricot glow, dotted with soft, heavily blurred street lamps in amber, rose and pale blue. About 140 tiny static beads (0.8–3.4 pt) cling to the glass, each drawn with a dark lower shadow and a pin-point highlight. A handful of larger runners (4.5–7.5 pt, slightly elongated) move with real stick-slip motion: each one holds still, then lurches 14–24 pt down within the first 30% of its cycle on a smoothstep, then waits again, meandering sideways as it goes and leaving a tapering trail of five micro-beads. Tapping the glass knocks a fresh drop loose that accelerates straight down under gravity (420 pt/s²) with a slight wobble. Quiet, intimate and cinematic.",
            "黄昏雨中的窗：玻璃蒙着淡雾，背后的蓝调天空从石板蓝经淡紫过渡到暖杏色，点缀重度模糊的琥珀、玫瑰与淡蓝街灯。约 140 颗细小静止雨珠（0.8–3.4pt）附着在玻璃上，每颗带下方暗影与针尖高光。几颗较大的“流滴”（4.5–7.5pt，略呈椭圆）以真实的“停—滑”方式运动：先静止，再于周期前 30% 内以 smoothstep 猛地下滑 14–24pt，再停住；下滑时左右蜿蜒，拖出五颗渐小的微珠。点击玻璃会震落一颗新水滴，在重力（420pt/s²）下加速直落并轻微摇摆。私密而富有电影感。"
        ),
        implementation: L(
            "One Canvas: a blurred drawLayer for the city lights, beads and highlights batched into three Paths, and runners whose y advances by floor(cycle) + smoothstep(fract(cycle)/0.3); tapped drops follow y₀ + ½·g·t².",
            "单个 Canvas：模糊 drawLayer 绘制城市灯光，雨珠与高光合并为三条 Path 批量绘制；流滴的 y 按 floor(周期) + smoothstep(fract(周期)/0.3) 推进；点击产生的水滴遵循 y₀ + ½·g·t²。"
        ),
        apis: ["Canvas", "GraphicsContext.drawLayer", "TimelineView(.animation)", "onTapGesture(coordinateSpace:perform:)", "Haptics"],
        tags: ["rain", "window", "droplets", "glass", "雨滴", "窗户", "玻璃", "下雨"],
        params: [
            .slider("beads", L("Beads", "雨珠数量"), 40...240, default: 140, step: 10, decimals: 0),
            .slider("runners", L("Runners", "流滴数量"), 0...12, default: 6, step: 1, decimals: 0),
            .slider("blur", L("City blur", "灯光模糊"), 6...30, default: 16, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        WindowDropletsDemo(ctx: ctx)
    }

    static let backgroundsRollingFog = Effect(
        id: "backgrounds.rolling-fog",
        category: .backgrounds,
        interaction: .tap,
        name: L("Rolling Fog", "山间流雾"),
        summary: L(
            "Layered fog banks drift between mountain ridges in parallax — tap to let the moon break through.",
            "层层雾带在山脊之间以视差缓缓流动，点击让月光破雾而出。"
        ),
        prompt: L(
            "A moonlit valley: a dusky indigo-to-mauve sky, a soft moon with a blurred glow, and three mountain ridges that darken toward the viewer. Between the ridges drift three fog banks, each made of six large blurred puffs (150–230 pt wide) sliding sideways at 8, 18 and 28 pt/s — far banks slower, near banks faster and denser — while gently rising and falling, so depth comes purely from parallax. Tapping parts the fog: density eases down by 70% over 1.2 s, holds for a second while the moon glow brightens, then the fog rolls back in over 3 s; tapping again resumes from the density on screen. Hushed, atmospheric and patient.",
            "月光下的山谷：天空从暮色靛蓝过渡到淡紫，一轮带模糊光晕的柔和月亮，以及三道越靠近观者越暗的山脊。山脊之间飘着三层雾带，每层由六团大面积模糊雾团（宽 150–230pt）组成，分别以每秒 8、18、28pt 横向滑动——远处更慢、近处更快更浓——同时轻轻起伏，纵深感完全来自视差。点击会拨开雾气：浓度在 1.2 秒内缓降 70%，停留约 1 秒，月晕同时变亮，随后雾气在 3 秒内重新漫回；再次点击会从当前浓度接着拨开。静谧、氛围浓厚、从容不迫。"
        ),
        implementation: L(
            "A Canvas interleaves ridge Paths with blurred drawLayer fog banks whose puff x positions wrap with accumulated time; the tap envelope (ease down, hold, ease back) scales every fog layer's opacity.",
            "Canvas 将山脊 Path 与模糊 drawLayer 雾带交错绘制，雾团的 x 位置随累积时间循环；点击包络（缓降、停留、缓升）统一缩放各层雾的不透明度。"
        ),
        apis: ["Canvas", "GraphicsContext.drawLayer", "TimelineView(.animation)", "onTapGesture", "Path"],
        tags: ["fog", "mist", "mountains", "parallax", "雾", "薄雾", "山谷", "视差"],
        params: [
            .slider("density", L("Density", "浓度"), 0.2...1.0, default: 0.7),
            .slider("speed", L("Drift speed", "飘移速度"), 0.2...3.0, default: 1.0, unit: "×"),
            .choice("palette", L("Light", "光线"), [L("Moonlit", "月夜"), L("Dawn", "黎明")]),
        ]
    ) { ctx in
        RollingFogDemo(ctx: ctx)
    }

    static let backgroundsAutumnWind = Effect(
        id: "backgrounds.autumn-wind",
        category: .backgrounds,
        interaction: .tap,
        name: L("Autumn Wind", "秋风落叶"),
        summary: L(
            "Leaves tumble down with a real pendulum flutter — tap to send a gust through them.",
            "落叶以真实的钟摆式翻飞飘落，点击让一阵风吹过。"
        ),
        prompt: L(
            "A warm dusk sky (plum to rust to amber) with a low glowing sun. Leaves in amber, coral, crimson and ochre fall in depth: near leaves are bigger, sharper and faster, far ones small and softly blurred. Each leaf follows a falling-leaf pendulum: it swings side to side on a sine, tilting with the swing, and its descent speed varies as 1 + ½·cos(2·phase), so it floats at the ends of each arc and drops through the middle; a slow cosine squash of its width fakes a 3D flip. A light 18 pt/s breeze carries everything. Tapping sends a gust: +220 pt/s of wind (capped at 420) that decays at 1.6/s and briefly spins the leaves faster. Cozy, nostalgic and alive.",
            "温暖的黄昏天空（梅紫 → 铁锈红 → 琥珀）低悬一轮发光的太阳。琥珀、珊瑚、绯红与赭黄色的落叶分层飘落：近处的叶子更大、更清晰、更快，远处的则更小并带柔和模糊。每片叶子遵循落叶的钟摆运动：沿正弦左右摆动、随摆动倾斜，下落速度按 1 + ½·cos(2·相位) 变化——在弧线两端几乎悬停，经过中点时加速下坠；叶片宽度随缓慢的余弦压缩，模拟三维翻转。一阵每秒 18pt 的微风带着所有叶子漂移。点击会刮起一阵风：风速 +220pt/s（上限 420），以 1.6/s 衰减，并让叶片短暂转得更快。温馨而怀旧。"
        ),
        implementation: L(
            "Each leaf's position is analytic: y = fall·(t + sin(2φ)/4ω), x = sway·sin φ + wind offset; one leaf Path is appended per color with addPath(_:transform:) (translate · rotate · scale) and far leaves are drawn in a blurred layer.",
            "每片叶子的位置由解析式得出：y = fall·(t + sin(2φ)/4ω)，x = sway·sin φ + 风偏移；同一叶形通过 addPath(_:transform:)（平移·旋转·缩放）按颜色合并到 Path 中，远处的叶子绘制在模糊图层里。"
        ),
        apis: ["Canvas", "Path.addPath(_:transform:)", "CGAffineTransform", "TimelineView(.animation)", "Haptics"],
        tags: ["leaves", "autumn", "wind", "fall", "落叶", "秋天", "风", "飘落"],
        params: [
            .slider("count", L("Leaves", "叶片数量"), 10...80, default: 38, step: 1, decimals: 0),
            .slider("speed", L("Speed", "速度"), 0.3...2.0, default: 1.0, unit: "×"),
            .slider("flutter", L("Flutter", "翻飞幅度"), 0...2, default: 1.0, unit: "×"),
        ]
    ) { ctx in
        AutumnWindDemo(ctx: ctx)
    }
}

// MARK: - Rain on glass

private struct FallingDrop {
    let x: CGFloat
    let y: CGFloat
    let born: Double
}

private final class GlassModel {
    let clock = BackgroundClock()
    private(set) var drops: [FallingDrop] = []

    func step(now: Double) -> Double {
        let t = clock.advance(to: now, speed: 1)
        drops.removeAll { t - $0.born > 2.5 }
        return t
    }

    func knock(at point: CGPoint) {
        drops.append(FallingDrop(x: point.x, y: point.y, born: clock.phase))
        if drops.count > 8 {
            drops.removeFirst(drops.count - 8)
        }
    }
}

private struct WindowDropletsDemo: View {
    let ctx: DemoContext
    @State private var model = GlassModel()
    @State private var size = CGSize(width: 340, height: 340)

    var body: some View {
        let beads = ctx.int("beads")
        let runners = ctx.int("runners")
        let blur = ctx.cg("blur")
        ZStack {
            // Blue hour, not night: keeps this apart from the night-city Rain variation in the family strip.
            LinearGradient(colors: [Color(hex: 0x1F2B4D), Color(hex: 0x5B4C7A), Color(hex: 0xC97B6E), Color(hex: 0xF2B27E)], startPoint: .top, endPoint: .bottom)
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let t = model.step(now: timeline.date.timeIntervalSinceReferenceDate)
                GlassCanvas(t: t, drops: model.drops, beads: beads, runners: runners, blur: blur)
            }
            BackgroundSampleTitle(
                title: L("Evening showers", "傍晚阵雨"),
                subtitle: L("Clearing after 8 PM", "20 点后转晴"),
                language: ctx.language,
                size: 26
            )
        }
        .contentShape(Rectangle())
        .onTapGesture(coordinateSpace: .local) { location in
            Haptics.tap(.light)
            model.knock(at: location)
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        .autoplay(ctx.isPreview, every: 1.4, delay: 0.5) {
            let point = CGPoint(x: CGFloat.random(in: 30...max(size.width - 30, 31)), y: CGFloat.random(in: 20...90))
            model.knock(at: point)
        }
        .backgroundsHint(L("Tap the glass to knock a drop loose", "点击玻璃震落水滴"), ctx)
    }
}

private struct GlassCanvas: View {
    let t: Double
    let drops: [FallingDrop]
    let beads: Int
    let runners: Int
    let blur: CGFloat

    var body: some View {
        Canvas { context, size in
            GlassCanvas.drawCity(&context, size: size, blur: blur)
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white.opacity(0.04)))
            var shadows = Path()
            var bodies = Path()
            var lights = Path()
            GlassCanvas.addBeads(size: size, count: beads, shadows: &shadows, bodies: &bodies, lights: &lights)
            GlassCanvas.addRunners(size: size, t: t, count: runners, shadows: &shadows, bodies: &bodies, lights: &lights)
            for drop in drops {
                let age = CGFloat(t - drop.born)
                let y = drop.y + 0.5 * 420 * age * age
                let x = drop.x + 3 * CGFloat(sin(Double(age) * 9))
                GlassCanvas.addDrop(center: CGPoint(x: x, y: y), radius: 6.5, shadows: &shadows, bodies: &bodies, lights: &lights)
            }
            context.fill(shadows, with: .color(.black.opacity(0.28)))
            context.fill(bodies, with: .color(.white.opacity(0.14)))
            context.fill(lights, with: .color(.white.opacity(0.75)))
        }
    }

    private static func drawCity(_ context: inout GraphicsContext, size: CGSize, blur: CGFloat) {
        // Warm street lamps and a few cool windows against the dusk sky.
        let colors: [Color] = [Color(hex: 0xFFB86B), Color(hex: 0xFF8FA3), Color(hex: 0xFFE0A3), Color(hex: 0x9FD4FF), Color(hex: 0xFFD27A)]
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: blur))
            for i in 0..<11 {
                let r = min(size.width, size.height) * (0.06 + 0.07 * BackgroundMath.unit(i, 81))
                let x = BackgroundMath.unit(i, 82) * size.width
                let y = size.height * (0.25 + 0.7 * BackgroundMath.unit(i, 83))
                let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                layer.fill(Path(ellipseIn: rect), with: .color(colors[i % colors.count].opacity(0.45)))
            }
        }
    }

    private static func addBeads(size: CGSize, count: Int, shadows: inout Path, bodies: inout Path, lights: inout Path) {
        for i in 0..<max(count, 0) {
            let x = BackgroundMath.unit(i, 84) * size.width
            let y = BackgroundMath.unit(i, 85) * size.height
            let k = BackgroundMath.unit(i, 86)
            let r = 0.8 + 2.6 * k * k
            addDrop(center: CGPoint(x: x, y: y), radius: r, shadows: &shadows, bodies: &bodies, lights: &lights)
        }
    }

    private static func addRunners(size: CGSize, t: Double, count: Int, shadows: inout Path, bodies: inout Path, lights: inout Path) {
        let span = Double(size.height) + 60
        for i in 0..<max(count, 0) {
            let rate = 0.35 + 0.4 * BackgroundMath.rand(i, 51)
            let cycle = t * rate + BackgroundMath.rand(i, 52) * 10
            let whole = cycle.rounded(.down)
            let s = min((cycle - whole) / 0.3, 1)
            let eased = s * s * (3 - 2 * s)
            let slipLength = 14 + 10 * BackgroundMath.rand(i, 53)
            let travel = (whole + eased) * slipLength
            let y = BackgroundMath.fract((BackgroundMath.rand(i, 54) * span + travel) / span) * span - 30
            let radius = 4.5 + 3 * BackgroundMath.unit(i, 56)
            let head = runnerPoint(index: i, y: y, width: size.width)
            addDrop(center: head, radius: radius, shadows: &shadows, bodies: &bodies, lights: &lights)
            for k in 1...5 {
                let trailY = y - Double(k) * 8
                let point = runnerPoint(index: i, y: trailY, width: size.width)
                let r = radius * 0.35 * (1 - CGFloat(k) * 0.15)
                bodies.addEllipse(in: CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2))
            }
        }
    }

    private static func runnerPoint(index: Int, y: Double, width: CGFloat) -> CGPoint {
        let meander = 5 * sin(y * 0.045 + BackgroundMath.rand(index, 57) * 6)
        let x = BackgroundMath.unit(index, 55) * width + CGFloat(meander)
        return CGPoint(x: x, y: CGFloat(y))
    }

    private static func addDrop(center: CGPoint, radius: CGFloat, shadows: inout Path, bodies: inout Path, lights: inout Path) {
        let body = CGRect(x: center.x - radius, y: center.y - radius * 1.1, width: radius * 2, height: radius * 2.2)
        shadows.addEllipse(in: body.offsetBy(dx: 0, dy: radius * 0.35))
        bodies.addEllipse(in: body)
        let h = max(radius * 0.32, 0.5)
        let spot = CGRect(x: center.x - radius * 0.45 - h, y: center.y - radius * 0.55 - h, width: h * 2, height: h * 2)
        lights.addEllipse(in: spot)
    }
}

// MARK: - Rolling fog

private final class FogModel {
    let clock = BackgroundClock()
    var partStart: Double = -100

    /// 0 = full fog, 1 = parted: ease down 1.2 s, hold 1 s, ease back 3 s.
    func parted(at now: Double) -> Double {
        let e = now - partStart
        if e < 0 { return 0 }
        if e < 1.2 { return smooth(e / 1.2) }
        if e < 2.2 { return 1 }
        if e < 5.2 { return 1 - smooth((e - 2.2) / 3) }
        return 0
    }

    /// Starts (or continues) a parting from the fog that is on screen now, so a repeated tap never snaps back to full density:
    /// while easing down it keeps going, while held it re-arms the hold, and while rolling back it eases down again from the current value.
    func part(at now: Double) {
        let e = now - partStart
        if e >= 0 && e < 1.2 { return }
        if e >= 1.2 && e < 2.2 {
            partStart = now - 1.2
            return
        }
        let current = parted(at: now)
        partStart = now - 1.2 * inverseSmooth(current)
    }

    private func smooth(_ x: Double) -> Double {
        let c = x.clamped(to: 0...1)
        return c * c * (3 - 2 * c)
    }

    /// Inverse of smoothstep on 0...1.
    private func inverseSmooth(_ y: Double) -> Double {
        let c = y.clamped(to: 0...1)
        return 0.5 - sin(asin(1 - 2 * c) / 3)
    }
}

private struct FogLook {
    let sky: [Color]
    let ridges: [Color]
    let moon: Color
    let fog: Color

    static func look(_ index: Int) -> FogLook {
        if index == 1 {
            return FogLook(
                sky: [Color(hex: 0x3B3D6E), Color(hex: 0xC98BA0), Color(hex: 0xF6C9A0)],
                ridges: [Color(hex: 0x7C6A8E), Color(hex: 0x54496E), Color(hex: 0x2E2A48)],
                moon: Color(hex: 0xFFE7C2),
                fog: Color(hex: 0xFFF1F0)
            )
        }
        return FogLook(
            sky: [Color(hex: 0x141A33), Color(hex: 0x2E3160), Color(hex: 0x6E6390)],
            ridges: [Color(hex: 0x3B3F63), Color(hex: 0x2A2D4A), Color(hex: 0x171A2E)],
            moon: Color(hex: 0xF5F1E3),
            fog: Color(hex: 0xE8ECFF)
        )
    }
}

private struct RollingFogDemo: View {
    let ctx: DemoContext
    @State private var model = FogModel()

    var body: some View {
        let look = FogLook.look(ctx.int("palette"))
        let speed = ctx["speed"]
        let density = ctx["density"]
        ZStack {
            LinearGradient(colors: look.sky, startPoint: .top, endPoint: .bottom)
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let t = model.clock.advance(to: now, speed: speed)
                let parted = model.parted(at: now)
                FogCanvas(t: t, look: look, density: density * (1 - 0.7 * parted), glow: parted)
            }
            BackgroundSampleTitle(
                title: L("Mist", "薄雾"),
                subtitle: L("Visibility 800 m", "能见度 800 米"),
                language: ctx.language,
                size: 34
            )
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 34)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.tap(.soft)
            part()
        }
        .autoplay(ctx.isPreview, every: 6.5, delay: 1.5) { part() }
        .backgroundsHint(L("Tap to part the fog", "点击拨开雾气"), ctx)
    }

    private func part() {
        model.part(at: Date().timeIntervalSinceReferenceDate)
    }
}

private struct FogCanvas: View {
    let t: Double
    let look: FogLook
    let density: Double
    let glow: Double

    var body: some View {
        Canvas { context, size in
            FogCanvas.drawMoon(&context, size: size, color: look.moon, glow: glow)
            for layer in 0..<3 {
                context.fill(FogCanvas.ridge(size: size, layer: layer), with: .color(look.ridges[layer]))
                FogCanvas.drawFog(&context, size: size, layer: layer, t: t, color: look.fog, density: density)
            }
        }
    }

    private static func drawMoon(_ context: inout GraphicsContext, size: CGSize, color: Color, glow: Double) {
        let center = CGPoint(x: size.width * 0.72, y: size.height * 0.24)
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 28))
            let r: CGFloat = 60
            layer.fill(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)), with: .color(color.opacity(0.3 + 0.3 * glow)))
        }
        let r: CGFloat = 20
        context.fill(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)), with: .color(color))
    }

    private static func ridge(size: CGSize, layer: Int) -> Path {
        let base = size.height * (0.52 + 0.14 * CGFloat(layer))
        let amplitude: CGFloat = 26 - 4 * CGFloat(layer)
        let frequency = 1.4 + 0.7 * Double(layer)
        let offset = Double(layer) * 1.9
        var path = Path()
        path.move(to: CGPoint(x: 0, y: size.height))
        var x: CGFloat = 0
        while x <= size.width + 8 {
            let u = Double(x / max(size.width, 1))
            let primary = sin(u * frequency * .pi * 2 + offset)
            let detail = 0.35 * sin(u * frequency * 5.3 * .pi + offset * 2)
            path.addLine(to: CGPoint(x: x, y: base - amplitude * CGFloat(primary + detail)))
            x += 8
        }
        path.addLine(to: CGPoint(x: size.width + 8, y: size.height))
        path.closeSubpath()
        return path
    }

    private static func drawFog(_ context: inout GraphicsContext, size: CGSize, layer: Int, t: Double, color: Color, density: Double) {
        let velocity = 8.0 + 10.0 * Double(layer)
        let bandY = size.height * (0.56 + 0.14 * CGFloat(layer))
        let opacity = density * (0.16 + 0.06 * Double(layer))
        context.drawLayer { fog in
            fog.addFilter(.blur(radius: 22))
            for i in 0..<6 {
                let seed = layer * 10 + i
                let width = 150 + 80 * BackgroundMath.unit(seed, 91)
                let height = 50 + 30 * BackgroundMath.unit(seed, 92)
                let wrap = Double(size.width + width * 2)
                let x = BackgroundMath.fract(BackgroundMath.rand(seed, 93) + t * velocity / wrap) * wrap - Double(width)
                let bob = 6 * sin(t * 0.3 + Double(i) * 1.3)
                let y = bandY + CGFloat(bob) + (BackgroundMath.unit(seed, 94) - 0.5) * 30
                let rect = CGRect(x: CGFloat(x), y: y - height / 2, width: width, height: height)
                fog.fill(Path(ellipseIn: rect), with: .color(color.opacity(opacity)))
            }
        }
    }
}

// MARK: - Autumn wind

private final class LeafModel {
    let clock = BackgroundClock()
    private(set) var windOffset: Double = 0
    private(set) var spin: Double = 0
    private var gust: Double = 0

    func step(now: Double, speed: Double) -> Double {
        let t = clock.advance(to: now, speed: speed)
        let dt = clock.delta
        gust *= exp(-dt * 1.6)
        windOffset += (18 + gust) * dt
        spin += gust * 0.012 * dt
        return t
    }

    func blow() {
        gust = min(gust + 220, 420)
    }
}

private struct AutumnWindDemo: View {
    let ctx: DemoContext
    @State private var model = LeafModel()

    var body: some View {
        let count = ctx.int("count")
        let speed = ctx["speed"]
        let flutter = ctx["flutter"]
        ZStack {
            LinearGradient(colors: [Color(hex: 0x2B1B3D), Color(hex: 0x7A3B45), Color(hex: 0xE0894A)], startPoint: .top, endPoint: .bottom)
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let t = model.step(now: timeline.date.timeIntervalSinceReferenceDate, speed: speed)
                LeafCanvas(t: t, windOffset: model.windOffset, spin: model.spin, count: count, flutter: flutter)
            }
            BackgroundSampleTitle(
                title: L("14°", "14°"),
                subtitle: L("Breezy · Leaves falling", "微风 · 落叶纷飞"),
                language: ctx.language,
                size: 44
            )
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 36)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.tap(.soft)
            model.blow()
        }
        .autoplay(ctx.isPreview, every: 4.0, delay: 1.2) { model.blow() }
        .backgroundsHint(L("Tap for a gust of wind", "点击刮起一阵风"), ctx)
    }
}

private struct LeafCanvas: View {
    let t: Double
    let windOffset: Double
    let spin: Double
    let count: Int
    let flutter: Double

    private static let colors: [Color] = [Color(hex: 0xFFB347), Color(hex: 0xFF7A5C), Color(hex: 0xD7263D), Color(hex: 0xC9892B)]

    var body: some View {
        Canvas { context, size in
            LeafCanvas.drawSun(&context, size: size)
            let paths = LeafCanvas.leafPaths(size: size, t: t, windOffset: windOffset, spin: spin, count: count, flutter: flutter)
            context.drawLayer { far in
                far.addFilter(.blur(radius: 1.6))
                for k in 0..<4 {
                    far.fill(paths.far[k], with: .color(LeafCanvas.colors[k].opacity(0.6)))
                }
            }
            for k in 0..<4 {
                context.fill(paths.near[k], with: .color(LeafCanvas.colors[k]))
            }
            context.stroke(paths.ribs, with: .color(.black.opacity(0.22)), lineWidth: 0.8)
        }
    }

    private static func drawSun(_ context: inout GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width * 0.3, y: size.height * 0.82)
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 40))
            let r: CGFloat = 90
            layer.fill(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)), with: .color(Color(hex: 0xFFD27A).opacity(0.55)))
        }
    }

    private static func leafShape() -> (outline: Path, rib: Path) {
        var outline = Path()
        outline.move(to: CGPoint(x: 0, y: -8))
        outline.addQuadCurve(to: CGPoint(x: 0, y: 8), control: CGPoint(x: 7, y: 0))
        outline.addQuadCurve(to: CGPoint(x: 0, y: -8), control: CGPoint(x: -7, y: 0))
        outline.closeSubpath()
        var rib = Path()
        rib.move(to: CGPoint(x: 0, y: -7))
        rib.addLine(to: CGPoint(x: 0, y: 10))
        return (outline, rib)
    }

    private static func leafPaths(size: CGSize, t: Double, windOffset: Double, spin: Double, count: Int, flutter: Double) -> (near: [Path], far: [Path], ribs: Path) {
        let shape = leafShape()
        var near = [Path](repeating: Path(), count: 4)
        var far = [Path](repeating: Path(), count: 4)
        var ribs = Path()
        let wrapW = Double(size.width) + 60
        let wrapH = Double(size.height) + 60
        for i in 0..<max(count, 0) {
            let depth = BackgroundMath.rand(i, 61)
            let omega = 1.1 + 0.9 * BackgroundMath.rand(i, 62)
            let phase = t * omega + BackgroundMath.rand(i, 63) * BackgroundMath.tau
            let fall = 26 + 34 * depth
            let sway = (14 + 18 * depth) * flutter
            let drop = fall * (t + sin(2 * phase) / (4 * omega))
            let rawY = BackgroundMath.rand(i, 64) * wrapH + drop
            let y = BackgroundMath.fract(rawY / wrapH) * wrapH - 30
            let rawX = BackgroundMath.rand(i, 65) * wrapW + sway * sin(phase) + windOffset * (0.5 + depth)
            let x = BackgroundMath.fract(rawX / wrapW) * wrapW - 30
            let tilt = 0.7 * flutter * cos(phase)
            let twirl = spin * (BackgroundMath.rand(i, 66) - 0.5) * 2
            let flip = cos(t * (0.8 + BackgroundMath.rand(i, 67)) + BackgroundMath.rand(i, 68) * 6)
            let flipX = flip >= 0 ? max(flip, 0.15) : min(flip, -0.15)
            let scale = 0.55 + 0.75 * depth
            let transform = CGAffineTransform(translationX: CGFloat(x), y: CGFloat(y))
                .rotated(by: CGFloat(tilt + twirl))
                .scaledBy(x: CGFloat(flipX * scale), y: CGFloat(scale))
            let colorIndex = Int(BackgroundMath.rand(i, 69) * 4) % 4
            if depth < 0.35 {
                far[colorIndex].addPath(shape.outline, transform: transform)
            } else {
                near[colorIndex].addPath(shape.outline, transform: transform)
                ribs.addPath(shape.rib, transform: transform)
            }
        }
        return (near, far, ribs)
    }
}
