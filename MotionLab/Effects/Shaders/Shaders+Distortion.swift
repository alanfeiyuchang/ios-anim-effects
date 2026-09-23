import SwiftUI

// MARK: - Ripple

extension Effect {
    static let shaderRipple = Effect(
        id: "shader.ripple",
        category: .shaders,
        interaction: .tap,
        name: L("Touch Ripple", "触点涟漪"),
        summary: L("A Metal water ripple that radiates from where you tap.", "从触点向外扩散的 Metal 水波涟漪。"),
        prompt: L(
            "On tap, a circular water ripple radiates outward from the exact touch point across the whole surface. Each pixel is displaced along the radial direction by a damped sine wave — amplitude ≈12 pt, frequency ≈15, exponential decay ≈8 — that reaches it after a delay proportional to its distance (wave speed ≈1200 pt/s), so the ring visibly travels. Crests are brightened by ~30% to fake a specular highlight. Each point settles within about half a second of the ring passing, and the shader switches off as soon as the farthest corner has calmed (≈ 0.9 s at the defaults), so the effect costs nothing at rest; subsequent taps restart it from the new point, feeling like touching the surface of liquid glass.",
            "点击时，一圈水波从精确的触点位置向整个画面扩散。每个像素沿径向被一条衰减正弦波推移——振幅约 12pt、频率约 15、指数衰减约 8——并按其与触点的距离延迟到达（波速约 1200pt/s），因此能清楚看到波环向外推进。波峰处亮度提升约 30%，模拟高光反射。波环经过后每一点约半秒即归于平静；最远的角落一旦平息（默认约 0.9 秒）着色器便立即关闭，静止时零开销。再次点击则从新位置重新激起，如同触碰一块液态玻璃。"
        ),
        implementation: L(
            "A [[stitchable]] Metal layer shader samples the view at a radially displaced position. A keyframeAnimator drives the elapsed time each time the tap trigger changes, over a duration derived from wave speed and decay (travel to the farthest corner plus ~4.6 / decay to settle within 1%).",
            "[[stitchable]] Metal layerEffect 着色器在径向偏移后的位置对视图采样；每次点击改变 trigger，由 keyframeAnimator 推进经过时间；时长由波速与衰减推导（波传到最远角的时间 + 约 4.6 / 衰减，使振幅降到 1% 以内）。"
        ),
        apis: ["layerEffect", "ShaderLibrary", "keyframeAnimator", "onTapGesture(coordinateSpace:)", "Metal"],
        tags: ["ripple", "water", "shader", "metal", "涟漪", "水波", "着色器", "WWDC24"],
        params: [
            .slider("amplitude", L("Amplitude", "振幅"), 2...30, default: 12, decimals: 0, unit: "pt"),
            .slider("frequency", L("Frequency", "频率"), 5...30, default: 15, decimals: 0),
            .slider("decay", L("Decay", "衰减"), 2...15, default: 8, decimals: 1),
            .slider("speed", L("Wave speed", "波速"), 400...2000, default: 1200, decimals: 0, unit: "pt/s"),
        ]
    ) { ctx in
        RippleDemo(ctx: ctx)
    }

