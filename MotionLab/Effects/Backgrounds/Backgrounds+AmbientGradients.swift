import SwiftUI

// Three more "Mesh & Ambient Gradients" variations, each with its own motion style:
// Conic Halo (angular momentum + friction), Light Leak (additive film sweeps + exposure flicker)
// and Wave Band (a traveling wave through a slanted mesh band that jiggles on tap).

extension Effect {
    static let backgroundsConicHalo = Effect(
        id: "backgrounds.conic-halo",
        category: .backgrounds,
        interaction: .tap,
        name: L("Conic Halo", "锥形光环"),
        summary: L(
            "Two blurred conic gradients counter-rotate into a glowing halo — tap to spin it up.",
            "两层模糊锥形渐变反向旋转，形成发光光环；点击即可让它加速飞转。"
        ),
        prompt: L(
            "A near-black stage holds a luminous halo built from two heavily blurred conic (angular) gradients: a 300 pt outer disc turning clockwise at about 0.35 rad/s (≈ 18 s per turn) and a 190 pt inner disc turning the other way at 60% of that speed, added with a plus-lighter blend, plus a crisp 1.5 pt conic ring and a dark blurred core that hollows the center. Tapping injects angular momentum: +7 rad/s (capped at 16) that bleeds away through exponential friction (≈ 1.6/s, half-life ≈ 0.43 s), so the halo whips around, swells up to 6% and brightens its ring, then coasts smoothly back to its idle drift with a soft haptic. It feels like a flywheel of light — focused, calm and physical.",
            "近乎纯黑的舞台中央，是由两层重度模糊的锥形渐变构成的发光光环：外层 300pt 圆盘以约 0.35 rad/s（约 18 秒一圈）顺时针旋转，内层 190pt 圆盘以其 60% 的速度反向旋转，以 plus-lighter 叠加；再加一圈 1.5pt 的清晰锥形细环与一个掏空中心的模糊暗核。点击注入角动量 +7 rad/s（上限 16），按指数摩擦（约 1.6/s，半衰期约 0.43 秒）流失：光环猛地甩转、最多放大 6%、细环同时变亮，再平滑滑回闲置漂移，伴随柔和触感。像一只由光构成的飞轮。"
        ),
        implementation: L(
            "A small model integrates angle += (base + boost)·dt each TimelineView frame and decays boost by exp(−friction·dt); two blurred AngularGradient circles, a stroked ring and a dark core are composited in one drawingGroup.",
            "小型模型在每个 TimelineView 帧中积分 angle += (base + boost)·dt，并以 exp(−friction·dt) 衰减 boost；两个模糊的 AngularGradient 圆、一圈描边细环与暗核在同一个 drawingGroup 中合成。"
        ),
        apis: ["AngularGradient", "TimelineView(.animation)", "rotationEffect", "blendMode(.plusLighter)", "drawingGroup"],
        tags: ["conic", "angular gradient", "halo", "spin", "锥形渐变", "光环", "旋转", "角动量"],
        params: [
            .slider("speed", L("Idle speed", "闲置转速"), 0.2...3.0, default: 1.0, unit: "×"),
            .slider("friction", L("Friction", "摩擦"), 0.6...4.0, default: 1.6, decimals: 1, unit: "/s"),
            .slider("blur", L("Softness", "柔化"), 10...60, default: 34, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        ConicHaloDemo(ctx: ctx)
    }

    static let backgroundsLightLeak = Effect(
        id: "backgrounds.light-leak",
        category: .backgrounds,
        interaction: .tap,
        name: L("Film Light Leak", "胶片漏光"),
        summary: L(
            "Warm analog light leaks sweep across the frame with a gentle exposure flicker — tap to burn.",
            "温暖的胶片漏光斜扫过画面，伴随轻微曝光闪烁；点击制造一次烧光。"
        ),
        prompt: L(
            "A dark, moody photo-like frame is crossed by four large, heavily blurred light leaks (36 pt blur) in amber, coral, magenta and cream. Each leak is a tilted ellipse that makes a long linear pass across the frame every 7–11 s, alternating left-to-right and right-to-left and entering at a new height each pass; its intensity follows sin²(π·progress), so it swells in and dies away without edges, and a white-hot inner core rides along. Leaks add with a plus-lighter blend so overlaps bloom. The whole layer flickers like a projector at 12 steps per second (up to ±8% around a 90% exposure). Tapping burns the film: a warm full-frame wash flashes in and fades exponentially (time constant ≈ 0.45 s). Nostalgic, analog and cinematic.",
            "一张深色、带情绪的“照片”上，四道重度模糊（36pt）的大面积漏光斜扫而过，颜色为琥珀、珊瑚、洋红与奶油白。每道漏光是一个倾斜的椭圆，每 7–11 秒线性横穿画面一次，方向左右交替，每次从新的高度进入；亮度遵循 sin²(π·进度)，无边界地渐起渐灭，内部跟着一团白热光芯。漏光以 plus-lighter 叠加，重叠处自然溢光。整层像放映机一样以每秒 12 步闪烁（以 90% 曝光为中心最多 ±8%）。点击会“烧片”：暖色全屏光晕瞬间亮起，以约 0.45 秒的时间常数指数衰减。怀旧而富有电影感。"
        ),
        implementation: L(
            "A Canvas with a blur filter and plus-lighter blend mode fills rotated ellipse Paths whose position and envelope come from accumulated time; exposure is a stepped hash of time, and the burn envelope is exp(−Δt·2.2) since the last tap.",
            "带模糊滤镜与 plus-lighter 混合模式的 Canvas 填充旋转椭圆 Path，其位置与包络由累积时间计算；曝光闪烁是时间的阶梯哈希，烧光包络为距上次点击的 exp(−Δt·2.2)。"
        ),
        apis: ["Canvas", "GraphicsContext.blendMode", "Path.applying(_:)", "TimelineView(.animation)", "Haptics"],
        tags: ["light leak", "film", "analog", "vintage", "漏光", "胶片", "复古", "电影感"],
        params: [
            .choice("palette", L("Film stock", "胶片风格"), [L("Warm", "暖调"), L("Cine", "电影冷调"), L("Rose", "玫瑰")]),
            .slider("speed", L("Sweep speed", "扫过速度"), 0.3...2.5, default: 1.0, unit: "×"),
            .slider("flicker", L("Flicker", "闪烁"), 0...1, default: 0.5),
        ]
    ) { ctx in
        LightLeakDemo(ctx: ctx)
    }

    static let backgroundsWaveBand = Effect(
        id: "backgrounds.wave-band",
        category: .backgrounds,
        interaction: .tap,
        name: L("Slanted Wave Band", "斜切波浪色带"),
        summary: L(
            "A slanted band of mesh gradient carries a traveling wave — tap and it jiggles like jelly.",
            "斜切的网格渐变色带中有一道行进波流过，点击后像果冻一样抖动。"
        ),
        prompt: L(
            "A landing-page hero: the top of the stage is a 4×3 mesh gradient of violet, pink, orange, amber, cyan and teal, clipped into a band whose lower edge slants down from right to left; below it sits the plain system background with a headline in primary text. Instead of wandering, the mesh's middle row carries a traveling wave — each column's vertex rises and falls on the same sine, 1.4 rad behind its left neighbor (≈ 4.8 s period at 1×) — so color crests roll across the band, while interior vertices sway ±7% sideways. Tapping hits the band: the wave amplitude kicks up by ~130% within ~0.15 s and rings out as a damped oscillation (decay 2.4/s, 9 rad/s), dipping to about half its resting height once before settling, like jelly. Confident, colorful and modern.",
            "一个落地页首屏：舞台上方是由紫、粉、橙、琥珀、青与蓝绿组成的 4×3 网格渐变，被裁成一条下边缘从右向左斜向下的色带，下方是系统背景与一行主色标题。网格不四处游走，而是在中间一行承载行进波：每列顶点沿同一正弦上下起伏，比左侧相邻列滞后 1.4 弧度（1× 时周期约 4.8 秒），色彩波峰从色带上滚过，内部顶点同时左右摇摆 ±7%。点击色带会“敲”它一下：波幅 0.15 秒内冲高约 130%，再以阻尼振荡（衰减 2.4/s、9 rad/s）回落，途中一度跌到常态一半，像果冻般稳定下来。自信、鲜艳、现代。"
        ),
        implementation: L(
            "MeshGradient(width: 4, height: 3) gets its 12 points from a traveling-wave function of accumulated time; the amplitude is multiplied by 1 + 1.3·e^(−2.4t)·cos(9t) after a tap, and a custom slanted Shape clips the band.",
            "MeshGradient(width: 4, height: 3) 的 12 个点由基于累积时间的行进波函数得出；点击后波幅乘以 1 + 1.3·e^(−2.4t)·cos(9t)，再用自定义斜切 Shape 裁出色带。"
        ),
        apis: ["MeshGradient", "TimelineView(.animation)", "Shape", "clipShape", "onTapGesture"],
        tags: ["mesh", "wave", "hero", "landing page", "网格渐变", "波浪", "首屏", "果冻"],
        params: [
            .slider("amplitude", L("Wave height", "波高"), 0.04...0.22, default: 0.12),
            .slider("speed", L("Wave speed", "波速"), 0.2...2.5, default: 1.0, unit: "×"),
            .slider("slant", L("Slant", "倾斜度"), 0...0.5, default: 0.3),
        ]
    ) { ctx in
        WaveBandDemo(ctx: ctx)
    }
}

// MARK: - Conic halo

private struct HaloState {
    let angle: Double
    let counter: Double
    let energy: Double
}

private final class HaloModel {
    let clock = BackgroundClock()
    private var angle: Double = 0
    private var counter: Double = 0
    private var boost: Double = 0
    /// Energy as drawn: eases toward the momentum-derived target (rate 14/s, ≈ 70 ms), so a kick swells the
    /// halo's scale and ring instead of popping them in one frame.
    private var shownEnergy: Double = 0

    func step(now: Double, speed: Double, friction: Double) -> HaloState {
        clock.advance(to: now, speed: 1)
        let dt = clock.delta
        boost *= exp(-dt * friction)
        let base = 0.35 * speed
        angle += (base + boost) * dt
        counter -= (base * 0.6 + boost * 0.45) * dt
        let energy = min(boost / 9, 1)
        shownEnergy += (energy - shownEnergy) * clock.follow(rate: 14)
        return HaloState(angle: angle, counter: counter, energy: shownEnergy)
    }

    func kick() {
        boost = min(boost + 7, 16)
    }
}

private struct ConicHaloDemo: View {
    let ctx: DemoContext
    @State private var model = HaloModel()

    var body: some View {
        let speed = ctx["speed"]
        let friction = ctx["friction"]
        let blur = ctx.cg("blur")
        ZStack {
            Color(hex: 0x07060F)
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let state = model.step(now: timeline.date.timeIntervalSinceReferenceDate, speed: speed, friction: friction)
                HaloLayers(state: state, blur: blur)
            }
            BackgroundSampleTitle(
                title: L("Focus", "专注"),
                subtitle: L("25:00 · Deep work", "25:00 · 深度工作"),
                language: ctx.language,
                size: 30
            )
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.tap(.soft)
            model.kick()
        }
        .autoplay(ctx.isPreview, every: 3.0, delay: 0.8) { model.kick() }
        .backgroundsHint(L("Tap to spin up the halo", "点击让光环加速"), ctx)
    }
}

private struct HaloLayers: View {
    let state: HaloState
    let blur: CGFloat

