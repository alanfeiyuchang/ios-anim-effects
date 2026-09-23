import SwiftUI

extension Effect {
    static let backgroundsHalftoneFlow = Effect(
        id: "backgrounds.halftone-flow",
        category: .backgrounds,
        interaction: .loop,
        name: L("Halftone Flow", "半调点阵流"),
        summary: L(
            "A dot matrix swells and shrinks with flowing interference waves — tap to flash the exposure.",
            "点阵随流动的干涉波起伏缩放，点击闪一次曝光。"
        ),
        prompt: L(
            "A dark graphite canvas covered edge to edge by a regular halftone dot matrix. Each dot’s radius is driven by a smooth interference field — two diagonal traveling sine waves, one horizontal drift and one ripple radiating from the center, each at its own speed (4–10 s periods) — so bands of large dots glide, cross and dissolve like light under water while quiet areas shrink to pinpoints. The whole matrix is tinted by one diagonal gradient (indigo → violet → pink → amber), so color stays still while form moves. A tap fires a flash-bulb exposure: within 80 ms every dot swells toward full coverage, strongest within ~180 pt of the finger, then the print relaxes through a damped swing (decay 2.6/s, 5.5 rad/s), briefly under-exposing before it settles in about 2 s. Crisp, calm and quietly premium.",
            "深石墨色画布被规则的半调点阵完整铺满。每个点的半径由平滑的干涉场驱动：两道斜向行进的正弦波、一道水平漂移的波与一道从中心扩散的涟漪，各自速度不同（周期 4–10 秒）。大点光带如水下光影般滑动、交错又消散，平静处缩成针尖。点阵由对角渐变（靛蓝 → 紫 → 粉 → 琥珀）统一着色，色彩静止、形态流动。点击如闪光灯“曝光”：80ms 内所有点膨大到接近铺满（指尖约 180pt 内最强），再以阻尼摆动（衰减 2.6/s、5.5 rad/s）回落，途中短暂欠曝、点径略小于常态，约 2 秒内平息。沉静而高级。"
        ),
        implementation: L(
            "Per frame, every dot's radius is sampled from a sum of sines, raised to a tap-driven exposure gamma (a damped swing, weighted toward the finger) and appended to a single Path, which is filled once with a linear gradient — one draw call for the whole field.",
            "每帧根据正弦叠加场计算每个点的半径，再按点击触发的曝光 gamma（阻尼摆动，靠近指尖更强）调整，追加到同一条 Path，最后以线性渐变一次性填充——整片点阵只需一次绘制调用。"
        ),
        apis: ["Canvas", "TimelineView(.animation)", "Path.addEllipse(in:)", "GraphicsContext.Shading.linearGradient"],
        tags: ["halftone", "dots", "pattern", "texture", "半调", "点阵", "纹理", "图案"],
        params: [
            .slider("spacing", L("Dot spacing", "点间距"), 9...24, default: 13, decimals: 0, unit: "pt"),
            .slider("speed", L("Flow speed", "流动速度"), 0.2...2.5, default: 1.0, unit: "×"),
            .choice("palette", L("Palette", "配色"), [L("Spectrum", "光谱"), L("Mint", "薄荷"), L("Mono", "单色")]),
        ]
    ) { ctx in
        HalftoneFlowDemo(ctx: ctx)
    }
}

private struct HalftoneFlowDemo: View {
    let ctx: DemoContext
    @State private var clock = BackgroundClock()
    /// Reference time of the last tap (the "flash-bulb" exposure).
    @State private var exposedAt: Double = -100
    @State private var origin = CGPoint(x: 170, y: 170)

    var body: some View {
        ZStack {
            Color(hex: 0x0A0A12)
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let t = clock.advance(to: now, speed: ctx["speed"])
                HalftoneCanvas(
                    t: t,
                    spacing: max(ctx.cg("spacing"), 6),
                    colors: HalftoneCanvas.paletteColors(ctx.int("palette")),
                    exposure: HalftoneExposure(origin: origin, amount: HalftoneExposure.envelope(age: now - exposedAt))
                )
            }
            BackgroundSampleTitle(
                title: L("Ship faster", "更快交付"),
                subtitle: L("Infrastructure that scales with you", "随你成长的基础设施"),
                language: ctx.language
            )
        }
        .contentShape(Rectangle())
        .onTapGesture { location in
            Haptics.tap(.soft)
            expose(at: location)
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size in
            origin = CGPoint(x: size.width / 2, y: size.height / 2)
        }
        .autoplay(ctx.isPreview, every: 3.4, delay: 1.2) { expose(at: origin) }
        .backgroundsHint(L("Tap to flash the exposure", "点击闪一次曝光"), ctx)
    }

    private func expose(at location: CGPoint) {
        origin = location
        exposedAt = Date().timeIntervalSinceReferenceDate
    }
}

/// A tap "over-exposes" the print: every dot's coverage is pushed toward full (strongest near the finger),
/// then relaxes through a brief under-exposure, like a flash bulb on photographic paper.
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
            let path = HalftoneCanvas.dots(size: size, t: t, spacing: spacing, exposure: exposure)
            context.fill(
                path,
                with: .linearGradient(Gradient(colors: colors), startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height))
            )
        }
    }

    private static func dots(size: CGSize, t: Double, spacing: CGFloat, exposure: HalftoneExposure) -> Path {
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
                let n = pow(base, exposure.gamma(x: dx, y: dy))
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
