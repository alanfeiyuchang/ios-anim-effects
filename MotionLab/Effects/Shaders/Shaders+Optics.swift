import SwiftUI

// MARK: - Chromatic aberration

extension Effect {
    static let shaderChromatic = Effect(
        id: "shader.chromatic-drag",
        category: .shaders,
        interaction: .gesture,
        name: L("Chromatic Motion Split", "色散拖影"),
        summary: L("Drag the card and its RGB channels tear apart in proportion to its speed.", "拖动卡片时，RGB 通道按速度撕裂分离，停下即重合。"),
        prompt: L(
            "A 260 × 300 pt artwork card rests at the center. Dragging it pulls the card toward the finger on a spring (response ≈ 0.4 s, damping ≈ 0.6) and tilts it up to 8° in the direction of travel. A Metal layer shader samples the red channel ahead of the motion and the blue channel behind it, offset by the card's live velocity (≈ 1 pt per 60 pt/s, capped at 18 pt), plus a radial lens fringe that grows toward the edges and blooms only while moving. At rest the channels align perfectly; a fast swipe smears them into cyan and magenta ghosts that snap back together as the spring settles, so speed itself becomes visible. Kinetic, editorial, a little glitchy — never messy.",
            "一张 260 × 300pt 的插画卡片静置中央。拖动时卡片通过弹簧（响应约 0.4 秒、阻尼约 0.6）追随手指，并沿运动方向最多倾斜 8°。Metal layerEffect 着色器把红色通道采样在运动前方、蓝色通道采样在后方，偏移量取卡片的实时速度（约每 60pt/s 偏移 1pt，最大 18pt），另叠加一圈越靠边缘越明显、仅在运动时绽开的径向镜头色边。静止时三通道完全重合；快速甩动时画面被拉出青色与品红残影，随弹簧稳定又迅速合拢——速度本身变得可见。动感、杂志感，带一点故障美学，却绝不凌乱。"
        ),
        implementation: L(
            "A reference-type spring model stepped by TimelineView tracks the card's position and velocity; visualEffect passes the size and the velocity-derived offset into a [[stitchable]] layer shader that splits R/G/B samples.",
            "由 TimelineView 逐帧推进的引用类型弹簧模型记录卡片位置与速度；visualEffect 把尺寸与由速度换算的偏移传给 [[stitchable]] layerEffect 着色器，分别采样 R/G/B。"
        ),
        apis: ["layerEffect", "visualEffect", "TimelineView", "DragGesture", "ShaderLibrary"],
        tags: ["chromatic aberration", "rgb split", "motion", "glitch", "velocity", "色散", "色差", "RGB 分离", "拖影"],
        params: [
            .slider("strength", L("Split strength", "分离强度"), 0.2...2.0, default: 1.0, unit: "×"),
            .slider("fringe", L("Lens fringe", "镜头色边"), 0...24, default: 8, decimals: 0, unit: "pt"),
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.9, default: 0.4, unit: "s"),
        ]
    ) { ctx in
        ChromaticDemo(ctx: ctx)
    }

    static let shaderKaleidoscope = Effect(
        id: "shader.kaleidoscope",
        category: .shaders,
        interaction: .loop,
        name: L("Kaleidoscope", "万花筒"),
        summary: L("Mirrored wedges of live artwork that slowly turn; drag to twist the tube.", "镜像楔形实时拼出花纹并缓缓旋转，拖动即可转动镜筒。"),
        prompt: L(
            "A 280 pt circular window shows a kaleidoscope built from colourful artwork. A Metal layer shader converts every pixel to polar coordinates, folds the angle into N mirrored wedges (8 by default) and samples the source at the folded angle, so a single slice repeats as a seamless rosette. Two rotations run at once: the sampled wedge turns at ≈ 0.35 rad/s — like rotating the tube, so the pattern continuously blooms and re-forms — while the whole rosette counter-drifts at ≈ 0.15 rad/s. Dragging horizontally twists the tube directly, and a soft rim light and outer glow frame the lens. Hypnotic, precise and endlessly varied.",
            "一个 280pt 的圆形视窗呈现由彩色插画构成的万花筒。Metal layerEffect 着色器把每个像素转换到极坐标，将角度折叠为 N 个镜像楔形（默认 8 个），再按折叠后的角度采样原图，于是一小片内容被无缝复制成完整的花窗。两个旋转同时进行：采样楔形以约 0.35 rad/s 转动——如同旋转镜筒，图案不断绽放、重组；整朵花窗则以约 0.15 rad/s 反向缓慢漂移。水平拖动可直接扭转镜筒，边缘的柔和轮廓光与外发光为镜片收边。催眠、精确，且变化无穷。"
        ),
        implementation: L(
            "visualEffect feeds the view size into a [[stitchable]] layer shader that folds atan2 angles into mirrored segments; ShaderClock supplies speed-scaled time and a DragGesture adds a manual spin offset.",
            "visualEffect 将视图尺寸传入 [[stitchable]] layerEffect 着色器，把 atan2 角度折叠为镜像分段；ShaderClock 提供按速度缩放的时间，DragGesture 叠加手动旋转偏移。"
        ),
        apis: ["layerEffect", "visualEffect", "TimelineView", "DragGesture", "Metal"],
        tags: ["kaleidoscope", "mirror", "symmetry", "polar", "pattern", "万花筒", "镜像", "对称", "花纹"],
        params: [
            .slider("segments", L("Mirrors", "镜面数"), 3...12, default: 8, step: 1, decimals: 0),
            .slider("speed", L("Turn speed", "旋转速度"), 0...2, default: 0.6, unit: "×"),
            .slider("zoom", L("Zoom", "缩放"), 0.5...1.6, default: 1.0, unit: "×"),
        ]
    ) { ctx in
        KaleidoscopeDemo(ctx: ctx)
    }

    static let shaderEdgeScan = Effect(
        id: "shader.edge-scan",
        category: .shaders,
        interaction: .tap,
        name: L("Neon Edge Scan", "霓虹边缘扫描"),
        summary: L("A glowing scan line sweeps the card, turning everything it passes into a neon wireframe.", "一道发光扫描线掠过卡片，所经之处化为霓虹线框。"),
        prompt: L(
            "A colourful artwork card is scanned like an AR capture. On tap, a luminous horizontal scan line (cyan, with an exponential glow ≈ 12 pt tall) sweeps from top to bottom over 1.4 s on an ease-in-out curve. Everything above the line is re-rendered by a Metal Sobel filter: luminance edges glow in the tint colour over a near-black navy base that keeps 8% of the original colour, so shapes, glyphs and the rounded border become a crisp neon wireframe, while everything below stays untouched. Tapping again sweeps back up and restores the artwork. A rigid haptic marks each pass. Technical, futuristic and satisfying.",
            "一张彩色插画卡片像 AR 扫描一样被“捕获”。点击后，一道明亮的水平扫描线（青色，指数衰减光晕约 12pt 高）以 ease-in-out 曲线在 1.4 秒内自上而下扫过。扫描线上方的内容由 Metal Sobel 滤镜重新渲染：亮度边缘以主题色发光，底色压成近黑的藏青并保留 8% 原色，图形、文字与圆角边框都变成清晰的霓虹线框；扫描线下方则保持原样。再次点击，扫描线自下而上扫回并还原插画。每次扫描伴随清脆触感。科技、未来感十足，令人满足。"
        ),
        implementation: L(
            "A [[stitchable]] layer shader takes eight neighbouring samples for a Sobel gradient and blends neon edges above an animatable scan position; an Animatable modifier interpolates that position so the line moves smoothly.",
            "[[stitchable]] layerEffect 着色器取八个相邻采样计算 Sobel 梯度，在可动画的扫描位置之上混合霓虹边缘；Animatable 修饰器插值扫描位置，让扫描线平滑移动。"
        ),
        apis: ["layerEffect", "Animatable", "ShaderLibrary", "Sobel", "withAnimation"],
        tags: ["edge detection", "sobel", "scan", "neon", "wireframe", "AR", "边缘检测", "扫描", "霓虹", "线框"],
        params: [
            .slider("duration", L("Sweep duration", "扫描时长"), 0.6...3.0, default: 1.4, unit: "s"),
            .slider("band", L("Glow height", "光晕高度"), 4...30, default: 12, decimals: 0, unit: "pt"),
            .choice("tint", L("Tint", "色调"), [L("Cyan", "青色"), L("Mint", "薄荷"), L("Pink", "粉色")]),
        ]
    ) { ctx in
        EdgeScanDemo(ctx: ctx)
    }
}

