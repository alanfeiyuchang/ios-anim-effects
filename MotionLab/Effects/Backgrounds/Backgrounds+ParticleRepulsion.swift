import SwiftUI

extension Effect {
    static let backgroundsParticleRepulsion = Effect(
        id: "backgrounds.particle-repulsion",
        category: .backgrounds,
        interaction: .gesture,
        name: L("Repelling Particles", "排斥粒子场"),
        summary: L(
            "A calm particle grid parts around your finger and springs back into place.",
            "平静的粒子网格在手指周围散开，又弹性回归原位。"
        ),
        prompt: L(
            "A dark midnight canvas holding a precise grid of ~500 tiny particles, each tethered to its home position by a slightly underdamped spring. Moving a finger across the field pushes particles radially away with a force that falls off quadratically toward the edge of an 80 pt influence radius, carving a clean moving void ringed by compressed particles. Displaced particles brighten and grow with their offset — resting dots are faint white, moderately displaced ones turn sky blue, strongly displaced ones glow pink — and a soft halo marks the touch point. On release, everything springs home with a small overshoot and settles in about a second. Responsive, physical and quietly delightful.",
            "午夜深色画布上整齐排列着约 500 个细小粒子，每个粒子都由一根略欠阻尼的弹簧拴在自己的原点。手指划过粒子场时，粒子被沿径向推开，推力在 80pt 影响半径内随距离呈二次方衰减，于是形成一块干净、随手移动的空洞，四周环绕被挤压的粒子。粒子越偏离原位就越亮、越大——静止时为淡白色，中度位移变为天蓝，大幅位移则发出粉色光芒——触点处还有一圈柔和光晕。松手后所有粒子带着轻微过冲弹回原位，约一秒内完全平静。灵敏、富有物理感，令人会心一笑。"
        ),
        implementation: L(
            "A reference-type model held in @State integrates spring + repulsion forces with semi-implicit Euler inside the Canvas renderer each TimelineView frame; particles are batched into three Paths by displacement.",
            "保存在 @State 中的引用类型模型，在每个 TimelineView 帧的 Canvas 渲染闭包里以半隐式欧拉法积分弹簧力与排斥力；粒子按位移分成三条 Path 批量绘制。"
        ),
        apis: ["Canvas", "TimelineView(.animation)", "DragGesture(minimumDistance: 0)", "@State reference model"],
        tags: ["particles", "repel", "physics", "interactive", "粒子", "排斥", "物理", "交互"],
        params: [
            .slider("radius", L("Influence radius", "影响半径"), 40...150, default: 80, decimals: 0, unit: "pt"),
            .slider("strength", L("Push strength", "推力"), 0.3...2.0, default: 1.0, unit: "×"),
            .slider("stiffness", L("Spring stiffness", "弹簧刚度"), 20...160, default: 70, decimals: 0),
        ]
    ) { ctx in
        ParticleRepulsionDemo(ctx: ctx)
    }
}

private final class SwarmModel {
    private var last: Double?
    private var size: CGSize = .zero
    private var home: [CGPoint] = []
    private var position: [CGPoint] = []
    private var velocity: [CGVector] = []
    var touch: CGPoint?
    private(set) var pointer: CGPoint?

    private static let spacing: CGFloat = 16

    private func rebuild(for newSize: CGSize) {
        size = newSize
        home = []
        let s = Self.spacing
        let columns = max(Int(newSize.width / s), 1)
        let rows = max(Int(newSize.height / s), 1)
        let offsetX = (newSize.width - CGFloat(columns - 1) * s) / 2
        let offsetY = (newSize.height - CGFloat(rows - 1) * s) / 2
        for row in 0..<rows {
            for column in 0..<columns {
                home.append(CGPoint(x: offsetX + CGFloat(column) * s, y: offsetY + CGFloat(row) * s))
            }
        }
        position = home
        velocity = Array(repeating: .zero, count: home.count)
    }

    func step(now: Double, size newSize: CGSize, radius: CGFloat, strength: CGFloat, stiffness: CGFloat, simulated: CGPoint?) {
        if newSize != size || home.isEmpty {
            rebuild(for: newSize)
        }
        var dt = 1.0 / 60.0
        if let last = last {
            dt = min(max(now - last, 0), 1.0 / 30.0)
        }
        last = now
        let h = CGFloat(dt)
        pointer = touch ?? simulated
        let damping = 2 * stiffness.squareRoot() * 0.45
        let push = strength * 5200

        for i in position.indices {
            var ax = stiffness * (home[i].x - position[i].x) - damping * velocity[i].dx
            var ay = stiffness * (home[i].y - position[i].y) - damping * velocity[i].dy
            if let p = pointer {
                let dx = position[i].x - p.x
                let dy = position[i].y - p.y
                let distance = max((dx * dx + dy * dy).squareRoot(), 0.001)
                if distance < radius {
                    let falloff = 1 - distance / radius
                    let force = falloff * falloff * push
                    ax += dx / distance * force
                    ay += dy / distance * force
                }
            }
            velocity[i].dx += ax * h
            velocity[i].dy += ay * h
            position[i].x += velocity[i].dx * h
            position[i].y += velocity[i].dy * h
        }
    }

    func draw(in context: inout GraphicsContext) {
        var calm = Path()
        var moved = Path()
        var excited = Path()
        for i in position.indices {
            let dx = position[i].x - home[i].x
            let dy = position[i].y - home[i].y
            let offset = (dx * dx + dy * dy).squareRoot()
            let p = position[i]
            if offset < 3 {
                calm.addEllipse(in: CGRect(x: p.x - 1.1, y: p.y - 1.1, width: 2.2, height: 2.2))
            } else if offset < 14 {
                moved.addEllipse(in: CGRect(x: p.x - 1.6, y: p.y - 1.6, width: 3.2, height: 3.2))
            } else {
                excited.addEllipse(in: CGRect(x: p.x - 2.1, y: p.y - 2.1, width: 4.2, height: 4.2))
            }
        }
        if let p = pointer {
            let r: CGFloat = 70
            let halo = Gradient(colors: [Palette.violet.opacity(0.28), Palette.violet.opacity(0)])
            context.fill(
                Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)),
                with: .radialGradient(halo, center: p, startRadius: 0, endRadius: r)
            )
        }
        context.fill(calm, with: .color(.white.opacity(0.28)))
        context.fill(moved, with: .color(Palette.sky))
        context.fill(excited, with: .color(Palette.pink))
    }
}

private struct ParticleRepulsionDemo: View {
    let ctx: DemoContext
    @State private var model = SwarmModel()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x070914), Color(hex: 0x10142A)], startPoint: .top, endPoint: .bottom)
            TimelineView(.animation) { timeline in
                let now = timeline.date.timeIntervalSinceReferenceDate
                Canvas { context, size in
                    let simulated: CGPoint? = ctx.isPreview
                        ? CGPoint(
                            x: size.width * CGFloat(0.5 + 0.32 * sin(now * 0.9)),
                            y: size.height * CGFloat(0.5 + 0.3 * sin(now * 1.37))
                        )
                        : nil
                    model.step(
                        now: now,
                        size: size,
                        radius: ctx.cg("radius"),
                        strength: ctx.cg("strength"),
                        stiffness: ctx.cg("stiffness"),
                        simulated: simulated
                    )
                    model.draw(in: &context)
                }
            }
        }
        .contentShape(Rectangle())
        .gesture(drag)
        .backgroundsHint(L("Drag through the particles", "在粒子中拖动手指"), ctx)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in model.touch = value.location }
            .onEnded { _ in model.touch = nil }
    }
}
