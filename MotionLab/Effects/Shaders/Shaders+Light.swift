import SwiftUI

// MARK: - Progressive blur & caustics

extension Effect {
    static let shaderProgressiveBlur = Effect(
        id: "shader.progressive-blur",
        category: .shaders,
        interaction: .tap,
        name: L("Progressive Blur", "渐进模糊"),
        summary: L("A variable blur that ramps along a mask, for scroll edges or tilt-shift focus.", "沿遮罩渐变增强的可变模糊，可做滚动边缘或移轴对焦。"),
        prompt: L(
            "A photo feed scrolls slowly beneath a large, crisp “Library” title. Instead of a hard material bar, a Metal layer shader blurs the list with a radius that ramps smoothly along a vertical mask: fully sharp below the focus line, easing (smoothstep) to a 14 pt disc blur about 70 pt above it, so rows melt softly into the header like the iOS scroll-edge effect. A tilt-shift mode keeps a 40 pt band sharp and blurs both sides, like a miniature photo. Tapping moves the focus line to the finger on a spring (response 0.5 s, damping 0.8). Soft, optical, premium.",
            "一列图片信息流在醒目清晰的“图库”大标题下缓慢滚动。这里没有生硬的材质条，而是由 Metal layerEffect 着色器沿竖直遮罩平滑改变模糊半径：对焦线以下完全清晰，向上约 70pt 内以 smoothstep 缓动增强到 14pt 的圆盘模糊，列表行像 iOS 滚动边缘效果一样柔和地融进标题。移轴模式则保留 40pt 高的清晰带、上下两侧同时模糊，宛如微缩摄影。点击时对焦线以弹簧（响应 0.5 秒、阻尼 0.8）移到手指处。柔和、光学、高级。"
        ),
        implementation: L(
            "A [[stitchable]] layer shader computes a per-pixel radius from a smoothstepped mask and averages 32 golden-angle taps (16 in grid previews) with a hashed per-pixel rotation; an Animatable modifier springs the focus line, and ShaderClock scrolls the feed.",
            "[[stitchable]] layerEffect 着色器按 smoothstep 遮罩逐像素计算模糊半径，以黄金角分布的 32 个采样点（网格预览中为 16 个，每像素哈希旋转）求平均；Animatable 修饰器以弹簧移动对焦线，ShaderClock 驱动信息流滚动。"
        ),
        apis: ["layerEffect", "Animatable", "TimelineView", "onTapGesture(coordinateSpace:)", "Metal"],
        tags: ["progressive blur", "variable blur", "tilt shift", "scroll edge", "渐进模糊", "可变模糊", "移轴", "滚动边缘"],
        params: [
            .slider("radius", L("Max blur", "最大模糊"), 4...24, default: 14, decimals: 0, unit: "pt"),
            .slider("fade", L("Ramp length", "渐变长度"), 20...140, default: 70, decimals: 0, unit: "pt"),
            .choice("mode", L("Mask", "遮罩"), [L("Top edge", "顶部边缘"), L("Tilt-shift", "移轴")]),
        ]
    ) { ctx in
        ProgressiveBlurDemo(ctx: ctx)
    }

