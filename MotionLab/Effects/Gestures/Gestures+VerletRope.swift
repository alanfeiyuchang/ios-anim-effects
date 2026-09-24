import SwiftUI

extension Effect {
    static let gesturesVerletRope = Effect(
        id: "gestures.verlet-rope",
        category: .gestures,
        interaction: .gesture,
        name: L("Pendant Rope", "吊坠绳索"),
        summary: L("A charm on a physically simulated rope: grab it, swing it, throw it and watch the cord whip.", "挂在物理绳索上的吊坠：抓起、摇晃、甩出，看绳子如鞭般甩动。"),
        prompt: L(
            "A 52 pt charm (sunset gradient, white star, soft coloured shadow) hangs from a small pin by a 190 pt cord made of 14 Verlet links under about 1,500 pt/s² gravity with light air drag, its constraints solved 10 times per 1/120 s step. The charm weighs about three links, so the cord stays taut under it and the charm always rotates to follow the last link. Grabbing the charm pins it to the finger, never beyond the cord's reach, while the cord drapes and curls behind it; letting go hands over the release velocity, so a flick sends it swinging in wide arcs as a wave travels down the cord and it whips around the pin. Lower stiffness turns the cord into an elastic bungee. Tactile, playful and physically honest.",
            "一枚52 pt的吊坠（日落渐变、白色星形、柔和同色投影）挂在小钉上，绳长约190 pt，由14节Verlet链段组成，受约1500 pt/s²的重力和轻微空气阻力，每个1/120秒步长求解10次约束。吊坠约重三节绳子，绳子被它拉得笔直，吊坠也始终顺着最后一节旋转。抓住吊坠它就固定在指尖（不会超出绳长），绳子在身后自然垂坠、卷曲；松手时继承离手速度，轻轻一甩就大幅摆荡，一道波沿绳传下，绳子绕着钉子鞭梢般甩动。降低刚度，绳子就变成有弹性的蹦极绳。俏皮而真实。"
        ),
        implementation: L(
            "A reference-type Verlet integrator runs fixed 1/120 s steps inside TimelineView with iterative distance constraints and a lighter inverse mass for the charm; a Canvas strokes the cord through midpoint curves and the charm view is positioned and rotated from the last link.",
            "引用类型的 Verlet 积分器在 TimelineView 中以固定 1/120 秒步长运行，迭代求解距离约束，并为吊坠设置较小的逆质量；Canvas 通过中点曲线描绘绳子，吊坠视图依据最后一节的位置与方向摆放、旋转。"
        ),
        apis: ["TimelineView(.animation)", "Canvas", "DragGesture.Value.velocity", "Verlet integration", "rotationEffect"],
        tags: ["rope", "verlet", "physics", "pendulum", "swing", "cord", "绳索", "物理", "摆动", "吊坠", "甩动"],
        params: [
            .slider("length", L("Cord length", "绳长"), 120...230, default: 190, decimals: 0, unit: "pt"),
            .slider("gravity", L("Gravity", "重力"), 500...2600, default: 1500, step: 50, decimals: 0, unit: "pt/s²"),
            .slider("stiffness", L("Stiffness", "刚度"), 1...16, default: 10, step: 1, decimals: 0),
        ]
    ) { ctx in
        VerletRopeDemo(ctx: ctx)
    }
}

private enum RopeMetrics {
    static let stage = CGSize(width: 300, height: 320)
    static let anchor = CGPoint(x: 150, y: 26)
    static let links = 14
    static let charm: CGFloat = 52
}

private final class RopeModel {
    private(set) var points: [CGPoint]
    private var previous: [CGPoint]
    /// Where the charm is pinned while held.
    var grab: CGPoint?
    private var accumulator: Double = 0
    private var lastDate: Date?
    private let h: Double = 1.0 / 120.0

    init() {
        let anchor = RopeMetrics.anchor
        let initial = (0...RopeMetrics.links).map { index in
            CGPoint(x: anchor.x + CGFloat(index) * 4, y: anchor.y + CGFloat(index) * 12)
        }
        points = initial
        previous = initial
    }

    var end: CGPoint { points.last ?? RopeMetrics.anchor }

    /// Hanging still (sub-pixel motion per step) and not held, so the timeline can pause.
    var isSettled: Bool {
        grab == nil && zip(points, previous).allSatisfy { abs($0.x - $1.x) < 0.025 && abs($0.y - $1.y) < 0.025 }
    }

    var endDirection: CGVector {
        guard points.count > 1 else { return CGVector(dx: 0, dy: 1) }
        let a = points[points.count - 2]
        let b = points[points.count - 1]
        let dx = b.x - a.x
        let dy = b.y - a.y
        let d = max((dx * dx + dy * dy).squareRoot(), 0.0001)
        return CGVector(dx: dx / d, dy: dy / d)
    }

