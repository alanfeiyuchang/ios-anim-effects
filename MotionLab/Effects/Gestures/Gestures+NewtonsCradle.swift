import SwiftUI

extension Effect {
    static let gesturesNewtonsCradle = Effect(
        id: "gestures.newtons-cradle",
        category: .gestures,
        interaction: .gesture,
        name: L("Newton's Cradle", "牛顿摆"),
        summary: L("Pull back a chrome ball and release: momentum clicks through the row and out the other side.", "拉起一颗铬球再松手，动量咔嗒穿过整排，从另一端弹出。"),
        prompt: L(
            "Five 36 pt chrome balls (radial highlight from white through silver to graphite) hang from a slim bar on 140 pt strings, each with a soft floor shadow that shrinks as the ball rises. Every ball is a real pendulum (g ≈ 2,000 pt/s², period about 1.7 s, light air drag) integrated at 240 Hz; dragging one swings it along its string arc up to ±52°, and releasing hands over the finger's tangential speed. Contacts resolve as near-elastic collisions (restitution 0.97) in alternating passes, so momentum crosses the resting balls within milliseconds and the far ball flies out while the middle ones barely move; two pulled balls send two out. Each hard contact ticks a rigid haptic, and the energy slowly bleeds away until the row hangs still. Precise and hypnotic.",
            "五颗 36 pt 的铬球（由白色高光经银色过渡到石墨色的径向渐变）以 140 pt 细绳并排挂在横梁下，地面各有一团柔和阴影，球升得越高影子越小。每颗球都是真实的单摆（g ≈ 2000 pt/s²，周期约 1.7 秒，轻微空气阻力），以 240 Hz 积分；拖动任一颗会让它沿绳弧摆起，最大 ±52°，松手时继承手指的切向速度。碰撞按近乎完全弹性（恢复系数 0.97）交替求解，动量几毫秒内穿过静止的球，最远端的球飞出、中间几乎不动；拉起两颗就弹出两颗。每次强碰撞一下清脆触感，能量缓缓耗散直到整排静止。精准，令人着迷。"
        ),
        implementation: L(
            "A reference-type model steps each pendulum with symplectic Euler at a fixed 1/240 s inside TimelineView, then resolves overlapping neighbors with restitution-weighted velocity exchange and positional correction; one Canvas draws bar, strings, shadows and chrome balls.",
            "引用类型模型在 TimelineView 中以固定 1/240 秒步长用辛欧拉法推进每个单摆，再对相互重叠的相邻球按恢复系数交换速度并修正位置；由一个 Canvas 绘制横梁、摆线、阴影与铬球。"
        ),
        apis: ["TimelineView(.animation)", "Canvas", "GraphicsContext.Shading.radialGradient", "DragGesture.Value.velocity", "Haptics"],
        tags: ["newton's cradle", "pendulum", "collision", "momentum", "physics", "牛顿摆", "单摆", "碰撞", "动量", "物理"],
        params: [
            .slider("balls", L("Balls", "球数"), 3...7, default: 5, step: 1, decimals: 0),
            .slider("restitution", L("Restitution", "恢复系数"), 0.8...1.0, default: 0.97),
            .slider("length", L("String length", "摆线长度"), 100...160, default: 140, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        NewtonsCradleDemo(ctx: ctx)
    }
}

private enum CradleMetrics {
    static let stage = CGSize(width: 300, height: 290)
    static let pivotY: CGFloat = 40
    static let diameter: CGFloat = 36
    static let spacing: CGFloat = 36.6
    static let maxAngle: Double = 0.9
    static let gravity: Double = 2000

    static func pivotX(_ index: Int, count: Int) -> CGFloat {
        stage.width / 2 + (CGFloat(index) - CGFloat(count - 1) / 2) * spacing
    }
}

private final class CradleModel {
    private(set) var theta: [Double] = []
    private var omega: [Double] = []
    var held: Int?
    var heldTarget: Double = 0
    private var scriptRelease: Date?
    private var pendingLift: (index: Int, angle: Double)?
    private var accumulator: Double = 0
    private var lastDate: Date?
    private var lastHaptic: Date = .distantPast
    private let h: Double = 1.0 / 240.0

    /// Hanging still with nothing scripted or held, so the timeline can pause.
    var isSettled: Bool {
        held == nil && pendingLift == nil && scriptRelease == nil
            && omega.allSatisfy { abs($0) < 0.02 } && theta.allSatisfy { abs($0) < 0.003 }
    }

    func configure(count: Int) {
        guard theta.count != count else { return }
        theta = Array(repeating: 0, count: count)
        omega = Array(repeating: 0, count: count)
        held = nil
    }

    /// Scripted pull-and-release, used by previews and the intro.
    func lift(index: Int, angle: Double) {
        pendingLift = (index: index, angle: angle)
    }

    func grab(_ index: Int, angle: Double) {
        guard theta.indices.contains(index) else { return }
        scriptRelease = nil
        held = index
        heldTarget = angle.clamped(to: -CradleMetrics.maxAngle...CradleMetrics.maxAngle)
    }

    func release(tangentialSpeed: Double, length: Double) {
        guard let index = held, omega.indices.contains(index) else { return }
        held = nil
        omega[index] = (tangentialSpeed / max(length, 1)).clamped(to: -9...9)
    }

    func step(to date: Date, length: Double, restitution: Double, haptics: Bool) {
        if let lift = pendingLift, theta.indices.contains(lift.index) {
            pendingLift = nil
            held = lift.index
            heldTarget = lift.angle
            scriptRelease = date.addingTimeInterval(0.55)
        }
        if let release = scriptRelease, date >= release {
            scriptRelease = nil
            if let index = held, omega.indices.contains(index) { omega[index] = 0 }
            held = nil
        }
        let raw = lastDate.map { date.timeIntervalSince($0) } ?? 0
        lastDate = date
        accumulator = min(accumulator + max(raw, 0), 0.08)
        var impact: Double = 0
        var steps = 0
        while accumulator >= h && steps < 24 {
            impact = max(impact, integrate(length: max(length, 1), restitution: restitution))
            accumulator -= h
            steps += 1
        }
        if haptics && impact > 260 && date.timeIntervalSince(lastHaptic) > 0.07 {
            lastHaptic = date
            // Never fire side effects while SwiftUI is evaluating the view: defer to the next main-loop turn.
            DispatchQueue.main.async { Haptics.tap(.rigid) }
        }
    }

    private func integrate(length: Double, restitution: Double) -> Double {
        let count = theta.count
        let k = CradleMetrics.gravity / length
        for index in 0..<count {
            if index == held {
                theta[index] += (heldTarget - theta[index]) * 0.25
                omega[index] = 0
                continue
            }
            let alpha = -k * sin(theta[index]) - 0.12 * omega[index]
            omega[index] += alpha * h
            theta[index] += omega[index] * h
        }
        var impact: Double = 0
        for pass in 0..<3 {
            let forward = pass % 2 == 0
            for step in 0..<max(count - 1, 0) {
                let i = forward ? step : count - 2 - step
                impact = max(impact, resolve(i, i + 1, length: length, restitution: restitution))
            }
        }
        return impact
    }

    /// Resolves contact between neighbors i (left) and j (right); returns the closing speed.
    private func resolve(_ i: Int, _ j: Int, length: Double, restitution e: Double) -> Double {
        let d = Double(CradleMetrics.diameter)
        let spacing = Double(CradleMetrics.spacing)
        let gap = spacing + length * (sin(theta[j]) - sin(theta[i])) - d
        guard gap < 0 else { return 0 }
        let ci = max(cos(theta[i]), 0.2)
        let cj = max(cos(theta[j]), 0.2)
        let vi = length * omega[i] * ci
        let vj = length * omega[j] * cj
        var closing: Double = 0
        if vi > vj {
            closing = vi - vj
            var ni = vi
            var nj = vj
            if held == i {
                nj = vi * (1 + e) - e * vj
            } else if held == j {
                ni = vj * (1 + e) - e * vi
            } else {
                ni = (1 - e) / 2 * vi + (1 + e) / 2 * vj
                nj = (1 + e) / 2 * vi + (1 - e) / 2 * vj
            }
            omega[i] = ni / (length * ci)
            omega[j] = nj / (length * cj)
        }
        let overlap = -gap
        if held == i {
            theta[j] += overlap / (length * cj)
        } else if held == j {
            theta[i] -= overlap / (length * ci)
        } else {
            theta[i] -= overlap / 2 / (length * ci)
            theta[j] += overlap / 2 / (length * cj)
        }
        return closing
    }
}

private struct NewtonsCradleDemo: View {
    let ctx: DemoContext
    @State private var model = CradleModel()
    @State private var grabbed: Int?
    @State private var awake = true
    /// Click haptics start only once the user has handled a ball (never for the intro swing).
    @State private var userTouched = false
    @State private var sleepWatcher: Task<Void, Never>?

    var body: some View {
        let count = ctx.int("balls").clamped(to: 3...7)
        let length = ctx["length"]
        let restitution = ctx["restitution"]
        let haptics = !ctx.isPreview && userTouched
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview), paused: !awake)) { timeline in
            let _ = model.configure(count: count)
            let _ = model.step(to: timeline.date, length: length, restitution: restitution, haptics: haptics)
            CradleCanvas(theta: model.theta, length: CGFloat(length))
        }
        .frame(width: CradleMetrics.stage.width, height: CradleMetrics.stage.height)
        .contentShape(Rectangle())
        .gesture(dragGesture(count: count, length: length))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Pull an end ball aside and let go", "把一端的球拉开再松手"), ctx: ctx)
                .padding(.bottom, 10)
        }
        // In the detail stage the shell's arrival intro fires this once.
        .autoplay(ctx.isPreview, every: 3.4, delay: 0.3) {
            wake()
            let index = Bool.random() ? 0 : count - 1
            model.lift(index: index, angle: index == 0 ? -0.75 : 0.75)
        }
        .onAppear { wake() }
        .onDisappear { sleepWatcher?.cancel() }
        .onChange(of: count) { wake() }
    }

    /// Runs the timeline while anything swings; a watcher pauses it once the row hangs still.
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

    private func dragGesture(count: Int, length: Double) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if grabbed == nil {
                    guard let index = ballIndex(at: value.startLocation, count: count, length: length) else { return }
                    grabbed = index
                    userTouched = true
                    wake()
                    if !ctx.isPreview { Haptics.tap(.light) }
                }
                guard let index = grabbed else { return }
                let px = CradleMetrics.pivotX(index, count: count)
                let angle = atan2(Double(value.location.x - px), Double(max(value.location.y - CradleMetrics.pivotY, 1)))
                model.grab(index, angle: angle)
            }
            .onEnded { value in
                guard grabbed != nil else { return }
                grabbed = nil
                let angle = model.held.map { model.theta.indices.contains($0) ? model.theta[$0] : 0 } ?? 0
                // Tangent of the string arc at the current angle.
                let tangential = Double(value.velocity.width) * cos(angle) - Double(value.velocity.height) * sin(angle)
                model.release(tangentialSpeed: tangential, length: length)
            }
    }

    private func ballIndex(at point: CGPoint, count: Int, length: Double) -> Int? {
        var best: Int?
        var bestDistance = CGFloat.greatestFiniteMagnitude
        for index in 0..<min(count, model.theta.count) {
            let angle = model.theta[index]
            let cx = CradleMetrics.pivotX(index, count: count) + CGFloat(length * sin(angle))
            let cy = CradleMetrics.pivotY + CGFloat(length * cos(angle))
            let d = ((point.x - cx) * (point.x - cx) + (point.y - cy) * (point.y - cy)).squareRoot()
            if d < bestDistance {
                bestDistance = d
                best = index
            }
        }
        return bestDistance < CradleMetrics.diameter / 2 + 18 ? best : nil
    }
}

