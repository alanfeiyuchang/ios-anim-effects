import SwiftUI

extension Effect {
    static let gesturesGravityToss = Effect(
        id: "gestures.gravity-toss",
        category: .gestures,
        interaction: .gesture,
        name: L("Gravity Toss", "重力抛球"),
        summary: L("Toss a ball: it arcs under gravity, squashes on the floor, bounces lower each time and rolls to a stop.", "抛出小球：在重力下划出抛物线，落地压扁、越弹越低，最后滚动停下。"),
        prompt: L(
            "A 56 pt beach ball (amber-to-coral gradient with a white band so its spin reads) rests on the floor of a 300 pt rounded arena above a soft contact shadow that shrinks and fades as it rises. Grab and throw it: the release velocity becomes its launch velocity and 1,800 pt/s² of gravity bends it into a true parabola. Each floor impact reflects the vertical speed with 0.62 restitution, squashes the ball up to 25% against the floor for about 80 ms and bleeds 8% of its horizontal speed, while walls and ceiling reflect it too. On the ground it rolls, spinning at v ∕ r until friction stops it, with a soft haptic on heavy impacts: honest, weighty physics.",
            "一个56 pt的沙滩球（琥珀到珊瑚渐变，一条白色色带让旋转清晰可见）静置在300 pt圆角场地的地面上，接触阴影随球升高而缩小变淡。抓起小球抛出：离手速度即初速度，1800 pt/s²的重力把它拉成一条真实的抛物线。每次落地，竖直速度按0.62的恢复系数反弹，小球贴地压扁最多25%、约80毫秒，水平速度损失8%，墙壁和顶部同样会反弹。落地后小球以v∕r的角速度滚动，直到被摩擦停住，重击时伴随柔和触感。真实、有分量的物理手感。"
        ),
        implementation: L(
            "A frame-stepped class integrates gravity, restitution, rolling friction and squash inside a TimelineView that sleeps once the ball settles; a DragGesture on the ball moves it by its global translation and hands the release velocity to the model.",
            "逐帧推进的模型类在 TimelineView 中积分重力、恢复系数、滚动摩擦与压扁，小球静止后时间线自动休眠；挂在小球上的 DragGesture 按全局位移移动小球，并把松手速度交给模型。"
        ),
        apis: ["TimelineView(.animation)", "DragGesture.Value.velocity", "DragGesture.Value.translation", "scaleEffect(x:y:anchor:)", "rotationEffect"],
        tags: ["gravity", "toss", "bounce", "parabola", "重力", "抛掷", "弹跳", "抛物线"],
        params: [
            .slider("gravity", L("Gravity", "重力"), 600...3200, default: 1800, step: 50, decimals: 0, unit: "pt/s²"),
            .slider("bounce", L("Restitution", "恢复系数"), 0.2...0.9, default: 0.62),
            .slider("friction", L("Rolling friction", "滚动摩擦"), 0.3...4.0, default: 1.4),
        ]
    ) { ctx in
        GravityTossDemo(ctx: ctx)
    }
}

private struct TossFrame {
    var position: CGPoint
    var spin: Double
    var squash: CGFloat
}

/// Frame-stepped ball physics. A class so the TimelineView can advance it without triggering state updates.
private final class TossModel {
    var position: CGPoint
    var velocity: CGVector = .zero
    var isHeld = false
    private var spin: Double = 0
    private var spinVelocity: Double = 0
    private var squash: CGFloat = 0
    private var onFloor = true
    private var lastDate: Date?
    /// Rate-limits floor haptics (the timeline can re-render a frame).
    private var lastImpact: Date?

    init(position: CGPoint) {
        self.position = position
    }

    var isSettled: Bool {
        !isHeld && onFloor && abs(velocity.dx) < 2 && abs(velocity.dy) < 1 && squash < 0.002
    }

    func resetClock() {
        lastDate = nil
    }

    func release(velocity newVelocity: CGVector) {
        velocity = newVelocity
        isHeld = false
        onFloor = false
        lastDate = nil
    }

    func step(to date: Date, arena: CGSize, radius: CGFloat, gravity: CGFloat, restitution: CGFloat, friction: CGFloat, haptics: Bool) -> TossFrame {
        let raw = lastDate.map { date.timeIntervalSince($0) } ?? 0
        lastDate = date
        let dt = CGFloat(min(max(raw, 0), 1.0 / 30.0))
        squash *= CGFloat(exp(-Double(dt) * 22))
        let floorY: CGFloat = arena.height - radius

        if isHeld || dt == 0 {
            return TossFrame(position: position, spin: spin, squash: squash)
        }

        if !onFloor {
            velocity.dy += gravity * dt
        } else {
            velocity.dx *= CGFloat(exp(-Double(dt * friction)))
            if abs(velocity.dx) < 2 { velocity.dx = 0 }
        }
        position.x += velocity.dx * dt
        position.y += velocity.dy * dt

        if position.y >= floorY {
            position.y = floorY
            let impact = velocity.dy
            if impact > 0 {
                squash = min(impact / 3200, 0.25)
                if haptics && impact > 700 && (lastImpact.map { date.timeIntervalSince($0) > 0.08 } ?? true) {
                    lastImpact = date
                    // Never fire side effects while SwiftUI is evaluating the view: defer to the next main-loop turn.
                    DispatchQueue.main.async { Haptics.tap(.soft) }
                }
                velocity.dy = -impact * restitution
                velocity.dx *= 0.92
                if abs(velocity.dy) < 60 {
                    velocity.dy = 0
                    onFloor = true
                }
            }
        }
        if position.y < radius {
            position.y = radius
            velocity.dy = abs(velocity.dy) * restitution
        }
        if position.x < radius || position.x > arena.width - radius {
            position.x = position.x.clamped(to: radius...max(arena.width - radius, radius))
            velocity.dx = -velocity.dx * restitution
        }

        // Rolling on the floor spins at v / r; in the air the spin slowly decays.
        if onFloor || position.y >= floorY - 0.5 {
            spinVelocity = Double(velocity.dx / max(radius, 1))
        } else {
            spinVelocity *= exp(-Double(dt) * 0.4)
        }
        spin += spinVelocity * Double(dt)
        return TossFrame(position: position, spin: spin, squash: squash)
    }
}

