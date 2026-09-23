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
            "A dark midnight canvas holding a precise grid of ~500 tiny particles, each tethered to its home position by an underdamped spring (damping ratio ≈ 0.45). Tapping, or swiping sideways across the field, pushes particles radially away with a force that falls off quadratically toward the edge of an 80 pt influence radius, carving a clean moving void ringed by compressed particles. Displaced particles brighten and grow continuously with their offset — size eases from 2.2 to 4.2 pt while color blends from faint white through sky blue to glowing pink over the first 18 pt of travel — and a soft halo marks the touch point. On release, everything springs home with a small overshoot and settles in about a second. Responsive, physical and quietly delightful.",
            "午夜深色画布上整齐排列约 500 个细小粒子，每个粒子都由一根欠阻尼弹簧（阻尼比约 0.45）拴在自己的原点。点击或横向划过粒子场时，粒子被沿径向推开，推力在 80pt 影响半径内随距离呈二次方衰减，形成一块随手移动的干净空洞，四周环绕被挤压的粒子。粒子越偏离原位就越亮、越大，且过渡连续——在前 18pt 的位移内，直径由 2.2pt 平滑增大到 4.2pt，颜色由淡白经天蓝渐变为发光的粉色——触点处还有一圈柔和光晕。松手后所有粒子带着轻微过冲弹回原位，约一秒内完全平静。灵敏而富有物理感。"
        ),
        implementation: L(
            "A reference-type model held in @State integrates spring + repulsion forces with semi-implicit Euler inside the Canvas renderer each TimelineView frame; particles are batched into eight Paths by displacement, each with an interpolated size and color, so the blend looks continuous at the cost of only eight fills.",
            "保存在 @State 中的引用类型模型，在每个 TimelineView 帧的 Canvas 渲染闭包里以半隐式欧拉法积分弹簧力与排斥力；粒子按位移分成八条 Path 批量绘制，每档尺寸与颜色均为插值结果，只需八次填充即可呈现连续过渡。"
        ),
        apis: ["Canvas", "TimelineView(.animation)", "DragGesture", "@State reference model"],
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
    /// Once the user has touched the field, the idle "ghost finger" stops wandering.
    var userTouched = false
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

    /// Eight displacement levels: size and color blend smoothly from a dim white dot (at home)
    /// through sky to hot pink (≥ 18 pt away). Batching per level keeps it to eight fills.
    private static let levels = 8
    private static let levelStyles: [(radius: CGFloat, color: Color)] = (0..<levels).map { k in
        let t = Double(k) / Double(levels - 1)
        let calm = (r: 1.0, g: 1.0, b: 1.0, a: 0.36)
        let sky = (r: 0x3A / 255.0, g: 0xC4 / 255.0, b: 0xFF / 255.0, a: 1.0)
        let pink = (r: 0xFF / 255.0, g: 0x5F / 255.0, b: 0xA2 / 255.0, a: 1.0)
        let (from, to, u) = t < 0.5 ? (calm, sky, t / 0.5) : (sky, pink, (t - 0.5) / 0.5)
        let color = Color(
            .sRGB,
            red: from.r + (to.r - from.r) * u,
            green: from.g + (to.g - from.g) * u,
            blue: from.b + (to.b - from.b) * u,
            opacity: from.a + (to.a - from.a) * u
        )
        return (radius: CGFloat(1.1 + 1.0 * t), color: color)
    }

    func draw(in context: inout GraphicsContext) {
        var bins = [Path](repeating: Path(), count: Self.levels)
        for i in position.indices {
            let dx = position[i].x - home[i].x
            let dy = position[i].y - home[i].y
            let offset = (dx * dx + dy * dy).squareRoot()
            let p = position[i]
            let level = Int((min(offset / 18, 1) * CGFloat(Self.levels - 1)).rounded())
            let r = Self.levelStyles[level].radius
            bins[level].addEllipse(in: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2))
        }
        if let p = pointer {
            let r: CGFloat = 70
            let halo = Gradient(colors: [Palette.violet.opacity(0.28), Palette.violet.opacity(0)])
            context.fill(
                Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)),
                with: .radialGradient(halo, center: p, startRadius: 0, endRadius: r)
            )
        }
        for level in 0..<Self.levels {
            context.fill(bins[level], with: .color(Self.levelStyles[level].color))
        }
    }
}

private struct ParticleRepulsionDemo: View {
    let ctx: DemoContext
    @State private var model = SwarmModel()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x070914), Color(hex: 0x10142A)], startPoint: .top, endPoint: .bottom)
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let now = timeline.date.timeIntervalSinceReferenceDate
                Canvas { context, size in
                    // Previews always wander; the detail stage wanders until the first touch so it never looks empty.
                    let simulated: CGPoint? = ctx.isPreview || !model.userTouched
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
        .backgroundsTouch { location in
            model.userTouched = true
            model.touch = location
        } onEnded: {
            model.touch = nil
        }
        .backgroundsHint(L("Tap or swipe sideways through the particles", "点击或横向划过粒子"), ctx)
    }

}
