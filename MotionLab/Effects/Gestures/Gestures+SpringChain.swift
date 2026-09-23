import SwiftUI

extension Effect {
    static let gesturesSpringChain = Effect(
        id: "gestures.spring-chain",
        category: .gestures,
        interaction: .gesture,
        name: L("Spring Chain Trail", "弹簧链尾迹"),
        summary: L("A comet of dots chasing your finger, each on a slightly lazier spring.", "一串圆点追随手指，每颗的弹簧都比前一颗更慵懒。"),
        prompt: L(
            "A chain of 10 glowing dots, shrinking from 52 pt at the head to 16 pt at the tail and shifting hue from mint to violet while fading from 100% to 35% opacity, is linked by a faint gradient thread. Touching or dragging anywhere on the stage sets the head's target; the head springs toward the finger and every following dot springs toward the dot in front of it (link response ≈ 0.12 s, damping 0.7), integrated per frame, so motion propagates down the chain like a whip: it stretches along fast strokes, curls through turns and coils back into a bead when the finger stops. The head sits on top and soft colored shadows add depth. Organic, like a school of fish following a lure.",
            "十颗发光圆点由一根淡淡的渐变细线串起：从头部 52pt 递减到尾部 16pt，色相由薄荷绿渐变为紫色，透明度从 100% 递减到 35%。在舞台任意位置按下或拖动都会设置头部的目标；头部以弹簧追向手指，其后每一颗圆点都以弹簧追向它前面那一颗（链节响应约 0.12 秒、阻尼 0.7），逐帧积分，运动像鞭子一样沿链条传递：快速划动时整串被拉长，转弯时卷曲，手指停下后又盘回一颗珠子。头部始终置顶，柔和的同色投影增加层次。有机灵动，像鱼群追逐诱饵。"
        ),
        implementation: L(
            "A reference-type model steps a spring per dot inside TimelineView (4 semi-implicit Euler substeps): the head's goal is the finger, each other dot's goal is its predecessor. The timeline pauses ~2 s after the chain settles.",
            "引用类型模型在 TimelineView 中逐帧为每颗圆点推进一个弹簧（每帧 4 次半隐式欧拉子步）：头部目标是手指，其余每颗的目标是前一颗圆点。链条静止约 2 秒后时间线暂停。"
        ),
        apis: ["TimelineView", "DragGesture", "Canvas", "spring integrator", "zIndex"],
        tags: ["trail", "follow", "chain", "cursor", "spring", "whip", "尾迹", "跟随", "弹簧链", "拖尾"],
        params: [
            .slider("count", L("Dots", "圆点数量"), 4...16, default: 10, step: 1, decimals: 0),
            .slider("link", L("Link response", "链节响应"), 0.06...0.25, default: 0.12, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.4...1.0, default: 0.7),
        ]
    ) { ctx in
        GestureSpringChainDemo(ctx: ctx)
    }
}

/// Per-frame spring chain: dot 0 chases the target, dot i chases dot i − 1.
private final class ChainModel {
    private(set) var positions: [CGPoint] = []
    private var velocities: [CGVector] = []
    private var lastDate: Date?

    func step(to date: Date, count: Int, target: CGPoint, response: Double, damping: Double) {
        if positions.count != count {
            let seed = positions.last ?? target
            while positions.count < count {
                positions.append(seed)
                velocities.append(.zero)
            }
            positions = Array(positions.prefix(count))
            velocities = Array(velocities.prefix(count))
        }
        let raw = lastDate.map { date.timeIntervalSince($0) } ?? 0
        lastDate = date
        let dt = CGFloat(min(max(raw, 0), 1.0 / 30.0))
        guard dt > 0 else { return }
        // The head is a touch snappier than the links so it stays glued to the finger.
        let substeps = 4
        let h = dt / CGFloat(substeps)
        for _ in 0..<substeps {
            for index in positions.indices {
                let goal = index == 0 ? target : positions[index - 1]
                let r = index == 0 ? response * 0.8 : response
                let omega = CGFloat(2 * Double.pi / max(r, 0.03))
                let stiffness = omega * omega
                let friction = 2 * CGFloat(damping) * omega
                var v = velocities[index]
                v.dx += (stiffness * (goal.x - positions[index].x) - friction * v.dx) * h
                v.dy += (stiffness * (goal.y - positions[index].y) - friction * v.dy) * h
                velocities[index] = v
                positions[index].x += v.dx * h
                positions[index].y += v.dy * h
            }
        }
    }
}

private struct GestureSpringChainDemo: View {
    let ctx: DemoContext
    @State private var model = ChainModel()
    @State private var target: CGPoint?
    @State private var size: CGSize = CGSize(width: 340, height: 340)
    @State private var phase: Double = 0
    @State private var touched = false
    @State private var awake = true
    @State private var sleepToken = 0

    var body: some View {
        let count = max(ctx.int("count"), 2)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let goal = target ?? center
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview), paused: !awake)) { timeline in
            let _ = model.step(to: timeline.date, count: count, target: goal, response: ctx["link"], damping: ctx["damping"])
            ChainDots(positions: model.positions)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    touched = true
                    wake()
                    target = value.location
                }
                .onEnded { _ in scheduleSleep() }
        )
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Drag anywhere", "在任意位置拖动"), ctx: ctx)
                .padding(.bottom, 14)
                .allowsHitTesting(false)
        }
        .autoplay(ctx.isPreview || !touched, every: 0.42, delay: 0.2) { wander(center: center) }
    }

    /// Idle attractor: a figure-eight that fills most of the stage.
    private func wander(center: CGPoint) {
        // The arrival intro can fire once after the first touch; never yank the chain from the finger.
        guard ctx.isPreview || !touched else { return }
        wake()
        phase += 0.85
        target = CGPoint(
            x: center.x + CGFloat(cos(phase)) * size.width * 0.33,
            y: center.y + CGFloat(sin(phase * 2)) * size.height * 0.26
        )
    }

    private func wake() {
        sleepToken += 1
        if !awake { awake = true }
    }

    /// Pause the timeline once the chain has had time to coil up (~2 s after release).
    private func scheduleSleep() {
        sleepToken += 1
        let token = sleepToken
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.2))
            if token == sleepToken { awake = false }
        }
    }
}

private struct ChainDots: View {
    let positions: [CGPoint]

    var body: some View {
        let count = positions.count
        ZStack {
            Canvas { context, _ in
                guard count > 1 else { return }
                var thread = Path()
                thread.move(to: positions[0])
                for point in positions.dropFirst() { thread.addLine(to: point) }
                context.stroke(
                    thread,
                    with: .linearGradient(
                        Gradient(colors: [Color(hue: 0.46, saturation: 0.7, brightness: 0.95).opacity(0.5), Color(hue: 0.74, saturation: 0.7, brightness: 0.95).opacity(0.1)]),
                        startPoint: positions[0],
                        endPoint: positions[count - 1]
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
            }
            ForEach(Array(positions.enumerated()), id: \.offset) { index, point in
                ChainDot(index: index, count: count)
                    .position(point)
                    .zIndex(Double(count - index))
            }
        }
    }
}

private struct ChainDot: View {
    let index: Int
    let count: Int

    var body: some View {
        let t = Double(index) / Double(max(count - 1, 1))
        let size = 52 - 36 * t
        let color = Color(hue: 0.46 + 0.28 * t, saturation: 0.7, brightness: 0.95)
        Circle()
            .fill(color.gradient)
            .frame(width: size, height: size)
            .shadow(color: color.opacity(0.45), radius: 10 - 6 * t, y: 4)
            .opacity(1 - 0.65 * t)
    }
}