    private static let outer: [Color] = [
        Color(hex: 0x6E7BFF), Color(hex: 0xFF5FA2), Color(hex: 0xFFC247), Color(hex: 0x21D4A8), Color(hex: 0x6E7BFF),
    ]
    private static let inner: [Color] = [
        Color(hex: 0xA46BFF), Color(hex: 0x3AC4FF), Color(hex: 0xFF7A5C), Color(hex: 0xA46BFF),
    ]

    var body: some View {
        let energy = state.energy
        ZStack {
            Circle()
                .fill(AngularGradient(colors: Self.outer, center: .center))
                .frame(width: 300, height: 300)
                .rotationEffect(.radians(state.angle))
                .blur(radius: blur)
                .opacity(0.9)
            Circle()
                .fill(AngularGradient(colors: Self.inner, center: .center))
                .frame(width: 190, height: 190)
                .rotationEffect(.radians(state.counter))
                .blur(radius: blur * 0.6)
                .blendMode(.plusLighter)
            Circle()
                .strokeBorder(AngularGradient(colors: Self.outer, center: .center), lineWidth: 1.5)
                .frame(width: 222, height: 222)
                .rotationEffect(.radians(state.angle * 1.5))
                .opacity(0.35 + 0.5 * energy)
            Circle()
                .fill(Color(hex: 0x07060F))
                .frame(width: 118, height: 118)
                .blur(radius: 18)
        }
        .scaleEffect(1 + 0.06 * energy)
        .drawingGroup()
    }
}

// MARK: - Light leak

private enum LeakPalette {
    static func colors(_ index: Int) -> [Color] {
        let hexes: [UInt32]
        switch index {
        case 1: hexes = [0x6FD6FF, 0x7B61FF, 0xFF8FB1, 0xC8F0FF]
        case 2: hexes = [0xFF9AC9, 0xFFC2A1, 0xD37BFF, 0xFFE6F0]
        default: hexes = [0xFFB347, 0xFF6A3D, 0xFF3D7F, 0xFFE3B0]
        }
        return hexes.map { Color(hex: $0) }
    }
}

private final class LeakModel {
    let clock = BackgroundClock()
    var burnStart: Double = -100

