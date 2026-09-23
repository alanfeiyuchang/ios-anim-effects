import SwiftUI

extension Effect {
    static let shaderGlassmorphism = Effect(
        id: "shader.glassmorphism",
        category: .shaders,
        interaction: .gesture,
        name: L("Frosted Glass Material", "磨砂玻璃材质"),
        summary: L("A SwiftUI material card over drifting color, with a tilt-reactive sheen — no Metal needed.", "漂浮色块上的 SwiftUI 材质卡片，倾斜时高光随之流动——无需 Metal。"),
        prompt: L(
            "A frosted-glass card floats on a deep, saturated indigo-to-magenta plate where heavily blurred color orbs (pink, sky, amber) orbit on 7–12 s loops, so the glass always has vivid color to diffuse — even on a light page. The card is a system material (background blur plus vibrancy), not a custom shader, with a 1 pt white hairline rim fading diagonally from 60% to 10% opacity and a soft drop shadow. A brief press (120 ms) arms it, then dragging tilts it up to ±12° in 3D; a diagonal specular sheen slides across the glass opposite the tilt and the orbs parallax behind it, then everything springs back (response 0.5 s, damping 0.7). Calm, luminous and physical.",
            "一张磨砂玻璃卡片悬浮在一块深靛蓝到洋红的高饱和底板上，高度模糊的彩色光球（粉、天蓝、琥珀）以 7～12 秒周期环绕，玻璃背后始终有鲜艳色彩可供柔化——即使在浅色页面上也不发灰。卡片使用系统材质（背景模糊 + 鲜明度）而非自定义着色器，边缘为 1pt 白色细描边、不透明度沿对角由 60% 渐变到 10%，并带柔和投影。按住约 120ms 后拖动，卡片在 3D 空间中倾斜最多 ±12°，一道斜向高光沿与倾斜相反的方向滑过玻璃，背后的光球产生视差；松手后一切以弹簧（响应 0.5 秒、阻尼 0.7）回正。宁静、通透、富有实体感。"
        ),
        implementation: L(
            "Pure SwiftUI materials, no Metal: blurred circles animated by TimelineView sit on a saturated gradient plate beneath a RoundedRectangle filled with .ultraThinMaterial; a press-armed DragGesture (LongPressGesture sequenced before it) drives rotation3DEffect and the offset of a gradient sheen overlay.",
            "纯 SwiftUI 材质实现，无需 Metal：TimelineView 驱动的模糊圆形铺在高饱和渐变底板上，位于 .ultraThinMaterial 圆角矩形之下；长按后接续的 DragGesture（LongPressGesture 串联）驱动 rotation3DEffect 与渐变高光层的位移。"
        ),
        apis: ["ultraThinMaterial", "rotation3DEffect", "TimelineView", "DragGesture", "blur"],
        tags: ["glassmorphism", "frosted", "material", "blur", "玻璃拟态", "毛玻璃", "材质", "磨砂"],
        params: [
            .slider("maxTilt", L("Max tilt", "最大倾斜"), 0...25, default: 12, decimals: 0, unit: "°"),
            .choice("material", L("Material", "材质"), [L("Ultra thin", "极薄"), L("Thin", "薄"), L("Regular", "常规")]),
        ]
    ) { ctx in
        GlassmorphismDemo(ctx: ctx)
    }