// MARK: - Chromatic demo

/// Spring-driven card position; velocity feeds the RGB split.
private final class ChromaticModel {
    var target: CGSize = .zero
    private(set) var position: CGSize = .zero
    private(set) var velocity: CGSize = .zero
    private var lastDate: Date?

    func step(to date: Date, response: Double, damping: Double) {
        let raw = lastDate.map { date.timeIntervalSince($0) } ?? 0
        lastDate = date
        let dt = CGFloat(min(max(raw, 0), 1.0 / 20.0))
        guard dt > 0 else { return }
        let omega = CGFloat(2 * Double.pi / max(response, 0.05))
        let stiffness = omega * omega
        let friction = 2 * CGFloat(damping) * omega
        let substeps = 4
        let h = dt / CGFloat(substeps)
        for _ in 0..<substeps {
            velocity.width += (stiffness * (target.width - position.width) - friction * velocity.width) * h
            velocity.height += (stiffness * (target.height - position.height) - friction * velocity.height) * h
            position.width += velocity.width * h
            position.height += velocity.height * h
        }
    }
}

private struct ChromaticDemo: View {
    let ctx: DemoContext
    @State private var model = ChromaticModel()
    @State private var flip = false

    var body: some View {
        let strength = ctx["strength"]
        let fringe = ctx["fringe"]
        let response = ctx["response"]
        VStack(spacing: 12) {
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let _ = model.step(to: timeline.date, response: response, damping: 0.6)
                ChromaticCard(
                    position: model.position,
                    velocity: model.velocity,
                    strength: strength,
                    fringe: fringe
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in model.target = value.translation }
                    .onEnded { _ in
                        model.target = .zero
                        if !ctx.isPreview { Haptics.tap(.soft) }
                    }
            )
            DemoHint(text: L("Drag or flick the card", "拖动或甩动卡片"), ctx: ctx)
        }
        .padding(.bottom, 8)
        .autoplay(ctx.isPreview, every: 0.9, delay: 0.3) { autoSwipe() }
    }

    private func autoSwipe() {
        flip.toggle()
        model.target = flip ? CGSize(width: CGFloat.random(in: -90...90), height: CGFloat.random(in: -50...50)) : .zero
    }
}