    func burn(at now: Double) -> Double {
        let e = now - burnStart
        guard e >= 0 else { return 0 }
        return exp(-e * 2.2)
    }
}

private struct LightLeakDemo: View {
    let ctx: DemoContext
    @State private var model = LeakModel()

    var body: some View {
        let colors = LeakPalette.colors(ctx.int("palette"))
        let speed = ctx["speed"]
        let flicker = ctx["flicker"]
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x1A0F14), Color(hex: 0x2B1A22), Color(hex: 0x0E0B10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let t = model.clock.advance(to: now, speed: speed)
                LeakCanvas(t: t, colors: colors, flicker: flicker, burn: model.burn(at: now))
            }
            BackgroundSampleTitle(
                title: L("Golden Hour", "黄金时刻"),
                subtitle: L("Shot on film · 35 mm", "胶片拍摄 · 35 毫米"),
                language: ctx.language,
                size: 30
            )
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.tap(.medium)
            burn()
        }
        .autoplay(ctx.isPreview, every: 4.0, delay: 1.2) { burn() }
        .backgroundsHint(L("Tap to burn the film", "点击烧光胶片"), ctx)
    }

    private func burn() {
        model.burnStart = Date().timeIntervalSinceReferenceDate
    }
}

private struct LeakCanvas: View {
    let t: Double
    let colors: [Color]
    let flicker: Double
    let burn: Double