    static let shaderWave = Effect(
        id: "shader.wave",
        category: .shaders,
        interaction: .loop,
        name: L("Flag Wave", "旗帜波动"),
        summary: L("Continuous sine distortion like fabric in the wind.", "如风中布料般持续起伏的正弦扭曲。"),
        prompt: L(
            "A card undulates continuously like a flag in a gentle breeze. Every pixel is displaced vertically by a sine wave travelling along the x-axis and horizontally by a slower cosine along the y-axis at half the amplitude, so the surface ripples diagonally rather than bouncing uniformly. The slope of the wave also lights the fabric: rising faces brighten and falling faces darken by up to ~30%, so folds read as real cloth. The loop is seamless with no easing — amplitude ≈6 pt, a wavelength parameter of 30 pt (≈190 pt crest to crest, i.e. 2π × 30), a ≈2 s cycle — calm and hypnotic, ideal for hero artwork or ambient headers.",
            "卡片像微风中的旗帜一样持续起伏。每个像素在竖直方向受沿 x 轴传播的正弦波推移，在水平方向受沿 y 轴、速度更慢、振幅减半的余弦波推移，使表面呈斜向涟漪而非整体上下跳动。波形斜率同时为布面打光：迎光面最多提亮约 30%，背光面相应变暗，褶皱因此具有真实布料的体积感。运动无缝循环、无缓动：振幅约 6pt，波长参数 30pt（波峰间距约 190pt，即 2π × 30），周期约 2 秒，平静而催眠，适合头图或氛围型标题区。"
        ),
        implementation: L(
            "A Metal layer shader samples the view at a sin/cos-displaced position and scales brightness by the wave's analytic slope for fold shading; a TimelineView(.animation) feeds accumulated, speed-scaled time.",
            "Metal layerEffect 着色器在经 sin/cos 位移后的坐标采样，并按波形的解析斜率调节亮度形成褶皱明暗；TimelineView(.animation) 提供按速度累积的时间。"
        ),
        apis: ["layerEffect", "TimelineView", "ShaderLibrary", "Metal"],
        tags: ["wave", "flag", "cloth", "distortion", "fabric", "波浪", "旗帜", "布料", "扭曲"],
        params: [
            .slider("amplitude", L("Amplitude", "振幅"), 0...16, default: 6, decimals: 1, unit: "pt"),
            .slider("wavelength", L("Wavelength", "波长"), 10...80, default: 30, decimals: 0, unit: "pt"),
            .slider("speed", L("Speed", "速度"), 0.5...8, default: 3, decimals: 1),
            .slider("shade", L("Fold shading", "褶皱明暗"), 0...1, default: 0.6),
        ]
    ) { ctx in
        WaveDemo(ctx: ctx)
    }

    static let shaderMagnifier = Effect(
        id: "shader.magnifier",
        category: .shaders,
        interaction: .gesture,
        name: L("Glass Lens", "玻璃透镜"),
        summary: L("Drag a glass sphere that magnifies, bends light at its rim and splits it into color.", "拖动一颗玻璃球：中心放大、边缘折光，并把光分解出彩色色边。"),
        prompt: L(
            "A glass sphere with a 70 pt radius floats over dense typography on a dark grid. A Metal layer shader treats it as a spherical cap: the core magnifies up to 2× with a quadratic falloff, the steep rim bends rays inward so the grid lines curve hard at the edge, and red and blue refract by different amounts near the rim, leaving a thin cyan/orange dispersion fringe. A specular highlight from the top-left and slight rim shading give it volume. Grabbing anywhere on the lens keeps the finger's offset; on release it springs home (response 0.45 s, damping 0.7). Optical, precise and tangible.",
            "一颗半径约 70pt 的玻璃球悬浮在深色网格与密集文字之上。Metal layerEffect 着色器把它当作球冠计算：中心按二次方衰减最多放大 2 倍；陡峭的边缘把光线向内折弯，网格线在边缘处强烈弯曲；红、蓝通道在边缘折射程度不同，留下一圈细细的青橙色散色边。左上方的镜面高光与轻微的边缘暗化带来体积感。在透镜任意位置按住拖动都会保持手指与球心的相对偏移；松手后以弹簧（响应 0.45 秒、阻尼 0.7）回到中心。光学、精准、可触可感。"
        ),
        implementation: L(
            "A [[stitchable]] layer shader computes a spherical-cap height per pixel, remaps samples for magnification plus rim refraction, samples R/G/B with different refraction for dispersion and adds a Blinn-style highlight; an Animatable modifier springs the center.",
            "[[stitchable]] layerEffect 着色器逐像素计算球冠高度，重映射采样点实现中心放大与边缘折射，并以不同折射量分别采样 R/G/B 形成色散，再叠加镜面高光；Animatable 修饰器让球心以弹簧移动。"
        ),
        apis: ["layerEffect", "Animatable", "DragGesture", "Shader.Argument.float2", "Metal"],
        tags: ["lens", "glass", "refraction", "dispersion", "magnifier", "透镜", "玻璃", "折射", "色散", "放大镜"],
        params: [
            .slider("radius", L("Radius", "半径"), 40...120, default: 70, decimals: 0, unit: "pt"),
            .slider("strength", L("Magnification", "放大强度"), 0.1...0.8, default: 0.5),
            .slider("dispersion", L("Dispersion", "色散"), 0...1, default: 0.5),
        ]
    ) { ctx in
        MagnifierDemo(ctx: ctx)
    }

