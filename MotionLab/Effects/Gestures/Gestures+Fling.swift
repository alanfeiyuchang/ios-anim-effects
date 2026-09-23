import SwiftUI

extension Effect {
    static let gesturesFling = Effect(
        id: "gestures.fling-inertia",
        category: .gestures,
        interaction: .gesture,
        name: L("Fling & Wall Bounce", "惯性甩动与撞墙反弹"),
        summary: L("Throw a puck; it glides with real momentum, ricochets off the walls and can be caught mid-flight.", "甩出圆球，带着真实惯性滑行、撞墙反弹，飞行中也能随手接住。"),
        prompt: L(
            "A glossy 64 pt puck (mint-to-sky gradient, inner highlight, colored drop shadow) sits inside a 290 pt rounded arena with a subtle dot grid. The puck follows the finger 1:1 and swells to 108% while held. On release it keeps the exact lift-off velocity and decelerates exponentially (time constant = glide factor, so it coasts velocity × glide points), with a faint comet trail whose length tracks its speed. Hitting a wall reflects the velocity with a restitution of ~0.82 and squashes the puck up to 22% for ~120 ms, anchored on the side touching the wall so it flattens against it rather than shrinking in mid-air, with a soft haptic on hard hits. The simulation pauses once the puck has settled. Because the physics is integrated every frame, touching the puck mid-flight catches it exactly where it is on screen — no jump. A hard flick ricochets several times; a gentle toss barely drifts.",
            "一个 64pt 的光泽圆球（薄荷绿到天蓝渐变、内高光、同色投影）置于 290pt 的圆角场地中，场地铺有淡淡的点阵。按住时圆球 1:1 跟手并放大到 108%。松手后圆球完整继承离手速度，并按指数规律减速（时间常数即滑行系数，滑行距离 = 速度 × 滑行系数），身后拖出一道随速度伸缩的淡彗尾。撞墙时速度按约 0.82 的恢复系数反射，圆球以接触墙面的一侧为锚点压扁最多 22%、约 120ms 后弹回——是贴着墙变扁，而不是悬空缩小；重击时伴随轻柔触感。圆球静止后模拟随即暂停。由于物理状态逐帧积分，飞行途中按住圆球会在它当前的屏幕位置被稳稳接住，毫无跳变。重甩连续反弹，轻抛只滑出一小段。"
        ),
        implementation: L(
            "A reference-type model integrates velocity with exponential friction and reflects it at the walls; TimelineView(.animation) steps it every frame and renders the puck, the wall-anchored squash and the trail, and pauses once the model settles. The DragGesture grabs the model's live position, so catching mid-flight is seamless.",
            "引用类型模型以指数摩擦积分速度并在墙面反射；TimelineView(.animation) 每帧推进模型并渲染圆球、贴墙锚定的挤压与尾迹，模型静止后即暂停。DragGesture 直接抓取模型的实时位置，因此飞行中接住毫无跳变。"
        ),
        apis: ["TimelineView(.animation)", "DragGesture.Value.velocity", "Canvas", "exp decay", "scaleEffect(x:y:)"],
        tags: ["fling", "inertia", "momentum", "bounce", "velocity", "physics", "惯性", "甩动", "反弹", "动量", "物理"],
        params: [
            .slider("glide", L("Glide factor", "滑行系数"), 0.15...0.8, default: 0.35, unit: "s"),
            .slider("bounce", L("Wall restitution", "撞墙弹性"), 0.3...1.0, default: 0.82),
            .slider("size", L("Puck size", "圆球尺寸"), 44...90, default: 64, step: 1, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        FlingDemo(ctx: ctx)
    }
}

/// One rendered frame of the simulation.
private struct FlingFrame {
    var position: CGPoint
    var squash: CGVector
    var trail: [CGPoint]
}

/// Frame-stepped puck physics. A class so the TimelineView can advance it without triggering state updates.
private final class FlingModel {
    /// Top-left of the puck inside the arena, in 0...bounds.
    var position: CGPoint
    var velocity: CGVector = .zero
    var isHeld = false
    private(set) var squash: CGVector = .zero
    private(set) var trail: [CGPoint] = []
    private var lastDate: Date?

    init(position: CGPoint) {
        self.position = position
    }

    var isResting: Bool {
        !isHeld && abs(velocity.dx) < 1 && abs(velocity.dy) < 1
    }

    /// Nothing left to animate: at rest, squash relaxed and trail drained.
    var isSettled: Bool {
        isResting && abs(squash.dx) < 0.002 && abs(squash.dy) < 0.002 && trail.isEmpty
    }

    func step(to date: Date, bounds: CGSize, glide: Double, restitution: Double, haptics: Bool) -> FlingFrame {
        let raw = lastDate.map { date.timeIntervalSince($0) } ?? 0
        lastDate = date
        let dt = CGFloat(min(max(raw, 0), 1.0 / 20.0))

        let relax = CGFloat(exp(-Double(dt) * 16))
        squash.dx *= relax
        squash.dy *= relax

        if !isHeld && dt > 0 {
            let friction = CGFloat(exp(-Double(dt) / max(glide, 0.05)))
            velocity.dx *= friction
            velocity.dy *= friction
            if (velocity.dx * velocity.dx + velocity.dy * velocity.dy).squareRoot() < 6 {
                velocity = .zero
            }
            position.x += velocity.dx * dt
            position.y += velocity.dy * dt
            let e = CGFloat(restitution)
            var impact: CGFloat = 0
            if position.x < 0 || position.x > bounds.width {
                position.x = position.x < 0 ? -position.x : 2 * bounds.width - position.x
                impact = max(impact, abs(velocity.dx))
                // Signed by the incoming direction: negative = left wall, positive = right wall.
                squash.dx = (velocity.dx < 0 ? -1 : 1) * min(abs(velocity.dx) / 2600, 0.22)
                velocity.dx = -velocity.dx * e
            }
            if position.y < 0 || position.y > bounds.height {
                position.y = position.y < 0 ? -position.y : 2 * bounds.height - position.y
                impact = max(impact, abs(velocity.dy))
                squash.dy = (velocity.dy < 0 ? -1 : 1) * min(abs(velocity.dy) / 2600, 0.22)
                velocity.dy = -velocity.dy * e
            }
            if haptics && impact > 700 { Haptics.tap(.soft) }
        }
        position.x = position.x.clamped(to: 0...max(bounds.width, 0))
        position.y = position.y.clamped(to: 0...max(bounds.height, 0))

        let speed = (velocity.dx * velocity.dx + velocity.dy * velocity.dy).squareRoot()
        if speed > 60 && !isHeld {
            trail.append(position)
            if trail.count > 10 { trail.removeFirst(trail.count - 10) }
        } else if !trail.isEmpty {
            trail.removeFirst()
        }
        return FlingFrame(position: position, squash: squash, trail: trail)
    }
}

private struct FlingDemo: View {
    let ctx: DemoContext
    @State private var model = FlingModel(position: CGPoint(x: 113, y: 113))
    @State private var grabOffset: CGSize?
    @State private var isDragging = false
    /// The timeline only runs while something moves; a watcher task puts it to sleep once settled.
    @State private var awake = true
    @State private var sleepWatcher: Task<Void, Never>?

    private let arena: CGFloat = 290

    var body: some View {
        let puck = ctx.cg("size")
        let bounds = CGSize(width: arena - puck, height: arena - puck)
        let glide = ctx["glide"]
        let restitution = ctx["bounce"]
        let haptics = !ctx.isPreview

        VStack(spacing: 14) {
            ZStack(alignment: .topLeading) {
                ArenaBackground()
                TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview), paused: !awake)) { timeline in
                    let snapshot = model.step(to: timeline.date, bounds: bounds, glide: glide, restitution: restitution, haptics: haptics)
                    FlingLayer(snapshot: snapshot, puck: puck, isDragging: isDragging)
                }
                .allowsHitTesting(false)
            }
            .frame(width: arena, height: arena)
            .contentShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .gesture(dragGesture(puck: puck, bounds: bounds))
            DemoHint(text: L("Flick the puck — catch it mid-flight", "甩动圆球，飞行中也能接住"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // In the detail stage the shell's arrival intro fires this once, showing the affordance.
        .autoplay(ctx.isPreview, every: 2.6, delay: 0.3) { randomFling(speed: Double.random(in: 1500...2600)) }
        .onAppear { wake() }
        .onDisappear { sleepWatcher?.cancel() }
    }

    private func wake() {
        if !awake { awake = true }
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

    private func dragGesture(puck: CGFloat, bounds: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if grabOffset == nil {
                    // Hit-test against the live, on-screen position so a moving puck can be caught.
                    let live = model.position
                    let dx = value.startLocation.x - (live.x + puck / 2)
                    let dy = value.startLocation.y - (live.y + puck / 2)
                    guard (dx * dx + dy * dy).squareRoot() <= puck / 2 + 26 else { return }
                    let wasMoving = !model.isResting
                    grabOffset = CGSize(width: value.startLocation.x - live.x, height: value.startLocation.y - live.y)
                    model.isHeld = true
                    model.velocity = .zero
                    wake()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { isDragging = true }
                    if !ctx.isPreview { Haptics.tap(wasMoving ? .medium : .light) }
                }
                guard let grab = grabOffset else { return }
                model.position = CGPoint(
                    x: (value.location.x - grab.width).clamped(to: 0...bounds.width),
                    y: (value.location.y - grab.height).clamped(to: 0...bounds.height)
                )
            }
            .onEnded { value in
                guard grabOffset != nil else { return }
                grabOffset = nil
                release(velocity: value.velocity)
            }
    }

    private func release(velocity: CGSize) {
        model.velocity = CGVector(
            dx: velocity.width.clamped(to: -4200...4200),
            dy: velocity.height.clamped(to: -4200...4200)
        )
        model.isHeld = false
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isDragging = false }
        wake()
    }

    private func randomFling(speed: Double) {
        guard !model.isHeld else { return }
        let angle = Double.random(in: 0..<(2 * Double.pi))
        model.velocity = CGVector(dx: CGFloat(cos(angle) * speed), dy: CGFloat(sin(angle) * speed))
        wake()
    }
}

private struct FlingLayer: View {
    let snapshot: FlingFrame
    let puck: CGFloat
    let isDragging: Bool

