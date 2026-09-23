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
        tags: ["chromatic aberration", "rgb split", "velocity", "glitch", "色散", "色差", "RGB 分离", "拖影"],
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
            "A 280 pt circular window shows a kaleidoscope built from full-bleed artwork whose motifs — dots, petals, bars and sparks — are scattered on three rings around the whole circle, so every slice holds something. A Metal layer shader converts every pixel to polar coordinates, wraps the angle into one of N wedges (8 by default) and mirrors it about the wedge center into [0, π/N], then samples the source at that angle and the same radius, so a single slice repeats as a seamless, truly mirrored rosette. Two rotations run at once: the sampled wedge turns at ≈ 0.35 rad/s — like rotating the tube, so the pattern continuously blooms and re-forms — while the whole rosette counter-drifts at ≈ 0.15 rad/s. Dragging horizontally twists the tube directly, and a soft rim light and outer glow frame the lens. Hypnotic, precise and endlessly varied.",
            "一个 280pt 的圆形视窗呈现由满版插画构成的万花筒：圆点、花瓣、短条与星芒分布在环绕整圈的三道圆环上，任何一片楔形都有内容。Metal layerEffect 着色器把每个像素转换到极坐标，把角度归入 N 个楔形之一（默认 8 个），再以楔形中线为轴镜像折叠到 [0, π/N]，然后以该角度、同一半径采样原图，于是一小片内容被无缝复制成真正镜像对称的花窗。两个旋转同时进行：采样楔形以约 0.35 rad/s 转动——如同旋转镜筒，图案不断绽放、重组；整朵花窗则以约 0.15 rad/s 反向缓慢漂移。水平拖动可直接扭转镜筒，边缘的柔和轮廓光与外发光为镜片收边。催眠、精确，且变化无穷。"
        ),
        implementation: L(
            "visualEffect feeds the view size into a [[stitchable]] layer shader that folds atan2 angles into mirrored segments; maxSampleOffset spans the whole 280 pt window because folded samples can land anywhere in it. ShaderClock supplies speed-scaled time, a Canvas draws the radial motifs and a horizontal-first DragGesture adds a manual spin offset.",
            "visualEffect 将视图尺寸传入 [[stitchable]] layerEffect 着色器，把 atan2 角度折叠为镜像分段；折叠后的采样点可能落在视窗任意位置，因此 maxSampleOffset 覆盖整个 280pt。ShaderClock 提供按速度缩放的时间，Canvas 绘制环形分布的图案，水平优先的 DragGesture 叠加手动旋转偏移。"
        ),
        apis: ["layerEffect", "visualEffect", "TimelineView", "DragGesture", "Metal"],
        tags: ["kaleidoscope", "mirror", "symmetry", "pattern", "万花筒", "镜像", "对称", "花纹"],
        params: [
            .slider("segments", L("Mirrors", "镜面数"), 3...12, default: 8, step: 1, decimals: 0),
            .slider("speed", L("Turn speed", "旋转速度"), 0...2, default: 1.0, unit: "×"),
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
            "A colorful artwork card is scanned like an AR capture. On tap, a luminous horizontal scan line (cyan, with an exponential glow ≈ 12 pt tall) sweeps from top to bottom over 1.4 s on an ease-in-out curve. Everything above the line is re-rendered by a Metal Sobel filter: luminance edges glow in the tint color over a near-black navy base that keeps 8% of the original color, so shapes, glyphs and the rounded border become a crisp neon wireframe, while everything below stays untouched. Tapping again sweeps back up and restores the artwork; at both ends the line parks three glow-heights beyond the card, so no stray glow lingers at rest. A rigid haptic marks each pass. Technical, futuristic and satisfying.",
            "一张彩色插画卡片像 AR 扫描一样被“捕获”。点击后，一道明亮的水平扫描线（青色，指数衰减光晕约 12pt 高）以 ease-in-out 曲线在 1.4 秒内自上而下扫过。扫描线上方的内容由 Metal Sobel 滤镜重新渲染：亮度边缘以主题色发光，底色压成近黑的藏青并保留 8% 原色，图形、文字与圆角边框都变成清晰的霓虹线框；扫描线下方则保持原样。再次点击，扫描线自下而上扫回并还原插画；两端停靠位置都在卡片外三倍光晕高度处，静止时不会残留光晕。每次扫描伴随清脆触感。科技、未来感十足，令人满足。"
        ),
        implementation: L(
            "A [[stitchable]] layer shader takes eight neighboring samples for a Sobel gradient and blends neon edges above an animatable scan position; an Animatable modifier interpolates that position so the line moves smoothly.",
            "[[stitchable]] layerEffect 着色器取八个相邻采样计算 Sobel 梯度，在可动画的扫描位置之上混合霓虹边缘；Animatable 修饰器插值扫描位置，让扫描线平滑移动。"
        ),
        apis: ["layerEffect", "Animatable", "ShaderLibrary", "Sobel", "withAnimation"],
        tags: ["edge detection", "sobel", "scan", "neon", "边缘检测", "扫描", "霓虹", "线框"],
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

    /// Home and still, so the timeline can pause.
    var isSettled: Bool {
        target == .zero && abs(position.width) < 0.2 && abs(position.height) < 0.2
            && abs(velocity.width) < 0.5 && abs(velocity.height) < 0.5
    }

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
    @State private var awake = true
    @State private var sleepWatcher: Task<Void, Never>?
    /// The card only starts following once a drag has moved mostly sideways, so vertical swipes scroll the page.
    @State private var engaged = false

    var body: some View {
        let strength = ctx["strength"]
        let fringe = ctx["fringe"]
        let response = ctx["response"]
        VStack(spacing: 12) {
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview), paused: !awake)) { timeline in
                let _ = model.step(to: timeline.date, response: response, damping: 0.6)
                ChromaticCard(
                    position: model.position,
                    velocity: model.velocity,
                    strength: strength,
                    fringe: fringe
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Hit area = the card at rest (260 × 300). The drag engages only after 10 pt of mostly
            // horizontal travel (then follows in any direction), so a vertical swipe still scrolls the page.
            .overlay {
                Color.clear
                    .frame(width: 260, height: 300)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 10)
                            .onChanged { value in
                                if !engaged {
                                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                                    engaged = true
                                }
                                // While awake the watcher is alive and a held card never settles.
                                if !awake { wake() }
                                model.target = value.translation
                            }
                            .onEnded { _ in
                                guard engaged else { return }
                                engaged = false
                                model.target = .zero
                                if !ctx.isPreview { Haptics.tap(.soft) }
                            }
                    )
            }
            DemoHint(text: L("Drag or flick the card", "拖动或甩动卡片"), ctx: ctx)
        }
        .padding(.bottom, 8)
        .autoplay(ctx.isPreview, every: 1.2, delay: 0.3) { autoSwipe() }
        .onAppear { wake() }
        .onDisappear { sleepWatcher?.cancel() }
    }

    /// Runs the spring only while the card moves; a watcher pauses the timeline at rest.
    private func wake() {
        if !awake { awake = true }
        sleepWatcher?.cancel()
        sleepWatcher = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(0.3))
                if model.isSettled {
                    awake = false
                    return
                }
            }
        }
    }

    /// Simulated flick: throw the card out, then let the spring pull it home so the split blooms and closes.
    private func autoSwipe() {
        wake()
        flip.toggle()
        let side: CGFloat = flip ? 1 : -1
        model.target = CGSize(width: side * CGFloat.random(in: 70...100), height: CGFloat.random(in: -50...50))
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.35))
            model.target = .zero
        }
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
        ShaderArtwork(variant: 5)
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
    @State private var dragging = false
    /// Scripted quarter-turn flourishes (arrival intro / previews), eased per frame in the clock.
    @State private var twistCount = 0
    @State private var twistStart = Date.distantPast

    var body: some View {
        let segments = ctx["segments"]
        let zoom = ctx["zoom"]
        VStack(spacing: 12) {
            ShaderClock(preview: ctx.isPreview, speed: ctx["speed"]) { time in
                let manual = spinOffset + dragSpin + scriptedTwist(now: Date())
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
                            // Folded samples can land anywhere in the window, up to its full size away.
                            maxSampleOffset: CGSize(width: 280, height: 280)
                        )
                    }
                    .clipShape(Circle())
            }
            .frame(width: 280, height: 280)
            .overlay(Circle().strokeBorder(LinearGradient(colors: [.white.opacity(0.7), .white.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5))
            .shadow(color: Palette.violet.opacity(0.35), radius: 24, y: 10)
            .contentShape(Circle())
            .gesture(
                // Horizontal-first with a small slop, so a vertical swipe still scrolls the page.
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        if !dragging {
                            guard abs(value.translation.width) > abs(value.translation.height) else { return }
                            dragging = true
                        }
                        dragSpin = Double(value.translation.width) / 70
                    }
                    .onEnded { _ in
                        spinOffset += dragSpin
                        dragSpin = 0
                        dragging = false
                    }
            )
            DemoHint(text: L("Drag sideways to turn the tube", "左右拖动以转动镜筒"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 4, delay: 0.2) { introTwist() }
    }

    /// A flourish on arrival shows the tube can be twisted: each one adds 0.9 rad with an ease-out over 1.2 s.
    /// (Shader arguments don't animate, so the easing is evaluated per frame.)
    private func introTwist() {
        twistCount += 1
        twistStart = Date()
    }

    private func scriptedTwist(now: Date) -> Double {
        guard twistCount > 0 else { return 0 }
        let p = min(max(now.timeIntervalSince(twistStart) / 1.2, 0), 1)
        let eased = 1 - pow(1 - p, 3)
        return 0.9 * (Double(twistCount - 1) + eased)
    }
}