    static let shaderSwirl = Effect(
        id: "shader.swirl",
        category: .shaders,
        interaction: .gesture,
        name: L("Twirl", "漩涡扭转"),
        summary: L("Drag to twist the content into a vortex that springs back.", "拖动将内容拧成漩涡，松手后弹回。"),
        prompt: L(
            "Pressing and dragging on the surface twists the content into a vortex whose center rides under the finger, so the swirl can be stirred around the card. Rotation is strongest at the core and falls off quadratically to zero at a ≈110 pt radius, so the pattern spirals smoothly without tearing. Drag distance maps to twist angle (up to ±2.5 rad), with the sign taken from the horizontal direction. Releasing lets the vortex unwind in place with an underdamped spring (response 0.6 s, damping 0.5), overshooting slightly the other way before settling — playful, liquid and tactile.",
            "在画面上按住拖动，内容会被拧成漩涡，漩涡中心始终跟随手指，可以在卡片上“搅动”。旋转在中心最强，并以二次方衰减至约 110pt 半径处为零，因此图案平滑盘旋而不撕裂。拖动距离映射为扭转角度（最大 ±2.5 弧度），方向由水平拖动方向决定。松手后漩涡在原地以欠阻尼弹簧（响应 0.6 秒、阻尼 0.5）解旋，并轻微反向过冲后稳定——俏皮、流体、富有触感。"
        ),
        implementation: L(
            "A Metal distortion shader rotates sample coordinates by an angle that decays with distance. The angle and center live in an Animatable ViewModifier; the center tracks the drag location and a spring animates the angle back to zero.",
            "Metal distortionEffect 以随距离衰减的角度旋转采样坐标；角度与中心放在遵循 Animatable 的 ViewModifier 中，中心跟随拖动位置，松手后用弹簧把角度动画回零。"
        ),
        apis: ["distortionEffect", "Animatable", "DragGesture", "spring"],
        tags: ["swirl", "twirl", "vortex", "漩涡", "扭曲", "旋转"],
        params: [
            .slider("radius", L("Radius", "半径"), 60...180, default: 110, decimals: 0, unit: "pt"),
            .slider("maxAngle", L("Max twist", "最大扭转"), 0.5...4, default: 2.5, decimals: 1, unit: " rad"),
        ]
    ) { ctx in
        SwirlDemo(ctx: ctx)
    }
}

// MARK: - Ripple demo

private struct RippleDemo: View {
    let ctx: DemoContext
    @State private var origin: CGPoint = CGPoint(x: 130, y: 150)
    @State private var trigger = 0