    static let shaderLiquidGlassLens = Effect(
        id: "shader.liquid-glass-lens",
        category: .shaders,
        interaction: .gesture,
        name: L("Liquid Glass Lens", "液态玻璃透镜"),
        summary: L("Drag a Liquid Glass droplet that refracts the content beneath.", "拖动一滴液态玻璃，实时折射下方内容。"),
        prompt: L(
            "A Liquid Glass droplet (iOS 26 material) rests over a colorful grid of content. Grabbing it keeps the finger's offset and the droplet trails the finger on a tight spring (response ≈ 0.18 s); the glass refracts whatever is beneath in real time, its rim catching specular light. It stretches up to 12% along the exact direction of travel — diagonals included — while narrowing across it, springing round again (response 0.35 s, damping 0.6) on release. A tap makes it pulse like a water bead. On iOS 18 a material droplet sits over a Metal lens that stretches along the same heading and sends a ripple ring out on each tap, so the lensing and its liquid motion survive. A physical, optical layer floating over the UI.",
            "一滴液态玻璃（iOS 26 材质）停在一片色彩丰富的内容网格之上。按住拖动时保持手指与水滴的相对偏移，水滴以紧致弹簧（响应约 0.18 秒）跟随手指；玻璃实时折射下方内容，边缘捕捉镜面高光。它沿真实运动方向（包括斜向）拉长最多 12%、垂直方向相应收窄，松手后以弹簧（响应 0.35 秒、阻尼 0.6）回弹成正圆。点击时它会像水珠一样脉动。在 iOS 18 上，材质水滴下方的 Metal 透镜随之沿同一方向拉伸，点击时荡开一圈水波，透镜感与液态动感依然保留。整体是一层悬浮于界面之上的真实光学材质。"
        ),
        implementation: L(
            "On iOS 26 the droplet uses .glassEffect(.regular.interactive(), in: Circle()); earlier systems fall back to .ultraThinMaterial with a gradient rim over an mlLensDrop distortion whose elliptical footprint follows the stretch and whose ripple ring plays on tap. Drag velocity sets a stretch applied as rotate(−θ) → scale → rotate(θ), so it follows any direction.",
            "iOS 26 上使用 .glassEffect(.regular.interactive(), in: Circle())；更早系统回退为 .ultraThinMaterial 加渐变描边，并对背景施加 mlLensDrop 扭曲：椭圆作用区随拉伸变形，点击时播放水波环。拖动速度决定拉伸量，按 旋转(−θ) → 缩放 → 旋转(θ) 施加，可沿任意方向拉伸。"
        ),
        apis: ["glassEffect", "Glass.interactive()", "DragGesture", "scaleEffect", "distortionEffect"],
        tags: ["liquid glass", "ios 26", "refraction", "lens", "液态玻璃", "折射", "透镜", "玻璃"],
        params: [
            .slider("size", L("Droplet size", "水滴尺寸"), 70...160, default: 110, decimals: 0, unit: "pt"),
            .toggle("tint", L("Tinted glass", "着色玻璃"), default: false),
        ],
        requirement: "iOS 26"
    ) { ctx in
        LiquidLensDemo(ctx: ctx)
    }
}

// MARK: - Glassmorphism

private struct GlassmorphismDemo: View {
    let ctx: DemoContext
    @State private var drag: CGSize = .zero
    /// True while a tilt is armed; resets itself if the system cancels the gesture, so the card always settles.
    @GestureState private var tilting = false

    private var material: Material {
        switch ctx.int("material") {
        case 1: return .thinMaterial
        case 2: return .regularMaterial
        default: return .ultraThinMaterial
        }
    }

    var body: some View {
        let maxTilt = ctx["maxTilt"]
        let nx = Double(drag.width / 140).clamped(to: -1...1)
        let ny = Double(drag.height / 140).clamped(to: -1...1)
        let parallax = CGSize(width: CGFloat(-nx * 18), height: CGFloat(-ny * 18))
        ZStack {
            ShaderClock(preview: ctx.isPreview) { time in
                GlassOrbs(time: time, parallax: parallax)
            }
            .background(
                LinearGradient(colors: [Color(hex: 0x1B1464), Color(hex: 0x4A1D96), Color(hex: 0xA3165F)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .padding(14)
            glassCard(nx: nx, ny: ny)
                .rotation3DEffect(.degrees(nx * maxTilt), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
                .rotation3DEffect(.degrees(-ny * maxTilt), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Only the card tilts, and only after a short press, so swipes (even on the card) still scroll the page.
        .overlay {
            Color.clear
                .frame(width: 250, height: 160)
                .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .gesture(tiltGesture)
                .onChange(of: tilting) { _, isTilting in
                    if !isTilting { settle() }
                }
        }
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Press the card, then drag to tilt", "按住卡片片刻再拖动使其倾斜"), ctx: ctx)
                .padding(.bottom, 22)
                .environment(\.colorScheme, .dark)
                .allowsHitTesting(false)
        }
        .autoplay(ctx.isPreview, every: 1.8, delay: 0.2) { tiltAndSettle() }
    }

    private var tiltGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.12)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .updating($tilting) { _, state, _ in state = true }
            .onChanged { value in
                guard case .second(true, let pending) = value else { return }
                guard let move = pending else {
                    Haptics.tap(.soft)
                    return
                }
                withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.8)) { drag = move.translation }
            }
    }

    private func settle() {
        guard drag != .zero else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { drag = .zero }
    }

    /// Simulated drag: tilt toward a random corner, then spring back flat.
    private func tiltAndSettle() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            drag = CGSize(width: CGFloat.random(in: -110...110), height: CGFloat.random(in: -90...90))
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.8))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { drag = .zero }
        }
    }

    private func glassCard(nx: Double, ny: Double) -> some View {
        // Typed up front so the modifier chain below stays cheap for the type checker.
        let sheenStart = UnitPoint(x: CGFloat(0.2 - nx * 0.5), y: CGFloat(-ny * 0.5))
        let sheenEnd = UnitPoint(x: CGFloat(0.8 - nx * 0.5), y: CGFloat(1 - ny * 0.5))
        let shadowX = CGFloat(-nx * 10)
        let shadowY = CGFloat(16 - ny * 6)
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "wave.3.right.circle.fill")
                    .font(.title)
                Spacer()
                Text(verbatim: "PLUS")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .italic()
            }
            Spacer()
            Text(verbatim: "•••• 2046")
                .font(.system(size: 22, weight: .semibold, design: .monospaced))
            Text(ctx.language == .zh ? "动效词典 会员卡" : "Motion Lexicon Member")
                .font(.footnote.weight(.medium))
                .opacity(0.8)
        }
        .foregroundStyle(.white)
        .padding(22)
        .frame(width: 250, height: 160)
        .background(material, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            LinearGradient(
                colors: [.clear, .white.opacity(0.35), .clear],
                startPoint: sheenStart,
                endPoint: sheenEnd
            )
            .blendMode(.plusLighter)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .allowsHitTesting(false)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(LinearGradient(colors: [.white.opacity(0.6), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 24, x: shadowX, y: shadowY)
        .environment(\.colorScheme, .dark)
    }
}

private struct GlassOrbs: View {
    let time: Double
    let parallax: CGSize

    var body: some View {
        ZStack {
            orb(Palette.pink, size: 170, x: cos(time / 1.4) * 70, y: sin(time / 1.9) * 60 - 30)
            orb(Palette.sky, size: 180, x: sin(time / 1.7) * 80 + 20, y: cos(time / 1.3) * 50 + 40)
            orb(Palette.amber, size: 120, x: cos(time / 1.1 + 2) * 90, y: sin(time / 1.5 + 1) * 80)
        }
        // Offsets don't grow layout bounds, so without a full-size frame the drawingGroup
        // rasterizes (and the blur clips) to a ~200 pt box, leaving hard-edged color slabs.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(parallax)
        .blur(radius: 30)
        .drawingGroup()
    }

    private func orb(_ color: Color, size: CGFloat, x: Double, y: Double) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .offset(x: x, y: y)
    }
}

