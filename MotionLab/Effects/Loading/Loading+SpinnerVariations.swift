import SwiftUI

// MARK: - Helpers

private func spinVarFrac(_ x: Double) -> Double { x - floor(x) }

/// A phase (in cycles) that advances at `rate` per second and stays continuous when the rate changes.
private struct SpinVarPhaseClock {
    var anchorDate = Date()
    var anchorPhase: Double = 0

    func phase(at date: Date, rate: Double) -> Double {
        anchorPhase + date.timeIntervalSince(anchorDate) * rate
    }

    mutating func rebase(at date: Date, oldRate: Double) {
        anchorPhase = phase(at: date, rate: oldRate)
        anchorDate = date
    }
}

/// A settle curve that overshoots once and lands exactly on 1 at u = 1.
private func spinVarSettle(_ u: Double, overshoot: Double) -> Double {
    let x = min(max(u, 0), 1)
    let decay: Double = -3 * log(max(overshoot, 0.005))
    let wobble: Double = exp(-decay * x) * cos(3 * .pi * x)
    return 1 - wobble * (1 - x * x * x)
}

/// Caption block shared by the spinner compositions.
private struct SpinnerCaption: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
    }
}

// MARK: - Gooey orbit

extension Effect {
    static let loadingGooeyOrbit = Effect(
        id: "loading.gooey-orbit",
        category: .loading,
        interaction: .loop,
        name: L("Gooey Orbit", "黏滴轨道"),
        summary: L("Satellite drops pull out of a liquid core and melt back in as it turns.", "卫星液滴从液态核心中拉出，旋转着又融回去。"),
        prompt: L(
            "A 52 pt liquid core sits at the center of a 150 pt stage, painted with a mint → sky → violet gradient. Three 22 pt satellite drops orbit it once every 4.8 s; each drop also swings its distance from 8 pt to 40 pt and back on its own cosine, staggered by a third of a cycle, so drops take turns stretching a sticky neck out of the core, snapping free, and melting back in. The metaball look comes from blurring the shapes by 8 pt and thresholding the alpha at 50%. The core breathes ±6% with the rhythm. Shown above 'Looking for nearby devices' and three placeholder avatars that pulse. Viscous, organic, calm.",
            "150 pt 画布中央是一颗 52 pt 的液态核心，填充薄荷绿 → 天蓝 → 紫罗兰渐变。三颗 22 pt 的卫星液滴每 4.8 秒绕它公转一圈，同时各自按余弦把与核心的距离在 8 pt 与 40 pt 之间往返，彼此错开三分之一个周期：液滴轮流从核心里拉出一段黏稠的“颈”，挣脱，再慢慢融回去。黏滴效果来自对形状做 8 pt 模糊后按 50% 透明度阈值裁切。核心随节奏呼吸 ±6%。下方是“正在查找附近设备”和三个脉动的占位头像。黏稠、有机、从容。"
        ),
        implementation: L(
            "A TimelineView feeds the time into a Canvas that stacks alphaThreshold on blur (the metaball trick); the Canvas masks a LinearGradient.",
            "TimelineView 把时间传给 Canvas，Canvas 在图层上叠加 alphaThreshold 与 blur 滤镜（经典 metaball 手法），再作为 LinearGradient 的遮罩。"
        ),
        apis: ["Canvas", "GraphicsContext.Filter.alphaThreshold", "GraphicsContext.Filter.blur", "TimelineView", "mask"],
        tags: ["gooey", "metaball", "liquid", "spinner", "黏滴", "融球", "液态", "加载"],
        params: [
            .slider("period", L("Orbit time", "公转周期"), 2...8, default: 4.8, decimals: 1, unit: "s"),
            .slider("goo", L("Gooeyness", "黏稠度"), 4...14, default: 8, decimals: 0, unit: "pt"),
            .slider("count", L("Drops", "液滴数"), 2...5, default: 3, step: 1, decimals: 0),
        ]
    ) { ctx in
        GooeyOrbitDemo(ctx: ctx)
    }
}

private struct GooeyOrbitDemo: View {
    let ctx: DemoContext

