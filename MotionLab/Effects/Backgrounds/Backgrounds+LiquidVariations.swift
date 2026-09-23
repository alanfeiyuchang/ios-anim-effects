import SwiftUI

// Two more "Liquid & Blobs" variations: Ink Bloom (exponential diffusion of dropped ink)
// and Slosh Tank (a spring-driven tilting water surface with a sloshing standing wave).

extension Effect {
    static let backgroundsInkBloom = Effect(
        id: "backgrounds.ink-bloom",
        category: .backgrounds,
        interaction: .tap,
        name: L("Ink Bloom", "水墨晕染"),
        summary: L(
            "Tap to drop ink into still water — it blooms, sinks in tendrils and slowly fades.",
            "点击向静水中滴入墨滴：墨色晕开、拖着墨丝下沉，再慢慢淡去。"
        ),
        prompt: L(
            "A calm paper-white surface (deep ink-black in dark mode). Each tap drops a bead of ink at the finger: a dense core appears within ~160 ms, then seven soft lobes push outward along random directions while growing, following a diffusion curve 1 − e^(−t/0.9 s) that starts fast and slows to a crawl; lobes also sink under gravity (quadratic in the growth), stretching into tendrils. A faint ring on the water surface expands and fades as the drop lands. Everything is blurred 10 pt and blended multiply on paper (screen in dark mode), so overlapping drops of indigo, magenta, teal and ochre mix like real pigment. Each drop fades quadratically over its lifetime (7 s by default). Meditative, organic and hand-made.",
            "平静的纸白色画面（深色模式下为墨黑）。每次点击都会在指尖处滴下一滴墨：约 160 毫秒内先出现浓重的墨核，随后七团柔软的墨瓣沿随机方向向外推开并长大，遵循 1 − e^(−t/0.9 秒) 的扩散曲线——起初迅速、随后慢到几乎静止；墨瓣同时受重力下沉（与扩散进度成二次方关系），被拉成墨丝。滴落处的水面上还会有一圈淡淡的波纹扩散、淡出。所有墨色都经 10pt 模糊，并在纸面上以正片叠底（深色模式下为滤色）混合，因此靛蓝、洋红、青绿与赭黄的墨滴重叠时会像真实颜料一样交融。每滴墨在生命周期内（默认 7 秒）按二次方淡出。冥想、有机、带有手作温度。"
        ),
        implementation: L(
            "A model stores drops (unit position, birth time, color, seed); a blurred Canvas redraws each drop's seven lobes, core and surface ring from its age every frame, using multiply or screen blend depending on the color scheme.",
            "模型保存每滴墨（单位坐标、诞生时间、颜色与种子）；模糊的 Canvas 每帧根据墨滴年龄重绘七团墨瓣、墨核与水面波纹，并按深浅色模式使用正片叠底或滤色混合。"
        ),
        apis: ["Canvas", "GraphicsContext.blendMode", "TimelineView(.animation)", "onTapGesture(coordinateSpace:perform:)", "colorScheme"],
        tags: ["ink", "watercolor", "diffusion", "bloom", "水墨", "晕染", "扩散", "墨滴"],
        params: [
            .slider("spread", L("Spread", "扩散范围"), 0.6...1.6, default: 1.0, unit: "×"),
            .slider("life", L("Lifetime", "存留时间"), 3...12, default: 7, decimals: 0, unit: "s"),
            .slider("speed", L("Diffusion speed", "扩散速度"), 0.3...2.0, default: 1.0, unit: "×"),
        ]
    ) { ctx in
        InkBloomDemo(ctx: ctx)
    }

