import SwiftUI

extension Effect {
    static let gesturesOrbitSlingshot = Effect(
        id: "gestures.orbit-slingshot",
        category: .gestures,
        interaction: .gesture,
        name: L("Orbit Slingshot", "引力弹弓"),
        summary: L("Pull a moon back, see its predicted path, and release it into orbit around a glowing star.", "向后拉动卫星、预览轨迹，松手让它绕着发光恒星公转。"),
        prompt: L(
            "A 300 pt dark-glass arena holds a 44 pt glowing star with a pulsing amber halo at its center and a 22 pt sky-blue moon resting 100 pt below it. Grabbing the moon and pulling it back works like a slingshot: the pull is capped at 90 pt, a dashed band stretches from the moon to its launch point, and a dotted preview of the next 2 s of trajectory updates live as you aim. On release the launch velocity is 3.5 × the pull vector, opposite to it, and the moon moves under inverse-square gravity (softened near the core), sweeping ellipses or slingshotting past the star with a fading 40-point comet trail. Hitting the star flashes it and respawns the moon; escaping the arena respawns it too. Cosmic, playful, genuinely physical.",
            "一个 300pt 的深色玻璃场地中心有一颗 44pt 的发光恒星，外圈是缓缓脉动的琥珀色光晕；一颗 22pt 的天蓝色卫星静置在恒星下方 100pt 处。抓住卫星向后拉，就像拉弹弓：拉动距离上限 90pt，一条虚线皮筋从卫星连到发射点，同时以点线实时预览接下来 2 秒的飞行轨迹。松手后发射速度为拉动向量反方向的 3.5 倍，卫星在平方反比引力（核心附近做了软化）下运动：或划出椭圆轨道，或借恒星引力甩出，身后拖着 40 个点逐渐淡出的彗尾。撞上恒星会让它闪亮一下并重生卫星，飞出场地同样会重生。充满宇宙感、好玩，而且是真实的物理。"
        ),
        implementation: L(
            "A frame-stepped class integrates softened inverse-square gravity with two semi-implicit Euler sub-steps per frame; while aiming, the same integrator runs 60 steps ahead to draw the dotted prediction in a Canvas. The DragGesture lives on the moon only, in a named coordinate space.",
            "逐帧推进的模型类以每帧两次半隐式欧拉子步积分带软化的平方反比引力；瞄准时用同一积分器向前推演 60 步，在 Canvas 中绘制点线预测轨迹。DragGesture 只挂在卫星上，使用具名坐标空间。"
        ),
        apis: ["TimelineView(.animation)", "Canvas", "DragGesture", "coordinateSpace(.named)", "StrokeStyle(dash:)"],
        tags: ["orbit", "gravity", "slingshot", "trajectory", "space", "轨道", "引力", "弹弓", "轨迹预测"],
        params: [
            .slider("gravity", L("Gravity", "引力强度"), 0.4...2.0, default: 1),
            .slider("power", L("Launch power", "发射力度"), 1.5...6.0, default: 3.5, decimals: 1),
            .slider("trail", L("Trail length", "彗尾长度"), 5...80, default: 40, step: 1, decimals: 0),
        ]
    ) { ctx in
        OrbitSlingshotDemo(ctx: ctx)
    }
}

private let orbitArena: CGFloat = 300
private let orbitCenter = CGPoint(x: 150, y: 150)
private let orbitPad = CGPoint(x: 150, y: 250)
private let orbitBaseG: CGFloat = 3_240_000

private struct OrbitFrame {
    var position: CGPoint
    var trail: [CGPoint]
    var flash: CGFloat
}

private enum OrbitPhysics {
    static func acceleration(at p: CGPoint, g: CGFloat) -> CGVector {
        let dx: CGFloat = orbitCenter.x - p.x
        let dy: CGFloat = orbitCenter.y - p.y
        let r2: CGFloat = dx * dx + dy * dy + 400
        let r: CGFloat = r2.squareRoot()
        let magnitude: CGFloat = g / r2
        return CGVector(dx: magnitude * dx / r, dy: magnitude * dy / r)
    }

    static func advance(_ p: inout CGPoint, _ v: inout CGVector, dt: CGFloat, g: CGFloat) {
        let a = acceleration(at: p, g: g)
        v.dx += a.dx * dt
        v.dy += a.dy * dt
        p.x += v.dx * dt
        p.y += v.dy * dt
    }
}