    var body: some View {
        let zh = ctx.language == .zh
        VStack(spacing: 18) {
            GooeyOrbitView(period: ctx["period"], goo: ctx.cg("goo"), count: max(ctx.int("count"), 1), preview: ctx.isPreview)
                .frame(width: 150, height: 150)
            SpinnerCaption(
                title: zh ? "正在查找附近设备" : "Looking for nearby devices",
                detail: zh ? "请保持设备解锁并靠近" : "Keep devices unlocked and close by"
            )
            GooeyAvatarRow()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct GooeyAvatarRow: View {
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: 30, height: 30)
                    .phaseAnimator([false, true]) { content, lit in
                        content.opacity(lit ? 1 : 0.45)
                    } animation: { _ in
                        .easeInOut(duration: 0.9).delay(Double(index) * 0.2)
                    }
            }
        }
    }
}

private struct GooeyOrbitView: View {
    let period: Double
    let goo: CGFloat
    let count: Int
    let preview: Bool
    @State private var clock = SpinVarPhaseClock()

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview))) { timeline in
            // Seconds on a clock that runs at 1 / period and is rescaled back, so changing the
            // period keeps the blobs where they are.
            let t: Double = clock.phase(at: timeline.date, rate: 1 / max(period, 0.1)) * period
            LinearGradient(colors: [Palette.mint, Palette.sky, Palette.violet], startPoint: .topLeading, endPoint: .bottomTrailing)
                .mask {
                    Canvas { context, size in
                        context.addFilter(.alphaThreshold(min: 0.5, color: .white))
                        context.addFilter(.blur(radius: goo))
                        context.drawLayer { layer in
                            for rect in GooeyOrbitView.blobs(t: t, period: period, count: count, size: size) {
                                layer.fill(Path(ellipseIn: rect), with: .color(.white))
                            }
                        }
                    }
                    .blur(radius: 0.6)
                    .drawingGroup()
                }
        }
        .onChange(of: period) { old, _ in clock.rebase(at: .now, oldRate: 1 / max(old, 0.1)) }
    }

    static func blobs(t: Double, period: Double, count: Int, size: CGSize) -> [CGRect] {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let reachPeriod: Double = period / 2
        let breath: Double = cos(2 * .pi * t / reachPeriod)
        let core: CGFloat = 26 * CGFloat(1 + 0.06 * breath)
        var rects: [CGRect] = [CGRect(x: center.x - core, y: center.y - core, width: core * 2, height: core * 2)]
        let spin: Double = 2 * .pi * t / period
        for index in 0..<count {
            let share: Double = Double(index) / Double(count)
            let swing: Double = 0.5 - 0.5 * cos(2 * .pi * (t / reachPeriod + share))
            let distance: CGFloat = 8 + 32 * CGFloat(swing)
            let angle: Double = spin + share * 2 * .pi
            let x: CGFloat = center.x + distance * CGFloat(cos(angle))
            let y: CGFloat = center.y + distance * CGFloat(sin(angle))
            let r: CGFloat = 11
            rects.append(CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
        }
        return rects
    }
}

// MARK: - Gyroscope

