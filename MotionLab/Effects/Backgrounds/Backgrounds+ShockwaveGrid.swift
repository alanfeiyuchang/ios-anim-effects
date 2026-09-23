import SwiftUI

extension Effect {
    static let backgroundsShockwaveGrid = Effect(
        id: "backgrounds.shockwave-grid",
        category: .backgrounds,
        interaction: .tap,
        name: L("Shockwave Grid", "冲击波点阵"),
        summary: L(
            "A lattice of spring-loaded dots — every tap sends a shockwave that sets them ringing.",
            "由弹簧点组成的点阵：每次点击都会激起一道冲击波，让点阵振荡回响。"
        ),
        prompt: L(
            "A near-black stage covered by a regular dot lattice (18 pt pitch). Every dot is a tiny damped spring: when a tap's shockwave front reaches it — the front travels outward at 260 pt/s — the dot starts a radial oscillation of 9 pt × e^(−2.4·τ) × sin(12·τ), scaled down with distance as 1 / (1 + d/180 pt), where τ is the time since the front passed. The result is an expanding ring of displacement with a ringing wake behind it rather than a single pulse. Dots brighten and grow with their energy — dim white at rest, sky-blue while moving, white-hot with a soft glow at the crest — and up to five shockwaves superimpose. Each tap gives a rigid haptic. Technical, crisp and satisfying.",
            "近乎纯黑的舞台上铺满规则点阵（间距 18pt）。每个点都是一个带阻尼的小弹簧：当点击产生的冲击波前沿到达它时——前沿以 260pt/s 向外扩散——该点开始做径向振荡，位移为 9pt × e^(−2.4·τ) × sin(12·τ)，并随距离按 1 / (1 + d/180pt) 衰减，其中 τ 为前沿经过后的时间。于是看到的是一圈不断扩大的位移环，后面拖着逐渐平息的余振，而不是单一脉冲。点的亮度与大小随能量变化——静止时是暗白色，运动时变成天蓝，波峰处白热并带柔和光晕——最多五道冲击波可以叠加。每次点击伴随一次清脆的触感。理性、利落、令人满足。"
        ),
        implementation: L(
            "A Canvas evaluates each dot's summed damped-sine displacement from every live shockwave analytically (no per-dot state), buckets dots by energy into three Paths and draws the hottest bucket twice, once blurred, for glow.",
            "Canvas 以解析方式计算每个点在所有活跃冲击波下叠加的阻尼正弦位移（无需逐点状态），按能量把点分入三条 Path，并把最亮的一组额外模糊绘制一次作为辉光。"
        ),
        apis: ["Canvas", "TimelineView(.animation)", "onTapGesture(coordinateSpace:perform:)", "GraphicsContext.drawLayer", "Haptics"],
        tags: ["grid", "dots", "shockwave", "spring", "点阵", "冲击波", "弹簧", "涟漪"],
        params: [
            .slider("spacing", L("Dot spacing", "点间距"), 12...28, default: 18, decimals: 0, unit: "pt"),
            .slider("waveSpeed", L("Wave speed", "波速"), 120...520, default: 260, decimals: 0, unit: "pt/s"),
            .slider("omega", L("Ringing", "振荡频率"), 6...22, default: 12, decimals: 0, unit: " rad/s"),
            .slider("damping", L("Damping", "阻尼"), 1...6, default: 2.4, decimals: 1),
        ]
    ) { ctx in
        ShockwaveGridDemo(ctx: ctx)
    }
}

private struct Shockwave {
    let origin: CGPoint
    let born: Double
}

private final class ShockModel {
    private(set) var waves: [Shockwave] = []

    func add(at point: CGPoint) {
        waves.append(Shockwave(origin: point, born: Date().timeIntervalSinceReferenceDate))
        if waves.count > 5 {
            waves.removeFirst(waves.count - 5)
        }
    }

    func live(at now: Double) -> [Shockwave] {
        waves.removeAll { now - $0.born > 6 }
        return waves
    }
}

private struct ShockSettings {
    let spacing: CGFloat
    let speed: Double
    let omega: Double
    let damping: Double
}