/// Frame-stepped orbital physics. A class so the TimelineView can advance it without triggering state updates.
private final class OrbitModel {
    var position = orbitPad
    var velocity: CGVector = .zero
    var isHeld = false
    var inFlight = false
    private var trail: [CGPoint] = []
    private var flash: CGFloat = 0
    private var lastDate: Date?

    func launch(from point: CGPoint, velocity newVelocity: CGVector) {
        position = point
        velocity = newVelocity
        isHeld = false
        inFlight = true
        lastDate = nil
    }

    private func respawn(flashStar: Bool) {
        position = orbitPad
        velocity = .zero
        inFlight = false
        trail.removeAll()
        if flashStar { flash = 1 }
    }

    func step(to date: Date, g: CGFloat, maxTrail: Int) -> OrbitFrame {
        let raw = lastDate.map { date.timeIntervalSince($0) } ?? 0
        lastDate = date
        let dt = CGFloat(min(max(raw, 0), 1.0 / 30.0))
        flash *= CGFloat(exp(-Double(dt) * 5))

        if inFlight && !isHeld && dt > 0 {
            OrbitPhysics.advance(&position, &velocity, dt: dt / 2, g: g)
            OrbitPhysics.advance(&position, &velocity, dt: dt / 2, g: g)
            trail.append(position)
            let dx: CGFloat = position.x - orbitCenter.x
            let dy: CGFloat = position.y - orbitCenter.y
            let r: CGFloat = (dx * dx + dy * dy).squareRoot()
            if r < 24 {
                respawn(flashStar: true)
            } else if r > 330 {
                respawn(flashStar: false)
            }
        } else if !trail.isEmpty {
            trail.removeFirst()
        }
        if trail.count > maxTrail { trail.removeFirst(trail.count - maxTrail) }
        return OrbitFrame(position: position, trail: trail, flash: flash)
    }
}

private struct OrbitSlingshotDemo: View {
    let ctx: DemoContext
    @State private var model = OrbitModel()
    @State private var anchor: CGPoint?
    @State private var pull: CGSize = .zero

