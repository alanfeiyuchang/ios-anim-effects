import SwiftUI

extension Effect {
    static let backgroundsHalftoneFlow = Effect(
        id: "backgrounds.halftone-flow",
        category: .backgrounds,
        interaction: .gesture,
        name: L("Halftone Flow", "半调点阵流"),
        summary: L(
            "A dot matrix swells with flowing interference waves; drag across it like an ink roller and the trail bleeds back.",
            "点阵随流动的干涉波起伏；像墨辊一样横向拖过，留下的墨痕会慢慢渗回。"
        ),
        prompt: L(
            "A dark graphite canvas covered edge to edge by a regular halftone dot matrix. Each dot’s radius follows a smooth interference field — two diagonal traveling sine waves, a horizontal drift and a ripple from the center (4–10 s periods) — so bands of large dots glide and dissolve like light under water while quiet areas shrink to pinpoints, all tinted by one still diagonal gradient (indigo → violet → pink → amber). Dragging sideways works like an ink roller: every dot inside a ~40 pt band along the finger’s path jumps to full coverage at once, with a soft 6 pt edge, and the inked trail bleeds back into the moving field over about 1.5 s on a smoothstep, with no bounce or oscillation. A tap leaves a single round blot. On arrival a flash-bulb exposure swells the whole print once. Crisp, tactile, quietly premium.",
            "深石墨色画布被规则的半调点阵铺满。每个点的半径由平滑干涉场驱动：两道斜向行进的正弦波、一道水平漂移波与一道中心涟漪（周期 4–10 秒），大点光带如水下光影般滑动消散，平静处缩成针尖，整体由静止的对角渐变（靛蓝 → 紫 → 粉 → 琥珀）着色。横向拖动如同滚过墨辊：手指路径两侧约 40pt 宽的带内，点立刻涨满，边缘柔和过渡 6pt；墨痕随后按 smoothstep 在约 1.5 秒内渗回流动的点阵，没有回弹或振荡。轻点只留下一枚圆形墨斑。进入页面时会有一次闪光灯式曝光。利落、可触、低调高级。"
        ),
        implementation: L(
            "Per frame, every dot's coverage is sampled from a sum of sines, then lifted toward full by the ink trail: finger samples spaced 4 pt apart, each weighted by a distance falloff and a 1.5 s smoothstep age fade. All dots go into a single Path filled once with a linear gradient.",
            "每帧根据正弦叠加场计算每个点的覆盖率，再由墨迹抬向涨满：手指采样点间隔 4pt，各自按距离衰减与 1.5 秒 smoothstep 时长淡出加权。所有点追加到同一条 Path，以线性渐变一次填充。"
        ),
        apis: ["Canvas", "TimelineView(.animation)", "DragGesture", "Path.addEllipse(in:)", "GraphicsContext.Shading.linearGradient"],
        tags: ["halftone", "dots", "ink roller", "texture", "半调", "点阵", "墨辊", "纹理"],
        params: [
            .slider("spacing", L("Dot spacing", "点间距"), 9...24, default: 13, decimals: 0, unit: "pt"),
            .slider("speed", L("Flow speed", "流动速度"), 0.2...2.5, default: 1.0, unit: "×"),
            .slider("fade", L("Ink bleed time", "墨迹渗回时间"), 0.5...3.0, default: 1.5, unit: "s"),
            .choice("palette", L("Palette", "配色"), [L("Spectrum", "光谱"), L("Mint", "薄荷"), L("Mono", "单色")]),
        ]
    ) { ctx in
        HalftoneFlowDemo(ctx: ctx)
    }
}

private struct HalftoneFlowDemo: View {
    let ctx: DemoContext
    @State private var clock = BackgroundClock()
    @State private var ink = HalftoneInk()
    /// Reference time of the arrival flash-bulb exposure (detail intro only).
    @State private var exposedAt: Double = -100
    @State private var origin = CGPoint(x: 170, y: 170)
    @State private var size = CGSize(width: 340, height: 340)

