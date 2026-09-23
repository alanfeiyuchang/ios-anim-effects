import SwiftUI

// MARK: - Skeleton shimmer

extension Effect {
    static let loadingSkeleton = Effect(
        id: "loading.skeleton-shimmer",
        category: .loading,
        interaction: .tap,
        name: L("Skeleton Shimmer", "骨架屏微光"),
        summary: L("Placeholder shapes with a diagonal sheen that dissolve into real content.", "占位骨架带斜向流光，再柔和溶解为真实内容。"),
        prompt: L(
            "A content card rendered as neutral skeleton blocks — a 110 pt hero image, a 40 pt avatar, two title bars and body lines — all at 8% label-color opacity with continuous rounded corners. A soft diagonal highlight band, tilted roughly 35° off vertical, sweeps left to right every 1.4 s, masked so it only lights up the placeholder shapes; it uses white at 70% in light mode and 14% in dark mode. When the data arrives, the skeleton fades out while the real card fades in from an 8 pt blur and 98% scale over a 0.5 s smooth curve, keeping the exact same layout so nothing jumps.",
            "一张以中性骨架块呈现的内容卡片——110 pt 的头图、40 pt 头像、两条标题条与若干正文行，全部为 8% 文字色、连续圆角。一条偏离竖直约 35° 的柔和斜向高光带每 1.4 秒从左向右扫过，并被遮罩限制只照亮占位形状；浅色模式用 70% 白，深色模式用 14% 白。数据到达时骨架淡出，真实卡片从 8 pt 模糊、98% 缩放，经 0.5 秒平滑曲线浮现，布局与骨架完全一致，没有任何跳动。"
        ),
        implementation: L(
            "A TimelineView moves a LinearGradient's start/end points; the gradient is masked by the same skeleton layout, and loaded content cross-fades with blur.",
            "TimelineView 移动线性渐变的起止点，并用同一骨架布局作遮罩；加载完成后真实内容以模糊交叉淡入。"
        ),
        apis: ["TimelineView", "LinearGradient", "mask(alignment:_:)", "blur(radius:)"],
        tags: ["skeleton", "shimmer", "placeholder", "content loading", "骨架屏", "微光", "占位", "加载"],
        params: [
            .slider("speed", L("Sweep speed", "扫光速度"), 0.4...2.5, default: 1.0),
            .slider("band", L("Band width", "光带宽度"), 0.15...0.6, default: 0.3),
            .slider("angle", L("Tilt", "倾斜"), 0...0.6, default: 0.25),
        ]
    ) { ctx in
        SkeletonDemo(ctx: ctx)
    }
}

private struct SkeletonDemo: View {
    let ctx: DemoContext
    @State private var loaded = false

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                SkeletonLayout(tint: Color.primary.opacity(0.08))
                    .overlay {
                        ShimmerBand(speed: ctx["speed"], band: ctx["band"], tilt: ctx["angle"])
                            .mask { SkeletonLayout(tint: .black) }
                    }
                    .opacity(loaded ? 0 : 1)
                SkeletonLoadedCard(language: ctx.language)
                    .opacity(loaded ? 1 : 0)
                    .blur(radius: loaded ? 0 : 8)
                    .scaleEffect(loaded ? 1 : 0.98)
            }
            .padding(16)
            .frame(width: 280)
            .demoCard()
            DemoHint(text: L("Tap to toggle loaded state", "点击切换加载状态"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { toggle() }
        .autoplay(ctx.isPreview, every: 2.6, delay: 1.6) { toggle() }
    }

    private func toggle() {
        withAnimation(.smooth(duration: 0.5)) { loaded.toggle() }
    }
}

private struct SkeletonLayout: View {
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(tint)
                .frame(height: 110)
            HStack(spacing: 12) {
                Circle().fill(tint).frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 8) {
                    Capsule().fill(tint).frame(width: 130, height: 10)
                    Capsule().fill(tint).frame(width: 84, height: 10)
                }
            }
            PlaceholderLines(count: 2, color: tint)
        }
    }
}

