import SwiftUI

extension Effect {
    static let shaderPixelate = Effect(
        id: "shader.pixelate",
        category: .shaders,
        interaction: .tap,
        name: L("Pixelate Swap", "像素化切换"),
        summary: L("Content dissolves into pixels, swaps, and resolves again.", "内容碎成像素块、替换后再重新清晰。"),
        prompt: L(
            "Tapping the card transitions its content through a mosaic: the image quantizes into progressively larger square cells (1 → ≈28 pt) over ≈375 ms with an ease-in curve; at peak coarseness the two scenes cross-fade under the mosaic for 80 ms, so the swap reads as blocks changing color rather than a hard cut, then the cells shrink back to full resolution over ≈410 ms with an ease-out. The effect reads like a retro game scene cut, precise and digital, while staying perfectly smooth because cell size animates continuously.",
            "点击卡片时，内容通过马赛克完成切换：画面在约 375 毫秒内以 ease-in 曲线量化为逐渐变大的方形像素块（1 → 约 28pt），在最粗糙时两幅画面于马赛克之下交叉淡化 80 毫秒，切换看起来只是色块变色而非生硬跳切，随后在约 410 毫秒内以 ease-out 曲线收缩回完整清晰度。效果如同复古游戏的场景切换，精准而数字化，同时因像素尺寸连续插值而保持丝滑。"
        ),
        implementation: L(
            "A Metal layer shader samples the center of each cell of a ZStack holding both scenes. The cell size lives in an Animatable ViewModifier: animated up, the scenes cross-fade for 80 ms at peak, then it animates down.",
            "Metal layerEffect 对叠放两幅画面的 ZStack 按像素格中心采样；像素尺寸存放在 Animatable ViewModifier 中：先动画放大，在峰值处两幅画面交叉淡化 80 毫秒，再动画缩小。"
        ),
        apis: ["layerEffect", "Animatable", "withAnimation", "Metal"],
        tags: ["pixelate", "mosaic", "retro", "transition", "像素", "马赛克", "复古", "转场"],
        params: [
            .slider("maxSize", L("Max cell size", "最大像素尺寸"), 8...48, default: 28, decimals: 0, unit: "pt"),
            .slider("duration", L("Duration", "时长"), 0.3...1.6, default: 0.75, unit: "s"),
        ]
    ) { ctx in
        PixelateDemo(ctx: ctx)
    }

    static let shaderDissolve = Effect(
        id: "shader.dissolve",
        category: .shaders,
        interaction: .tap,
        name: L("Burn Dissolve", "燃烧溶解"),
        summary: L("Noise-driven disintegration with a glowing ember edge.", "由噪声驱动、带发光余烬边缘的溶解消散。"),
        prompt: L(
            "The card disintegrates into nothing along an organic fractal-noise mask: as progress runs from 0 to 1 over ≈1.2 s (ease-in-out), pixels whose noise value falls below the moving threshold vanish behind a smooth, anti-aliased cut, and just inside it a thin ember ramp runs white-hot → edge color → charred brown before the untouched artwork, like paper burning away. Tapping again reverses the process so the card re-materializes from the ashes. The edge stays clean yet irregular, conveying a dramatic, magical deletion.",
            "卡片沿着有机的分形噪声遮罩逐渐消散：进度在约 1.2 秒内（ease-in-out）从 0 推进到 1，噪声值低于移动阈值的像素在平滑抗锯齿的切口后消失；切口内侧是一窄条余烬渐变——白热 → 边缘色 → 焦褐——再过渡回未受影响的画面，如同纸张被火焰烧尽。再次点击则反向播放，卡片从灰烬中重新凝聚。边缘干净却不规则，传达出戏剧化、带魔法感的删除动作。"
        ),
        implementation: L(
            "A Metal color shader compares 4-octave value noise against an animated threshold, smoothsteps alpha across a tiny band for an anti-aliased cut and maps the distance above it to a white-hot → edge → char ramp; progress is an Animatable modifier value.",
            "Metal colorEffect 将 4 层倍频值噪声与动画阈值比较，在极窄区间内 smoothstep 透明度得到抗锯齿切口，并把高出阈值的距离映射为白热 → 边缘色 → 焦褐的渐变；进度由 Animatable modifier 插值。"
        ),
        apis: ["colorEffect", "Animatable", "fbm noise", "Metal"],
        tags: ["dissolve", "burn", "disintegrate", "delete", "溶解", "燃烧", "消散", "删除"],
        params: [
            .slider("scale", L("Noise scale", "噪声尺度"), 6...60, default: 24, decimals: 0),
            .slider("duration", L("Duration", "时长"), 0.4...3, default: 1.2, unit: "s"),
            .choice("edge", L("Edge color", "边缘颜色"), [L("Ember", "余烬"), L("Plasma", "等离子"), L("Frost", "冰霜")]),
        ]
    ) { ctx in
        DissolveDemo(ctx: ctx)
    }