extension Effect {
    static let loadingGyroscope = Effect(
        id: "loading.gyroscope",
        category: .loading,
        interaction: .loop,
        name: L("Gyroscope Rings", "陀螺仪圆环"),
        summary: L("Three rings tumble on different 3D axes around a glowing core.", "三只圆环绕不同的 3D 轴翻滚，环抱一颗发光核心。"),
        prompt: L(
            "Three 120 pt hairline rings (2.5 pt, mint, sky and violet) tumble in true perspective around a 22 pt glowing core: the first turns about the X axis once per 2.4 s, the second about Y once per 3.2 s, the third about a diagonal axis once per 4.0 s, so they cross and uncross like a gimbal and never repeat the same silhouette. The core breathes 0.9 → 1.1 every 1.2 s with a soft sky bloom. Beneath, a 'Calibrating motion sensors' caption and three X / Y / Z readouts drift in monospaced digits. Precise, scientific, weightless.",
            "三只 120 pt 的细线圆环（线宽 2.5 pt，薄荷绿、天蓝、紫罗兰）在真实透视中围绕一颗 22 pt 的发光核心翻滚：第一只绕 X 轴每 2.4 秒一圈，第二只绕 Y 轴每 3.2 秒一圈，第三只绕对角轴每 4.0 秒一圈，于是它们像万向节一样交叠又分开，轮廓永不重复。核心每 1.2 秒在 0.9 → 1.1 间呼吸，带柔和的天蓝辉光。下方是“正在校准运动传感器”说明与三组等宽数字的 X / Y / Z 读数缓缓漂移。精密、科学、失重般轻盈。"
        ),
        implementation: L(
            "A TimelineView computes three angles per frame and applies rotation3DEffect with perspective to stroked circles; the readouts are sines of the same clock.",
            "TimelineView 每帧计算三个角度，对描边圆施加带透视的 rotation3DEffect；读数取自同一时钟的正弦值。"
        ),
        apis: ["TimelineView", "rotation3DEffect(_:axis:perspective:)", "Circle().stroke", "monospacedDigit()"],
        tags: ["gyroscope", "3d", "rings", "calibrate", "陀螺仪", "三维", "圆环", "校准"],
        params: [
            .slider("speed", L("Speed", "速度"), 0.3...2.0, default: 1.0),
            .slider("perspective", L("Perspective", "透视"), 0...1, default: 0.6),
            .toggle("glow", L("Core glow", "核心辉光"), default: true),
        ]
    ) { ctx in
        GyroscopeDemo(ctx: ctx)
    }
}

private struct GyroscopeDemo: View {
    let ctx: DemoContext

    var body: some View {
        let zh = ctx.language == .zh
        VStack(spacing: 20) {
            GyroscopeView(speed: ctx["speed"], perspective: ctx.cg("perspective"), glow: ctx.bool("glow"), preview: ctx.isPreview)
                .frame(width: 150, height: 150)
            SpinnerCaption(
                title: zh ? "正在校准运动传感器" : "Calibrating motion sensors",
                detail: zh ? "请将设备平放" : "Keep your device on a flat surface"
            )
            GyroReadouts(speed: ctx["speed"])
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct GyroscopeView: View {
    let speed: Double
    let perspective: CGFloat
    let glow: Bool
    let preview: Bool
    @State private var clock = SpinVarPhaseClock()

    private let colors: [Color] = [Palette.mint, Palette.sky, Palette.violet]
    private let periods: [Double] = [2.4, 3.2, 4.0]
    private let axes: [(x: CGFloat, y: CGFloat, z: CGFloat)] = [(1, 0, 0), (0, 1, 0), (1, 1, 0.3)]

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview))) { timeline in
            let t: Double = clock.phase(at: timeline.date, rate: speed)
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    ring(index: index, t: t)
                }
                core(t: t)
            }
        }
        .onChange(of: speed) { old, _ in clock.rebase(at: .now, oldRate: old) }
    }

    private func ring(index: Int, t: Double) -> some View {
        let degrees: Double = spinVarFrac(t / periods[index]) * 360
        return Circle()
            .stroke(colors[index], lineWidth: 2.5)
            .frame(width: 120, height: 120)
            .rotation3DEffect(.degrees(degrees), axis: axes[index], perspective: perspective)
    }

    private func core(t: Double) -> some View {
        let breath: CGFloat = 1 + 0.1 * CGFloat(sin(2 * .pi * t / 1.2))
        return Circle()
            .fill(Palette.aurora)
            .frame(width: 22, height: 22)
            .scaleEffect(breath)
            .shadow(color: Palette.sky.opacity(glow ? 0.7 : 0), radius: 12)
    }
}

private struct GyroReadouts: View {
    let speed: Double

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.12)) { timeline in
            let t: Double = timeline.date.timeIntervalSinceReferenceDate * speed
            HStack(spacing: 16) {
                readout("X", value: sin(t * 1.3) * 0.42)
                readout("Y", value: cos(t * 0.9) * 0.37)
                readout("Z", value: sin(t * 0.7 + 1) * 0.12 + 0.98)
            }
        }
    }

    private func readout(_ axis: String, value: Double) -> some View {
        HStack(spacing: 4) {
            Text(axis)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(String(format: "%+.2f", value))
                .font(.caption.weight(.semibold).monospacedDigit())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.primary.opacity(0.06), in: Capsule())
    }
}