/// Full-bleed source art with motifs spread around every angle on three rings, so whichever
/// slice the tube samples, the rosette has shapes to mirror.
private struct KaleidoSource: View {
    let time: Double

    private static let colors: [Color] = [Palette.amber, Palette.mint, Palette.pink, .white, Palette.sky, Palette.coral, Palette.violet]

    var body: some View {
        ZStack {
            AngularGradient(
                colors: [Palette.indigo, Palette.pink, Palette.amber, Palette.mint, Palette.sky, Palette.violet, Palette.indigo],
                center: .center,
                angle: .degrees(time * 12)
            )
            RadialGradient(colors: [.white.opacity(0.55), .clear], center: .center, startRadius: 0, endRadius: 70)
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                drawRing(&context, center: center, radius: 46 + 6 * sin(time * 0.8), count: 7, size: 18, style: 0, phase: time * 0.2)
                drawRing(&context, center: center, radius: 92 + 8 * sin(time * 0.6 + 1), count: 9, size: 30, style: 1, phase: -time * 0.15)
                drawRing(&context, center: center, radius: 138 + 10 * cos(time * 0.5), count: 11, size: 24, style: 2, phase: time * 0.1)
                drawRing(&context, center: center, radius: 180, count: 13, size: 16, style: 0, phase: -time * 0.12)
            }
        }
        .frame(width: 280, height: 280)
    }

    /// style 0: dots, 1: petals, 2: rotated bars. Colors cycle per motif so neighbors differ.
    private func drawRing(_ context: inout GraphicsContext, center: CGPoint, radius: Double, count: Int, size: CGFloat, style: Int, phase: Double) {
        for index in 0..<count {
            let angle = Double(index) / Double(count) * 2 * .pi + phase
            let point = CGPoint(x: center.x + CGFloat(cos(angle) * radius), y: center.y + CGFloat(sin(angle) * radius))
            let color = Self.colors[(index + style * 2) % Self.colors.count]
            let scale = CGFloat(0.7 + 0.3 * Double(index % 3))
            let w = size * scale
            switch style {
            case 1:
                let petal = Path(ellipseIn: CGRect(x: -w * 0.35, y: -w * 0.8, width: w * 0.7, height: w * 1.6))
                    .applying(CGAffineTransform(rotationAngle: CGFloat(angle + .pi / 2)))
                    .applying(CGAffineTransform(translationX: point.x, y: point.y))
                context.fill(petal, with: .color(color.opacity(0.92)))
            case 2:
                let bar = Path(roundedRect: CGRect(x: -w * 0.18, y: -w, width: w * 0.36, height: w * 2), cornerRadius: w * 0.18)
                    .applying(CGAffineTransform(rotationAngle: CGFloat(angle * 1.5 + time * 0.4)))
                    .applying(CGAffineTransform(translationX: point.x, y: point.y))
                context.fill(bar, with: .color(color))
            default:
                context.fill(Path(ellipseIn: CGRect(x: point.x - w / 2, y: point.y - w / 2, width: w, height: w)), with: .color(color))
                context.fill(Path(ellipseIn: CGRect(x: point.x - w / 5, y: point.y - w / 5, width: w * 0.4, height: w * 0.4)), with: .color(Color(hex: 0x1B1464).opacity(0.55)))
            }
        }
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
            isEnabled: scanY > EdgeScanDemo.restTop(band: band) + 1
        )
    }
}