private struct ChromaticCard: View {
    let position: CGSize
    let velocity: CGSize
    let strength: Double
    let fringe: Double

    var body: some View {
        let k = CGFloat(strength) / 60
        let raw = CGSize(width: velocity.width * k, height: velocity.height * k)
        let length = (raw.width * raw.width + raw.height * raw.height).squareRoot()
        let scale = length > 18 ? 18 / length : 1
        let shift = CGPoint(x: raw.width * scale, y: raw.height * scale)
        let tilt = Double(velocity.width / 90).clamped(to: -8...8)
        // The lens fringe blooms with motion too, so a card at rest is perfectly clean.
        let radial = fringe * Double(min(length / 6, 1))
        ShaderArtwork()
            .visualEffect { content, proxy in
                content.layerEffect(
                    ShaderLibrary.mlChromatic(.float2(proxy.size), .float2(shift), .float(radial)),
                    maxSampleOffset: CGSize(width: 32, height: 32)
                )
            }
            .rotationEffect(.degrees(tilt))
            .shadow(color: Palette.violet.opacity(0.3), radius: 22, y: 14)
            .offset(position)
    }
}

// MARK: - Kaleidoscope demo

private struct KaleidoscopeDemo: View {
    let ctx: DemoContext
    @State private var spinOffset: Double = 0
    @State private var dragSpin: Double = 0