    static let shaderGlitch = Effect(
        id: "shader.glitch",
        category: .shaders,
        interaction: .loop,
        name: L("RGB Glitch", "RGB 故障"),
        summary: L("Digital macro-block corruption with an RGB split, and a tap-triggered datamosh burst.", "数字宏块损坏叠加 RGB 分离，点击触发一次数据错乱爆发。"),
        prompt: L(
            "A digital, codec-style glitch rather than an analog tape fault: the red and blue channels sit a few points apart for a permanent chromatic fringe, and the image is cut into 12 pt macro-blocks. Six times per second a fresh set of 4 × 2-block clusters is corrupted: each hit block either jumps to a neighbouring block in 2D (offsets quantized to half a block) or freezes into vertical streaks of its own top row, and some swap their color channels, like a broken P-frame. About 12% of clusters are hit at rest. A tap spikes the intensity to maximum for 400 ms: more blocks break, the split widens and the palette posterizes to four levels, then it snaps back. Motion is deliberately steppy and unsmoothed, yet sparse enough to stay legible.",
            "偏数字编解码而非模拟磁带的故障效果：红、蓝通道错开数个点，形成常驻的色差边缘；画面被切成 12pt 的宏块。每秒六次重新挑选若干 4 × 2 宏块的簇进行“损坏”：命中的宏块要么在二维方向跳到相邻宏块（位移按半个宏块量化），要么冻结成自身顶行拉出的竖向条纹，部分还会交换颜色通道，如同丢失的 P 帧。静止时约 12% 的簇受损。点击会让强度拉满 400 毫秒：更多宏块破碎、色差加宽、色阶压成四级，随后骤然恢复。运动刻意呈阶跃、不做平滑，但足够稀疏以保持可读。"
        ),
        implementation: L(
            "A Metal layer shader hashes macro-block clusters per time step, remaps hit blocks by a quantized 2D jump or a frozen top-row smear, samples R/G/B at split offsets and posterizes near full intensity; TimelineView supplies time.",
            "Metal layerEffect 按时间步对宏块簇做哈希，命中的宏块按量化的二维跳跃或冻结顶行拖影重映射采样，再以分离偏移分别采样 R/G/B，并在强度接近满值时做色阶压缩；时间由 TimelineView 提供。"
        ),
        apis: ["layerEffect", "TimelineView", "hash noise", "Metal"],
        tags: ["glitch", "datamosh", "chromatic aberration", "cyberpunk", "故障", "数据错乱", "色差", "赛博朋克"],
        params: [
            .slider("intensity", L("Intensity", "强度"), 0...1, default: 0.35),
            .slider("split", L("RGB split", "RGB 分离"), 0...12, default: 4, decimals: 1, unit: "pt"),
            .slider("slice", L("Block size", "宏块尺寸"), 6...24, default: 12, decimals: 0, unit: "pt"),
            .slider("rate", L("Re-roll rate", "重随机频率"), 2...12, default: 6, decimals: 0, unit: "/s"),
        ]
    ) { ctx in
        GlitchDemo(ctx: ctx)
    }