    var body: some View {
        let sx = abs(snapshot.squash.dx)
        let sy = abs(snapshot.squash.dy)
        // Anchor the squash on the wall-contact side so the puck flattens against the wall.
        let anchor = UnitPoint(
            x: snapshot.squash.dx < 0 ? 0 : (snapshot.squash.dx > 0 ? 1 : 0.5),
            y: snapshot.squash.dy < 0 ? 0 : (snapshot.squash.dy > 0 ? 1 : 0.5)
        )
        ZStack(alignment: .topLeading) {
            Canvas { context, _ in
                let count = snapshot.trail.count
                for (index, point) in snapshot.trail.enumerated() {
                    let t = CGFloat(index + 1) / CGFloat(max(count, 1))
                    let r = puck / 2 * (0.35 + 0.5 * t)
                    let rect = CGRect(x: point.x + puck / 2 - r, y: point.y + puck / 2 - r, width: r * 2, height: r * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(Palette.sky.opacity(Double(0.22 * t))))
                }
            }
            PuckView(isDragging: isDragging)
                .frame(width: puck, height: puck)
                .scaleEffect(x: 1 - sx + sy * 0.5, y: 1 - sy + sx * 0.5, anchor: anchor)
                .offset(x: snapshot.position.x, y: snapshot.position.y)
        }
    }
}

private struct ArenaBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 34, style: .continuous)
            .fill(Palette.elevated)
            .overlay {
                Canvas { context, size in
                    let spacing: CGFloat = 22
                    var y = spacing / 2
                    while y < size.height {
                        var x = spacing / 2
                        while x < size.width {
                            context.fill(Path(ellipseIn: CGRect(x: x - 1, y: y - 1, width: 2, height: 2)), with: .color(.primary.opacity(0.12)))
                            x += spacing
                        }
                        y += spacing
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            }
            .overlay(RoundedRectangle(cornerRadius: 34, style: .continuous).strokeBorder(Palette.stroke, lineWidth: 1))
            .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
    }
}

private struct PuckView: View {
    let isDragging: Bool

    var body: some View {
        Circle()
            .fill(LinearGradient(colors: [Palette.mint, Palette.sky], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                Circle()
                    .fill(LinearGradient(colors: [.white.opacity(0.55), .clear], startPoint: .top, endPoint: .center))
                    .padding(5)
            }
            .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 1))
            .shadow(color: Palette.sky.opacity(isDragging ? 0.55 : 0.35), radius: isDragging ? 18 : 10, y: isDragging ? 10 : 5)
            .scaleEffect(isDragging ? 1.08 : 1)
    }
}