private struct CradleCanvas: View {
    let theta: [Double]
    let length: CGFloat

    var body: some View {
        Canvas { context, _ in
            let count = theta.count
            guard count > 0 else { return }
            let r = CradleMetrics.diameter / 2
            let left = CradleMetrics.pivotX(0, count: count) - 34
            let right = CradleMetrics.pivotX(count - 1, count: count) + 34
            let floorY = CradleMetrics.pivotY + length + r + 16

            let bar = CGRect(x: left, y: CradleMetrics.pivotY - 8, width: right - left, height: 8)
            context.fill(
                Path(roundedRect: bar, cornerRadius: 4, style: .continuous),
                with: .linearGradient(
                    Gradient(colors: [Color(white: 0.85), Color(white: 0.5)]),
                    startPoint: CGPoint(x: 0, y: bar.minY),
                    endPoint: CGPoint(x: 0, y: bar.maxY)
                )
            )

            var strings = Path()
            var centers: [CGPoint] = []
            for index in 0..<count {
                let pivot = CGPoint(x: CradleMetrics.pivotX(index, count: count), y: CradleMetrics.pivotY)
                let center = CGPoint(x: pivot.x + length * CGFloat(sin(theta[index])), y: pivot.y + length * CGFloat(cos(theta[index])))
                strings.move(to: pivot)
                strings.addLine(to: center)
                centers.append(center)

                let lift = min(max((floorY - r - 16 - center.y) / 80, 0), 1)
                let w = 34 * (1 - 0.45 * lift)
                context.fill(
                    Path(ellipseIn: CGRect(x: center.x - w / 2, y: floorY - 3, width: w, height: 6)),
                    with: .color(.black.opacity(0.16 * Double(1 - 0.7 * lift)))
                )
            }
            context.stroke(strings, with: .color(.primary.opacity(0.35)), lineWidth: 1)

            for center in centers {
                let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
                let chrome = Gradient(stops: [
                    .init(color: .white, location: 0),
                    .init(color: Color(white: 0.86), location: 0.25),
                    .init(color: Color(white: 0.52), location: 0.7),
                    .init(color: Color(white: 0.26), location: 1),
                ])
                context.fill(
                    Path(ellipseIn: rect),
                    with: .radialGradient(chrome, center: CGPoint(x: center.x - r * 0.35, y: center.y - r * 0.4), startRadius: 0, endRadius: r * 1.5)
                )
                context.stroke(Path(ellipseIn: rect.insetBy(dx: 0.5, dy: 0.5)), with: .color(.black.opacity(0.18)), lineWidth: 1)
            }
        }
    }
}