// MARK: - Flip tile

extension Effect {
    static let loadingFlipTile = Effect(
        id: "loading.flip-tile",
        category: .loading,
        interaction: .loop,
        name: L("Spring Flip Tile", "弹簧翻转方块"),
        summary: L("A tile flips 180° on alternating axes, overshooting and settling each beat.", "方块交替绕两轴翻转 180°，每一拍都过冲再落定。"),
        prompt: L(
            "A 64 pt continuous-corner tile flips 180° every 0.9 s beat, alternating between the X and Y axes, in 0.8-perspective 3D. Each flip follows a spring-like settle that overshoots by about 10% and rings once before landing exactly flat, then the next beat starts. The tile's color advances through indigo → violet → pink → amber at the instant it is edge-on, so the change is hidden inside the motion. While flipping, the tile lifts to 112% scale and its contact shadow below shrinks and fades, then both return as it lands. Captioned 'Building your workspace'. Playful, rhythmic, tactile.",
            "一块 64 pt 的连续圆角方块每 0.9 秒一拍翻转 180°，在 X 轴与 Y 轴之间交替，透视系数 0.8。每次翻转都像弹簧落定：约过冲 10%、回摆一次后恰好平躺，下一拍随即开始。方块在侧面朝向镜头的一瞬间切换颜色（靛蓝 → 紫罗兰 → 粉 → 琥珀），把换色藏进动作里。翻转时方块抬升到 112%，下方接触阴影随之缩小变淡，落地时一起复原。配文“正在搭建你的工作区”。俏皮、有节奏、有触感。"
        ),
        implementation: L(
            "A TimelineView splits time into beats and maps each beat through a damped-cosine settle curve that is forced to land at 1; rotation3DEffect alternates its axis per beat.",
            "TimelineView 将时间切成节拍，每拍经过阻尼余弦落定曲线（强制在终点等于 1）映射为角度；rotation3DEffect 每拍交替旋转轴。"
        ),
        apis: ["TimelineView", "rotation3DEffect(_:axis:perspective:)", "RoundedRectangle(style: .continuous)", "scaleEffect"],
        tags: ["flip", "tile", "3d", "bounce", "翻转", "方块", "弹簧", "加载"],
        params: [
            .slider("beat", L("Beat", "节拍"), 0.5...1.6, default: 0.9, decimals: 1, unit: "s"),
            .slider("overshoot", L("Overshoot", "过冲"), 0...0.3, default: 0.1),
            .slider("size", L("Tile size", "方块大小"), 40...90, default: 64, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        FlipTileDemo(ctx: ctx)
    }
}

private struct FlipTileDemo: View {
    let ctx: DemoContext

    var body: some View {
        let zh = ctx.language == .zh
        VStack(spacing: 26) {
            FlipTileView(beat: max(ctx["beat"], 0.2), overshoot: ctx["overshoot"], side: ctx.cg("size"), preview: ctx.isPreview)
                .frame(width: 140, height: 140)
            SpinnerCaption(
                title: zh ? "正在搭建你的工作区" : "Building your workspace",
                detail: zh ? "导入模板与成员…" : "Importing templates and members…"
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct FlipTileView: View {
    let beat: Double
    let overshoot: Double
    let side: CGFloat
    let preview: Bool
    @State private var clock = SpinVarPhaseClock()

    private let colors: [Color] = [Palette.indigo, Palette.violet, Palette.pink, Palette.amber]

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview))) { timeline in
            let t: Double = clock.phase(at: timeline.date, rate: 1 / beat)
            let index: Int = Int(floor(t))
            let u: Double = t - floor(t)
            let angle: Double = 180 * spinVarSettle(u, overshoot: overshoot)
            let lift: CGFloat = CGFloat(sin(.pi * min(u * 1.6, 1)))
            let passed: Int = angle > 90 ? 1 : 0
            let color: Color = colors[(index + passed) % colors.count]
            let axis: (x: CGFloat, y: CGFloat, z: CGFloat) = index % 2 == 0 ? (1, 0, 0) : (0, 1, 0)
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: side * 0.28, style: .continuous)
                    .fill(color.gradient)
                    .overlay { Circle().fill(.white.opacity(0.9)).frame(width: side * 0.22, height: side * 0.22) }
                    .frame(width: side, height: side)
                    .rotation3DEffect(.degrees(angle), axis: axis, perspective: 0.8)
                    .scaleEffect(1 + 0.12 * lift)
                    .offset(y: -14 * lift)
                    .shadow(color: color.opacity(0.35), radius: 12, y: 8)
                Ellipse()
                    .fill(Color.primary.opacity(0.14 - 0.08 * Double(lift)))
                    .frame(width: side * (0.9 - 0.3 * lift), height: 8)
                    .blur(radius: 3)
                    .padding(.top, 14)
            }
        }
        .onChange(of: beat) { old, _ in clock.rebase(at: .now, oldRate: 1 / old) }
    }
}