// MARK: - Liquid glass lens

/// True where the real Liquid Glass material exists; the fallback adds a Metal bulge instead.
private var liquidGlassAvailable: Bool {
    #if compiler(>=6.2)
    if #available(iOS 26.0, *) { return true }
    #endif
    return false
}

private struct LiquidLensDemo: View {
    let ctx: DemoContext
    @State private var position: CGPoint?
    /// Finger-to-center offset captured when a drag starts on the droplet.
    @State private var grab: CGSize?
    /// Stretch amount (0…0.12) and its direction in radians.
    @State private var stretch: CGFloat = 0
    @State private var heading: Double = 0
    @State private var pulse = false
    /// Counts taps; the fractional part while it animates n → n + 1 drives the fallback lens's ripple ring.
    @State private var ripples: Double = 0
    @State private var size: CGSize = CGSize(width: 340, height: 340)

    var body: some View {
        let diameter = ctx.cg("size")
        let point = position ?? CGPoint(x: size.width / 2, y: size.height / 2)
        ZStack {
            LensBackdrop()
                .modifier(LensRefraction(
                    center: point,
                    radius: Double(diameter) / 2,
                    heading: heading,
                    stretch: stretch,
                    ripples: ripples,
                    enabled: !liquidGlassAvailable
                ))
            LensDroplet(diameter: diameter, tinted: ctx.bool("tint"))
                // Stretch along the travel direction: rotate into it, scale, rotate back.
                .rotationEffect(.radians(-heading))
                .scaleEffect(x: 1 + stretch, y: 1 - stretch * 0.6)
                .rotationEffect(.radians(heading))
                .scaleEffect(pulse ? 1.12 : 1)
                .position(point)
            // Only the droplet is interactive, so swipes on the backdrop still scroll the page.
            Color.clear
                .frame(width: diameter, height: diameter)
                .contentShape(Circle())
                .position(point)
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.space))
                        .onChanged { value in drag(value, current: point, radius: diameter / 2) }
                        .onEnded { _ in
                            grab = nil
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { stretch = 0 }
                        }
                )
                .simultaneousGesture(TapGesture().onEnded { flex() })
        }
        .coordinateSpace(.named(Self.space))
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Drag or tap the droplet", "拖动或点击水滴"), ctx: ctx)
                .padding(.bottom, 12)
                .allowsHitTesting(false)
        }
        .autoplay(ctx.isPreview, every: 1.6, delay: 0.2) { glide() }
    }

    private static let space = "liquidLensStage"

    private func drag(_ value: DragGesture.Value, current: CGPoint, radius: CGFloat) {
        if grab == nil {
            let dx = current.x - value.startLocation.x
            let dy = current.y - value.startLocation.y
            grab = hypot(dx, dy) <= radius ? CGSize(width: dx, height: dy) : .zero
        }
        let offset = grab ?? .zero
        let velocity = value.velocity
        let speed = hypot(velocity.width, velocity.height)
        withAnimation(.interactiveSpring(response: 0.18, dampingFraction: 0.8)) {
            position = CGPoint(x: value.location.x + offset.width, y: value.location.y + offset.height)
            stretch = min(speed / 3000, 0.12)
        }
        if speed > 60 {
            // Stretch is symmetric, so keep the angle in (-π/2, π/2] to avoid spinning through 180°.
            var angle = atan2(Double(velocity.height), Double(velocity.width))
            if angle > .pi / 2 { angle -= .pi }
            if angle <= -.pi / 2 { angle += .pi }
            heading = angle
        }
    }

    /// Simulated drag: slide diagonally with a stretch, then relax.
    private func glide() {
        let target = CGPoint(
            x: CGFloat.random(in: 80...max(81, size.width - 80)),
            y: CGFloat.random(in: 80...max(81, size.height - 80))
        )
        let from = position ?? CGPoint(x: size.width / 2, y: size.height / 2)
        heading = {
            var angle = atan2(Double(target.y - from.y), Double(target.x - from.x))
            if angle > .pi / 2 { angle -= .pi }
            if angle <= -.pi / 2 { angle += .pi }
            return angle
        }()
        withAnimation(.spring(response: 0.8, dampingFraction: 0.65)) { position = target }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { stretch = 0.1 }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.35))
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { stretch = 0 }
        }
    }

    private func flex() {
        Haptics.tap(.soft)
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { pulse = true }
        withAnimation(.easeOut(duration: 0.75)) { ripples = ripples.rounded(.down) + 1 }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.18))
            withAnimation(.spring(response: 0.4, dampingFraction: 0.45)) { pulse = false }
        }
    }
}