    var body: some View {
        VStack(spacing: 14) {
            ShaderArtwork(variant: 2)
                .modifier(RippleEffect(
                    at: origin,
                    trigger: trigger,
                    amplitude: ctx["amplitude"],
                    frequency: ctx["frequency"],
                    decay: ctx["decay"],
                    speed: ctx["speed"]
                ))
                .onTapGesture(coordinateSpace: .local) { location in
                    origin = location
                    trigger += 1
                    Haptics.tap(.soft)
                }
            DemoHint(text: L("Tap anywhere on the card", "点击卡片任意位置"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.2, delay: 0.3) {
            origin = CGPoint(x: CGFloat.random(in: 60...200), y: CGFloat.random(in: 70...230))
            trigger += 1
        }
    }
}

private struct RippleEffect<T: Equatable>: ViewModifier {
    var at: CGPoint
    var trigger: T
    var amplitude: Double
    var frequency: Double
    var decay: Double
    var speed: Double

    func body(content: Content) -> some View {
        let origin = at
        let amplitude = amplitude
        let frequency = frequency
        let decay = decay
        let speed = speed
        // Wave reaches the farthest corner of the 260 × 300 card, then decays to 1% (e^-4.6).
        let far = [CGPoint(x: 0, y: 0), CGPoint(x: 260, y: 0), CGPoint(x: 0, y: 300), CGPoint(x: 260, y: 300)]
            .map { hypot($0.x - origin.x, $0.y - origin.y) }
            .max() ?? 400
        let duration: TimeInterval = Double(far) / max(speed, 1) + 4.6 / max(decay, 0.5)
        content.keyframeAnimator(initialValue: 0.0, trigger: trigger) { view, elapsed in
            view.modifier(RippleShaderModifier(
                origin: origin,
                elapsed: elapsed,
                duration: duration,
                amplitude: amplitude,
                frequency: frequency,
                decay: decay,
                speed: speed
            ))
        } keyframes: { _ in
            MoveKeyframe(0.0)
            LinearKeyframe(duration, duration: duration)
        }
    }
}

private struct RippleShaderModifier: ViewModifier {
    var origin: CGPoint
    var elapsed: TimeInterval
    var duration: TimeInterval
    var amplitude: Double
    var frequency: Double
    var decay: Double
    var speed: Double

    func body(content: Content) -> some View {
        let shader = ShaderLibrary.mlRipple(
            .float2(origin),
            .float(elapsed),
            .float(amplitude),
            .float(frequency),
            .float(decay),
            .float(speed)
        )
        content.layerEffect(
            shader,
            maxSampleOffset: CGSize(width: amplitude, height: amplitude),
            isEnabled: elapsed > 0 && elapsed < duration
        )
    }
}

// MARK: - Wave demo

private struct WaveDemo: View {
    let ctx: DemoContext

    var body: some View {
        let amplitude = ctx["amplitude"]
        let wavelength = ctx["wavelength"]
        let speed = ctx["speed"]
        let shade = ctx["shade"]
        // Speed scales the accumulated clock (not the shader time), so dragging the slider never jumps the wave.
        ShaderClock(preview: ctx.isPreview, speed: speed) { time in
            ShaderArtwork(variant: 1)
                .padding(20)
                .layerEffect(
                    ShaderLibrary.mlFlagWave(.float(time), .float(amplitude), .float(wavelength), .float(shade)),
                    maxSampleOffset: CGSize(width: amplitude, height: amplitude)
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Magnifier demo

private struct MagnifierDemo: View {
    let ctx: DemoContext
    @State private var center: CGPoint?
    /// Offset from the finger to the lens center, captured when a drag starts on the lens.
    @State private var grab: CGSize?
    @State private var size: CGSize = CGSize(width: 340, height: 340)

    var body: some View {
        let radius = ctx["radius"]
        let home = CGPoint(x: size.width / 2, y: size.height / 2)
        ShaderGridArtwork()
            .modifier(GlassLensModifier(
                center: center ?? home,
                radius: radius,
                magnify: ctx["strength"],
                dispersion: ctx["dispersion"]
            ))
            // Only the lens itself is draggable, so swipes elsewhere still scroll the page.
            .overlay {
                Color.clear
                    .frame(width: radius * 2, height: radius * 2)
                    .contentShape(Circle())
                    .position(center ?? home)
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.space))
                            .onChanged { value in drag(value, home: home, radius: CGFloat(radius)) }
                            .onEnded { _ in
                                grab = nil
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { center = nil }
                            }
                    )
            }
            .coordinateSpace(.named(Self.space))
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
            .overlay(alignment: .bottom) {
                DemoHint(text: L("Drag the lens", "拖动透镜"), ctx: ctx)
                    .padding(.bottom, 14)
                    .environment(\.colorScheme, .dark)
                    .allowsHitTesting(false)
            }
            .autoplay(ctx.isPreview, every: 1.8, delay: 0.3) { glide(home: home) }
    }

    private static let space = "glassLensStage"

    private func drag(_ value: DragGesture.Value, home: CGPoint, radius: CGFloat) {
        let current = center ?? home
        if grab == nil {
            let dx = current.x - value.startLocation.x
            let dy = current.y - value.startLocation.y
            // Grabbing the lens keeps the finger's offset, so it never jumps under the finger.
            grab = hypot(dx, dy) <= radius ? CGSize(width: dx, height: dy) : .zero
            Haptics.tap(.soft)
        }
        let offset = grab ?? .zero
        let target = CGPoint(
            x: (value.location.x + offset.width).clamped(to: 0...max(size.width, 1)),
            y: (value.location.y + offset.height).clamped(to: 0...max(size.height, 1))
        )
        withAnimation(.interactiveSpring(response: 0.18, dampingFraction: 0.86)) { center = target }
    }

    /// Simulated drag: glide to a spot over the text, then spring home.
    private func glide(home: CGPoint) {
        let spot = CGPoint(
            x: home.x + CGFloat.random(in: -90...90),
            y: home.y + (Bool.random() ? -40 : 30)
        )
        withAnimation(.spring(response: 0.7, dampingFraction: 0.78)) { center = spot }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.9))
            guard grab == nil else { return }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { center = nil }
        }
    }
}

