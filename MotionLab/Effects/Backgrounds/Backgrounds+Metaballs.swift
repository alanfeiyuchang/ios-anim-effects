import SwiftUI

extension Effect {
    static let backgroundsMetaballs = Effect(
        id: "backgrounds.metaballs",
        category: .backgrounds,
        interaction: .gesture,
        name: L("Liquid Metaballs", "液态融球"),
        summary: L(
            "Mercury beads orbit a chrome pool; drag a droplet out until its neck pinches off and it springs home.",
            "水银珠环绕一汪镜面液池；拖出一颗液滴，细颈被拉断后它会弹回并重新融合。"
        ),
        prompt: L(
            "On a graphite canvas, liquid mercury: a pulsing central pool with several beads (seven by default) orbiting on slow Lissajous paths (≈7–15 s). When beads touch they neck and fuse into one chrome surface, then pinch apart. The metal is a slowly rotating graphite → silver → ice-blue gradient with a crisp 3 pt specular rim on every upper-left edge (the silhouette minus itself shifted toward the light, added with plusLighter) and a tight contact shadow beneath instead of a glow. Dragging sideways pulls a droplet out of the pool on a neck that thins as it stretches; past ~90 pt it pinches off with a rigid haptic, and the freed droplet springs back (response 0.5 s, damping 0.55), overshoots and re-merges. Releasing earlier retracts it neck and all. Heavy, cool, surface-tension tactile.",
            "石墨色画布上一汪液态水银：中央液池脉动，数颗水银珠（默认七颗）沿缓慢的李萨如轨迹（约 7–15 秒）环绕。相碰时拉出细颈、融成一片镜面再分开。金属填充缓慢旋转的石墨 → 银 → 冰蓝渐变，每个左上边缘有一道朝向光源、以 plusLighter 叠加的清晰 3pt 高光边，下方是紧致投影而非辉光。横向拖动会从液池里拉出一颗液滴，细颈越拉越细；超过约 90pt 即断开并伴随清脆触感，脱离的液滴以弹簧（响应 0.5 秒、阻尼 0.55）弹回、略微过冲后重新融合。提前松手则连颈缩回。沉甸冷冽，表面张力十足。"
        ),
        implementation: L(
            "One model produces the circles (pool, beads, the finger droplet and a tapering neck chain); a Canvas stacking alphaThreshold on blur turns them into a silhouette that masks a rotating LinearGradient. A second threshold pass, minus a copy shifted 3 pt with destinationOut, is the plusLighter rim; a blurred offset Canvas is the contact shadow. The freed droplet integrates a damped spring.",
            "同一个模型给出所有圆（液池、水银珠、手指液滴与逐渐变细的颈部链），叠加 alphaThreshold 与 blur 的 Canvas 把它们合成轮廓，遮罩旋转的 LinearGradient。第二遍阈值轮廓以 destinationOut 减去偏移 3pt 的副本，得到 plusLighter 高光边；模糊偏移的 Canvas 充当接触投影。断开的液滴用阻尼弹簧积分回弹。"
        ),
        apis: ["Canvas", "GraphicsContext.Filter.alphaThreshold", "GraphicsContext.BlendMode.destinationOut", "blendMode(.plusLighter)", "DragGesture"],
        tags: ["metaball", "mercury", "liquid metal", "surface tension", "融球", "水银", "液态金属", "表面张力"],
        params: [
            .slider("count", L("Beads", "水银珠数量"), 3...10, default: 7, step: 1, decimals: 0),
            .slider("goo", L("Surface tension", "表面张力"), 6...30, default: 16, decimals: 0, unit: "pt"),
            .slider("speed", L("Orbit speed", "环绕速度"), 0.2...2.0, default: 0.8, unit: "×"),
            .slider("pinch", L("Pinch-off distance", "断颈距离"), 50...140, default: 90, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        MetaballsDemo(ctx: ctx)
    }
}

/// Mercury model: orbiting beads plus a finger droplet that stretches out of the pool on a neck,
/// pinches off past `pinch` points and springs home (response 0.5 s, damping 0.55) to re-merge.
private final class MercuryModel {
    let clock = BackgroundClock()
    var touch: CGPoint?
    /// Previews never buzz.
    var haptics = true
    private(set) var time: Double = 0
    private(set) var drop: CGPoint?
    /// Whether the droplet still hangs on its neck (false once it pinched off).
    private(set) var attached = false
    private var velocity = CGVector.zero
    /// Pinched during the current touch: the finger no longer grabs until it lifts.
    private var latched = false

    static func core(size: CGSize, t: Double) -> (center: CGPoint, radius: CGFloat) {
        let side: CGFloat = min(size.width, size.height)
        let radius: CGFloat = side * CGFloat(0.13 + 0.015 * sin(t * 1.7))
        return (CGPoint(x: size.width / 2, y: size.height / 2), radius)
    }

    static func dropRadius(size: CGSize) -> CGFloat {
        min(size.width, size.height) * 0.075
    }

    func step(now: Double, speed: Double, size: CGSize, pinch: CGFloat, simulated: CGPoint?) -> Double {
        let t = clock.advance(to: now, speed: speed)
        time = t
        let dt: Double = clock.delta
        guard dt > 0 else { return t }
        let core = Self.core(size: size, t: t)
        let target: CGPoint? = touch ?? simulated
        if target == nil { latched = false }
        if let target, !latched {
            follow(target, core: core, dt: dt, pinch: pinch)
        } else if let current = drop {
            springHome(current, core: core, dt: dt)
        }
        return t
    }

    /// The droplet leaves the pool's rim toward the finger and chases it with a short exponential lag.
    private func follow(_ target: CGPoint, core: (center: CGPoint, radius: CGFloat), dt: Double, pinch: CGFloat) {
        let current: CGPoint
        if let drop {
            current = drop
        } else {
            let dx: CGFloat = target.x - core.center.x
            let dy: CGFloat = target.y - core.center.y
            let length: CGFloat = max(hypot(dx, dy), 0.001)
            current = CGPoint(x: core.center.x + dx / length * core.radius * 0.6, y: core.center.y + dy / length * core.radius * 0.6)
            attached = true
        }
        let k: CGFloat = CGFloat(1 - exp(-dt * 9))
        let next = CGPoint(x: current.x + (target.x - current.x) * k, y: current.y + (target.y - current.y) * k)
        velocity = CGVector(dx: (next.x - current.x) / CGFloat(dt), dy: (next.y - current.y) / CGFloat(dt))
        drop = next
        let stretch: CGFloat = hypot(next.x - core.center.x, next.y - core.center.y) - core.radius
        if attached && stretch > pinch {
            attached = false
            latched = true
            if haptics { Haptics.tap(.rigid) }
        }
    }

    /// Semi-implicit damped spring toward the pool's centre; merged once it sinks back inside.
    private func springHome(_ current: CGPoint, core: (center: CGPoint, radius: CGFloat), dt: Double) {
        let omega: CGFloat = 2 * .pi / 0.5
        let damping: CGFloat = 0.55
        let step: CGFloat = CGFloat(dt)
        let ox: CGFloat = current.x - core.center.x
        let oy: CGFloat = current.y - core.center.y
        velocity.dx += (-omega * omega * ox - 2 * damping * omega * velocity.dx) * step
        velocity.dy += (-omega * omega * oy - 2 * damping * omega * velocity.dy) * step
        let next = CGPoint(x: current.x + velocity.dx * step, y: current.y + velocity.dy * step)
        let distance: CGFloat = hypot(next.x - core.center.x, next.y - core.center.y)
        let speed: CGFloat = hypot(velocity.dx, velocity.dy)
        if distance < core.radius * 0.35 && speed < 40 {
            drop = nil
            attached = false
            velocity = .zero
        } else {
            drop = next
        }
    }

    /// Every circle of the liquid for this frame: pool, beads, droplet and its tapering neck.
    func circles(count: Int, size: CGSize, pinch: CGFloat) -> [CGRect] {
        let t = time
        let core = Self.core(size: size, t: t)
        let side: CGFloat = min(size.width, size.height)
        let orbit: CGFloat = side * 0.34
        var rects: [CGRect] = [Self.circle(core.center, core.radius)]
        for i in 0..<max(count, 0) {
            let a: Double = 0.5 + BackgroundMath.rand(i, 1) * 0.7
            let b: Double = 0.5 + BackgroundMath.rand(i, 2) * 0.7
            let p: Double = BackgroundMath.rand(i, 3) * BackgroundMath.tau
            let x: CGFloat = core.center.x + orbit * CGFloat(sin(t * a + p))
            let y: CGFloat = core.center.y + orbit * CGFloat(cos(t * b + p * 1.3))
            let r: CGFloat = side * CGFloat(0.05 + BackgroundMath.rand(i, 4) * 0.05)
            rects.append(Self.circle(CGPoint(x: x, y: y), r))
        }
        guard let drop else { return rects }
        let dropR: CGFloat = Self.dropRadius(size: size)
        rects.append(Self.circle(drop, dropR))
        if attached {
            // Neck: a chain of circles from the pool to the droplet, thinning as the stretch nears the pinch.
            let dx: CGFloat = drop.x - core.center.x
            let dy: CGFloat = drop.y - core.center.y
            let length: CGFloat = hypot(dx, dy)
            let stretch: CGFloat = max(length - core.radius, 0)
            let thin: CGFloat = max(1 - stretch / max(pinch, 1), 0)
            let links: Int = max(Int(length / 7), 3)
            for k in 1..<links {
                let f: CGFloat = CGFloat(k) / CGFloat(links)
                let base: CGFloat = core.radius * 0.5 * (1 - f) + dropR * 0.7 * f
                let r: CGFloat = base * (0.3 + 0.7 * thin)
                rects.append(Self.circle(CGPoint(x: core.center.x + dx * f, y: core.center.y + dy * f), r))
            }
        }
        return rects
    }

    private static func circle(_ center: CGPoint, _ radius: CGFloat) -> CGRect {
        CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    }
}

private struct MetaballsDemo: View {
    let ctx: DemoContext
    @State private var model = MercuryModel()
    @State private var size = CGSize(width: 340, height: 340)

    private static let chrome: [Color] = [
        Color(hex: 0x2E333B), Color(hex: 0x8A94A3), Color(hex: 0xEEF3F8), Color(hex: 0xA9CBE6), Color(hex: 0x3A414C),
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate
            // Step once per frame, before any canvas draws, so shadow, metal and rim share the same instant.
            let _ = model.step(now: now, speed: ctx["speed"], size: size, pinch: ctx.cg("pinch"), simulated: simulatedTouch(now: now))
            let circles = model.circles(count: ctx.int("count"), size: size, pinch: ctx.cg("pinch"))
            let spin: Double = now * 0.35
            let dx = CGFloat(0.5 * cos(spin))
            let dy = CGFloat(0.5 * sin(spin))
            ZStack {
                MercuryShadow(circles: circles)
                LinearGradient(
                    colors: Self.chrome,
                    startPoint: UnitPoint(x: 0.5 + dx, y: 0.5 + dy),
                    endPoint: UnitPoint(x: 0.5 - dx, y: 0.5 - dy)
                )
                .mask {
                    MercurySilhouette(circles: circles, goo: ctx.cg("goo"))
                }
                MercuryRim(circles: circles, goo: ctx.cg("goo"))
                    .blendMode(.plusLighter)
            }
            .drawingGroup()
        }
        .background(Color(hex: 0x101216))
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newSize in
            size = newSize
        }
        .onAppear { model.haptics = !ctx.isPreview }
        .backgroundsTouch { location in model.touch = location } onEnded: { model.touch = nil }
        .backgroundsHint(L("Drag a droplet out of the pool", "从液池里拖出一颗液滴"), ctx)
        .onDisappear { model.touch = nil }
    }

