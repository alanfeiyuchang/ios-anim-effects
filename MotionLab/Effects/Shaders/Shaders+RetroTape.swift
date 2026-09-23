import SwiftUI

// Two more "Retro & Print" variations: an ordered 1-bit / Game Boy dither with stop-motion timing,
// and a VHS tape look with per-line wobble, a rolling tracking band and tap-triggered tracking loss.

extension Effect {
    static let shaderDither = Effect(
        id: "shader.dither",
        category: .shaders,
        interaction: .tap,
        name: L("Ordered Dither", "有序抖动"),
        summary: L(
            "A 4×4 Bayer dither turns a living scene into a handheld-console screen — tap to swap palettes.",
            "4×4 Bayer 有序抖动把动态画面变成掌机屏幕，点击切换配色。"
        ),
        prompt: L(
            "A small planet scene — a lit sphere with a sweeping terminator, an orbiting moon and a gradient sky — is rendered through an ordered-dither screen: the image is quantized into 3 pt cells, each cell's luminance is compared against a 4×4 Bayer threshold matrix and snapped to one of four tones on a two-color ramp (Game Boy green by default), so smooth gradients turn into crisp cross-hatch patterns. The scene itself animates on twos, stepping at 12 fps like stop-motion. Tapping swaps the palette (Game Boy → 1-bit Mac → amber terminal → blueprint) with a 'pixel crunch': cells swell by 10 pt in 80 ms, the palette changes at the peak, then they spring back (response 0.45 s, damping 0.8). Nostalgic, graphic and crisp.",
            "一个小行星场景——受光的球体与缓缓扫过的明暗交界线、环绕的卫星、渐变天空——被送进有序抖动网屏：画面先量化为 3pt 像素格，每格亮度与 4×4 Bayer 阈值矩阵比较，吸附到双色渐变上的四个色阶之一（默认 Game Boy 绿），渐变化作清晰的交叉网纹。场景以“一拍二”方式运动，每秒 12 帧逐格步进，像定格动画。点击切换配色（Game Boy → 1-bit Mac → 琥珀终端 → 蓝图），并伴随一次“像素挤压”：80 毫秒内像素格放大 10pt，在峰值处换色，再以弹簧（响应 0.45 秒、阻尼 0.8）回弹。"
        ),
        implementation: L(
            "A [[stitchable]] layer shader samples each cell center, computes a Bayer index with bit operations, quantizes luminance with floor(l·(n−1) + threshold) and maps it onto a dark→light color pair; the source time is floored to 1/12 s and the pixel size is an Animatable value.",
            "[[stitchable]] layerEffect 着色器在每个像素格中心采样，用位运算计算 Bayer 索引，以 floor(l·(n−1) + 阈值) 量化亮度，并映射到暗→亮双色；源画面的时间按 1/12 秒取整，像素尺寸是 Animatable 数值。"
        ),
        apis: ["layerEffect", "Animatable", "Canvas", "ShaderLibrary", "Metal"],
        tags: ["dither", "1-bit", "game boy", "pixel art", "抖动", "像素", "复古", "掌机"],
        params: [
            .slider("pixel", L("Pixel size", "像素尺寸"), 1...8, default: 3, step: 1, decimals: 0, unit: "pt"),
            .slider("levels", L("Tones", "色阶"), 2...6, default: 4, step: 1, decimals: 0),
            .toggle("stopMotion", L("Stop-motion 12 fps", "定格 12 帧"), default: true),
        ]
    ) { ctx in
        DitherDemo(ctx: ctx)
    }