    var body: some View {
        let segments = ctx["segments"]
        let zoom = ctx["zoom"]
        let manual = spinOffset + dragSpin
        VStack(spacing: 12) {
            ShaderClock(preview: ctx.isPreview, speed: ctx["speed"]) { time in
                KaleidoSource(time: time)
                    .visualEffect { content, proxy in
                        content.layerEffect(
                            ShaderLibrary.mlKaleidoscope(
                                .float2(proxy.size),
                                .float(segments),
                                .float(-time * 0.15),
                                .float(time * 0.35 + manual),
                                .float(zoom)
                            ),
                            maxSampleOffset: .zero
                        )
                    }
                    .clipShape(Circle())
            }
            .frame(width: 280, height: 280)
            .overlay(Circle().strokeBorder(LinearGradient(colors: [.white.opacity(0.7), .white.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5))
            .shadow(color: Palette.violet.opacity(0.35), radius: 24, y: 10)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in dragSpin = Double(value.translation.width) / 70 }
                    .onEnded { _ in
                        spinOffset += dragSpin
                        dragSpin = 0
                    }
            )
            DemoHint(text: L("Drag sideways to turn the tube", "左右拖动以转动镜筒"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Colourful, asymmetric source art: a single wedge of it becomes the whole rosette.
private struct KaleidoSource: View {
    let time: Double

    var body: some View {
        ZStack {
            AngularGradient(
                colors: [Palette.indigo, Palette.pink, Palette.amber, Palette.mint, Palette.sky, Palette.violet, Palette.indigo],
                center: .center,
                angle: .degrees(time * 12)
            )
            Circle()
                .fill(Palette.amber)
                .frame(width: 70, height: 70)
                .offset(x: 70 + 14 * cos(time * 0.7), y: 30 + 10 * sin(time * 0.9))
            Circle()
                .fill(.white.opacity(0.85))
                .frame(width: 34, height: 34)
                .offset(x: 105, y: -26 + 18 * sin(time * 0.6))
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Palette.mint)
                .frame(width: 26, height: 90)
                .rotationEffect(.degrees(time * 20))
                .offset(x: 40, y: 64)
            Image(systemName: "sparkle")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(.white)
                .offset(x: 58, y: -8)
            Capsule()
                .fill(Palette.coral)
                .frame(width: 110, height: 14)
                .rotationEffect(.degrees(28))
                .offset(x: 90, y: 100)
        }
        .frame(width: 280, height: 280)
    }
}

// MARK: - Edge scan demo

private struct EdgeScanModifier: ViewModifier, Animatable {
    var scanY: Double
    let band: Double
    let tint: Color

    var animatableData: Double {
        get { scanY }
        set { scanY = newValue }
    }

    func body(content: Content) -> some View {
        content.layerEffect(
            ShaderLibrary.mlEdgeScan(.float(scanY), .float(band), .color(tint), .float(3.2)),
            maxSampleOffset: CGSize(width: 2, height: 2),
            isEnabled: scanY > EdgeScanDemo.restTop + 1
        )
    }
}

private struct EdgeScanDemo: View {
    let ctx: DemoContext
    @State private var scanned = false

    static let restTop: Double = -60
    static let restBottom: Double = 360

    private var tint: Color {
        switch ctx.int("tint") {
        case 1: return Palette.mint
        case 2: return Palette.pink
        default: return Color(hex: 0x4FE3FF)
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            ShaderArtwork()
                .modifier(EdgeScanModifier(
                    scanY: scanned ? EdgeScanDemo.restBottom : EdgeScanDemo.restTop,
                    band: ctx["band"],
                    tint: tint
                ))
                .shadow(color: tint.opacity(scanned ? 0.45 : 0.15), radius: 22, y: 10)
                .contentShape(Rectangle())
                .onTapGesture { sweep() }
            DemoHint(text: L("Tap to scan / restore", "点击扫描 / 还原"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: ctx["duration"] + 1.2, delay: 0.4) { sweep() }
    }

    private func sweep() {
        if !ctx.isPreview { Haptics.tap(.rigid) }
        withAnimation(.easeInOut(duration: ctx["duration"])) { scanned.toggle() }
    }
}