    static let shaderCaustics = Effect(
        id: "shader.caustics",
        category: .shaders,
        interaction: .loop,
        name: L("Pool Caustics", "泳池焦散"),
        summary: L("Dancing caustic light and refraction over a tiled pool floor; tap to drop a ripple.", "瓷砖池底上跃动的焦散光纹与折射，点击投下一圈涟漪。"),
        prompt: L(
            "A tiled pool floor seen through moving water. A Metal layer shader builds a height field from three crossing sine swells plus soft value noise, refracts the tiles by its gradient (≈ 3–5 pt of wobble) and tints them aqua; on top, an iterative caustic network — sharpened with pow(·, 8) — draws thin, bright light filaments that pinch, merge and split continuously, shifted by the same refraction so light and floor move together. Tapping drops a ripple ring that travels at ≈ 240 pt/s and fades within ≈ 2 s, bending tiles and filaments as it passes. Cool, sunlit and hypnotic.",
            "透过流动的水面看到的瓷砖池底。Metal layerEffect 着色器由三组交错的正弦涌浪加柔和的值噪声构成水面高度场，按其梯度折射瓷砖（约 3～5pt 的晃动）并染上水蓝色；其上叠加一张迭代计算、经 pow(·, 8) 锐化的焦散光网，细亮的光丝不断收束、汇合、分裂，并随同一折射偏移，让光与池底一起晃动。点击会投下一圈以约 240pt/s 扩散、约 2 秒内消散的涟漪，所经之处瓷砖与光丝都被弯折。清凉、阳光感十足，令人着迷。"
        ),
        implementation: L(
            "A [[stitchable]] layer shader takes finite-difference gradients of a sum-of-sines + noise height field to offset the sample, then adds a tileable-style iterative caustic term; ShaderClock supplies time and the last tap's origin and age feed the ripple.",
            "[[stitchable]] layerEffect 着色器对“正弦叠加 + 噪声”高度场做有限差分求梯度来偏移采样，再叠加迭代计算的焦散光项；ShaderClock 提供时间，最近一次点击的位置与时长驱动涟漪。"
        ),
        apis: ["layerEffect", "TimelineView", "Canvas", "onTapGesture(coordinateSpace:)", "Metal"],
        tags: ["caustics", "water", "pool", "refraction", "焦散", "水面", "泳池", "光纹"],
        params: [
            .slider("speed", L("Water speed", "水流速度"), 0.2...2, default: 1, unit: "×"),
            .slider("intensity", L("Light intensity", "光纹强度"), 0...1.5, default: 0.9),
            .slider("refraction", L("Refraction", "折射"), 0...16, default: 8, decimals: 0),
        ]
    ) { ctx in
        CausticsDemo(ctx: ctx)
    }
}

// MARK: - Progressive blur demo

private struct ProgressiveBlurModifier: ViewModifier, Animatable {
    var focusY: Double
    let radius: Double
    let fade: Double
    let tiltShift: Bool
    /// Blur samples per pixel: 16 in grid previews, 32 on the detail stage.
    let taps: Double

    var animatableData: Double {
        get { focusY }
        set { focusY = newValue }
    }

    func body(content: Content) -> some View {
        content.layerEffect(
            ShaderLibrary.mlProgressiveBlur(
                .float(radius),
                .float(focusY),
                .float(20),
                .float(fade),
                .float(tiltShift ? 1 : 0),
                .float(taps)
            ),
            maxSampleOffset: CGSize(width: radius, height: radius)
        )
    }
}

private struct ProgressiveBlurDemo: View {
    let ctx: DemoContext
    @State private var focus: Double?
    /// Bumped by every tap, so a pending intro/autoplay return never resets the focus the user just chose.
    @State private var generation = 0

    private static let height: CGFloat = 330
    private static let rowHeight: CGFloat = 72
    private static let rows = 6

    var body: some View {
        let tiltShift = ctx.int("mode") == 1
        let restFocus: Double = tiltShift ? 190 : 150
        VStack(spacing: 12) {
            ShaderClock(preview: ctx.isPreview) { time in
                feed(time: time)
                    .modifier(ProgressiveBlurModifier(
                        focusY: focus ?? restFocus,
                        radius: ctx["radius"],
                        fade: ctx["fade"],
                        tiltShift: tiltShift,
                        taps: ctx.isPreview ? 16 : 32
                    ))
            }
            .frame(width: 300, height: Self.height)
            .background(Palette.elevated)
            .overlay(alignment: .topLeading) { header(tiltShift: tiltShift) }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Palette.stroke))
            .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
            .contentShape(Rectangle())
            .onTapGesture(coordinateSpace: .local) { location in
                generation += 1
                Haptics.selection()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { focus = Double(location.y) }
            }
            DemoHint(text: L("Tap to move the focus line", "点击移动对焦线"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.4, delay: 0.3) { sweepFocus(rest: restFocus) }
    }

    /// Simulated tap: glide the focus line down, then back to rest.
    private func sweepFocus(rest: Double) {
        generation += 1
        let token = generation
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { focus = rest + 90 }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.1))
            guard token == generation else { return }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { focus = nil }
        }
    }

    private func feed(time: Double) -> some View {
        let cycle = Double(Self.rowHeight) * Double(Self.rows)
        let offset = (time * 22).truncatingRemainder(dividingBy: cycle)
        return VStack(spacing: 0) {
            ForEach(0..<(Self.rows * 2), id: \.self) { index in
                BlurFeedRow(index: index % Self.rows, language: ctx.language)
                    .frame(height: Self.rowHeight)
            }
        }
        .offset(y: -CGFloat(offset))
        .frame(width: 300, height: Self.height, alignment: .top)
        .background(Palette.elevated)
        .clipped()
    }

    @ViewBuilder
    private func header(tiltShift: Bool) -> some View {
        if !tiltShift {
            Text(L("Library", "图库"), ctx.language)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .allowsHitTesting(false)
        }
    }
}