    static let shaderVHS = Effect(
        id: "shader.vhs",
        category: .shaders,
        interaction: .tap,
        name: L("VHS Tape", "VHS 录像带"),
        summary: L(
            "Wobbly scanlines, bleeding color and a rolling tracking band — tap to lose tracking.",
            "抖动的扫描线、溢出的色彩与滚动的跟踪噪带，点击让画面失去跟踪。"
        ),
        prompt: L(
            "A home-video frame with an on-screen display ('▶ PLAY' and a running SP timecode) plays through a worn VHS deck. Every scanline jitters sideways by animated value noise (±1 pt by default), color is delayed 3–6 pt to the right while luminance stays sharp, soft scanlines ripple the brightness by 6%, and the bottom 14 pt shimmer with head-switching noise. A band of tape noise rolls down the frame every ~7.7 s, tearing lines sideways and sprinkling snow in proportion to the tracking error. Tapping loses tracking: the error spikes to full and decays quadratically over 1.2 s while the OSD flips to 'TRACKING', then the picture settles. Warm, lo-fi and nostalgic.",
            "一段带屏显（“▶ PLAY”与不断跳动的 SP 时间码）的家庭录像，通过一台老旧的 VHS 录像机播放。每条扫描线都随动态值噪声左右抖动（默认约 ±1pt），色度向右延迟 3–6pt 而亮度保持清晰，柔和扫描线让亮度起伏 6%，底部 14pt 伴随磁头切换噪声闪烁。一条磁带噪带约每 7.7 秒自上而下滚过画面，按跟踪误差的大小把扫描线撕向一侧并撒下雪花噪点。点击会让画面失去跟踪：误差瞬间拉满，并在 1.2 秒内按二次方回落，屏显同时切换为“TRACKING”，随后画面恢复稳定。温暖、低保真、充满怀旧感。"
        ),
        implementation: L(
            "A [[stitchable]] layer shader offsets each row by noise, band tearing and head-switch sine, samples R and B further right than G and restores the original luma, then mixes in hashed snow and scanlines; tracking = idle + (1 − Δt/1.2)² after a tap.",
            "[[stitchable]] layerEffect 着色器按噪声、噪带撕裂与磁头切换正弦偏移每一行，R 与 B 比 G 更靠右采样后再还原原始亮度，最后混入哈希雪花与扫描线；点击后跟踪误差 = 基础值 + (1 − Δt/1.2)²。"
        ),
        apis: ["layerEffect", "TimelineView", "ShaderLibrary", "onTapGesture", "Metal"],
        tags: ["vhs", "tape", "retro", "tracking", "录像带", "复古", "扫描线", "故障"],
        params: [
            .slider("wobble", L("Line wobble", "行抖动"), 0...6, default: 2, decimals: 1, unit: "pt"),
            .slider("chroma", L("Chroma delay", "色度延迟"), 0...6, default: 3, decimals: 1, unit: "pt"),
            .slider("tracking", L("Idle tracking error", "基础跟踪误差"), 0...1, default: 0.3),
        ]
    ) { ctx in
        VHSDemo(ctx: ctx)
    }
}

// MARK: - Dither

private struct DitherPalette {
    let dark: Color
    let light: Color

    static let all: [DitherPalette] = [
        DitherPalette(dark: Color(hex: 0x0F380F), light: Color(hex: 0x9BBC0F)),
        DitherPalette(dark: Color(hex: 0x111111), light: Color(hex: 0xF2F2F2)),
        DitherPalette(dark: Color(hex: 0x1A0C00), light: Color(hex: 0xFFB000)),
        DitherPalette(dark: Color(hex: 0x0A2463), light: Color(hex: 0xBFE3FF)),
    ]
}

private struct DitherDemo: View {
    let ctx: DemoContext
    @State private var paletteIndex = 0
    @State private var crunch: Double = 0

    var body: some View {
        let pixel = ctx["pixel"]
        let levels = ctx["levels"]
        let stopMotion = ctx.bool("stopMotion")
        let palette = DitherPalette.all[paletteIndex % DitherPalette.all.count]
        VStack(spacing: 14) {
            ShaderClock(preview: ctx.isPreview) { time in
                let sceneTime = stopMotion ? (time * 12).rounded(.down) / 12 : time
                DitherScene(time: sceneTime)
                    .frame(width: 260, height: 300)
                    .modifier(DitherModifier(pixel: pixel + crunch, levels: levels, dark: palette.dark, light: palette.light))
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            }
            .frame(width: 260, height: 300)
            .contentShape(Rectangle())
            .onTapGesture { cycle() }
            DemoHint(text: L("Tap to swap the palette", "点击切换配色"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.4, delay: 0.6) { cycle() }
    }

    /// Pixel crunch: swell for 80 ms, swap the palette at the peak, spring back.
    private func cycle() {
        Haptics.tap(.rigid)
        withAnimation(.easeOut(duration: 0.08)) { crunch = 10 }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(80))
            paletteIndex += 1
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { crunch = 0 }
        }
    }
}

private struct DitherModifier: ViewModifier, Animatable {
    var pixel: Double
    let levels: Double
    let dark: Color
    let light: Color

    var animatableData: Double {
        get { pixel }
        set { pixel = newValue }
    }

    func body(content: Content) -> some View {
        let size = max(pixel, 1)
        content.layerEffect(
            ShaderLibrary.mlDither(.float(size), .float(levels), .color(dark), .color(light)),
            maxSampleOffset: CGSize(width: size, height: size)
        )
    }
}