// MARK: - Infinity comet

extension Effect {
    static let loadingInfinityComet = Effect(
        id: "loading.infinity-comet",
        category: .loading,
        interaction: .loop,
        name: L("Infinity Comet", "无限彗星"),
        summary: L("A glowing head races a figure-eight, trailing a tapering tail of light.", "发光的彗头沿 8 字轨迹奔跑，身后拖着渐细的光尾。"),
        prompt: L(
            "Between an iPhone glyph and an Apple Watch glyph, a faint 160 × 40 pt lemniscate (∞) track hints at the path. A 9 pt glowing head travels the figure-eight once every 2.2 s, speeding through the crossing and easing through the loops, followed by a tail of 32 samples that taper from full size to 15% and fade from 100% to 0% while their color slides from sky through violet to pink, so the path paints itself and dissolves. Each device glyph glows when the head swings past its side. Captioned 'Pairing…'. Fluid, continuous, a little magical.",
            "iPhone 与 Apple Watch 两个图标之间，一条 160 × 40 pt 的淡色双纽线（∞）轨道暗示路径。9 pt 的发光彗头每 2.2 秒沿 8 字跑完一圈，经过交叉点时加速、绕弯时放缓；身后跟着 32 个采样点组成的尾巴，从满尺寸渐细到 15%、透明度从 100% 渐隐到 0%，颜色由天蓝经紫罗兰滑向粉色——轨迹边画边消散。彗头摆到哪一侧，那一侧的设备图标就微微发光。配文“正在配对…”。流畅、连绵、带点魔法感。"
        ),
        implementation: L(
            "A TimelineView evaluates a parametric lemniscate with a speed-warped phase; a Canvas draws the fading tail samples and a blurred head.",
            "TimelineView 用变速相位计算参数化双纽线；Canvas 绘制渐隐的尾部采样点与模糊的彗头。"
        ),
        apis: ["TimelineView", "Canvas", "Path(ellipseIn:)", "GraphicsContext.addFilter(.blur)"],
        tags: ["infinity", "comet", "trail", "pairing", "无限", "彗星", "拖尾", "配对"],
        params: [
            .slider("period", L("Lap time", "单圈时长"), 1...4, default: 2.2, decimals: 1, unit: "s"),
            .slider("trail", L("Tail length", "尾巴长度"), 8...60, default: 32, step: 1, decimals: 0),
            .toggle("glow", L("Glow", "辉光"), default: true),
        ]
    ) { ctx in
        InfinityCometDemo(ctx: ctx)
    }
}

private struct InfinityCometDemo: View {
    let ctx: DemoContext
    @State private var clock = SpinVarPhaseClock()

    var body: some View {
        let zh = ctx.language == .zh
        let period: Double = max(ctx["period"], 0.3)
        VStack(spacing: 26) {
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let phase: Double = spinVarFrac(clock.phase(at: timeline.date, rate: 1 / period))
                let side: Double = cos(InfinityPath.warp(phase) * 2 * .pi)
                HStack(spacing: 6) {
                    device("iphone", lit: side < -0.6)
                    InfinityCanvas(phase: phase, trail: max(ctx.int("trail"), 2), glow: ctx.bool("glow"))
                        .frame(width: 176, height: 72)
                    device("applewatch", lit: side > 0.6)
                }
            }
            SpinnerCaption(
                title: zh ? "正在配对…" : "Pairing…",
                detail: zh ? "请让手表靠近 iPhone" : "Hold your watch near your iPhone"
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: ctx["period"]) { old, _ in clock.rebase(at: .now, oldRate: 1 / max(old, 0.3)) }
    }

