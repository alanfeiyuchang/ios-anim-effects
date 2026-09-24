import SwiftUI

extension Effect {
    static let backgroundsFireflies = Effect(
        id: "backgrounds.fireflies",
        category: .backgrounds,
        interaction: .loop,
        name: L("Fireflies", "萤火虫"),
        summary: L(
            "Warm motes of light wander and pulse through a dusky forest.",
            "温暖的光点在暮色森林中游走、明灭。"
        ),
        prompt: L(
            "A dusky forest-green gradient backdrop with a darker floor. Dozens of fireflies — warm lime and honey-gold points, each wrapped in a soft radial halo — wander on slow, organic paths made of two layered sine drifts per axis (periods ≈ 5–25 s at the default pace, each with its own seeded phase), never in lockstep. Every firefly pulses independently: brightness rises and falls on a squared-sine curve every 2.5–5 s, lingering dim and flaring briefly, and halos add together where they overlap; halo size varies per particle to fake depth. Tapping startles the swarm: fireflies within ~120 pt flare to full brightness within ~50 ms and scatter outward up to ≈ 37 pt (peaking ≈ 160 ms after the tap), then drift back over about 1.5 s as the glow decays. Quiet, magical and nocturnal — a summer evening you could fall asleep to.",
            "暮色森林绿渐变背景，底部更深。数十只萤火虫——暖青柠色与蜂蜜金色的光点，各自包裹一圈柔和的径向光晕——沿缓慢而有机的路径游走：每个轴由两层正弦漂移叠加（默认速度下周期约 5–25 秒，相位由种子决定），从不同步。每只独立呼吸闪烁：亮度按正弦平方曲线每 2.5–5 秒起落一次，多数时间微暗、偶尔骤亮；光晕大小因粒子而异，营造景深。点击会惊动光群：120pt 内的萤火虫 50ms 内亮到最强，向外散开最多约 37pt（约 160ms 达峰），再于约 1.5 秒内随光芒衰减漂回。安静奇幻，满是仲夏夜气息。"
        ),
        implementation: L(
            "Canvas inside TimelineView(.animation): each firefly's position and pulse are pure functions of its index and time, drawn as radial-gradient discs with .plusLighter blending. A tap stores an origin and timestamp; a distance falloff times an out-and-back impulse envelope offsets and brightens nearby fireflies.",
            "TimelineView(.animation) 中的 Canvas：每只萤火虫的位置与脉动都是索引与时间的纯函数，以 .plusLighter 混合绘制径向渐变圆。点击记录圆心与时间，距离衰减乘以“先散开再回位”的脉冲包络，为附近的萤火虫施加位移并提亮。"
        ),
        apis: ["Canvas", "TimelineView(.animation)", "GraphicsContext.Shading.radialGradient", ".plusLighter"],
        tags: ["particles", "fireflies", "glow", "night", "粒子", "萤火虫", "光点", "夜晚"],
        params: [
            .slider("count", L("Fireflies", "数量"), 10...120, default: 55, step: 1, decimals: 0),
            .slider("speed", L("Wander speed", "游走速度"), 0.2...2.0, default: 0.8, unit: "×"),
            .slider("glow", L("Glow radius", "光晕半径"), 6...32, default: 15, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        FirefliesDemo(ctx: ctx)
    }
}

private struct FirefliesDemo: View {
    let ctx: DemoContext
    @State private var clock = BackgroundClock()
    /// Recent startles; a new tap adds to the ones still playing, so scattered fireflies never snap home.
    @State private var bursts: [FireflyBurst] = []

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x0B1F2A), Color(hex: 0x0E2A22), Color(hex: 0x050E0B)],
                startPoint: .top,
                endPoint: .bottom
            )
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let t = clock.advance(to: timeline.date.timeIntervalSinceReferenceDate, speed: ctx["speed"])
                FireflyField(
                    t: t,
                    count: ctx.int("count"),
                    glow: ctx.cg("glow"),
                    bursts: bursts,
                    now: timeline.date.timeIntervalSinceReferenceDate
                )
            }
            BackgroundSampleTitle(
                title: L("Midsummer", "仲夏夜"),
                subtitle: L("Sleep sounds · 45 min", "助眠白噪音 · 45 分钟"),
                language: ctx.language,
                size: 26
            )
        }
        .contentShape(Rectangle())
        .onTapGesture { location in
            let now = Date().timeIntervalSinceReferenceDate
            bursts = Array(bursts.filter { now - $0.time < 2.5 }.suffix(3)) + [FireflyBurst(origin: location, time: now)]
            Haptics.tap(.soft)
        }
        .backgroundsHint(L("Tap to startle the fireflies", "点击惊动萤火虫"), ctx)
    }
}