    static let backgroundsSloshTank = Effect(
        id: "backgrounds.slosh-tank",
        category: .backgrounds,
        interaction: .gesture,
        name: L("Slosh Tank", "晃动水箱"),
        summary: L(
            "Water that tilts toward your finger and sloshes back on a springy, underdamped surface.",
            "水面向手指一侧倾斜，松手后以欠阻尼弹簧来回晃荡。"
        ),
        prompt: L(
            "The stage is a tank of water filled to 55%: a translucent back surface and a brighter mint-to-blue front surface, each a live curve with a thin white crest, over a deep navy backdrop with small bubbles rising through the water. The surface tilt is a spring (stiffness 55, damping ratio 0.12 by default): touching or dragging sideways sets a target slope that piles water toward the finger, and letting go releases it, so the surface swings past level several times before settling. The tilt velocity also drives a second, S-shaped slosh mode (up to ±24 pt), the back surface follows at 82% of the tilt, and fine ripples keep moving on top. A soft haptic marks each release. Playful, weighty and liquid.",
            "整个舞台是一只注水 55% 的水箱：后层半透明水面与更明亮的薄荷绿至蓝色前层水面，都是带白色细波峰的实时曲线；背景为深海军蓝，小气泡在水中缓缓上升。水面倾斜由弹簧驱动（默认刚度 55、阻尼比 0.12）：按住或横向拖动会设定目标斜率，使水向手指一侧堆高；松手后弹簧释放，水面会越过水平线来回摆动好几次才平息。倾斜速度还会激发第二个 S 形晃动模态（最多 ±24pt），后层水面以 82% 的倾斜跟随，细小涟漪始终在表面流动。每次松手伴随一次柔和触感。俏皮、有分量、充满液体感。"
        ),
        implementation: L(
            "A model integrates a damped spring for the slope with semi-implicit Euler inside TimelineView; a Canvas builds each surface Path from tilt + velocity-driven sin(2πx) mode + ripples and draws bubbles only below the surface.",
            "模型在 TimelineView 中以半隐式欧拉积分斜率的阻尼弹簧；Canvas 用倾斜 + 由速度驱动的 sin(2πx) 模态 + 涟漪构建每层水面 Path，并只在水面以下绘制气泡。"
        ),
        apis: ["Canvas", "TimelineView(.animation)", "DragGesture", "Path", "GraphicsContext.Shading.linearGradient"],
        tags: ["water", "slosh", "spring", "liquid", "水面", "晃动", "弹簧", "液体"],
        params: [
            .slider("stiffness", L("Stiffness", "刚度"), 20...140, default: 55, decimals: 0),
            .slider("damping", L("Damping ratio", "阻尼比"), 0.05...0.6, default: 0.12),
            .slider("level", L("Fill level", "水位"), 0.3...0.8, default: 0.55),
        ]
    ) { ctx in
        SloshTankDemo(ctx: ctx)
    }
}

// MARK: - Ink bloom

private struct InkDrop {
    /// Unit coordinates (0...1) inside the stage.
    let center: CGPoint
    let born: Double
    let color: Int
    let seed: Int
}

private final class InkModel {
    let clock = BackgroundClock()
    private(set) var drops: [InkDrop] = []
    private var serial = 0

    func step(now: Double, speed: Double, life: Double) -> Double {
        let t = clock.advance(to: now, speed: speed)
        drops.removeAll { t - $0.born > life }
        return t
    }

    func drop(at unit: CGPoint) {
        serial += 1
        drops.append(InkDrop(center: unit, born: clock.phase, color: serial % 4, seed: serial * 7 + 3))
        if drops.count > 10 {
            drops.removeFirst(drops.count - 10)
        }
    }
}

private enum InkPalette {
    static func colors(dark: Bool) -> [Color] {
        let hexes: [UInt32] = dark
            ? [0x6E7BFF, 0xFF5FA2, 0x21D4A8, 0xFFC247]
            : [0x2B2FA8, 0xC2186B, 0x0E8A87, 0xD9822B]
        return hexes.map { Color(hex: $0) }
    }
}

private struct InkBloomDemo: View {
    let ctx: DemoContext
    @State private var model = InkModel()
    @State private var size = CGSize(width: 340, height: 340)
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let dark = scheme == .dark
        let speed = ctx["speed"]
        let life = ctx["life"]
        let spread = ctx["spread"]
        ZStack {
            Color(hex: dark ? 0x0C0E14 : 0xF3EFE6)
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let t = model.step(now: timeline.date.timeIntervalSinceReferenceDate, speed: speed, life: life)
                InkCanvas(t: t, drops: model.drops, spread: spread, life: life, dark: dark)
            }
            BackgroundSampleTitle(
                title: L("Ink & Water", "水 · 墨"),
                subtitle: L("A quiet place to think", "一处安静思考的地方"),
                language: ctx.language,
                color: dark ? .white : Color.black.opacity(0.72),
                size: 28
            )
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 34)
        }
        .contentShape(Rectangle())
        .onTapGesture(coordinateSpace: .local) { location in
            Haptics.tap(.soft)
            let unit = CGPoint(x: location.x / max(size.width, 1), y: location.y / max(size.height, 1))
            model.drop(at: unit)
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        .onAppear {
            if model.drops.isEmpty {
                model.drop(at: CGPoint(x: 0.34, y: 0.5))
                model.drop(at: CGPoint(x: 0.66, y: 0.62))
            }
        }
        .autoplay(ctx.isPreview, every: 1.6, delay: 0.4) {
            model.drop(at: CGPoint(x: Double.random(in: 0.18...0.82), y: Double.random(in: 0.3...0.75)))
        }
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap to drop ink", "点击滴入墨滴"), ctx: ctx)
                .padding(.bottom, 14)
                .allowsHitTesting(false)
        }
    }
}