    static let shaderCRT = Effect(
        id: "shader.crt",
        category: .shaders,
        interaction: .loop,
        name: L("CRT Monitor", "CRT 显示器"),
        summary: L("Curved glass, rolling scanlines and a soft vignette.", "弧面玻璃、滚动扫描线与柔和暗角。"),
        prompt: L(
            "Content is rendered as if on a vintage CRT: the image is barrel-distorted so edges bow outward, with pure black outside the curved glass; fine horizontal scanlines crawl continuously while a slow brightness roll sweeps down the screen every ~3 s; red and blue channels are offset by ~1.2 pt with a faint trailing smear for phosphor bleed, and a radial vignette darkens the edges by ~28%, more in the corners. A tap degausses the tube: the glass curvature wobbles at about 3.5 Hz and the color fringe spikes by ~5 pt, both decaying exponentially within about a second, with a heavy haptic thunk. Warm, nostalgic and analog without sacrificing legibility.",
            "内容仿佛显示在复古 CRT 显示器上：画面呈桶形畸变、边缘向外鼓起，弧面玻璃之外是纯黑；细密的水平扫描线持续蠕动，每约 3 秒还有一道缓慢的亮度波自上而下扫过；红、蓝通道偏移约 1.2pt 并带一丝拖尾，模拟荧光粉溢色；径向暗角让边缘变暗约 28%，四角更甚。点击即“消磁”：玻璃曲率以约 3.5Hz 来回颤动，色边瞬间加宽约 5pt，二者在一秒左右内指数衰减，并伴随一记沉重的触感。温暖、怀旧、充满模拟质感，又不牺牲可读性。"
        ),
        implementation: L(
            "A Metal layer shader remaps UVs with barrel distortion, samples R/B at a bleed offset plus a trailing smear, and multiplies scanline, roll and vignette terms; visualEffect provides the view size. A tap timestamps a degauss whose decaying sine is added to the curvature and bleed arguments each frame.",
            "Metal layerEffect 通过桶形畸变重映射 UV，按溢色偏移采样 R/B 并叠加拖尾，再叠乘扫描线、亮度滚动与暗角；visualEffect 提供视图尺寸。点击记录消磁时刻，其衰减正弦每帧叠加到曲率与溢色参数上。"
        ),
        apis: ["layerEffect", "visualEffect", "TimelineView", "Metal"],
        tags: ["crt", "retro", "scanline", "vhs", "复古", "扫描线", "显示器", "怀旧"],
        params: [
            .slider("curvature", L("Curvature", "曲率"), 0...0.3, default: 0.12),
            .slider("scanlines", L("Scanline strength", "扫描线强度"), 0...0.5, default: 0.18),
            .slider("bleed", L("Color bleed", "溢色"), 0...4, default: 1.2, decimals: 1, unit: "pt"),
        ]
    ) { ctx in
        CRTDemo(ctx: ctx)
    }