/// Animatable so springs move the lens (shader arguments don't animate on their own).
private struct GlassLensModifier: ViewModifier, Animatable {
    var center: CGPoint
    var radius: Double
    var magnify: Double
    var dispersion: Double

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(center.x, center.y) }
        set { center = CGPoint(x: newValue.first, y: newValue.second) }
    }

    func body(content: Content) -> some View {
        content
            .layerEffect(
                ShaderLibrary.mlGlassLens(.float2(center), .float(radius), .float(magnify), .float(dispersion)),
                maxSampleOffset: CGSize(width: radius, height: radius)
            )
            .overlay {
                Circle()
                    .strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.75), .white.opacity(0.1), .white.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1
                    )
                    .frame(width: radius * 2, height: radius * 2)
                    .shadow(color: .black.opacity(0.35), radius: 12, y: 8)
                    .position(center)
                    .allowsHitTesting(false)
            }
    }
}

// MARK: - Swirl demo

private struct SwirlDemo: View {
    let ctx: DemoContext
    @State private var center = CGPoint(x: 130, y: 150)
    @State private var angle: Double = 0

    var body: some View {
        VStack(spacing: 14) {
            ShaderArtwork(variant: 4)
                .modifier(SwirlModifier(center: center, radius: ctx["radius"], angle: angle))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            // The vortex rides under the finger; distance sets the twist, horizontal direction its sign.
                            center = value.location
                            let maxAngle = ctx["maxAngle"]
                            let distance = Double(hypot(value.translation.width, value.translation.height))
                            let sign: Double = value.translation.width < 0 ? -1 : 1
                            angle = (sign * distance / 60).clamped(to: -maxAngle...maxAngle)
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) { angle = 0 }
                        }
                )
            DemoHint(text: L("Press and stir around", "按住并拖动搅动"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.8, delay: 0.2) { stir() }
    }

    /// Simulated stir: the vortex travels diagonally while twisting, then unwinds in place.
    private func stir() {
        center = CGPoint(x: 90, y: 110)
        withAnimation(.easeInOut(duration: 0.6)) {
            center = CGPoint(x: 170, y: 190)
            angle = ctx["maxAngle"]
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.7))
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) { angle = 0 }
        }
    }
}

private struct SwirlModifier: ViewModifier, Animatable {
    var center: CGPoint
    var radius: Double
    var angle: Double

    var animatableData: AnimatablePair<Double, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(angle, AnimatablePair(center.x, center.y)) }
        set {
            angle = newValue.first
            center = CGPoint(x: newValue.second.first, y: newValue.second.second)
        }
    }

    func body(content: Content) -> some View {
        content.distortionEffect(
            ShaderLibrary.mlSwirl(.float2(center), .float(radius), .float(angle)),
            maxSampleOffset: CGSize(width: radius, height: radius),
            isEnabled: abs(angle) > 0.001
        )
    }
}