    var body: some View {
        ZStack {
            Color(hex: 0x0A0A12)
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let t = clock.advance(to: now, speed: ctx["speed"])
                let fade: Double = max(ctx["fade"], 0.1)
                let _ = ink.prepare(now: now, fade: fade, simulated: simulatedRoller(now: now))
                HalftoneCanvas(
                    t: t,
                    spacing: max(ctx.cg("spacing"), 6),
                    colors: HalftoneCanvas.paletteColors(ctx.int("palette")),
                    exposure: HalftoneExposure(origin: origin, amount: HalftoneExposure.envelope(age: now - exposedAt)),
                    ink: ink.snapshot(now: now, fade: fade)
                )
            }
            BackgroundSampleTitle(
                title: L("Ship faster", "更快交付"),
                subtitle: L("Infrastructure that scales with you", "随你成长的基础设施"),
                language: ctx.language
            )
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { newSize in
            size = newSize
            origin = CGPoint(x: newSize.width / 2, y: newSize.height / 2)
        }
        // Horizontal-first and simultaneous (vertical swipes still scroll the page); a tap pokes a single blot.
        .backgroundsTouch(onChanged: { point in
            if !ink.rolling && !ctx.isPreview { Haptics.tap(.soft) }
            ink.roll(to: point, at: Date().timeIntervalSinceReferenceDate)
        }, onEnded: {
            ink.lift()
        })
        // The flash bulb survives only as the detail page's arrival play; previews demo the roller instead.
        .autoplay(false, every: 3.4) { expose(at: origin) }
        .backgroundsHint(L("Drag sideways to roll ink", "横向拖动滚上墨迹"), ctx)
        .onDisappear { ink.lift() }
    }

    private func expose(at location: CGPoint) {
        origin = location
        exposedAt = Date().timeIntervalSinceReferenceDate
    }

    /// Previews can't be touched: every 3.4 s a "roller" sweeps across the print on a gentle S.
    private func simulatedRoller(now: Double) -> CGPoint? {
        guard ctx.isPreview else { return nil }
        let cycle: Double = now.truncatingRemainder(dividingBy: 3.4)
        guard cycle < 1.4 else { return nil }
        let f: Double = cycle / 1.4
        let lane: Double = (now / 3.4).rounded(.down).truncatingRemainder(dividingBy: 3)
        let x: CGFloat = size.width * CGFloat(0.08 + 0.84 * f)
        let y: CGFloat = size.height * CGFloat(0.3 + 0.2 * lane) + 26 * CGFloat(sin(f * .pi * 2))
        return CGPoint(x: x, y: y)
    }
}

/// One inked point of the roller's trail.
private struct HalftoneInkSample {
    let point: CGPoint
    let time: Double
}

/// The ink roller's trail: finger samples 4 pt apart, dropped once fully bled back.
private final class HalftoneInk {
    private var samples: [HalftoneInkSample] = []
    private var last: CGPoint?
    private var simulating = false
    private(set) var rolling = false

    func roll(to point: CGPoint, at time: Double) {
        rolling = true
        guard let from = last else {
            append(point, time)
            last = point
            return
        }
        let distance: CGFloat = hypot(point.x - from.x, point.y - from.y)
        guard distance >= 4 else { return }
        let steps: Int = min(Int(distance / 4), 40)
        for k in 1...max(steps, 1) {
            let f: CGFloat = CGFloat(k) / CGFloat(max(steps, 1))
            append(CGPoint(x: from.x + (point.x - from.x) * f, y: from.y + (point.y - from.y) * f), time)
        }
        last = point
    }

    func lift() {
        rolling = false
        last = nil
    }

    private func append(_ point: CGPoint, _ time: Double) {
        samples.append(HalftoneInkSample(point: point, time: time))
        if samples.count > 400 { samples.removeFirst(samples.count - 400) }
    }

    /// Prunes bled-out samples and feeds the preview's simulated roller. Returns the live sample count.
    @discardableResult
    func prepare(now: Double, fade: Double, simulated: CGPoint?) -> Int {
        if let simulated {
            simulating = true
            roll(to: simulated, at: now)
        } else if simulating {
            simulating = false
            lift()
        }
        samples.removeAll { now - $0.time > fade }
        return samples.count
    }

    func snapshot(now: Double, fade: Double) -> HalftoneInkField {
        HalftoneInkField(samples: samples, now: now, fade: fade)
    }
}

/// Coverage boost from the ink trail at a dot: full inside a ~40 pt band, a 6 pt soft edge, and a
/// smoothstep bleed back over `fade` seconds (no oscillation).
private struct HalftoneInkField {
    let samples: [HalftoneInkSample]
    let now: Double
    let fade: Double