    static let shaderHalftone = Effect(
        id: "shader.halftone",
        category: .shaders,
        interaction: .loop,
        name: L("CMYK Halftone", "CMYK 半色调"),
        summary: L("Live artwork separated into four rotated ink screens, like a press print.", "实时画面被分解为四层旋转网屏，如同印刷机印出。"),
        prompt: L(
            "A slowly animating sunset poster is printed live with process inks. A Metal layer shader separates each pixel into cyan, magenta, yellow and black and draws each ink as its own dot screen at the classic angles (C 15°, M 75°, Y 0°, K 45°): every rotated cell samples the artwork at its center and grows a dot whose area follows that ink’s amount. The inks multiply over warm off-white paper, so overlapping dots mix into reds, greens and deep blues and the familiar rosette moiré appears. As the sun drifts and the hills scroll, dots swell and shrink in waves; dragging pulls the sun under the finger on a spring (response 0.35 s), and on release it eases back into its drift. Tactile, editorial and unmistakably printed.",
            "一张缓慢变化的日落海报被实时“印刷”出来。Metal layerEffect 着色器把每个像素分解为青、品红、黄、黑四种油墨，并按经典网角（C 15°、M 75°、Y 0°、K 45°）分别绘制网屏：每个旋转网格在中心对画面采样，网点面积随该油墨的用量变化。四色在暖白纸上相乘叠印，重叠的网点混出红、绿与深蓝，经典的玫瑰斑网纹随之出现。太阳漂移、山丘滚动时，网点成片胀缩；拖动可让太阳以弹簧（响应 0.35 秒）跟到指尖下，松手后再缓缓回到原本的漂移轨迹。富有触感、杂志感十足，一眼就是印刷品。"
        ),
        implementation: L(
            "A [[stitchable]] layer shader loops over four screens: rotate the position into screen space, snap to the cell center, rotate back, sample, convert RGB to CMYK and draw an anti-aliased dot, multiplying each ink over paper. The Canvas scene underneath is Animatable on a hold factor that blends the sun between its drift and the finger.",
            "[[stitchable]] layerEffect 着色器循环处理四层网屏：把坐标旋转到网屏空间、吸附到网格中心再旋回，采样后将 RGB 转为 CMYK，绘制抗锯齿网点并把各色油墨相乘叠印在纸色上。下层 Canvas 场景以“握持系数”为 Animatable 数据，在自身漂移与手指位置之间混合太阳位置。"
        ),
        apis: ["layerEffect", "TimelineView", "Canvas", "Metal"],
        tags: ["halftone", "cmyk", "print", "risograph", "半色调", "网点", "印刷", "四色"],
        params: [
            .slider("cell", L("Screen size", "网格尺寸"), 4...16, default: 7, decimals: 0, unit: "pt"),
            .slider("angle", L("Screen rotation", "网屏旋转"), 0...90, default: 0, decimals: 0, unit: "°"),
            .slider("gain", L("Dot gain", "网点扩大"), 0.6...1.6, default: 1.0, unit: "×"),
        ]
    ) { ctx in
        HalftoneDemo(ctx: ctx)
    }

    static let shaderPlasma = Effect(
        id: "shader.plasma",
        category: .shaders,
        interaction: .loop,
        name: L("Plasma Field", "等离子场"),
        summary: L("A generative, endlessly flowing iridescent field — tap to shift its palette.", "程序生成、无限流动的虹彩能量场，点击切换色相。"),
        prompt: L(
            "A full-bleed generative background of flowing iridescent plasma: four overlapping sine fields (horizontal, vertical, diagonal and radial) are summed and mapped onto a deliberately limited, cyclic three-stop ramp — cyan → violet → gold — while the troughs sink into deep indigo, so luminous bands fold into one another over dark valleys. The ramp slowly advances, the motion never visibly repeats, and there are no hard edges. A tap jumps the whole palette one stop forward (cyan → violet → gold) on a 0.9 s cubic ease-out, while a flash that rises in 120 ms lifts the troughs and brightens the bands, then fades at ≈ 3.2/s. Ambient, liquid and high-energy — suited to splash screens or premium paywalls.",
            "全屏程序化生成的流动虹彩等离子背景：水平、竖直、对角与径向四组正弦场叠加后，映射到刻意克制的三色循环色带——青 → 紫 → 金——场的低谷沉入深靛蓝，明亮的色带在暗色谷底之上持续翻卷。色带缓慢推进，画面没有可见的重复，也没有硬边。点击会让整条色带前进一档（青 → 紫 → 金），以 0.9 秒三次缓出过渡，同时一道 120ms 内亮起的闪光抬亮谷底与色带，再以约 3.2/s 衰减。充满能量的液态氛围表面，适合启动页或高级付费墙。"
        ),
        implementation: L(
            "A Metal color shader computes the color purely from position, size and time on a Rectangle — four sine fields feed a smoothstepped three-stop ramp shaded toward indigo in the troughs; a tap eases a palette offset one stop forward per frame and passes a short flash that lifts the troughs.",
            "在 Rectangle 上使用 Metal colorEffect，仅依据位置、尺寸与时间计算颜色——四组正弦场驱动平滑过渡的三色色带，低谷向靛蓝压暗；点击后逐帧缓动色带偏移前进一档，并传入短暂闪光以抬亮谷底。"
        ),
        apis: ["colorEffect", "visualEffect", "TimelineView", "Metal"],
        tags: ["plasma", "generative", "iridescent", "background", "等离子", "生成艺术", "虹彩", "背景"],
        params: [
            .slider("scale", L("Scale", "尺度"), 0.4...2.5, default: 1),
            .slider("speed", L("Speed", "速度"), 0.1...3, default: 1),
        ]
    ) { ctx in
        PlasmaDemo(ctx: ctx)
    }
}

