import SwiftUI

extension Effect {
    static let backgroundsRain = Effect(
        id: "backgrounds.rain",
        category: .backgrounds,
        interaction: .loop,
        name: L("Night Rain", "夜雨"),
        summary: L(
            "Wind-slanted rain streaks over blurred city lights — tap for lightning.",
            "随风倾斜的雨丝划过朦胧城市灯火，点击召唤闪电。"
        ),
        prompt: L(
            "A moody night-city backdrop: a deep blue-slate gradient with a handful of heavily blurred amber, coral and cyan window lights glowing near the bottom. Over it, a dense curtain of fine rain streaks falls at a wind-set slant; each streak's speed and length scale with a random depth value, and streaks are split into a near layer (1.3 pt, brighter) and a far layer (0.7 pt, fainter), so near drops are brighter, longer and faster while distant ones read as a faint haze. At the base, small flattened ripple ellipses expand and fade on staggered ~0.8 s cycles where drops land. Tapping triggers a lightning strike: an instant cold-white flash for 80 ms, a brief dip, a second flicker from ~160 to 240 ms, then an exponential fade over ~0.5 s with a heavy haptic. Cinematic, melancholic and cosy.",
            "情绪化的夜城背景：深蓝灰渐变，底部点缀几团高度模糊的琥珀色、珊瑚色与青色窗灯。其上密集的细雨丝按风向倾斜坠落；每条雨丝的速度与长度随随机景深值变化，并分为近景（1.3pt、更亮）与远景（0.7pt、更淡）两层，近处雨滴更亮、更长、更快，远处则化为一层淡淡雨雾。画面底部，雨滴落点处的扁平涟漪椭圆以约 0.8 秒的错峰周期扩散并淡出。点击触发闪电：先是持续 80 毫秒的冷白闪光，短暂变暗后在约 160–240 毫秒再闪一次，随后在约 0.5 秒内指数衰减，并伴随强烈触觉反馈。电影感十足，忧郁又温馨。"
        ),
        implementation: L(
            "One Canvas: a blurred drawLayer for city lights, rain streaks batched into two depth Paths, stroked ripple ellipses, and a flash overlay whose envelope is computed from the time since the last tap.",
            "单个 Canvas：模糊 drawLayer 绘制城市灯光，雨丝按景深合并为两条 Path 批量描边，另有描边涟漪椭圆，以及根据距上次点击时间计算包络的闪光层。"
        ),
        apis: ["Canvas", "TimelineView(.animation)", "GraphicsContext.drawLayer", "onTapGesture", "Haptics"],
        tags: ["rain", "weather", "storm", "lightning", "下雨", "天气", "雷雨", "闪电"],
        params: [
            .slider("count", L("Intensity", "雨量"), 60...320, default: 180, step: 10, decimals: 0),
            .slider("wind", L("Wind angle", "风向角度"), -30...30, default: 12, decimals: 0, unit: "°"),
            .slider("speed", L("Fall speed", "下落速度"), 0.4...2.0, default: 1.0, unit: "×"),
        ]
    ) { ctx in
        RainDemo(ctx: ctx)
    }
}

private final class RainModel {
    let clock = BackgroundClock()
    var flashStart: Double = -100

    func flash(at now: Double) -> Double {
        let e = now - flashStart
        if e < 0 { return 0 }
        if e < 0.08 { return 1 }
        if e < 0.16 { return 0.25 }
        if e < 0.24 { return 0.85 }
        return max(0, 0.85 * exp(-(e - 0.24) * 6))
    }
}

private struct RainDemo: View {
    let ctx: DemoContext
    @State private var model = RainModel()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x0B1220), Color(hex: 0x14203A), Color(hex: 0x1B2740)], startPoint: .top, endPoint: .bottom)
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let t = model.clock.advance(to: now, speed: ctx["speed"])
                RainCanvas(t: t, flash: model.flash(at: now), count: ctx.int("count"), wind: ctx["wind"])
            }
            BackgroundSampleTitle(
                title: L("18°", "18°"),
                subtitle: L("Light rain · Umbrella advised", "小雨 · 建议带伞"),
                language: ctx.language,
                size: 44
            )
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 36)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.tap(.heavy)
            strike()
        }
        .autoplay(ctx.isPreview, every: 4.5, delay: 1.5) { strike() }
        .backgroundsHint(L("Tap for lightning", "点击召唤闪电"), ctx)
    }

    private func strike() {
        model.flashStart = Date().timeIntervalSinceReferenceDate
    }
}