private struct InkCanvas: View {
    let t: Double
    let drops: [InkDrop]
    let spread: Double
    let life: Double
    let dark: Bool

    var body: some View {
        Canvas { context, size in
            let colors = InkPalette.colors(dark: dark)
            context.blendMode = dark ? .screen : .multiply
            context.addFilter(.blur(radius: 10))
            for drop in drops {
                InkCanvas.draw(&context, drop: drop, color: colors[drop.color % colors.count], size: size, t: t, spread: spread, life: life)
            }
        }
    }

    private static func draw(
        _ context: inout GraphicsContext,
        drop: InkDrop,
        color: Color,
        size: CGSize,
        t: Double,
        spread: Double,
        life: Double
    ) {
        let age = t - drop.born
        guard age >= 0 else { return }
        let fade = max(0, 1 - age / max(life, 0.1))
        let alpha = min(age * 6, 1) * fade * fade
        guard alpha > 0.002 else { return }
        let g = CGFloat(1 - exp(-age / 0.9))
        let side = min(size.width, size.height)
        let scale = CGFloat(spread)
        let origin = CGPoint(x: drop.center.x * size.width, y: drop.center.y * size.height)

        for k in 0..<7 {
            let direction = BackgroundMath.rand(drop.seed, k) * BackgroundMath.tau
            let reach = side * (0.05 + 0.13 * BackgroundMath.unit(drop.seed, k + 10)) * scale
            let sink = side * 0.09 * BackgroundMath.unit(drop.seed, k + 20)
            let cx = origin.x + CGFloat(cos(direction)) * reach * g
            let cy = origin.y + CGFloat(sin(direction)) * reach * g + sink * g * g
            let radius = side * (0.03 + 0.07 * BackgroundMath.unit(drop.seed, k + 30)) * scale * (0.25 + g)
            let rect = CGRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2)
            context.fill(Path(ellipseIn: rect), with: .color(color.opacity(alpha * 0.55)))
        }

        let coreRadius = side * 0.035 * (1 + 1.4 * g) * scale
        let core = CGRect(x: origin.x - coreRadius, y: origin.y - coreRadius, width: coreRadius * 2, height: coreRadius * 2)
        context.fill(Path(ellipseIn: core), with: .color(color.opacity(alpha * 0.8 * (1 - 0.6 * Double(g)))))

        let ringRadius = 10 + g * side * 0.3
        let ring = CGRect(x: origin.x - ringRadius, y: origin.y - ringRadius, width: ringRadius * 2, height: ringRadius * 2)
        context.stroke(Path(ellipseIn: ring), with: .color(color.opacity(0.3 * Double(1 - g) * fade)), lineWidth: 1.5)
    }
}

// MARK: - Slosh tank

private struct SloshState {
    let t: Double
    let slope: Double
    let velocity: Double
}

private final class SloshModel {
    let clock = BackgroundClock()
    var touching = false
    /// Desired surface slope (dy/dx) while a finger is down.
    var target: Double = 0
    private var slope: Double = 0
    private var velocity: Double = 0
    private var kickSign: Double = 1

    func step(now: Double, stiffness: Double, dampingRatio: Double) -> SloshState {
        let t = clock.advance(to: now, speed: 1)
        let dt = clock.delta
        let goal = touching ? target : 0
        let damping = 2 * dampingRatio * sqrt(stiffness)
        let accel = stiffness * (goal - slope) - damping * velocity
        velocity += accel * dt
        slope = (slope + velocity * dt).clamped(to: -0.6...0.6)
        return SloshState(t: t, slope: slope, velocity: velocity)
    }

    /// Simulated shove used by previews: alternates direction.
    func kick() {
        velocity += 2.4 * kickSign
        kickSign = -kickSign
    }
}

private struct SloshTankDemo: View {
    let ctx: DemoContext
    @State private var model = SloshModel()
    @State private var size = CGSize(width: 340, height: 340)