// MARK: - Animatable shader modifiers

private struct PixelateModifier: ViewModifier, Animatable {
    var size: Double

    var animatableData: Double {
        get { size }
        set { size = newValue }
    }

    func body(content: Content) -> some View {
        content.layerEffect(
            ShaderLibrary.mlPixelate(.float(size)),
            maxSampleOffset: CGSize(width: size, height: size),
            isEnabled: size > 1.01
        )
    }
}

private struct DissolveModifier: ViewModifier, Animatable {
    var progress: Double
    var scale: Double
    var edge: Color

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content.colorEffect(
            ShaderLibrary.mlDissolve(.float(progress), .float(scale), .color(edge)),
            isEnabled: progress > 0.0001
        )
    }
}

// MARK: - Demos

/// Bottom hint for the tap-only transitions. With Reduce Motion the stage's arrival intro is skipped,
/// so a hand glyph pulses three times to show the card is tappable.
private struct StylizeTapCue: View {
    let text: LocalizedText
    let ctx: DemoContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulses = 0

    var body: some View {
        if !ctx.isPreview {
            HStack(spacing: 5) {
                if reduceMotion {
                    Image(systemName: "hand.tap.fill")
                        .symbolEffect(.pulse, options: .repeat(3), value: pulses)
                        .onAppear { pulses += 1 }
                }
                Text(text, ctx.language)
            }
            .font(.footnote.weight(.medium))
            .foregroundStyle(.secondary)
        }
    }
}

private struct PixelateDemo: View {
    let ctx: DemoContext
    @State private var size: Double = 1
    @State private var showSecond = false
    @State private var busy = false

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                ShaderArtwork(variant: 0)
                    .opacity(showSecond ? 0 : 1)
                ShaderArtwork(variant: 1)
                    .opacity(showSecond ? 1 : 0)
            }
            .modifier(PixelateModifier(size: size))
            .contentShape(Rectangle())
            .onTapGesture(perform: swapContent)
            StylizeTapCue(text: L("Tap to swap content", "点击切换内容"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.0, delay: 0.4) { swapContent() }
    }

    private func swapContent() {
        guard !busy else { return }
        busy = true
        let half = ctx["duration"] / 2
        withAnimation(.easeIn(duration: half)) { size = ctx["maxSize"] }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(half))
            // Cross-fade under the coarsest mosaic so the swap never reads as a cut.
            withAnimation(.linear(duration: 0.08)) { showSecond.toggle() }
            try? await Task.sleep(for: .seconds(0.08))
            withAnimation(.easeOut(duration: half * 1.1)) { size = 1 }
            try? await Task.sleep(for: .seconds(half * 1.1))
            busy = false
        }
    }
}

private struct DissolveDemo: View {
    let ctx: DemoContext
    @State private var gone = false
    /// Bumped by every tap, so a pending intro/autoplay restore never undoes the user's burn.
    @State private var generation = 0