private struct GravityTossDemo: View {
    let ctx: DemoContext
    @State private var model = TossModel(position: CGPoint(x: 150, y: 272))
    @State private var grabStart: CGPoint?
    @State private var held = false
    @State private var awake = true
    @State private var userTouched = false
    @State private var sleepWatcher: Task<Void, Never>?

    private let arena = CGSize(width: 300, height: 300)
    private let radius: CGFloat = 28

    var body: some View {
        let gravity = ctx.cg("gravity")
        let restitution = ctx.cg("bounce")
        let friction = ctx.cg("friction")
        let haptics = !ctx.isPreview && userTouched

        VStack(spacing: 12) {
            ZStack(alignment: .topLeading) {
                TossArena()
                TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview), paused: !awake)) { timeline in
                    let frame = model.step(to: timeline.date, arena: arena, radius: radius, gravity: gravity, restitution: restitution, friction: friction, haptics: haptics)
                    ZStack(alignment: .topLeading) {
                        contactShadow(frame)
                        TossBall(spin: frame.spin, held: held)
                            .frame(width: radius * 2, height: radius * 2)
                            .scaleEffect(x: 1 + frame.squash, y: 1 - frame.squash, anchor: .bottom)
                            .gesture(dragGesture)
                            .position(frame.position)
                    }
                }
            }
            .frame(width: arena.width, height: arena.height)
            DemoHint(text: L("Grab the ball and throw it", "抓起小球抛出去"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 3.0, delay: 0.4) { randomToss() }
        .onAppear { wake() }
        .onDisappear { sleepWatcher?.cancel() }
    }

    private func contactShadow(_ frame: TossFrame) -> some View {
        let height: CGFloat = max(arena.height - radius - frame.position.y, 0)
        let fade: CGFloat = max(1 - height / arena.height, 0.15)
        return Ellipse()
            .fill(Color.black.opacity(0.18 * Double(fade)))
            .frame(width: radius * 1.8 * fade, height: 8 * fade)
            .blur(radius: 3)
            .position(x: frame.position.x, y: arena.height - 5)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                if grabStart == nil {
                    grabStart = model.position
                    model.isHeld = true
                    model.velocity = .zero
                    userTouched = true
                    wake()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { held = true }
                    if !ctx.isPreview { Haptics.tap(.light) }
                }
                guard let start = grabStart else { return }
                let x: CGFloat = start.x + value.translation.width
                let y: CGFloat = start.y + value.translation.height
                model.position = CGPoint(
                    x: x.clamped(to: radius...(arena.width - radius)),
                    y: y.clamped(to: radius...(arena.height - radius))
                )
            }
            .onEnded { value in
                guard grabStart != nil else { return }
                grabStart = nil
                model.release(velocity: CGVector(
                    dx: value.velocity.width.clamped(to: -3200...3200),
                    dy: value.velocity.height.clamped(to: -3200...3200)
                ))
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { held = false }
                wake()
            }
    }

    private func wake() {
        if !awake { awake = true }
        model.resetClock()
        sleepWatcher?.cancel()
        sleepWatcher = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(0.3))
                if model.isSettled {
                    awake = false
                    return
                }
            }
        }
    }

    private func randomToss() {
        guard !model.isHeld else { return }
        let towardCenter: CGFloat = model.position.x > arena.width / 2 ? -1 : 1
        model.release(velocity: CGVector(
            dx: towardCenter * CGFloat.random(in: 260...620),
            dy: -CGFloat.random(in: 900...1250)
        ))
        wake()
    }
}

private struct TossArena: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 34, style: .continuous)
            .fill(Palette.elevated)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.primary.opacity(0.06))
                    .frame(height: 1)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 1)
            }
            .overlay(RoundedRectangle(cornerRadius: 34, style: .continuous).strokeBorder(Palette.stroke, lineWidth: 1))
            .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
    }
}

private struct TossBall: View {
    let spin: Double
    let held: Bool

    var body: some View {
        Circle()
            .fill(LinearGradient(colors: [Palette.amber, Palette.coral], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                Capsule()
                    .fill(.white.opacity(0.85))
                    .frame(height: 8)
                    .rotationEffect(.radians(spin))
            }
            .overlay {
                Circle()
                    .fill(LinearGradient(colors: [.white.opacity(0.45), .clear], startPoint: .top, endPoint: .center))
                    .padding(5)
            }
            .clipShape(Circle())
            .shadow(color: Palette.coral.opacity(held ? 0.5 : 0.3), radius: held ? 16 : 8, y: held ? 10 : 4)
            .scaleEffect(held ? 1.08 : 1)
    }
}