private struct RainCanvas: View {
    let t: Double
    let flash: Double
    let count: Int
    let wind: Double

    var body: some View {
        Canvas { context, size in
            RainCanvas.drawCityLights(&context, size: size)
            RainCanvas.drawStreaks(&context, size: size, t: t, count: count, wind: wind, flash: flash)
            RainCanvas.drawRipples(&context, size: size, t: t)
            if flash > 0.001 {
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: 0xDDE6FF).opacity(flash * 0.55)))
            }
        }
    }

    private static func drawCityLights(_ context: inout GraphicsContext, size: CGSize) {
        let colors: [Color] = [Palette.amber, Palette.coral, Palette.sky, Color(hex: 0xFFE0A3), Palette.pink]
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 16))
            for i in 0..<9 {
                let r = min(size.width, size.height) * (0.05 + 0.06 * BackgroundMath.unit(i, 21))
                let x = BackgroundMath.unit(i, 22) * size.width
                let y = size.height * (0.62 + 0.32 * BackgroundMath.unit(i, 23))
                let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                layer.fill(Path(ellipseIn: rect), with: .color(colors[i % colors.count].opacity(0.4)))
            }
        }
    }

    private static func drawStreaks(_ context: inout GraphicsContext, size: CGSize, t: Double, count: Int, wind: Double, flash: Double) {
        let theta = wind * .pi / 180
        let slope = CGFloat(tan(theta))
        let dirX = CGFloat(sin(theta))
        let dirY = CGFloat(cos(theta))
        var far = Path()
        var near = Path()
        for i in 0..<max(count, 0) {
            let depth = BackgroundMath.rand(i, 1)
            let length = CGFloat(12 + 22 * depth)
            let span = size.height + length + 20
            let y = CGFloat(BackgroundMath.fract(BackgroundMath.rand(i, 2) + t * (0.9 + 0.8 * depth))) * span - length
            let x0 = (BackgroundMath.unit(i, 3) * 1.8 - 0.4) * size.width
            let x = x0 + slope * (y - size.height / 2)
            let head = CGPoint(x: x, y: y)
            let tail = CGPoint(x: x - length * dirX, y: y - length * dirY)
            if depth > 0.55 {
                near.move(to: tail)
                near.addLine(to: head)
            } else {
                far.move(to: tail)
                far.addLine(to: head)
            }
        }
        let tint = Color(hex: 0xC9D8FF)
        context.stroke(far, with: .color(tint.opacity(0.22 + flash * 0.3)), style: StrokeStyle(lineWidth: 0.7, lineCap: .round))
        context.stroke(near, with: .color(tint.opacity(0.5 + flash * 0.4)), style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
    }

    private static func drawRipples(_ context: inout GraphicsContext, size: CGSize, t: Double) {
        for i in 0..<14 {
            let cycle = t * 1.25 + BackgroundMath.rand(i, 31)
            let p = BackgroundMath.fract(cycle)
            // Each new cycle lands the ripple somewhere else.
            let seed = i * 97 + Int(cycle.rounded(.down))
            let rx = CGFloat(3 + 16 * p)
            let ry = rx * 0.28
            let x = BackgroundMath.unit(seed, 32) * size.width
            let y = size.height * (0.84 + 0.14 * BackgroundMath.unit(seed, 33))
            let rect = CGRect(x: x - rx, y: y - ry, width: rx * 2, height: ry * 2)
            context.stroke(Path(ellipseIn: rect), with: .color(.white.opacity((1 - p) * 0.35)), lineWidth: 1)
        }
    }
}