    private static let core: Double = 17
    private static let edge: Double = 23

    private static func smoothstep(_ x: Double) -> Double {
        let t = min(max(x, 0), 1)
        return t * t * (3 - 2 * t)
    }

    func weight(x: Double, y: Double) -> Double {
        var best = 0.0
        for sample in samples {
            let dx: Double = x - Double(sample.point.x)
            guard abs(dx) < Self.edge else { continue }
            let dy: Double = y - Double(sample.point.y)
            guard abs(dy) < Self.edge else { continue }
            let d: Double = (dx * dx + dy * dy).squareRoot()
            let spatial: Double = 1 - Self.smoothstep((d - Self.core) / (Self.edge - Self.core))
            let fresh: Double = 1 - Self.smoothstep((now - sample.time) / fade)
            best = max(best, spatial * fresh)
            if best >= 0.999 { break }
        }
        return best
    }
}

/// The arrival flash bulb "over-exposes" the print: every dot's coverage is pushed toward full, then relaxes
/// through a brief under-exposure, like a flash bulb on photographic paper.
private struct HalftoneExposure {
    let origin: CGPoint
    /// Signed exposure: > 0 swells dots, < 0 shrinks them, 0 at rest.
    let amount: Double

    /// Rise in 80 ms, then a damped swing (decay 2.6/s, 5.5 rad/s) that dips to ≈ −0.23 before settling.
    static func envelope(age: Double) -> Double {
        guard age >= 0, age < 2.2 else { return 0 }
        let attack = min(age / 0.08, 1)
        return attack * exp(-2.6 * age) * cos(5.5 * age)
    }

    /// Exponent applied to the dot coverage n (0…1): below 1 swells, above 1 shrinks.
    func gamma(x: Double, y: Double) -> Double {
        guard amount != 0 else { return 1 }
        let dx = x - Double(origin.x)
        let dy = y - Double(origin.y)
        let local = 0.6 + 0.4 * exp(-(dx * dx + dy * dy) / 32_400)
        return exp(-1.3 * amount * local)
    }
}

private struct HalftoneCanvas: View {
    let t: Double
    let spacing: CGFloat
    let colors: [Color]
    let exposure: HalftoneExposure
    let ink: HalftoneInkField

    static func paletteColors(_ index: Int) -> [Color] {
        switch index {
        case 1:
            return [Palette.mint, Palette.sky, Palette.blue]
        case 2:
            return [.white.opacity(0.95), .white.opacity(0.45)]
        default:
            return [Palette.indigo, Palette.violet, Palette.pink, Palette.amber]
        }
    }

    var body: some View {
        Canvas { context, size in
            let path = HalftoneCanvas.dots(size: size, t: t, spacing: spacing, exposure: exposure, ink: ink)
            context.fill(
                path,
                with: .linearGradient(Gradient(colors: colors), startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height))
            )
        }
    }

    private static func dots(size: CGSize, t: Double, spacing: CGFloat, exposure: HalftoneExposure, ink: HalftoneInkField) -> Path {
        var path = Path()
        let cx = Double(size.width / 2)
        let cy = Double(size.height / 2)
        let maxRadius = spacing * 0.46
        var y = spacing / 2
        while y < size.height {
            var x = spacing / 2
            while x < size.width {
                let dx = Double(x)
                let dy = Double(y)
                let distance = ((dx - cx) * (dx - cx) + (dy - cy) * (dy - cy)).squareRoot()
                var field = sin((dx + dy) * 0.016 + t * 1.1)
                field += sin((dx - dy) * 0.021 - t * 0.8)
                field += sin(dx * 0.012 + t * 0.6)
                field += sin(distance * 0.035 - t * 1.5)
                let base = ((field / 3 + 1) / 2).clamped(to: 0...1)
                let exposed: Double = pow(base, exposure.gamma(x: dx, y: dy))
                // The roller's ink lifts the dot toward full coverage, then bleeds back into the field.
                let inked: Double = ink.samples.isEmpty ? 0 : ink.weight(x: dx, y: dy)
                let n: Double = exposed + (1 - exposed) * inked
                let radius = maxRadius * CGFloat(0.1 + 0.9 * n * n)
                if radius > 0.3 {
                    path.addEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
                }
                x += spacing
            }
            y += spacing
        }
        return path
    }
}