private struct BlurFeedRow: View {
    let index: Int
    let language: AppLanguage

    private static let titles: [LocalizedText] = [
        L("Morning Light", "晨光"), L("Tide Pools", "潮汐池"), L("Night Market", "夜市"),
        L("Paper Cranes", "纸鹤"), L("Neon Rain", "霓虹雨"), L("Desert Bloom", "沙漠花开"),
    ]
    private static let symbols = ["sun.horizon.fill", "water.waves", "lamp.table.fill", "bird.fill", "cloud.rain.fill", "camera.macro"]

    var body: some View {
        let colors = Palette.spectrum
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(colors: [colors[index % colors.count], colors[(index + 2) % colors.count]], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 52, height: 52)
                .overlay {
                    Image(systemName: Self.symbols[index % Self.symbols.count])
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                }
            VStack(alignment: .leading, spacing: 5) {
                Text(Self.titles[index % Self.titles.count], language)
                    .font(.subheadline.weight(.semibold))
                Text(verbatim: language == .zh ? "\(12 + index * 7) 张照片" : "\(12 + index * 7) photos")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 18)
    }
}

// MARK: - Caustics demo

private struct CausticsDemo: View {
    let ctx: DemoContext
    @State private var origin = CGPoint(x: 150, y: 160)
    @State private var tapDate: Date?

    var body: some View {
        let intensity = ctx["intensity"]
        let refraction = ctx["refraction"]
        VStack(spacing: 12) {
            ShaderClock(preview: ctx.isPreview, speed: ctx["speed"]) { time in
                let age = tapDate.map { Date().timeIntervalSince($0) } ?? -1
                PoolFloor()
                    .layerEffect(
                        ShaderLibrary.mlCaustics(
                            .float(time),
                            .float(intensity),
                            .float(refraction),
                            .float2(origin),
                            .float(age)
                        ),
                        maxSampleOffset: CGSize(width: refraction * 3 + 4, height: refraction * 3 + 4)
                    )
            }
            .frame(width: 300, height: 320)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).strokeBorder(.white.opacity(0.25), lineWidth: 1))
            .shadow(color: Palette.sky.opacity(0.35), radius: 22, y: 12)
            .contentShape(Rectangle())
            .onTapGesture(coordinateSpace: .local) { location in drop(at: location) }
            DemoHint(text: L("Tap the water", "点击水面"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 3, delay: 0.4) {
            drop(at: CGPoint(x: CGFloat.random(in: 70...230), y: CGFloat.random(in: 80...240)))
        }
    }

    private func drop(at point: CGPoint) {
        Haptics.tap(.soft)
        origin = point
        tapDate = Date()
    }
}

/// Aqua pool tiles with grout lines and a dark lane stripe.
private struct PoolFloor: View {
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: 0x7FD8E8)))
            let tile: CGFloat = 24
            var grout = Path()
            var x: CGFloat = 0
            while x <= size.width {
                grout.move(to: CGPoint(x: x, y: 0))
                grout.addLine(to: CGPoint(x: x, y: size.height))
                x += tile
            }
            var y: CGFloat = 0
            while y <= size.height {
                grout.move(to: CGPoint(x: 0, y: y))
                grout.addLine(to: CGPoint(x: size.width, y: y))
                y += tile
            }
            let lane = CGRect(x: size.width / 2 - 18, y: 36, width: 36, height: size.height - 72)
            context.fill(Path(roundedRect: lane, cornerRadius: 6), with: .color(Color(hex: 0x16507A)))
            let cross = CGRect(x: size.width / 2 - 54, y: 36, width: 108, height: 22)
            context.fill(Path(roundedRect: cross, cornerRadius: 6), with: .color(Color(hex: 0x16507A)))
            context.stroke(grout, with: .color(.white.opacity(0.55)), lineWidth: 1.5)
        }
    }
}