private struct SkeletonLoadedCard: View {
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Palette.sunset)
                .frame(height: 110)
                .overlay {
                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.9))
                }
            HStack(spacing: 12) {
                Circle()
                    .fill(Palette.ocean)
                    .frame(width: 40, height: 40)
                    .overlay { Text("ML").font(.caption.weight(.bold)).foregroundStyle(.white) }
                VStack(alignment: .leading, spacing: 2) {
                    Text(language == .zh ? "极光工作室" : "Aurora Studio").font(.subheadline.weight(.semibold))
                    Text(language == .zh ? "2 分钟前" : "2 min ago").font(.caption).foregroundStyle(.secondary)
                }
            }
            Text(language == .zh ? "新的设计系统已发布，快来看看动效规范。" : "Our new design system is live — check out the motion specs.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct ShimmerBand: View {
    let speed: Double
    let band: Double
    let tilt: Double
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let peak = Color.white.opacity(scheme == .dark ? 0.14 : 0.7)
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate * speed
            let x = (t / 1.4).truncatingRemainder(dividingBy: 1) * (1.4 + band * 2) - 0.2 - band
            LinearGradient(
                stops: [
                    .init(color: peak.opacity(0), location: 0),
                    .init(color: peak, location: 0.5),
                    .init(color: peak.opacity(0), location: 1),
                ],
                startPoint: UnitPoint(x: x - band, y: 0.5 - tilt),
                endPoint: UnitPoint(x: x + band, y: 0.5 + tilt)
            )
        }
    }
}

// MARK: - Audio wave bars

extension Effect {
    static let loadingAudioWave = Effect(
        id: "loading.audio-wave",
        category: .loading,
        interaction: .loop,
        name: L("Audio Wave Bars", "音频波形条"),
        summary: L("Rounded bars pulse like a live voice waveform.", "圆角竖条如实时语音波形般起伏。"),
        prompt: L(
            "A voice-capture card: a pulsing red dot, 'Listening…' and a tabular elapsed timer on top, a live transcript line underneath. At its heart, 13 rounded 7 pt bars with 6 pt gaps share one continuous vertical gradient (violet → sky → mint). Each bar's height is driven by two layered sine waves at different frequencies and phase offsets, shaped by a bell-curve envelope so the center bars swing tallest and the edges stay calm — organic, live speech rather than a mechanical equalizer. Bars grow symmetrically from the center line, or optionally from the baseline, while the record dot breathes between 100% and 35% opacity every 0.8 s.",
            "一张语音采集卡片：顶部是脉动的红色录音点、“正在聆听…”与等宽计时器，底部是一行实时转写文字。卡片中央是 13 根 7 pt 宽的圆角竖条，间距 6 pt，整组共用一条连续的竖向渐变（紫罗兰 → 天蓝 → 薄荷绿）。每根竖条的高度由两道频率、相位不同的正弦波叠加驱动，再乘以钟形包络：中间摆幅最大、两侧较平静——像真实的实时语音，而非机械的均衡器。竖条默认从中线对称伸缩，也可改为从底线生长；录音点每 0.8 秒在 100% 与 35% 透明度之间呼吸。"
        ),
        implementation: L(
            "A TimelineView computes each bar height; the bars form a mask over a single LinearGradient so the color spans the group. A periodic TimelineView ticks the timer and phaseAnimator pulses the record dot.",
            "TimelineView 计算每根竖条高度，竖条作为遮罩覆盖在同一条线性渐变上，使颜色贯穿整组；周期性 TimelineView 驱动计时器，phaseAnimator 让录音点脉动。"
        ),
        apis: ["TimelineView", "mask(alignment:_:)", "LinearGradient", "phaseAnimator"],
        tags: ["audio", "waveform", "voice", "equalizer", "音频", "波形", "语音", "均衡器"],
        params: [
            .slider("count", L("Bars", "竖条数"), 5...19, default: 13, step: 1, decimals: 0),
            .slider("speed", L("Speed", "速度"), 0.3...2.0, default: 1.0),
            .slider("height", L("Max height", "最大高度"), 30...110, default: 80, decimals: 0, unit: "pt"),
            .toggle("mirror", L("Center aligned", "居中对称"), default: true),
        ]
    ) { ctx in
        AudioWaveDemo(ctx: ctx)
    }
}

private struct AudioWaveDemo: View {
    let ctx: DemoContext
    @State private var start = Date()

    private var zh: Bool { ctx.language == .zh }