    /// Previews can't be touched: every 3.2 s a "finger" drags outward from the pool past the pinch, then lifts.
    private func simulatedTouch(now: Double) -> CGPoint? {
        guard ctx.isPreview else { return nil }
        let cycle: Double = now.truncatingRemainder(dividingBy: 3.2)
        guard cycle < 2.0 else { return nil }
        let angle: Double = (now / 3.2).rounded(.down) * 2.4
        let reach: CGFloat = min(size.width, size.height) * CGFloat(0.12 + 0.3 * cycle / 2.0)
        return CGPoint(
            x: size.width / 2 + reach * CGFloat(cos(angle)),
            y: size.height / 2 + reach * CGFloat(sin(angle))
        )
    }
}

/// The liquid's silhouette: blurred white circles cut at 50% alpha, so nearby shapes neck and fuse.
private struct MercurySilhouette: View {
    let circles: [CGRect]
    let goo: CGFloat

    var body: some View {
        Canvas { context, _ in
            MercuryRim.silhouette(&context, circles: circles, goo: goo, color: .white)
        }
    }
}

/// Specular rim: the silhouette minus a copy shifted 3 pt away from the top-left light (destinationOut),
/// leaving a crisp crescent on every upper-left edge; composited with plusLighter.
private struct MercuryRim: View {
    let circles: [CGRect]
    let goo: CGFloat

