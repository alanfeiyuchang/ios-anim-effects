import SwiftUI

extension Effect {
    static let backgroundsStarfieldWarp = Effect(
        id: "backgrounds.starfield-warp",
        category: .backgrounds,
        interaction: .gesture,
        name: L("Starfield Warp", "星际跃迁"),
        summary: L(
            "A 3D starfield streams toward you — press and hold to jump to light speed.",
            "三维星空迎面流动，长按即可跃迁至光速。"
        ),
        prompt: L(
            "A deep-space backdrop — near-black fading to indigo at the centre — filled with a few hundred stars projected in perspective from a central vanishing point. Each star travels along its own radial ray; its distance, brightness and line width grow as it approaches, and it is drawn as a streak whose length is proportional to current velocity, with a gradient that fades from transparent at the tail to full brightness at the head, and a subtle cyan or violet tint on a minority of stars. Pressing and holding (without moving, so page scrolling is never trapped) eases velocity up to about 7× over ~0.5 s (exponential approach), stretching stars into long light-speed trails and blooming a soft blue glow at the core; releasing eases back to a leisurely cruise with no discontinuity. A medium haptic marks the engage. It feels immersive, kinetic and cinematic.",
            "深空背景由近乎纯黑向中心的靛蓝渐变，数百颗星星以中心灭点做透视投影。每颗星沿各自的径向射线飞来，越靠近则越亮、越粗，并以与当前速度成正比的拖尾线段绘制，拖尾由尾端透明渐变到头部全亮，少数星星带有青色或紫色色调。长按（手指不移动，因此不会拦截页面滚动）时速度以指数趋近方式在约 0.5 秒内加速到约 7 倍，星点被拉成长长的光速轨迹，中心泛起柔和蓝色辉光；松手后平滑减速回巡航状态，全程无跳变。按下时伴随中等强度的触觉反馈。整体沉浸、充满速度感与电影感。"
        ),
        implementation: L(
            "A small reference model eases velocity toward a target and integrates a depth phase; Canvas projects each star's z = fract(seed − phase) and strokes head-to-tail segments.",
            "一个小型引用类型模型将速度缓动至目标值并积分深度相位；Canvas 以 z = fract(seed − phase) 做透视投影，描边从星头到星尾的线段。"
        ),
        apis: ["Canvas", "TimelineView(.animation)", "onLongPressGesture(onPressingChanged:)", "GraphicsContext.stroke"],
        tags: ["starfield", "warp", "hyperspace", "space", "星空", "跃迁", "光速", "宇宙"],
        params: [
            .slider("count", L("Stars", "星星数量"), 80...420, default: 240, step: 10, decimals: 0),
            .slider("speed", L("Cruise speed", "巡航速度"), 0.2...2.0, default: 0.6, unit: "×"),
            .slider("streak", L("Streak length", "拖尾长度"), 0...3, default: 1.2, decimals: 1, unit: "×"),
        ]
    ) { ctx in
        WarpDemo(ctx: ctx)
    }
}

private final class WarpModel {
    private var last: Double?
    private(set) var phase: Double = 0
    private(set) var velocity: Double = 0.6
    private(set) var boost: Double = 0
    var boosting = false

    func step(now: Double, base: Double, autoBoost: Bool) -> Double {
        var dt = 0.0
        if let last = last {
            dt = min(max(now - last, 0), 0.05)
        }
        last = now
        let boosted = boosting || autoBoost
        let target = base * (boosted ? 7 : 1)
        velocity += (target - velocity) * (1 - exp(-dt * (boosted ? 4.5 : 2.2)))
        phase += dt * velocity * 0.22
        boost = ((velocity / max(base, 0.01) - 1) / 6).clamped(to: 0...1)
        return phase
    }
}

private struct WarpDemo: View {
    let ctx: DemoContext
    @State private var model = WarpModel()

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate
            let autoBoost = ctx.isPreview && BackgroundMath.fract(now / 6) > 0.62
            let phase = model.step(now: now, base: ctx["speed"], autoBoost: autoBoost)
            WarpCanvas(
                phase: phase,
                velocity: model.velocity,
                boost: model.boost,
                count: ctx.int("count"),
                streak: ctx["streak"]
            )
        }
        .background(Color(hex: 0x020208))
        .contentShape(Rectangle())
        // A long press that never "completes" reports pressing for as long as the finger stays down,
        // and fails (releasing the boost) as soon as the finger moves, so the page can still scroll.
        .onLongPressGesture(minimumDuration: 60, maximumDistance: 10, perform: {}, onPressingChanged: { pressing in
            if pressing && !model.boosting { Haptics.tap(.medium) }
            model.boosting = pressing
        })
        .backgroundsHint(L("Press and hold to warp", "长按进入跃迁"), ctx)
    }
}

private struct WarpCanvas: View {
    let phase: Double
    let velocity: Double
    let boost: Double
    let count: Int
    let streak: Double

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let reach = max(size.width, size.height) * 0.5
            WarpCanvas.drawCore(&context, center: center, reach: reach, boost: boost)
            for index in 0..<max(count, 0) {
                WarpCanvas.drawStar(&context, index: index, center: center, reach: reach, phase: phase, trail: velocity * 0.02 * streak)
            }
        }
    }

    private static func drawCore(_ context: inout GraphicsContext, center: CGPoint, reach: CGFloat, boost: Double) {
        let radius = reach * CGFloat(0.9 + boost * 0.5)
        let gradient = Gradient(colors: [
            Color(hex: 0x4F7CFF).opacity(0.22 + 0.4 * boost),
            Color(hex: 0x2A1F7A).opacity(0.18),
            .clear,
        ])
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: rect), with: .radialGradient(gradient, center: center, startRadius: 0, endRadius: radius))
    }

    private static func drawStar(_ context: inout GraphicsContext, index i: Int, center: CGPoint, reach: CGFloat, phase: Double, trail: Double) {
        let z = max(BackgroundMath.fract(BackgroundMath.rand(i, 3) - phase), 0.015)
        let tailZ = min(z + trail + 0.004, 1)
        let angle = BackgroundMath.rand(i, 1) * BackgroundMath.tau
        let spread = 0.12 + BackgroundMath.rand(i, 2) * 0.88
        let dir = CGPoint(x: cos(angle), y: sin(angle))
        let head = reach * CGFloat(spread * 0.16 / z)
        let tail = reach * CGFloat(spread * 0.16 / tailZ)

        let tailPoint = CGPoint(x: center.x + dir.x * tail, y: center.y + dir.y * tail)
        let headPoint = CGPoint(x: center.x + dir.x * head, y: center.y + dir.y * head)
        var path = Path()
        path.move(to: tailPoint)
        path.addLine(to: headPoint)

        let closeness = 1 - z
        let alpha = min(1, closeness * 1.5)
        let color: Color
        if i % 7 == 0 {
            color = Color(hex: 0xB9A4FF)
        } else if i % 5 == 0 {
            color = Color(hex: 0x9FE3FF)
        } else {
            color = .white
        }
        // Gradient tail: transparent at the far end, full brightness at the head, so streaks read as motion.
        context.stroke(
            path,
            with: .linearGradient(
                Gradient(colors: [color.opacity(0), color.opacity(alpha * 0.55), color.opacity(alpha)]),
                startPoint: tailPoint,
                endPoint: headPoint
            ),
            style: StrokeStyle(lineWidth: CGFloat(0.4 + closeness * 2.2), lineCap: .round)
        )
    }
}