/// A tap that startles nearby fireflies: they flare and scatter, then drift back.
private struct FireflyBurst {
    let origin: CGPoint
    let time: Double

    /// Offset and flare (0…1) for a firefly resting at `point`, `now` seconds on the real clock.
    func effect(on point: CGPoint, now: Double) -> (offset: CGVector, flare: Double) {
        let age = now - time
        guard age >= 0, age < 2.5 else { return (offset: CGVector(dx: 0, dy: 0), flare: 0) }
        let dx = point.x - origin.x
        let dy = point.y - origin.y
        let distance = max((dx * dx + dy * dy).squareRoot(), 0.001)
        let falloff = exp(-pow(Double(distance) / 120, 2))
        // Out fast, back slowly: rises in ~0.15 s, decays over ~1.5 s.
        let push = 60 * falloff * (1 - exp(-age * 12)) * exp(-age * 2)
        // The flare gets a short attack too (~50 ms), so the swarm lights up rather than cutting to full in one frame.
        // Scaled so it still peaks at full brightness (≈ 115 ms), then decays as before.
        let flare = min(1.43 * falloff * (1 - exp(-age * 20)) * exp(-age * 2.2), falloff)
        let offset = CGVector(dx: dx / distance * CGFloat(push), dy: dy / distance * CGFloat(push))
        return (offset, flare)
    }
}

private struct FireflyField: View {
    let t: Double
    let count: Int
    let glow: CGFloat
    let bursts: [FireflyBurst]
    let now: Double

    var body: some View {
        Canvas { context, size in
            context.blendMode = .plusLighter
            for index in 0..<max(count, 0) {
                FireflyField.draw(&context, index: index, size: size, t: t, glow: glow, bursts: bursts, now: now)
            }
        }
    }

    private static let lime = Color(hex: 0xD9FF7A)
    private static let gold = Color(hex: 0xFFD36B)

    private static func draw(
        _ context: inout GraphicsContext,
        index i: Int,
        size: CGSize,
        t: Double,
        glow: CGFloat,
        bursts: [FireflyBurst],
        now: Double
    ) {
        let r = { (salt: Int) -> Double in BackgroundMath.rand(i, salt) }
        let driftX = 26 * sin(t * (0.3 + 0.4 * r(3)) + r(4) * BackgroundMath.tau) + 10 * sin(t * (0.7 + r(5)) + Double(i))
        let driftY = 22 * cos(t * (0.25 + 0.35 * r(6)) + r(7) * BackgroundMath.tau) + 9 * sin(t * (0.6 + r(8)) - Double(i))
        let rest = CGPoint(
            x: BackgroundMath.unit(i, 1) * size.width + CGFloat(driftX),
            y: (0.12 + BackgroundMath.unit(i, 2) * 0.84) * size.height + CGFloat(driftY)
        )
        var startle = (offset: CGVector(dx: 0, dy: 0), flare: 0.0)
        for burst in bursts {
            let hit = burst.effect(on: rest, now: now)
            startle.offset.dx += hit.offset.dx
            startle.offset.dy += hit.offset.dy
            startle.flare = max(startle.flare, hit.flare)
        }
        let x = rest.x + startle.offset.dx
        let y = rest.y + startle.offset.dy

        // Flicker runs on the real clock (2.5–5 s per flash) so the wander-speed slider never changes it.
        let wave = max(0, sin(now * (1.25 + r(9) * 1.25) + r(10) * BackgroundMath.tau))
        let pulse = max(0.15 + 0.85 * wave * wave, startle.flare)
        let color = r(11) > 0.5 ? lime : gold
        let radius = glow * CGFloat(0.6 + 0.8 * r(12))

        let halo = Gradient(stops: [
            .init(color: color.opacity(0.9 * pulse), location: 0),
            .init(color: color.opacity(0.28 * pulse), location: 0.35),
            .init(color: color.opacity(0), location: 1),
        ])
        let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
        context.fill(
            Path(ellipseIn: rect),
            with: .radialGradient(halo, center: CGPoint(x: x, y: y), startRadius: 0, endRadius: radius)
        )
        let core: CGFloat = 1.3
        context.fill(
            Path(ellipseIn: CGRect(x: x - core, y: y - core, width: core * 2, height: core * 2)),
            with: .color(.white.opacity(0.4 + 0.6 * pulse))
        )
    }
}