    static func silhouette(_ context: inout GraphicsContext, circles: [CGRect], goo: CGFloat, color: Color) {
        context.addFilter(.alphaThreshold(min: 0.5, color: color))
        context.addFilter(.blur(radius: goo))
        context.drawLayer { layer in
            for rect in circles {
                layer.fill(Path(ellipseIn: rect), with: .color(.white))
            }
        }
    }

    var body: some View {
        Canvas { context, _ in
            context.drawLayer { rim in
                rim.opacity = 0.85
                rim.drawLayer { lit in
                    MercuryRim.silhouette(&lit, circles: circles, goo: goo, color: Color(hex: 0xF4FAFF))
                }
                rim.blendMode = .destinationOut
                rim.translateBy(x: 3, y: 3)
                rim.drawLayer { cut in
                    MercuryRim.silhouette(&cut, circles: circles, goo: goo, color: .white)
                }
            }
        }
    }
}

/// Tight contact shadow under the metal (no bloom): the same circles, darkened, blurred and dropped 5 pt.
private struct MercuryShadow: View {
    let circles: [CGRect]

    var body: some View {
        Canvas { context, _ in
            context.addFilter(.blur(radius: 6))
            let shade = GraphicsContext.Shading.color(.black.opacity(0.6))
            for rect in circles {
                context.fill(Path(ellipseIn: rect.offsetBy(dx: 0, dy: 5)), with: shade)
            }
        }
    }
}