    var body: some View {
        Canvas { context, size in
            let step = Int((t * 12).rounded(.down))
            let jitter = (BackgroundMath.rand(step, 45) - 0.5) * 2
            // Centred on 90% so the flicker swings both ways (±8% at full flicker) instead of only dimming.
            let exposure = (0.9 + flicker * 0.08 * jitter).clamped(to: 0...1)
            context.opacity = exposure
            context.blendMode = .plusLighter
            context.addFilter(.blur(radius: 36))
            for index in 0..<4 {
                LeakCanvas.drawLeak(&context, size: size, index: index, t: t, color: colors[index % colors.count])
            }
            if burn > 0.002 {
                let wash = Color(hex: 0xFFB36B).opacity(0.55 * burn)
                context.fill(Path(CGRect(origin: .zero, size: size).insetBy(dx: -40, dy: -40)), with: .color(wash))
            }
        }
    }

    private static func drawLeak(_ context: inout GraphicsContext, size: CGSize, index: Int, t: Double, color: Color) {
        let period = 7.0 + 4.0 * BackgroundMath.rand(index, 41)
        let cycle = t / period + BackgroundMath.rand(index, 42)
        let p = BackgroundMath.fract(cycle)
        let seed = index * 31 + Int(cycle.rounded(.down))
        let wave = sin(p * .pi)
        let envelope = wave * wave
        let travel: Double = index % 2 == 0 ? (-0.4 + 1.8 * p) : (1.4 - 1.8 * p)
        let x = CGFloat(travel) * size.width
        let y = size.height * CGFloat(0.15 + 0.7 * BackgroundMath.rand(seed, 43))
        let angle = CGFloat(-0.5 + 0.35 * BackgroundMath.rand(seed, 44))
        let length = size.width * CGFloat(0.8 + 0.5 * BackgroundMath.rand(seed, 46))
        let thickness = size.height * CGFloat(0.22 + 0.2 * BackgroundMath.rand(seed, 47))
        let rect = CGRect(x: -length / 2, y: -thickness / 2, width: length, height: thickness)
        let transform = CGAffineTransform(translationX: x, y: y).rotated(by: angle)
        context.fill(Path(ellipseIn: rect).applying(transform), with: .color(color.opacity(0.75 * envelope)))
        let core = rect.insetBy(dx: length * 0.3, dy: thickness * 0.3)
        context.fill(Path(ellipseIn: core).applying(transform), with: .color(Color.white.opacity(0.35 * envelope)))
    }
}