/// A grayscale-friendly scene with smooth gradients (so the dither has something to chew on).
private struct DitherScene: View {
    let time: Double

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            context.fill(Path(rect), with: .linearGradient(
                Gradient(colors: [Color(white: 0.05), Color(white: 0.45)]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: size.height)
            ))
            let center = CGPoint(x: size.width / 2, y: size.height * 0.46)
            let moonAngle = time * 0.8
            let moon = CGPoint(x: center.x + CGFloat(112 * cos(moonAngle)), y: center.y + CGFloat(34 * sin(moonAngle)))
            let moonBehind = sin(moonAngle) < 0
            if moonBehind { DitherScene.drawMoon(&context, at: moon) }
            DitherScene.drawPlanet(&context, center: center, time: time)
            if !moonBehind { DitherScene.drawMoon(&context, at: moon) }
            context.draw(
                Text(verbatim: "PLANET·01").font(.system(size: 15, weight: .heavy, design: .monospaced)).foregroundStyle(.white),
                at: CGPoint(x: size.width / 2, y: size.height - 30)
            )
        }
    }

    private static func drawPlanet(_ context: inout GraphicsContext, center: CGPoint, time: Double) {
        let radius: CGFloat = 78
        let light = CGPoint(
            x: center.x + CGFloat(50 * cos(time * 0.5)),
            y: center.y - 30 + CGFloat(12 * sin(time * 0.5))
        )
        let disc = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        context.fill(disc, with: .radialGradient(
            Gradient(colors: [.white, Color(white: 0.55), Color(white: 0.08)]),
            center: light,
            startRadius: 0,
            endRadius: radius * 1.7
        ))
        var ring = Path()
        ring.addEllipse(in: CGRect(x: center.x - radius * 1.5, y: center.y - 12, width: radius * 3, height: 24))
        context.stroke(ring, with: .color(Color(white: 0.8)), lineWidth: 3)
    }

    private static func drawMoon(_ context: inout GraphicsContext, at point: CGPoint) {
        let r: CGFloat = 16
        let rect = CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2)
        context.fill(Path(ellipseIn: rect), with: .radialGradient(
            Gradient(colors: [.white, Color(white: 0.3)]),
            center: CGPoint(x: point.x - 5, y: point.y - 5),
            startRadius: 0,
            endRadius: r * 1.6
        ))
    }
}

// MARK: - VHS

private struct VHSDemo: View {
    let ctx: DemoContext
    @State private var burstStart = Date.distantPast

    var body: some View {
        let wobble = ctx["wobble"]
        let chroma = ctx["chroma"]
        let idle = ctx["tracking"]
        VStack(spacing: 14) {
            ShaderClock(preview: ctx.isPreview) { time in
                let burst = VHSDemo.burst(since: burstStart)
                let tracking = min(1, idle + burst)
                let reach = wobble * 0.5 + tracking * 20 + 14 + chroma * 2
                VHSFrame(time: time, lost: burst > 0.05)
                    .layerEffect(
                        ShaderLibrary.mlVHS(
                            .float2(CGSize(width: 260, height: 300)),
                            .float(time),
                            .float(tracking),
                            .float(wobble),
                            .float(chroma)
                        ),
                        maxSampleOffset: CGSize(width: reach, height: 0)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            }
            .frame(width: 260, height: 300)
            .contentShape(Rectangle())
            .onTapGesture { loseTracking() }
            DemoHint(text: L("Tap to lose tracking", "点击让画面失去跟踪"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 3.2, delay: 0.8) { loseTracking() }
    }

    /// (1 − Δt/1.2)² for 1.2 s after a tap, else 0.
    private static func burst(since start: Date) -> Double {
        let elapsed = Date().timeIntervalSince(start)
        guard elapsed >= 0, elapsed < 1.2 else { return 0 }
        let k = 1 - elapsed / 1.2
        return k * k
    }

    private func loseTracking() {
        Haptics.tap(.heavy)
        burstStart = Date()
    }
}

private struct VHSFrame: View {
    let time: Double
    let lost: Bool

    var body: some View {
        ZStack {
            ShaderArtwork(variant: 7)
            VStack(alignment: .leading) {
                Text(verbatim: lost ? "TRACKING" : "▶ PLAY")
                Spacer()
                Text(verbatim: VHSFrame.timecode(time))
                    .monospacedDigit()
            }
            .font(.system(size: 15, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.5), radius: 0, x: 1, y: 1)
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(width: 260, height: 300)
    }

    private static func timecode(_ time: Double) -> String {
        let total = Int(time) + 754
        let minutes = (total / 60) % 60
        let seconds = total % 60
        return String(format: "SP 0:%02d:%02d", minutes, seconds)
    }
}