    func step(to date: Date, length: CGFloat, gravity: Double, iterations: Int) {
        let raw = lastDate.map { date.timeIntervalSince($0) } ?? 0
        lastDate = date
        accumulator = min(accumulator + max(raw, 0), 0.1)
        let link = length / CGFloat(RopeMetrics.links)
        var steps = 0
        while accumulator >= h && steps < 14 {
            integrate(link: link, gravity: gravity, iterations: max(iterations, 1))
            accumulator -= h
            steps += 1
        }
    }

    func release(velocity: CGSize) {
        grab = nil
        guard let last = points.indices.last else { return }
        let vx = velocity.width.clamped(to: -3200...3200)
        let vy = velocity.height.clamped(to: -3200...3200)
        previous[last] = CGPoint(x: points[last].x - vx * CGFloat(h), y: points[last].y - vy * CGFloat(h))
    }

    /// Adds velocity (pt/s) to the charm.
    func kick(_ velocity: CGSize) {
        guard grab == nil, let last = points.indices.last else { return }
        previous[last].x -= velocity.width * CGFloat(h)
        previous[last].y -= velocity.height * CGFloat(h)
    }

    private func integrate(link: CGFloat, gravity: Double, iterations: Int) {
        let last = points.count - 1
        guard last >= 1 else { return }
        let g = CGFloat(gravity * h * h)
        for index in 1...last {
            let p = points[index]
            let vx = (p.x - previous[index].x) * 0.997
            let vy = (p.y - previous[index].y) * 0.997
            previous[index] = p
            points[index] = CGPoint(x: p.x + vx, y: p.y + vy + g)
        }
        points[0] = RopeMetrics.anchor
        if let grab {
            points[last] = RopeModel.reachable(grab, reach: link * CGFloat(last))
        }
        for _ in 0..<iterations {
            for index in 0..<last {
                let a = points[index]
                let b = points[index + 1]
                let dx = b.x - a.x
                let dy = b.y - a.y
                let d = max((dx * dx + dy * dy).squareRoot(), 0.0001)
                let diff = (d - link) / d
                let wa: CGFloat = index == 0 ? 0 : 1
                let wb: CGFloat = index + 1 == last ? (grab == nil ? 0.35 : 0) : 1
                let total = wa + wb
                guard total > 0 else { continue }
                points[index].x += dx * diff * wa / total
                points[index].y += dy * diff * wa / total
                points[index + 1].x -= dx * diff * wb / total
                points[index + 1].y -= dy * diff * wb / total
            }
        }
    }

    private static func reachable(_ point: CGPoint, reach: CGFloat) -> CGPoint {
        let anchor = RopeMetrics.anchor
        let dx = point.x - anchor.x
        let dy = point.y - anchor.y
        let d = (dx * dx + dy * dy).squareRoot()
        guard d > reach, d > 0 else { return point }
        return CGPoint(x: anchor.x + dx / d * reach, y: anchor.y + dy / d * reach)
    }
}

private struct VerletRopeDemo: View {
    let ctx: DemoContext
    @State private var model = RopeModel()
    @State private var grabOffset: CGSize?
    @State private var isHeld = false
    @State private var awake = true
    @State private var sleepWatcher: Task<Void, Never>?
    /// Resets on system cancellation too, so a stolen touch never leaves the charm pinned to a ghost finger.
    @GestureState private var pressing = false

    /// Stage coordinates for the drag (the model's own space).
    private static let space = "ropeStage"