    private var edgeColor: Color {
        switch ctx.int("edge") {
        case 1: return Palette.violet
        case 2: return Palette.sky
        default: return Color(hex: 0xFF8A3D)
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            ShaderArtwork(variant: 3)
                .modifier(DissolveModifier(progress: gone ? 1 : 0, scale: ctx["scale"], edge: edgeColor))
                .contentShape(Rectangle())
                .onTapGesture { toggle() }
            StylizeTapCue(text: L("Tap to burn / restore", "点击溶解 / 复原"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: ctx["duration"] * 2 + 1.0, delay: 0.4) { autoplayCycle() }
    }

    private func toggle() {
        generation += 1
        if !ctx.isPreview { Haptics.tap(.rigid) }
        withAnimation(.easeInOut(duration: ctx["duration"])) { gone.toggle() }
    }

    /// Preview loop: burn away, hold ~0.3 s, then re-materialize, so the card is visible most of the time.
    private func autoplayCycle() {
        let duration = ctx["duration"]
        generation += 1
        let token = generation
        withAnimation(.easeInOut(duration: duration)) { gone = true }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration + 0.3))
            guard token == generation else { return }
            withAnimation(.easeInOut(duration: duration)) { gone = false }
        }
    }
}

private struct GlitchDemo: View {
    let ctx: DemoContext
    @State private var burstUntil = Date.distantPast