    private func device(_ symbol: String, lit: Bool) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 28, weight: .regular))
            .foregroundStyle(lit ? AnyShapeStyle(Palette.sky) : AnyShapeStyle(Color.secondary))
            .shadow(color: Palette.sky.opacity(lit ? 0.6 : 0), radius: 8)
            .animation(.easeOut(duration: 0.3), value: lit)
            .frame(width: 34)
    }
}

private enum InfinityPath {
    /// Faster through the crossing, slower through the loops.
    static func warp(_ u: Double) -> Double {
        u - 0.05 * sin(4 * .pi * u)
    }

    static func point(_ u: Double, in size: CGSize) -> CGPoint {
        let theta: Double = warp(u) * 2 * .pi
        let s: Double = sin(theta)
        let c: Double = cos(theta)
        let denom: Double = 1 + s * s
        let x: Double = c / denom
        let y: Double = s * c / denom
        let halfW: Double = Double(size.width) / 2 - 8
        let halfH: Double = Double(size.height) - 16
        let px: CGFloat = size.width / 2 + CGFloat(x * halfW)
        let py: CGFloat = size.height / 2 + CGFloat(y * halfH)
        return CGPoint(x: px, y: py)
    }
}

/// Sky → violet → pink, interpolated continuously along the tail so the colour slides instead of banding.
private func infinityTailColor(_ f: Double) -> Color {
    let stops: [UInt32] = [0x3AC4FF, 0xA46BFF, 0xFF5FA2]
    let u: Double = min(max(f, 0), 1) * Double(stops.count - 1)
    let i: Int = min(Int(u), stops.count - 2)
    let t: Double = u - Double(i)
    let a: UInt32 = stops[i]
    let b: UInt32 = stops[i + 1]
    let r: Double = Double((a >> 16) & 0xFF) + (Double((b >> 16) & 0xFF) - Double((a >> 16) & 0xFF)) * t
    let g: Double = Double((a >> 8) & 0xFF) + (Double((b >> 8) & 0xFF) - Double((a >> 8) & 0xFF)) * t
    let bl: Double = Double(a & 0xFF) + (Double(b & 0xFF) - Double(a & 0xFF)) * t
    return Color(.sRGB, red: r / 255, green: g / 255, blue: bl / 255, opacity: 1)
}

private struct InfinityCanvas: View {
    let phase: Double
    let trail: Int
    let glow: Bool

    var body: some View {
        Canvas { context, size in
            var track = Path()
            for step in 0...120 {
                let p = InfinityPath.point(Double(step) / 120, in: size)
                if step == 0 { track.move(to: p) } else { track.addLine(to: p) }
            }
            context.stroke(track, with: .color(.primary.opacity(0.08)), lineWidth: 3)
            for i in stride(from: trail - 1, through: 0, by: -1) {
                let f: Double = Double(i) / Double(trail)
                let p = InfinityPath.point(spinVarFrac(phase - f * 0.35), in: size)
                let r: CGFloat = 4.5 * CGFloat(1 - 0.85 * f)
                let color: Color = infinityTailColor(f)
                let rect = CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)
                context.fill(Path(ellipseIn: rect), with: .color(color.opacity(1 - f)))
            }
            let head = InfinityPath.point(phase, in: size)
            if glow {
                var halo = context
                halo.addFilter(.blur(radius: 8))
                halo.fill(Path(ellipseIn: CGRect(x: head.x - 10, y: head.y - 10, width: 20, height: 20)), with: .color(Palette.sky.opacity(0.8)))
            }
            context.fill(Path(ellipseIn: CGRect(x: head.x - 4.5, y: head.y - 4.5, width: 9, height: 9)), with: .color(glow ? Color.white : Palette.sky))
        }
    }
}