    var body: some View {
        let stiffness = ctx["stiffness"]
        let damping = ctx["damping"]
        let level = ctx["level"]
        ZStack {
            LinearGradient(colors: [Color(hex: 0x0B1426), Color(hex: 0x12203D)], startPoint: .top, endPoint: .bottom)
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let state = model.step(now: timeline.date.timeIntervalSinceReferenceDate, stiffness: stiffness, dampingRatio: damping)
                SloshCanvas(state: state, level: level)
            }
            BackgroundSampleTitle(
                title: L("1.8 L", "1.8 升"),
                subtitle: L("Daily goal · 72%", "今日目标 · 72%"),
                language: ctx.language,
                size: 40
            )
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 34)
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        .backgroundsTouch { location in
            model.touching = true
            let u = Double(location.x / max(size.width, 1))
            model.target = (-(u - 0.5) * 0.9).clamped(to: -0.45...0.45)
        } onEnded: {
            model.touching = false
            Haptics.tap(.soft)
        }
        .autoplay(ctx.isPreview, every: 2.8, delay: 0.5) { model.kick() }
        .backgroundsHint(L("Tap or drag sideways to tilt the water", "点击或横向拖动让水倾斜"), ctx)
    }
}

private struct SloshCanvas: View {
    let state: SloshState
    let level: Double

    var body: some View {
        Canvas { context, size in
            let top = size.height * CGFloat(1 - level)
            let back = SloshCanvas.surface(size: size, state: state, level: level, tilt: 0.82, phase: 1.7, lift: -6)
            let backShading = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [Color(hex: 0x3AC4FF).opacity(0.45), Color(hex: 0x1D4ED8).opacity(0.55)]),
                startPoint: CGPoint(x: 0, y: top),
                endPoint: CGPoint(x: 0, y: size.height)
            )
            context.fill(back.fill, with: backShading)

            let front = SloshCanvas.surface(size: size, state: state, level: level, tilt: 1, phase: 0, lift: 0)
            let frontShading = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [Color(hex: 0x5BE7C4).opacity(0.85), Color(hex: 0x2563EB).opacity(0.9)]),
                startPoint: CGPoint(x: 0, y: top),
                endPoint: CGPoint(x: 0, y: size.height)
            )
            context.fill(front.fill, with: frontShading)
            context.stroke(back.crest, with: .color(.white.opacity(0.25)), lineWidth: 1)
            context.stroke(front.crest, with: .color(.white.opacity(0.7)), lineWidth: 1.5)
            SloshCanvas.drawBubbles(&context, size: size, state: state, level: level)
        }
    }

    /// Surface height at `x` (points, y grows downward).
    static func height(x: CGFloat, size: CGSize, state: SloshState, level: Double, tilt: Double, phase: Double, lift: CGFloat) -> CGFloat {
        let base = size.height * CGFloat(1 - level) + lift
        let u = Double(x / max(size.width, 1))
        let slant = CGFloat(state.slope * tilt) * (x - size.width / 2)
        let mode = CGFloat((state.velocity * 7).clamped(to: -24...24)) * CGFloat(sin(u * 2 * .pi))
        let ripple = 3 * sin(u * 11 + state.t * 2.2 + phase) + 1.6 * sin(u * 23 - state.t * 3.1)
        return base + slant + mode + CGFloat(ripple)
    }

    private static func surface(size: CGSize, state: SloshState, level: Double, tilt: Double, phase: Double, lift: CGFloat) -> (fill: Path, crest: Path) {
        var fill = Path()
        var crest = Path()
        fill.move(to: CGPoint(x: 0, y: size.height))
        var x: CGFloat = 0
        var first = true
        while x <= size.width + 6 {
            let y = height(x: x, size: size, state: state, level: level, tilt: tilt, phase: phase, lift: lift)
            let point = CGPoint(x: x, y: y)
            fill.addLine(to: point)
            if first {
                crest.move(to: point)
                first = false
            } else {
                crest.addLine(to: point)
            }
            x += 6
        }
        fill.addLine(to: CGPoint(x: size.width + 6, y: size.height))
        fill.closeSubpath()
        return (fill, crest)
    }

    private static func drawBubbles(_ context: inout GraphicsContext, size: CGSize, state: SloshState, level: Double) {
        let depth = Double(size.height) * level
        var bubbles = Path()
        for i in 0..<16 {
            let rise = BackgroundMath.fract(BackgroundMath.rand(i, 71) + state.t * 0.12 * (0.5 + BackgroundMath.rand(i, 72)))
            let x = BackgroundMath.unit(i, 73) * size.width + CGFloat(6 * sin(state.t * 2 + Double(i)))
            let y = size.height - CGFloat(rise * depth)
            let surfaceY = height(x: x, size: size, state: state, level: level, tilt: 1, phase: 0, lift: 0)
            guard y > surfaceY + 8 else { continue }
            let r = 1.5 + 2.5 * BackgroundMath.unit(i, 74)
            bubbles.addEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
        }
        context.stroke(bubbles, with: .color(.white.opacity(0.4)), lineWidth: 1)
    }
}