    var body: some View {
        VStack(spacing: 14) {
            ShaderClock(preview: ctx.isPreview) { time in
                let bursting = Date() < burstUntil
                let intensity = bursting ? 1.0 : ctx["intensity"]
                // A hit block moves at most one block, plus the R/B split (≤ 1.65 × split).
                let glitchReach = CGFloat(ctx["slice"] + ctx["split"] * 1.7 + 2)
                GlitchCard()
                    .layerEffect(
                        ShaderLibrary.mlGlitch(
                            .float(time),
                            .float(intensity),
                            .float(ctx["split"]),
                            .float(ctx["slice"]),
                            .float(ctx["rate"])
                        ),
                        maxSampleOffset: CGSize(width: glitchReach, height: glitchReach)
                    )
            }
            .onTapGesture { triggerBurst() }
            DemoHint(text: L("Tap for a glitch burst", "点击触发强烈故障"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.4, delay: 0.4) { triggerBurst() }
    }

    private func triggerBurst() {
        if !ctx.isPreview { Haptics.tap(.heavy) }
        burstUntil = Date().addingTimeInterval(0.4)
    }
}

private struct GlitchCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(verbatim: "SYSTEM://")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(Palette.mint)
            Text(verbatim: "NEON\nDRIFT")
                .font(.system(size: 54, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineSpacing(-6)
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { index in
                    Capsule()
                        .fill(Palette.spectrum[index])
                        .frame(width: 28, height: 6)
                }
            }
        }
        .padding(26)
        .frame(width: 260, height: 260, alignment: .leading)
        .background(Color(hex: 0x0E0F1A), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

private struct CRTDemo: View {
    let ctx: DemoContext
    @State private var degaussAt = Date.distantPast

    var body: some View {
        let scanlines = ctx["scanlines"]
        ShaderClock(preview: ctx.isPreview) { time in
            // Degauss: a decaying ~3.5 Hz wobble of the glass curvature plus a colour-fringe spike.
            let wobble = CRTDemo.degauss(since: degaussAt)
            let curvature = ctx["curvature"] + 0.16 * wobble.bend
            let bleed = ctx["bleed"] + 5 * wobble.fringe
            // Barrel reach ≈ |curvature| × half the screen (≤ 160 pt), plus the 2× bleed smear horizontally.
            let barrel: Double = 165 * (abs(curvature) + 0.02) + 4
            let crtReach = CGSize(width: CGFloat(barrel + bleed * 2), height: CGFloat(barrel))
            CRTScreen(time: time, language: ctx.language)
                .visualEffect { content, proxy in
                    content.layerEffect(
                        ShaderLibrary.mlCRT(.float2(proxy.size), .float(time), .float(curvature), .float(scanlines), .float(bleed)),
                        maxSampleOffset: crtReach
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                // Bounded size keeps the bezel clear of the stage's replay button and edges.
                .frame(maxWidth: 290, maxHeight: 320)
                .contentShape(Rectangle())
                .onTapGesture {
                    degaussAt = Date()
                    Haptics.tap(.heavy)
                }
                .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap to degauss", "点击消磁"), ctx: ctx)
                .padding(.bottom, 2)
                .allowsHitTesting(false)
        }
        .autoplay(ctx.isPreview, every: 4.0, delay: 1.5) { degaussAt = Date() }
    }

    /// Curvature wobble (±1) and fringe (0…1) for a degauss that started at `start`; both decay over ~0.9 s.
    private static func degauss(since start: Date) -> (bend: Double, fringe: Double) {
        let age = Date().timeIntervalSince(start)
        guard age >= 0, age < 1.2 else { return (bend: 0, fringe: 0) }
        let envelope = exp(-age * 4)
        return (bend: sin(age * 22) * envelope, fringe: envelope)
    }
}

private struct CRTScreen: View {
    let time: Double
    let language: AppLanguage

    private static let lines: [LocalizedText] = [
        L("> BOOT MOTION.LEXICON", "> 启动 MOTION.LEXICON"),
        L("> LOADING SPRINGS…  OK", "> 载入弹簧……  完成"),
        L("> LOADING SHADERS… OK", "> 载入着色器…… 完成"),
        L("> MOTION LEXICON READY_", "> 动效词典 就绪_"),
    ]

    var body: some View {
        let lines = CRTScreen.lines
        let visible = Int(time * 1.2) % (lines.count + 2)
        VStack(alignment: .leading, spacing: 8) {
            ForEach(0..<lines.count, id: \.self) { index in
                Text(lines[index], language)
                    .opacity(index < visible ? 1 : 0)
            }
            Spacer()
            HStack(spacing: 4) {
                ForEach(0..<12, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Palette.mint.opacity(Double((index + Int(time * 8)) % 12) / 12))
                        .frame(height: 10)
                }
            }
        }
        .font(.system(size: 14, weight: .semibold, design: .monospaced))
        .foregroundStyle(Palette.mint)
        .shadow(color: Palette.mint.opacity(0.8), radius: 6)
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(hex: 0x06140F))
    }
}

private struct HalftoneDemo: View {
    let ctx: DemoContext
    /// Where the finger last held the sun, in unit coordinates of the poster.
    @State private var sunTarget = CGPoint(x: 0.5, y: 0.42)
    /// 0 = free drift, 1 = held by the finger; sprung so the sun eases in and back out.
    @State private var hold: Double = 0

    private static let posterSize = CGSize(width: 270, height: 300)

    var body: some View {
        let cell = ctx["cell"]
        let angle = ctx["angle"] * .pi / 180
        let gain = ctx["gain"]
        VStack(spacing: 12) {
            ShaderClock(preview: ctx.isPreview) { time in
                HalftonePoster(time: time, sunTarget: sunTarget, hold: hold)
                    .frame(width: HalftoneDemo.posterSize.width, height: HalftoneDemo.posterSize.height)
                    .layerEffect(
                        ShaderLibrary.mlHalftoneCMYK(.float(cell), .float(angle), .float(gain)),
                        maxSampleOffset: CGSize(width: cell, height: cell)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
            }
            // Horizontal-first (then free) drag plus tap, so a vertical swipe still scrolls the page.
            .backgroundsTouch { location in
                let size = HalftoneDemo.posterSize
                sunTarget = CGPoint(x: (location.x / size.width).clamped(to: 0...1), y: (location.y / size.height).clamped(to: 0...1))
                if hold < 1 {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { hold = 1 }
                }
            } onEnded: {
                withAnimation(.spring(response: 0.9, dampingFraction: 0.75)) { hold = 0 }
            }
            DemoHint(text: L("Drag the sun across the poster", "拖动太阳划过海报"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// A sunset poster: warm sky, drifting sun and two scrolling hill silhouettes.
/// Animatable on `hold`, so the sun eases between its own drift and the finger.
private struct HalftonePoster: View, Animatable {
    let time: Double
    let sunTarget: CGPoint
    var hold: Double

    var animatableData: Double {
        get { hold }
        set { hold = newValue }
    }

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            context.fill(Path(rect), with: .linearGradient(
                Gradient(colors: [Color(hex: 0x3A2E8C), Palette.pink, Palette.amber]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: size.height * 0.75)
            ))
            let drift = CGPoint(x: 0.5 + 0.18 * cos(time * 0.4), y: 0.42 + 0.06 * sin(time * 0.5))
            let k = CGFloat(hold)
            let sun = CGPoint(
                x: size.width * (drift.x + (sunTarget.x - drift.x) * k),
                y: size.height * (drift.y + (sunTarget.y - drift.y) * k)
            )
            context.fill(Path(ellipseIn: CGRect(x: sun.x - 56, y: sun.y - 56, width: 112, height: 112)), with: .color(Color(hex: 0xFFE27A)))
            context.fill(hill(size, base: 0.66, amplitude: 22, frequency: 1.6, phase: time * 0.35), with: .color(Color(hex: 0xE2365B)))
            context.fill(hill(size, base: 0.8, amplitude: 16, frequency: 2.3, phase: -time * 0.5), with: .color(Color(hex: 0x14365A)))
        }
    }

    private func hill(_ size: CGSize, base: CGFloat, amplitude: CGFloat, frequency: CGFloat, phase: Double) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: size.height))
        var x: CGFloat = 0
        while x <= size.width + 6 {
            let y = size.height * base + amplitude * CGFloat(sin(Double(x / size.width * frequency * 2 * .pi) + phase))
            path.addLine(to: CGPoint(x: x, y: y))
            x += 6
        }
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.closeSubpath()
        return path
    }
}

private struct PlasmaDemo: View {
    let ctx: DemoContext
    /// Palette jumps so far; each one eases the ramp forward by one color stop (1/3).
    @State private var shifts = 0
    @State private var shiftAt = Date.distantPast

    var body: some View {
        let scale = ctx["scale"]
        let speed = ctx["speed"]
        ShaderClock(preview: ctx.isPreview, speed: speed) { time in
            let jump = paletteJump(now: Date())
            let palette: Double = jump.palette
            let flash: Double = jump.flash
            Rectangle()
                .visualEffect { content, proxy in
                    content.colorEffect(
                        ShaderLibrary.mlPlasma(.float2(proxy.size), .float(time), .float(scale), .float(palette), .float(flash))
                    )
                }
                .overlay { PlasmaBadge(language: ctx.language) }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.tap(.soft)
            shift()
        }
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap to shift the palette", "点击切换色相"), ctx: ctx)
                .padding(.bottom, 14)
                .environment(\.colorScheme, .dark)
                .allowsHitTesting(false)
        }
        .autoplay(ctx.isPreview, every: 3.2, delay: 1.0) { shift() }
    }

    private func shift() {
        shifts += 1
        shiftAt = Date()
    }

    /// Shader arguments don't animate, so the jump is eased per frame: the ramp moves one stop (1/3) with a
    /// cubic ease-out over 0.9 s, while a flash rises in 120 ms and decays at ≈ 3.2/s.
    private func paletteJump(now: Date) -> (palette: Double, flash: Double) {
        guard shifts > 0 else { return (0, 0) }
        let elapsed = max(now.timeIntervalSince(shiftAt), 0)
        let p = min(elapsed / 0.9, 1)
        let eased = 1 - pow(1 - p, 3)
        let palette = (Double((shifts - 1) % 3) + eased) / 3
        let flash = elapsed < 0.12 ? elapsed / 0.12 : exp(-(elapsed - 0.12) * 3.2)
        return (palette, flash)
    }
}

private struct PlasmaBadge: View {
    let language: AppLanguage

    var body: some View {
        VStack(spacing: 6) {
            Text(verbatim: "Pro")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
            Text(language == .zh ? "解锁全部动效" : "Unlock every effect")
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 26)
        .padding(.vertical, 18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .environment(\.colorScheme, .dark)
        .allowsHitTesting(false)
    }
}
