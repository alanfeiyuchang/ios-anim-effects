import SwiftUI

extension Effect {
    static let shaderPixelate = Effect(
        id: "shader.pixelate",
        category: .shaders,
        interaction: .tap,
        name: L("Pixelate Swap", "像素化切换"),
        summary: L("Content dissolves into pixels, swaps, and resolves again.", "内容碎成像素块、替换后再重新清晰。"),
        prompt: L(
            "Tapping the card transitions its content through a mosaic: the image quantizes into progressively larger square cells (1 → ≈28 pt) over 350 ms with an ease-in curve, the content is swapped at peak coarseness where the change is invisible, then the cells shrink back to full resolution over 400 ms with an ease-out. The effect reads like a retro game scene cut, precise and digital, while staying perfectly smooth because cell size animates continuously.",
            "点击卡片时，内容通过马赛克完成切换：画面在 350 毫秒内以 ease-in 曲线量化为逐渐变大的方形像素块（1 → 约 28pt），在最粗糙、肉眼无法分辨的瞬间替换内容，随后在 400 毫秒内以 ease-out 曲线收缩回完整清晰度。效果如同复古游戏的场景切换，精准而数字化，同时因像素尺寸连续插值而保持丝滑。"
        ),
        implementation: L(
            "A Metal layer shader samples the center of each cell. The cell size lives in an Animatable ViewModifier, animated up, content swapped, then animated down.",
            "Metal layerEffect 对每个像素格的中心点采样；像素尺寸存放在 Animatable ViewModifier 中，先动画放大、替换内容，再动画缩小。"
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
            "The card disintegrates into nothing along an organic fractal-noise mask: as progress runs from 0 to 1 over ≈1.2 s (ease-in-out), pixels whose noise value falls below the moving threshold vanish, while a thin band just above the threshold glows in a hot ember color, like paper burning away. Tapping again reverses the process so the card re-materializes from the ashes. The edge stays crisp yet irregular, conveying a dramatic, magical deletion.",
            "卡片沿着有机的分形噪声遮罩逐渐消散：进度在约 1.2 秒内（ease-in-out）从 0 推进到 1，噪声值低于移动阈值的像素消失，而阈值上方的一窄条边缘呈炽热的余烬色发光，如同纸张被火焰烧尽。再次点击则反向播放，卡片从灰烬中重新凝聚。边缘清晰却不规则，传达出戏剧化、带魔法感的删除动作。"
        ),
        implementation: L(
            "A Metal color shader compares 4-octave value noise against an animated threshold and mixes in an edge color; progress is an Animatable modifier value.",
            "Metal colorEffect 将 4 层倍频值噪声与动画阈值比较，并在边缘混合发光色；进度由 Animatable modifier 插值。"
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
        summary: L("Chromatic split and slice jitter, with a tap-triggered burst.", "色差分离与切片抖动，点击触发强烈故障。"),
        prompt: L(
            "A cyberpunk glitch: the red and blue channels drift a few points apart horizontally for a permanent chromatic-aberration fringe, faint scanlines modulate brightness, and at random intervals (≈6 times per second) horizontal 14 pt slices tear sideways by up to ±26 pt for a single frame. A tap spikes the intensity to maximum for 400 ms before decaying back, like a corrupted signal momentarily losing sync. Motion is deliberately steppy and unsmoothed, yet sparse enough to stay legible.",
            "赛博朋克风格的故障效果：红、蓝通道在水平方向错开数个点，形成常驻的色差边缘；细微的扫描线调制亮度；并以随机间隔（约每秒 6 次）将 14pt 高的水平切片横向撕裂最多 ±26pt，仅持续一帧。点击会让强度瞬间拉满 400 毫秒后回落，如同信号短暂失步。运动刻意呈阶跃、不做平滑，但足够稀疏以保持可读。"
        ),
        implementation: L(
            "A Metal layer shader samples R/G/B at offset positions and shifts hashed horizontal bands per time step; TimelineView supplies time.",
            "Metal layerEffect 在不同偏移位置分别采样 R/G/B，并按时间步用哈希随机平移水平切片；时间由 TimelineView 提供。"
        ),
        apis: ["layerEffect", "TimelineView", "hash noise", "Metal"],
        tags: ["glitch", "chromatic aberration", "cyberpunk", "故障", "色差", "赛博朋克", "RGB"],
        params: [
            .slider("intensity", L("Intensity", "强度"), 0...1, default: 0.35),
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
            "Content is rendered as if on a vintage CRT: the image is barrel-distorted so edges bow outward, with pure black outside the curved glass; fine horizontal scanlines scroll downward continuously while a slow brightness roll sweeps the screen every ~3 s; red and blue channels are offset by ~1 pt for phosphor bleed, and a radial vignette darkens the corners by ~28%. The result feels warm, nostalgic and analog without sacrificing legibility.",
            "内容仿佛显示在复古 CRT 显示器上：画面呈桶形畸变、边缘向外鼓起，弧面玻璃外为纯黑；细密的水平扫描线持续向下滚动，同时每约 3 秒有一道缓慢的亮度波扫过屏幕；红、蓝通道偏移约 1pt 模拟荧光粉溢色，径向暗角使四角变暗约 28%。整体温暖、怀旧、充满模拟质感，同时不牺牲可读性。"
        ),
        implementation: L(
            "A Metal layer shader remaps UVs with barrel distortion and multiplies scanline, roll and vignette terms; visualEffect provides the view size.",
            "Metal layerEffect 通过桶形畸变重映射 UV，并叠乘扫描线、亮度滚动与暗角；visualEffect 提供视图尺寸。"
        ),
        apis: ["layerEffect", "visualEffect", "TimelineView", "Metal"],
        tags: ["crt", "retro", "scanline", "vhs", "复古", "扫描线", "显示器", "怀旧"],
        params: [
            .slider("curvature", L("Curvature", "曲率"), 0...0.3, default: 0.12),
            .toggle("enabled", L("Effect on", "开启效果"), default: true),
        ]
    ) { ctx in
        CRTDemo(ctx: ctx)
    }

    static let shaderHalftone = Effect(
        id: "shader.halftone",
        category: .shaders,
        interaction: .loop,
        name: L("Halftone", "半色调网点"),
        summary: L("Live content rendered as a print-style dot screen.", "实时内容以印刷网点风格呈现。"),
        prompt: L(
            "Moving content is rendered through a halftone screen: the surface is divided into a regular grid (≈9 pt cells) and each cell draws a single anti-aliased dot whose color is sampled from the cell center and whose radius grows as brightness falls, recreating comic-book / risograph print texture. Because the underlying gradient artwork slowly rotates, the dots swell and shrink in waves, producing a tactile, editorial motion texture.",
            "动态内容通过半色调网屏渲染：画面被划分为规则网格（约 9pt 一格），每格绘制一个抗锯齿圆点，颜色取自格中心，半径随亮度降低而增大，重现漫画 / 孔版印刷的网点质感。由于底层渐变图形缓慢旋转，圆点会成片地膨胀收缩，形成富有触感的杂志排版风格动态纹理。"
        ),
        implementation: L(
            "A Metal layer shader samples each cell center, computes luminance and draws a smoothstep-edged disc; the content below animates with TimelineView.",
            "Metal layerEffect 对每个网格中心采样、计算亮度并用 smoothstep 绘制圆点边缘；下层内容由 TimelineView 驱动动画。"
        ),
        apis: ["layerEffect", "TimelineView", "AngularGradient", "Metal"],
        tags: ["halftone", "print", "comic", "dots", "半色调", "网点", "印刷", "漫画"],
        params: [
            .slider("cell", L("Cell size", "网格尺寸"), 4...20, default: 9, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        HalftoneDemo(ctx: ctx)
    }

    static let shaderPlasma = Effect(
        id: "shader.plasma",
        category: .shaders,
        interaction: .loop,
        name: L("Plasma Field", "等离子场"),
        summary: L("A generative, endlessly flowing iridescent field.", "程序生成、无限流动的虹彩能量场。"),
        prompt: L(
            "A full-bleed generative background of flowing iridescent plasma: four overlapping sine fields (horizontal, vertical, diagonal and radial) are summed and mapped through a cosine color palette, so bands of cyan, violet and gold continuously fold into one another. The palette itself slowly rotates, the motion never repeats visibly, and there are no hard edges — an ambient, liquid, high-energy surface suited to splash screens or premium paywalls.",
            "全屏程序化生成的流动虹彩等离子背景：水平、竖直、对角与径向四组正弦场叠加后，通过余弦调色板映射成颜色，青、紫、金色带持续相互翻卷。调色板本身缓慢轮转，画面无可见重复、没有硬边——一种充满能量的液态氛围表面，适合启动页或高级付费墙。"
        ),
        implementation: L(
            "A Metal color shader computes the color purely from position, size and time on a Rectangle; no source pixels are needed.",
            "在 Rectangle 上使用 Metal colorEffect，仅依据位置、尺寸与时间计算颜色，无需源像素。"
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

private struct PixelateDemo: View {
    let ctx: DemoContext
    @State private var size: Double = 1
    @State private var variant = 0
    @State private var busy = false

    var body: some View {
        VStack(spacing: 14) {
            ShaderArtwork(variant: variant)
                .modifier(PixelateModifier(size: size))
                .onTapGesture(perform: swapContent)
            DemoHint(text: L("Tap to swap content", "点击切换内容"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.0, delay: 0.4) { swapContent() }
    }

    private func swapContent() {
        guard !busy else { return }
        busy = true
        let half = ctx["duration"] / 2
        withAnimation(.easeIn(duration: half)) { size = ctx["maxSize"] }
        Task {
            try? await Task.sleep(for: .seconds(half))
            variant = 1 - variant
            withAnimation(.easeOut(duration: half * 1.1)) { size = 1 }
            try? await Task.sleep(for: .seconds(half * 1.1))
            busy = false
        }
    }
}

private struct DissolveDemo: View {
    let ctx: DemoContext
    @State private var gone = false

    private var edgeColor: Color {
        switch ctx.int("edge") {
        case 1: return Palette.violet
        case 2: return Palette.sky
        default: return Color(hex: 0xFF8A3D)
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            ShaderArtwork()
                .modifier(DissolveModifier(progress: gone ? 1 : 0, scale: ctx["scale"], edge: edgeColor))
                .contentShape(Rectangle())
                .onTapGesture { toggle() }
            DemoHint(text: L("Tap to burn / restore", "点击溶解 / 复原"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.8, delay: 0.4) { toggle() }
    }

    private func toggle() {
        Haptics.tap(.rigid)
        withAnimation(.easeInOut(duration: ctx["duration"])) { gone.toggle() }
    }
}

private struct GlitchDemo: View {
    let ctx: DemoContext
    @State private var burstUntil = Date.distantPast

    var body: some View {
        VStack(spacing: 14) {
            ShaderClock { time in
                let bursting = Date() < burstUntil
                let intensity = bursting ? 1.0 : ctx["intensity"]
                GlitchCard()
                    .layerEffect(
                        ShaderLibrary.mlGlitch(.float(time), .float(intensity)),
                        maxSampleOffset: CGSize(width: 32, height: 0)
                    )
            }
            .onTapGesture { triggerBurst() }
            DemoHint(text: L("Tap for a glitch burst", "点击触发强烈故障"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.4, delay: 0.4) { triggerBurst() }
    }

    private func triggerBurst() {
        Haptics.tap(.heavy)
        burstUntil = Date().addingTimeInterval(0.4)
    }
}

private struct GlitchCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SYSTEM://")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(Palette.mint)
            Text("NEON\nDRIFT")
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

    var body: some View {
        let curvature = ctx["curvature"]
        let enabled = ctx.bool("enabled")
        ShaderClock { time in
            CRTScreen(time: time)
                .visualEffect { content, proxy in
                    content.layerEffect(
                        ShaderLibrary.mlCRT(.float2(proxy.size), .float(time), .float(curvature)),
                        maxSampleOffset: CGSize(width: 40, height: 40),
                        isEnabled: enabled
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct CRTScreen: View {
    let time: Double

    var body: some View {
        let lines = ["> BOOT MOTION.LEXICON", "> LOADING SPRINGS…  OK", "> LOADING SHADERS… OK", "> 动效词典 READY_"]
        let visible = Int(time * 1.2) % (lines.count + 2)
        VStack(alignment: .leading, spacing: 8) {
            ForEach(0..<lines.count, id: \.self) { index in
                Text(lines[index])
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

    var body: some View {
        let cell = ctx["cell"]
        ShaderClock { time in
            ZStack {
                AngularGradient(colors: [Palette.pink, Palette.amber, Palette.mint, Palette.sky, Palette.violet, Palette.pink], center: .center, angle: .degrees(time * 30))
                RadialGradient(colors: [.white, .clear], center: UnitPoint(x: 0.5 + 0.3 * cos(time), y: 0.5 + 0.3 * sin(time * 0.8)), startRadius: 0, endRadius: 160)
                Image(systemName: "star.fill")
                    .font(.system(size: 120, weight: .black))
                    .foregroundStyle(Color(hex: 0x1B1B2F))
                    .rotationEffect(.degrees(time * -20))
            }
            .frame(width: 270, height: 270)
            .layerEffect(ShaderLibrary.mlHalftone(.float(cell)), maxSampleOffset: CGSize(width: cell, height: cell))
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct PlasmaDemo: View {
    let ctx: DemoContext

    var body: some View {
        let scale = ctx["scale"]
        let speed = ctx["speed"]
        ShaderClock { time in
            Rectangle()
                .visualEffect { content, proxy in
                    content.colorEffect(
                        ShaderLibrary.mlPlasma(.float2(proxy.size), .float(time * speed), .float(scale))
                    )
                }
                .overlay {
                    VStack(spacing: 6) {
                        Text("Pro")
                            .font(.system(size: 44, weight: .heavy, design: .rounded))
                        Text(ctx.language == .zh ? "解锁全部动效" : "Unlock every effect")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 18)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .environment(\.colorScheme, .dark)
                }
        }
    }
}