    var body: some View {
        VStack(spacing: 18) {
            header
            AudioBars(
                count: max(ctx.int("count"), 1),
                speed: ctx["speed"],
                maxHeight: ctx.cg("height"),
                centered: ctx.bool("mirror")
            )
            .frame(height: 110)
            Text(zh ? "“把明早的站会改到十点……”" : "“Move tomorrow's standup to ten…”")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .frame(width: 292)
        .demoCard(cornerRadius: 26)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Palette.red)
                .frame(width: 8, height: 8)
                .phaseAnimator([1.0, 0.35]) { content, level in
                    content.opacity(level)
                } animation: { _ in
                    .easeInOut(duration: 0.8)
                }
            Text(zh ? "正在聆听…" : "Listening…")
                .font(.subheadline.weight(.semibold))
            Spacer(minLength: 8)
            TimelineView(.periodic(from: start, by: 1)) { context in
                Text(AudioWaveDemo.clock(context.date.timeIntervalSince(start)))
                    .font(.subheadline.weight(.medium).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    static func clock(_ elapsed: TimeInterval) -> String {
        let total = max(Int(elapsed), 0) % 600
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

private struct AudioBars: View {
    let count: Int
    let speed: Double
    let maxHeight: CGFloat
    let centered: Bool

    private let barWidth: CGFloat = 7
    private let gap: CGFloat = 6

    var body: some View {
        let total = CGFloat(count) * barWidth + CGFloat(max(count - 1, 0)) * gap
        LinearGradient(colors: [Palette.violet, Palette.sky, Palette.mint], startPoint: .top, endPoint: .bottom)
            .frame(width: total, height: maxHeight)
            .mask {
                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 10_000) * speed
                    HStack(alignment: centered ? .center : .bottom, spacing: gap) {
                        ForEach(0..<count, id: \.self) { index in
                            Capsule()
                                .frame(width: barWidth, height: max(barWidth, maxHeight * AudioBars.level(t, index: index, count: count)))
                        }
                    }
                    .frame(width: total, height: maxHeight, alignment: centered ? .center : .bottom)
                }
            }
    }

    static func level(_ t: Double, index: Int, count: Int) -> CGFloat {
        let i = Double(index)
        let envelope = 0.3 + 0.7 * sin(.pi * (i + 0.5) / Double(count))
        let wave = 0.5 + 0.28 * sin(t * 5.1 + i * 0.8) + 0.22 * sin(t * 7.7 - i * 1.3)
        return CGFloat(min(max(envelope * wave, 0.05), 1))
    }
}

// MARK: - Pulse rings

extension Effect {
    static let loadingPulseRings = Effect(
        id: "loading.pulse-rings",
        category: .loading,
        interaction: .loop,
        name: L("Radar Pulse", "雷达脉冲"),
        summary: L("Concentric rings ripple out from a glowing core.", "同心圆环从发光核心向外涟漪扩散。"),
        prompt: L(
            "A 72 pt gradient core disc with a white antenna glyph and a soft colored shadow sits at the center. Three rings are emitted from behind it in an even stagger across a 2.2 s period; each expands from the core's edge to about 2.6× its size on a quadratic ease-out, its tinted fill fading from 18% to 0 and its 1.5 pt hairline stroke from 60% to 0. The core breathes subtly (±3%). Over a 6 s scene, three nearby-device avatars (40 pt, white rim) pop onto the radar one after another, 1.1 s apart, on a back-out curve that overshoots ~10%, then all fade together before the search restarts, under a 'Looking for nearby devices…' caption. Calm and hopeful, like AirDrop discovery.",
            "中心是一枚 72 pt 的渐变圆形核心，内含白色天线图标并带柔和彩色投影。三圈圆环在 2.2 秒周期内均匀错峰地从核心背后发出：每圈以二次缓出从核心边缘扩大到约 2.6 倍，着色填充从 18% 淡到 0，1.5 pt 细描边从 60% 淡到 0；核心本身轻微呼吸（±3%）。在 6 秒一轮的场景中，三枚附近设备的头像（40 pt、白色描边）每隔 1.1 秒依次以回弹曲线“啵”地出现在雷达上，约有 10% 过冲，随后一起淡出、重新开始搜索；下方写着“正在查找附近的设备…”。平静而充满期待，就像隔空投送的发现过程。"
        ),
        implementation: L(
            "A TimelineView derives each ring's normalized age from a shared clock plus index offset and maps it to frame size and opacity; peer avatars use a back-out easing of the same clock for their pop-in.",
            "TimelineView 由共享时钟加索引偏移得到每圈的归一化“年龄”，再映射为尺寸与透明度；设备头像用同一时钟的回弹缓动实现弹出。"
        ),
        apis: ["TimelineView", "Circle", "strokeBorder", "shadow"],
        tags: ["radar", "pulse", "ripple", "searching", "雷达", "脉冲", "涟漪", "搜索"],
        params: [
            .slider("count", L("Rings", "圆环数"), 1...5, default: 3, step: 1, decimals: 0),
            .slider("period", L("Period", "周期"), 1.0...4.0, default: 2.2, decimals: 1, unit: "s"),
            .slider("spread", L("Spread", "扩散倍数"), 1.5...3.5, default: 2.6, decimals: 1, unit: "×"),
            .choice("tint", L("Tint", "色调"), [L("Ocean", "海洋"), L("Mint", "薄荷"), L("Coral", "珊瑚")], default: 0),
        ]
    ) { ctx in
        VStack(spacing: 14) {
            PulseRingsView(
                count: max(ctx.int("count"), 1),
                period: ctx["period"],
                spread: ctx.cg("spread"),
                tint: [Palette.blue, Palette.mint, Palette.coral][min(max(ctx.int("tint"), 0), 2)]
            )
            .frame(width: 260, height: 250)
            Text(ctx.language == .zh ? "正在查找附近的设备…" : "Looking for nearby devices…")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct PulseRingsView: View {
    let count: Int
    let period: Double
    let spread: CGFloat
    let tint: Color

    private let core: CGFloat = 72

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 10_000)
            ZStack {
                ForEach(0..<count, id: \.self) { index in
                    ring(age: ((t / period) + Double(index) / Double(count)).truncatingRemainder(dividingBy: 1))
                }
                ForEach(0..<PulsePeer.all.count, id: \.self) { index in
                    peer(index, t: t)
                }
                coreDisc(breath: 1 + 0.03 * sin(t * 2 * .pi / period))
            }
        }
    }

    private func peer(_ index: Int, t: Double) -> some View {
        let spec = PulsePeer.all[index]
        let state = PulsePeer.state(t, index: index)
        let angle = spec.angle * Double.pi / 180
        return Text(spec.initials)
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 40, height: 40)
            .background(LinearGradient(colors: spec.colors, startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
            .overlay { Circle().strokeBorder(.white, lineWidth: 2.5) }
            .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
            .scaleEffect(state.scale)
            .opacity(state.opacity)
            .offset(x: CGFloat(cos(angle)) * 100, y: CGFloat(sin(angle)) * 100)
    }

    private func ring(age: Double) -> some View {
        let eased = 1 - (1 - age) * (1 - age)
        let side = core + (core * spread - core) * CGFloat(eased)
        return Circle()
            .fill(tint.opacity(0.18 * (1 - age)))
            .overlay { Circle().strokeBorder(tint.opacity(0.6 * (1 - age)), lineWidth: 1.5) }
            .frame(width: side, height: side)
    }

    private func coreDisc(breath: Double) -> some View {
        Circle()
            .fill(LinearGradient(colors: [tint.opacity(0.75), tint], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: core, height: core)
            .overlay {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .shadow(color: tint.opacity(0.45), radius: 14, y: 6)
            .scaleEffect(breath)
    }
}

private struct PulsePeer {
    let initials: String
    let colors: [Color]
    /// Position on the radar, in degrees (0° = 3 o'clock, clockwise).
    let angle: Double

    static let all: [PulsePeer] = [
        PulsePeer(initials: "MJ", colors: [Palette.pink, Palette.coral], angle: -145),
        PulsePeer(initials: "DK", colors: [Palette.mint, Palette.sky], angle: -30),
        PulsePeer(initials: "AN", colors: [Palette.amber, Palette.coral], angle: 105),
    ]

    /// Staggered back-out pop-in over a 6 s scene, then a shared fade before the loop restarts.
    static func state(_ t: Double, index: Int) -> (scale: CGFloat, opacity: Double) {
        let local = t.truncatingRemainder(dividingBy: 6)
        let a = min(max((local - 0.8 - Double(index) * 1.1) / 0.45, 0), 1)
        let out = min(max((6 - local) / 0.45, 0), 1)
        let c1 = 1.70158
        let c3 = c1 + 1
        let back = a <= 0 ? 0 : 1 + c3 * pow(a - 1, 3) + c1 * pow(a - 1, 2)
        return (CGFloat(back) * CGFloat(0.85 + 0.15 * out), min(a * 2, 1) * out)
    }
}

// MARK: - Morphing square grid

extension Effect {
    static let loadingSquareGrid = Effect(
        id: "loading.square-grid",
        category: .loading,
        interaction: .loop,
        name: L("Morphing Grid", "形变方格"),
        summary: L("A 3×3 grid that ripples between squares and dots diagonally.", "3×3 方格沿对角线在方块与圆点间涟漪形变。"),
        prompt: L(
            "A 3×3 grid of 26 pt tiles with 8 pt gutters, shown at 1.55× and tinted by one mint → sky → violet gradient spanning the whole grid, over a blurred aurora glow that breathes between 25% and 45% opacity. Each tile continuously morphs between a full rounded square (6 pt corners, 100% scale, 0°) and a small circle (45% scale, rotated 90°) on a cosine wave with a 1.6 s period. The phase is delayed 120 ms per diagonal step (row + column), so a soft ripple rolls from the top-left corner to the bottom-right. Corner radius, scale and rotation interpolate together, like a single breathing material.",
            "3×3 方格，每格 26 pt、间距 8 pt，以 1.55 倍显示，整组共用一条薄荷绿 → 天蓝 → 紫罗兰渐变着色，身后是一团在 25% 与 45% 透明度之间呼吸的模糊极光辉光。每个方格沿 1.6 秒周期的余弦波，在完整圆角方块（6 pt 圆角、100% 大小、0°）与小圆点（45% 大小、旋转 90°）之间连续形变。相位按对角线步数（行 + 列）每步延迟 120 毫秒，于是一道柔和涟漪从左上角滚向右下角。圆角、缩放与旋转同步插值，仿佛整块材质在一起呼吸。"
        ),
        implementation: L(
            "A TimelineView computes a per-tile cosine value from the diagonal index and maps it to cornerRadius, scale and rotation; the grid masks one gradient.",
            "TimelineView 按对角线索引计算每格余弦值，映射为圆角、缩放与旋转；整组方格遮罩同一条渐变。"
        ),
        apis: ["TimelineView", "RoundedRectangle", "mask(alignment:_:)", "rotationEffect"],
        tags: ["grid", "morph", "squares", "ripple", "方格", "形变", "涟漪", "加载"],
        params: [
            .slider("period", L("Period", "周期"), 0.8...3.0, default: 1.6, decimals: 1, unit: "s"),
            .slider("stagger", L("Stagger", "错峰"), 0...0.3, default: 0.12, unit: "s"),
            .slider("minScale", L("Min scale", "最小缩放"), 0.2...0.9, default: 0.45),
        ]
    ) { ctx in
        SquareGridView(period: ctx["period"], stagger: ctx["stagger"], minScale: ctx.cg("minScale"))
            .background {
                Circle()
                    .fill(Palette.aurora)
                    .frame(width: 170, height: 170)
                    .blur(radius: 44)
                    .phaseAnimator([0.25, 0.45]) { content, level in
                        content.opacity(level)
                    } animation: { _ in
                        .easeInOut(duration: 1.6)
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct SquareGridView: View {
    let period: Double
    let stagger: Double
    let minScale: CGFloat

    private let cell: CGFloat = 26
    private let gap: CGFloat = 8

    var body: some View {
        let side = cell * 3 + gap * 2
        LinearGradient(colors: [Palette.mint, Palette.sky, Palette.violet], startPoint: .topLeading, endPoint: .bottomTrailing)
            .frame(width: side, height: side)
            .mask {
                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 10_000)
                    VStack(spacing: gap) {
                        ForEach(0..<3, id: \.self) { row in
                            HStack(spacing: gap) {
                                ForEach(0..<3, id: \.self) { column in
                                    tile(morph(t, diagonal: row + column))
                                }
                            }
                        }
                    }
                }
            }
            .scaleEffect(1.55)
    }

    private func morph(_ t: Double, diagonal: Int) -> CGFloat {
        let phase = (t - Double(diagonal) * stagger) / period * 2 * .pi
        return CGFloat(0.5 - 0.5 * cos(phase))
    }

    /// m = 1 → rounded square, m = 0 → small circle.
    private func tile(_ m: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 6 + (cell / 2 - 6) * (1 - m), style: .continuous)
            .frame(width: cell, height: cell)
            .scaleEffect(minScale + (1 - minScale) * m)
            .rotationEffect(.degrees(Double(1 - m) * 90))
    }
}