    var body: some View {
        let g = orbitBaseG * ctx.cg("gravity")
        let maxTrail = ctx.int("trail")
        VStack(spacing: 12) {
            ZStack(alignment: .topLeading) {
                OrbitArenaBackground()
                TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                    let frame = model.step(to: timeline.date, g: g, maxTrail: maxTrail)
                    ZStack(alignment: .topLeading) {
                        OrbitTrailCanvas(frame: frame, aim: aimPreview(g: g))
                        OrbitStar(flash: frame.flash, date: timeline.date)
                            .position(orbitCenter)
                        moon
                            .gesture(dragGesture)
                            .position(displayPosition(frame))
                    }
                }
            }
            .frame(width: orbitArena, height: orbitArena)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .coordinateSpace(.named("orbit"))
            DemoHint(text: L("Pull the moon back and release", "向后拉动卫星再松手"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 5.0, delay: 0.3) { autoLaunch() }
    }

    private var moon: some View {
        Circle()
            .fill(LinearGradient(colors: [Palette.sky, Palette.blue], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(Circle().strokeBorder(.white.opacity(0.4), lineWidth: 1))
            .frame(width: 22, height: 22)
            .shadow(color: Palette.sky.opacity(0.7), radius: 8)
            .padding(10)
            .contentShape(Circle())
            .scaleEffect(anchor != nil ? 1.15 : 1)
    }

    private func displayPosition(_ frame: OrbitFrame) -> CGPoint {
        guard let start = anchor else { return frame.position }
        return CGPoint(x: start.x + pull.width, y: start.y + pull.height)
    }

    private func launchVelocity() -> CGVector {
        let power = ctx.cg("power")
        return CGVector(dx: -pull.width * power, dy: -pull.height * power)
    }

    /// Dashed band + dotted two-second prediction, only while aiming.
    private func aimPreview(g: CGFloat) -> OrbitAim? {
        guard let start = anchor else { return nil }
        let moonPoint = CGPoint(x: start.x + pull.width, y: start.y + pull.height)
        var p = moonPoint
        var v = launchVelocity()
        var dots: [CGPoint] = []
        for index in 0..<60 {
            OrbitPhysics.advance(&p, &v, dt: 1.0 / 30.0, g: g)
            if index % 2 == 1 { dots.append(p) }
        }
        return OrbitAim(anchor: start, moon: moonPoint, dots: dots)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("orbit"))
            .onChanged { value in
                if anchor == nil {
                    anchor = model.position
                    model.isHeld = true
                    if !ctx.isPreview { Haptics.tap(.light) }
                }
                let dx = value.translation.width
                let dy = value.translation.height
                let length = (dx * dx + dy * dy).squareRoot()
                let scale: CGFloat = length > 90 ? 90 / length : 1
                pull = CGSize(width: dx * scale, height: dy * scale)
            }
            .onEnded { _ in
                guard let start = anchor else { return }
                let from = CGPoint(x: start.x + pull.width, y: start.y + pull.height)
                model.launch(from: from, velocity: launchVelocity())
                anchor = nil
                pull = .zero
                if !ctx.isPreview { Haptics.tap(.medium) }
            }
    }

    private func autoLaunch() {
        guard anchor == nil else { return }
        let side: CGFloat = Bool.random() ? 1 : -1
        model.launch(
            from: orbitPad,
            velocity: CGVector(dx: side * CGFloat.random(in: 150...215), dy: CGFloat.random(in: -40...20))
        )
    }
}

private struct OrbitAim {
    let anchor: CGPoint
    let moon: CGPoint
    let dots: [CGPoint]
}

private struct OrbitTrailCanvas: View {
    let frame: OrbitFrame
    let aim: OrbitAim?

    var body: some View {
        Canvas { context, _ in
            let count = frame.trail.count
            for (index, point) in frame.trail.enumerated() {
                let t = CGFloat(index + 1) / CGFloat(max(count, 1))
                let r: CGFloat = 1 + 5 * t
                let rect = CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2)
                context.fill(Path(ellipseIn: rect), with: .color(Palette.sky.opacity(Double(0.5 * t))))
            }
            guard let aim = self.aim else { return }
            var band = Path()
            band.move(to: aim.anchor)
            band.addLine(to: aim.moon)
            context.stroke(band, with: .color(.white.opacity(0.6)), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 5]))
            for (index, dot) in aim.dots.enumerated() {
                let fade = 1 - Double(index) / Double(max(aim.dots.count, 1))
                let rect = CGRect(x: dot.x - 2, y: dot.y - 2, width: 4, height: 4)
                context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.75 * fade)))
            }
        }
        .frame(width: orbitArena, height: orbitArena)
        .allowsHitTesting(false)
    }
}

private struct OrbitStar: View {
    let flash: CGFloat
    let date: Date

    var body: some View {
        let t = date.timeIntervalSinceReferenceDate
        let pulse = CGFloat(0.5 + 0.5 * sin(t * 2.2))
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Palette.amber.opacity(0.55), .clear], center: .center, startRadius: 10, endRadius: 70))
                .frame(width: 140, height: 140)
                .scaleEffect(0.9 + 0.12 * pulse + 0.5 * flash)
            Circle()
                .fill(RadialGradient(colors: [.white, Palette.amber, Palette.coral], center: .center, startRadius: 2, endRadius: 24))
                .frame(width: 44, height: 44)
                .shadow(color: Palette.amber.opacity(0.9), radius: 14 + 20 * flash)
        }
        .allowsHitTesting(false)
    }
}

private struct OrbitArenaBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 34, style: .continuous)
            .fill(LinearGradient(colors: [Color(hex: 0x0E1230), Color(hex: 0x1B1340)], startPoint: .top, endPoint: .bottom))
            .overlay {
                Canvas { context, size in
                    var generator = SeededStars(seed: 7)
                    for _ in 0..<60 {
                        let x = generator.next() * size.width
                        let y = generator.next() * size.height
                        let r = 0.5 + generator.next() * 1.2
                        let rect = CGRect(x: x, y: y, width: r, height: r)
                        context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.25 + 0.5 * Double(generator.next()))))
                    }
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 34, style: .continuous).strokeBorder(.white.opacity(0.08), lineWidth: 1))
    }
}

/// Tiny deterministic generator so the star field doesn't reshuffle on every redraw.
private struct SeededStars {
    var state: UInt64

    init(seed: UInt64) { state = seed &* 0x9E37_79B9_7F4A_7C15 }

    mutating func next() -> CGFloat {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        let value = Double((state >> 33) & 0xFFFFFF) / Double(0xFFFFFF)
        return CGFloat(value)
    }
}