    var body: some View {
        let length = ctx.cg("length")
        let gravity = ctx["gravity"]
        let iterations = ctx.int("stiffness")
        ZStack {
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview), paused: !awake)) { timeline in
                let _ = model.step(to: timeline.date, length: length, gravity: gravity, iterations: iterations)
                // Only a disc around the live charm takes touches, so swipes elsewhere still scroll the page.
                RopeLayer(points: model.points, direction: model.endDirection, isHeld: isHeld)
                    .contentShape(RopeHitArea(center: charmCenter, radius: RopeMetrics.charm / 2 + 24))
                    .gesture(dragGesture)
            }
        }
        .frame(width: RopeMetrics.stage.width, height: RopeMetrics.stage.height)
        .coordinateSpace(.named(VerletRopeDemo.space))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Grab the charm and fling it", "抓住吊坠甩出去"), ctx: ctx)
                .padding(.bottom, 10)
        }
        // In the detail stage the shell's arrival intro fires this once.
        .autoplay(ctx.isPreview, every: 1.8, delay: 0.2) {
            wake()
            model.kick(CGSize(width: (Bool.random() ? 1 : -1) * CGFloat.random(in: 900...1500), height: -CGFloat.random(in: 0...300)))
        }
        .onAppear { wake() }
        .onDisappear { sleepWatcher?.cancel() }
        .onChange(of: length) { wake() }
        .onChange(of: gravity) { wake() }
        .onChange(of: iterations) { wake() }
        .onChange(of: pressing) { _, isPressing in
            // System cancellation (no onEnded): let go with no fling.
            if !isPressing { letGo(velocity: .zero, completed: false) }
        }
    }

    /// Runs the timeline while the cord moves; a watcher pauses it once it hangs still.
    private func wake() {
        if !awake { awake = true }
        sleepWatcher?.cancel()
        sleepWatcher = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(0.4))
                if model.isSettled {
                    awake = false
                    return
                }
            }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(VerletRopeDemo.space))
            .updating($pressing) { _, state, _ in state = true }
            .onChanged { value in
                if grabOffset == nil {
                    let center = charmCenter
                    let dx = value.startLocation.x - center.x
                    let dy = value.startLocation.y - center.y
                    // A little wider than the hit disc: the charm may have swung on since it was drawn.
                    guard (dx * dx + dy * dy).squareRoot() < RopeMetrics.charm / 2 + 40 else { return }
                    // Remember where on the charm the finger landed, relative to the cord's end point.
                    grabOffset = CGSize(width: value.startLocation.x - model.end.x, height: value.startLocation.y - model.end.y)
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { isHeld = true }
                    wake()
                    if !ctx.isPreview { Haptics.tap(.light) }
                }
                guard let offset = grabOffset else { return }
                model.grab = CGPoint(x: value.location.x - offset.width, y: value.location.y - offset.height)
            }
            .onEnded { value in letGo(velocity: value.velocity, completed: true) }
    }

    /// Single, guarded release (lift hands over the finger's velocity and taps; cancellation passes
    /// zero and stays silent).
    private func letGo(velocity: CGSize, completed: Bool) {
        guard grabOffset != nil else { return }
        grabOffset = nil
        model.release(velocity: velocity)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isHeld = false }
        if completed && !ctx.isPreview { Haptics.tap(.soft) }
    }

    private var charmCenter: CGPoint {
        let end = model.end
        let dir = model.endDirection
        return CGPoint(x: end.x + dir.dx * RopeMetrics.charm / 2, y: end.y + dir.dy * RopeMetrics.charm / 2)
    }
}

/// The touch target: a disc around the charm (finger-sized margin included).
private struct RopeHitArea: Shape {
    let center: CGPoint
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    }
}

private struct RopeLayer: View {
    let points: [CGPoint]
    let direction: CGVector
    let isHeld: Bool

    var body: some View {
        let end = points.last ?? RopeMetrics.anchor
        let center = CGPoint(x: end.x + direction.dx * RopeMetrics.charm / 2, y: end.y + direction.dy * RopeMetrics.charm / 2)
        let angle = atan2(Double(direction.dy), Double(direction.dx)) - Double.pi / 2
        ZStack {
            Canvas { context, _ in
                let cord = RopeLayer.smooth(points)
                var shadow = context
                shadow.translateBy(x: 0, y: 3)
                shadow.stroke(cord, with: .color(.black.opacity(0.12)), style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
                context.stroke(cord, with: .color(.primary.opacity(0.7)), style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                let pin = RopeMetrics.anchor
                context.fill(Path(ellipseIn: CGRect(x: pin.x - 7, y: pin.y - 7, width: 14, height: 14)), with: .color(Palette.elevated))
                context.stroke(Path(ellipseIn: CGRect(x: pin.x - 7, y: pin.y - 7, width: 14, height: 14)), with: .color(.primary.opacity(0.35)), lineWidth: 1.5)
                context.fill(Path(ellipseIn: CGRect(x: pin.x - 2.5, y: pin.y - 2.5, width: 5, height: 5)), with: .color(.primary.opacity(0.6)))
            }
            Charm(isHeld: isHeld)
                .rotationEffect(.radians(angle))
                .position(center)
        }
    }

    private static func smooth(_ points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        guard points.count > 2 else {
            if let last = points.last { path.addLine(to: last) }
            return path
        }
        for index in 1..<(points.count - 1) {
            let current = points[index]
            let next = points[index + 1]
            path.addQuadCurve(to: CGPoint(x: (current.x + next.x) / 2, y: (current.y + next.y) / 2), control: current)
        }
        if let last = points.last { path.addLine(to: last) }
        return path
    }
}

private struct Charm: View {
    let isHeld: Bool

    var body: some View {
        Circle()
            .fill(Palette.sunset)
            .overlay {
                Circle()
                    .fill(LinearGradient(colors: [.white.opacity(0.5), .clear], startPoint: .top, endPoint: .center))
                    .padding(4)
            }
            .overlay {
                Image(systemName: "star.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }
            .overlay(Circle().strokeBorder(.white.opacity(0.4), lineWidth: 1))
            .frame(width: RopeMetrics.charm, height: RopeMetrics.charm)
            .shadow(color: Palette.coral.opacity(isHeld ? 0.5 : 0.32), radius: isHeld ? 18 : 10, y: isHeld ? 10 : 6)
            .scaleEffect(isHeld ? 1.08 : 1)
    }
}