// MARK: - Slanted wave band

private enum BandMesh {
    private static let hexes: [UInt32] = [
        0x7A5CFF, 0xFF5FA2, 0xFF7A45, 0xFFC247,
        0x3AC4FF, 0xA46BFF, 0xFF4D7A, 0xFF9A3D,
        0x21D4A8, 0x4F7CFF, 0xB86BFF, 0xFF5FA2,
    ]
    static let colors: [Color] = hexes.map { Color(hex: $0) }

    static func points(t: Double, amplitude: Double) -> [SIMD2<Float>] {
        var result: [SIMD2<Float>] = []
        result.reserveCapacity(12)
        for row in 0..<3 {
            for col in 0..<4 {
                var x = Double(col) / 3
                var y = Double(row) / 2
                if col > 0 && col < 3 {
                    x += 0.07 * sin(t * 0.8 + Double(col) * 1.9 + Double(row))
                }
                if row == 1 {
                    y += amplitude * sin(t * 1.3 - Double(col) * 1.4)
                }
                result.append(SIMD2<Float>(Float(x), Float(y)))
            }
        }
        return result
    }
}

private final class BandModel {
    let clock = BackgroundClock()
    /// Extra amplitude (0 at rest) and its velocity: a damped oscillator with decay 2.4/s and 9 rad/s.
    private var ring: Double = 0
    private var ringVelocity: Double = 0

    /// Returns accumulated time and the amplitude multiplier (1 at rest).
    func step(now: Double, speed: Double) -> (t: Double, gain: Double) {
        let t = clock.advance(to: now, speed: speed)
        // x'' = −(9² + 2.4²)·x − 2·2.4·x′, i.e. x = A·e^(−2.4t)·sin(9t) after an impulse; fixed substeps keep it stable.
        var remaining = clock.delta
        while remaining > 0 {
            let dt = min(remaining, 1.0 / 240.0)
            ringVelocity += (-(81 + 5.76) * ring - 4.8 * ringVelocity) * dt
            ring += ringVelocity * dt
            remaining -= dt
        }
        if abs(ring) < 0.0005 && abs(ringVelocity) < 0.005 {
            ring = 0
            ringVelocity = 0
        }
        return (t, max(1 + ring, 0))
    }

    /// A hit is an impulse, not a jump: the amplitude kicks up to about +130% within ~0.15 s (A·0.68 with A = 1.91),
    /// dips to about half its resting height once, then settles. A second hit adds to whatever is still ringing.
    func hit() {
        ringVelocity += 1.91 * 9
    }
}

private struct SlantedBand: Shape {
    var slant: CGFloat

    func path(in rect: CGRect) -> Path {
        let right = rect.minY + rect.height * (0.6 - slant / 2)
        let left = rect.minY + rect.height * (0.6 + slant / 2)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: right))
        path.addLine(to: CGPoint(x: rect.minX, y: left))
        path.closeSubpath()
        return path
    }
}

private struct WaveBandDemo: View {
    let ctx: DemoContext
    @State private var model = BandModel()

    var body: some View {
        let amplitude = ctx["amplitude"]
        let speed = ctx["speed"]
        ZStack(alignment: .bottomLeading) {
            Color(uiColor: .systemBackground)
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let state = model.step(now: timeline.date.timeIntervalSinceReferenceDate, speed: speed)
                MeshGradient(
                    width: 4,
                    height: 3,
                    // Capped so the middle row can never cross rows 0 and 2 and fold the mesh.
                    points: BandMesh.points(t: state.t, amplitude: min(amplitude * state.gain, 0.4)),
                    colors: BandMesh.colors
                )
            }
            .clipShape(SlantedBand(slant: ctx.cg("slant")))
            headline
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.tap(.soft)
            hit()
        }
        .autoplay(ctx.isPreview, every: 3.2, delay: 0.8) { hit() }
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L("Build what's next", "构建下一步"), ctx.language)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.primary)
            Text(L("Tap the band to make it ring", "点击色带让它抖动起来"), ctx.language)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .opacity(ctx.isPreview ? 0 : 1)
        }
        .padding(22)
        .allowsHitTesting(false)
    }

    private func hit() {
        model.hit()
    }
}