private struct EdgeScanDemo: View {
    let ctx: DemoContext
    @State private var scanned = false

    /// Rest positions sit 3 glow-heights beyond the 300 pt card, where the exponential glow is < 5%.
    static func restTop(band: Double) -> Double { -3 * band }
    static func restBottom(band: Double) -> Double { 300 + 3 * band }

    private var tint: Color {
        switch ctx.int("tint") {
        case 1: return Palette.mint
        case 2: return Palette.pink
        default: return Color(hex: 0x4FE3FF)
        }
    }

    var body: some View {
        let band = ctx["band"]
        VStack(spacing: 14) {
            ShaderArtwork(variant: 6)
                .modifier(EdgeScanModifier(
                    scanY: scanned ? EdgeScanDemo.restBottom(band: band) : EdgeScanDemo.restTop(band: band),
                    band: band,
                    tint: tint
                ))
                .shadow(color: tint.opacity(scanned ? 0.45 : 0.15), radius: 22, y: 10)
                .contentShape(Rectangle())
                .onTapGesture { sweep() }
            DemoHint(text: L("Tap to scan / restore", "点击扫描 / 还原"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: ctx["duration"] * 2 + 1.6, delay: 0.4) { scanAndRestore() }
    }

    /// Autoplay / arrival intro: scan down, hold the wireframe briefly, then sweep back up.
    private func scanAndRestore() {
        let duration = ctx["duration"]
        withAnimation(.easeInOut(duration: duration)) { scanned = true }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration + 0.6))
            withAnimation(.easeInOut(duration: duration)) { scanned = false }
        }
    }

    private func sweep() {
        if !ctx.isPreview { Haptics.tap(.rigid) }
        withAnimation(.easeInOut(duration: ctx["duration"])) { scanned.toggle() }
    }
}