private struct ShockwaveGridDemo: View {
    let ctx: DemoContext
    @State private var model = ShockModel()
    @State private var size = CGSize(width: 340, height: 340)

    var body: some View {
        let settings = ShockSettings(
            spacing: max(ctx.cg("spacing"), 8),
            speed: max(ctx["waveSpeed"], 1),
            omega: ctx["omega"],
            damping: ctx["damping"]
        )
        ZStack {
            RadialGradient(colors: [Color(hex: 0x141827), Color(hex: 0x07080D)], center: .center, startRadius: 0, endRadius: 260)
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let now = timeline.date.timeIntervalSinceReferenceDate
                ShockCanvas(now: now, waves: model.live(at: now), settings: settings)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(coordinateSpace: .local) { location in
            Haptics.tap(.rigid)
            model.add(at: location)
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        .autoplay(ctx.isPreview, every: 1.8, delay: 0.3) {
            let point = CGPoint(
                x: CGFloat.random(in: 0.2...0.8) * size.width,
                y: CGFloat.random(in: 0.2...0.8) * size.height
            )
            model.add(at: point)
        }
        .backgroundsHint(L("Tap anywhere to send a shockwave", "点击任意位置发出冲击波"), ctx)
    }
}

private struct ShockCanvas: View {
    let now: Double
    let waves: [Shockwave]
    let settings: ShockSettings

    var body: some View {
        Canvas { context, size in
            let paths = ShockCanvas.dots(size: size, now: now, waves: waves, settings: settings)
            context.fill(paths.dim, with: .color(.white.opacity(0.22)))
            context.fill(paths.mid, with: .color(Palette.sky.opacity(0.85)))
            context.drawLayer { glow in
                glow.addFilter(.blur(radius: 4))
                glow.fill(paths.hot, with: .color(Palette.sky))
            }
            context.fill(paths.hot, with: .color(.white))
        }
    }

    private static func dots(size: CGSize, now: Double, waves: [Shockwave], settings: ShockSettings) -> (dim: Path, mid: Path, hot: Path) {
        var dim = Path()
        var mid = Path()
        var hot = Path()
        let pitch = settings.spacing
        let cols = Int(size.width / pitch) + 1
        let rows = Int(size.height / pitch) + 1
        let originX = (size.width - CGFloat(cols - 1) * pitch) / 2
        let originY = (size.height - CGFloat(rows - 1) * pitch) / 2
        for row in 0..<rows {
            for col in 0..<cols {
                let base = CGPoint(x: originX + CGFloat(col) * pitch, y: originY + CGFloat(row) * pitch)
                let offset = displacement(of: base, now: now, waves: waves, settings: settings)
                let energy = offset.energy
                let radius = 1.3 + CGFloat(min(energy, 8)) * 0.2
                let center = CGPoint(x: base.x + offset.dx, y: base.y + offset.dy)
                let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
                if energy < 0.8 {
                    dim.addEllipse(in: rect)
                } else if energy < 3 {
                    mid.addEllipse(in: rect)
                } else {
                    hot.addEllipse(in: rect)
                }
            }
        }
        return (dim, mid, hot)
    }

    private static func displacement(of point: CGPoint, now: Double, waves: [Shockwave], settings: ShockSettings) -> (dx: CGFloat, dy: CGFloat, energy: Double) {
        var dx: CGFloat = 0
        var dy: CGFloat = 0
        var energy: Double = 0
        for wave in waves {
            let vx = point.x - wave.origin.x
            let vy = point.y - wave.origin.y
            let distance = max(hypot(vx, vy), 0.001)
            let tau = (now - wave.born) - Double(distance) / settings.speed
            guard tau > 0 else { continue }
            let falloff = 1 / (1 + Double(distance) / 180)
            let envelope = exp(-settings.damping * tau) * falloff
            guard envelope > 0.004 else { continue }
            let amount = 9 * envelope * sin(settings.omega * tau)
            dx += vx / distance * CGFloat(amount)
            dy += vy / distance * CGFloat(amount)
            energy += abs(amount)
        }
        return (dx, dy, energy)
    }
}
