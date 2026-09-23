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
            "A dusky forest-green gradient backdrop with a darker floor. Dozens of fireflies — warm lime and honey-gold points, each wrapped in a soft radial halo — wander on slow, organic paths made of two layered sine drifts per axis (periods 5–20 s, each particle with its own seeded phase), never in lockstep. Every firefly pulses independently: its brightness rises and falls on a squared-sine curve every 2.5–5 s, lingering dim and flaring briefly, while halos add together where they overlap. Halo size varies per particle to fake depth. The overall mood is quiet, magical and nocturnal — a summer evening you could fall asleep to.",
            "暮色森林绿渐变背景，底部更深。数十只萤火虫——暖青柠色与蜂蜜金色的光点，各自包裹一圈柔和径向光晕——沿缓慢而有机的路径游走：每个轴由两层正弦漂移叠加（周期 5–20 秒，每个粒子相位由种子决定），彼此从不同步。每只萤火虫独立呼吸闪烁：亮度按正弦平方曲线每 2.5–5 秒起落一次，多数时间微暗、偶尔骤亮，重叠处光晕叠加增亮。光晕大小因粒子而异，营造景深。整体安静、奇幻、充满夏夜气息，令人放松。"
        ),
        implementation: L(
            "Canvas inside TimelineView(.animation): each firefly's position and pulse are pure functions of its index and time, drawn as radial-gradient discs with .plusLighter blending.",
            "TimelineView(.animation) 中的 Canvas：每只萤火虫的位置与脉动都是索引与时间的纯函数，以 .plusLighter 混合绘制径向渐变圆。"
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

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x0B1F2A), Color(hex: 0x0E2A22), Color(hex: 0x050E0B)],
                startPoint: .top,
                endPoint: .bottom
            )
            TimelineView(.animation) { timeline in
                let t = clock.advance(to: timeline.date.timeIntervalSinceReferenceDate, speed: ctx["speed"])
                FireflyField(t: t, count: ctx.int("count"), glow: ctx.cg("glow"))
            }
            BackgroundSampleTitle(
                title: L("Midsummer", "仲夏夜"),
                subtitle: L("Sleep sounds · 45 min", "助眠白噪音 · 45 分钟"),
                language: ctx.language,
                size: 26
            )
        }
    }
}

private struct FireflyField: View {
    let t: Double
    let count: Int
    let glow: CGFloat

    var body: some View {
        Canvas { context, size in
            context.blendMode = .plusLighter
            for index in 0..<max(count, 0) {
                FireflyField.draw(&context, index: index, size: size, t: t, glow: glow)
            }
        }
    }

    private static let lime = Color(hex: 0xD9FF7A)
    private static let gold = Color(hex: 0xFFD36B)

    private static func draw(_ context: inout GraphicsContext, index i: Int, size: CGSize, t: Double, glow: CGFloat) {
        let r = { (salt: Int) -> Double in BackgroundMath.rand(i, salt) }
        let driftX = 26 * sin(t * (0.3 + 0.4 * r(3)) + r(4) * BackgroundMath.tau) + 10 * sin(t * (0.7 + r(5)) + Double(i))
        let driftY = 22 * cos(t * (0.25 + 0.35 * r(6)) + r(7) * BackgroundMath.tau) + 9 * sin(t * (0.6 + r(8)) - Double(i))
        let x = BackgroundMath.unit(i, 1) * size.width + CGFloat(driftX)
        let y = (0.12 + BackgroundMath.unit(i, 2) * 0.84) * size.height + CGFloat(driftY)

        let wave = max(0, sin(t * (1.6 + r(9) * 1.4) + r(10) * BackgroundMath.tau))
        let pulse = 0.15 + 0.85 * wave * wave
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