/// iOS 18 fallback: a Metal lens under the droplet that stretches along the drag heading with it and
/// rings with a water-bead ripple on tap, so the fallback keeps the droplet's own motion, not just a bulge.
/// Animatable so the lens rides the same springs as the droplet.
private struct LensRefraction: ViewModifier, Animatable {
    var center: CGPoint
    var radius: Double
    var heading: Double
    var stretch: CGFloat
    var ripples: Double
    var enabled: Bool

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, Double>> {
        get { AnimatablePair(AnimatablePair(center.x, center.y), AnimatablePair(stretch, ripples)) }
        set {
            center = CGPoint(x: newValue.first.first, y: newValue.first.second)
            stretch = newValue.second.first
            ripples = newValue.second.second
        }
    }

    func body(content: Content) -> some View {
        let ripple = ripples - ripples.rounded(.down)
        let reach = CGFloat(radius) * (1 + stretch) + 8
        return content.distortionEffect(
            ShaderLibrary.mlLensDrop(
                .float2(center),
                .float(radius),
                .float(0.32),
                .float(heading),
                .float(stretch),
                .float(ripple)
            ),
            maxSampleOffset: CGSize(width: reach, height: reach),
            isEnabled: enabled
        )
    }
}

private struct LensBackdrop: View {
    private let symbols = ["sun.max.fill", "moon.stars.fill", "cloud.bolt.fill", "leaf.fill", "flame.fill", "drop.fill",
                           "sparkles", "bolt.fill", "heart.fill", "star.fill", "music.note", "camera.fill"]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xFDEBFF), Color(hex: 0xDDE6FF)], startPoint: .top, endPoint: .bottom)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 14) {
                ForEach(symbols.indices, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Palette.spectrum[index % Palette.spectrum.count].gradient)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            Image(systemName: symbols[index])
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                }
            }
            .padding(24)
        }
    }
}

private struct LensDroplet: View {
    let diameter: CGFloat
    let tinted: Bool

    var body: some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            Circle()
                .fill(Color.clear)
                .frame(width: diameter, height: diameter)
                .glassEffect(glass, in: Circle())
        } else {
            fallback
        }
        #else
        fallback
        #endif
    }

    #if compiler(>=6.2)
    @available(iOS 26.0, *)
    private var glass: Glass {
        tinted ? Glass.regular.tint(Palette.violet.opacity(0.35)).interactive() : Glass.regular.interactive()
    }
    #endif

    private var fallback: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .overlay {
                Circle().fill(tinted ? Palette.violet.opacity(0.18) : Color.clear)
            }
            .overlay {
                Circle()
                    .strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0.15), .white.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1.5
                    )
            }
            .overlay(alignment: .topLeading) {
                Ellipse()
                    .fill(.white.opacity(0.55))
                    .frame(width: diameter * 0.32, height: diameter * 0.16)
                    .blur(radius: 4)
                    .offset(x: diameter * 0.18, y: diameter * 0.14)
            }
            .frame(width: diameter, height: diameter)
            .shadow(color: .black.opacity(0.18), radius: 14, y: 8)
    }
}
