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
            "On tap, a circular water ripple radiates outward from the exact touch point across the whole surface. Each pixel is displaced along the radial direction by a damped sine wave — amplitude ≈12 pt, frequency ≈15, exponential decay ≈8 — that reaches it after a delay proportional to its distance (wave speed ≈1200 pt/s), so the ring visibly travels. Crests are brightened by ~30% to fake a specular highlight. The whole ripple settles in about 1–2 seconds; subsequent taps restart it from the new point, feeling like touching the surface of liquid glass.",
            "点击时，一圈水波从精确的触点位置向整个画面扩散。每个像素沿径向被一条衰减正弦波推移——振幅约 12pt、频率约 15、指数衰减约 8——并按其与触点的距离延迟到达（波速约 1200pt/s），因此能清楚看到波环向外推进。波峰处亮度提升约 30%，模拟高光反射。整个涟漪在 1～2 秒内平息，再次点击则从新位置重新激起，如同触碰一块液态玻璃。"
        ),
        implementation: L(
            "A [[stitchable]] Metal layer shader samples the view at a radially displaced position. A keyframeAnimator drives the elapsed time from 0 to the duration each time the tap trigger changes.",
            "[[stitchable]] Metal layerEffect 着色器在径向偏移后的位置对视图采样；每次点击改变 trigger，由 keyframeAnimator 将经过时间从 0 线性推进到时长。"
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
            "A card undulates continuously like a flag in a gentle breeze. Every pixel is displaced vertically by a sine wave travelling along the x-axis and horizontally by a slower cosine along the y-axis at half the amplitude, so the surface ripples diagonally rather than bouncing uniformly. The motion loops seamlessly with no easing, amplitude ≈6 pt and a wavelength of ≈30 pt, producing a calm, hypnotic, cloth-like drift ideal for hero artwork or ambient headers.",
            "卡片像微风中的旗帜一样持续起伏。每个像素在竖直方向受沿 x 轴传播的正弦波推移，在水平方向受沿 y 轴、速度更慢、振幅减半的余弦波推移，使表面呈斜向涟漪而非整体上下跳动。运动无缝循环、无缓动，振幅约 6pt、波长约 30pt，呈现平静、催眠般的布料飘动感，适合头图或氛围型标题区。"
        ),
        implementation: L(
            "A Metal distortion shader returns a new sample position from sin/cos of position and time; a TimelineView(.animation) feeds the time every frame.",
            "Metal distortionEffect 着色器依据位置与时间的 sin/cos 返回新的采样坐标，TimelineView(.animation) 逐帧提供时间。"
        ),
        apis: ["distortionEffect", "TimelineView", "ShaderLibrary", "Metal"],
        tags: ["wave", "flag", "cloth", "distortion", "波浪", "旗帜", "布料", "扭曲"],
        params: [
            .slider("amplitude", L("Amplitude", "振幅"), 0...16, default: 6, decimals: 1, unit: "pt"),
            .slider("wavelength", L("Wavelength", "波长"), 10...80, default: 30, decimals: 0, unit: "pt"),
            .slider("speed", L("Speed", "速度"), 0.5...8, default: 3, decimals: 1),
        ]
    ) { ctx in
        WaveDemo(ctx: ctx)
    }

    static let shaderMagnifier = Effect(
        id: "shader.magnifier",
        category: .shaders,
        interaction: .gesture,
        name: L("Lens Magnifier", "透镜放大镜"),
        summary: L("Drag a bulging lens that magnifies whatever is beneath it.", "拖动一枚凸透镜，放大其下方的内容。"),
        prompt: L(
            "A circular convex lens follows the finger across dense typographic content. Inside the lens radius (≈70 pt) pixels are pulled toward the center with a quadratic falloff — strongest magnification at the core, blending seamlessly to 1× at the rim — so text bulges like a drop of water rather than being cropped and scaled. A hairline white ring and soft shadow outline the lens. On lift-off the lens springs back to rest with response 0.4 s, damping 0.7.",
            "一枚圆形凸透镜跟随手指在密集的文字内容上移动。透镜半径（约 70pt）内的像素以二次方衰减向圆心收拢——中心放大最强、边缘平滑过渡回 1 倍——文字如水滴般鼓起，而非生硬地裁切放大。透镜外缘有一圈细白线与柔和阴影。松手后透镜以弹簧（响应 0.4 秒、阻尼 0.7）回到中心。"
        ),
        implementation: L(
            "A Metal distortion shader remaps positions within a radius toward the lens center; DragGesture updates the center, which is passed as float2.",
            "Metal distortionEffect 将半径内的坐标向透镜中心重映射；DragGesture 更新中心点并以 float2 传入着色器。"
        ),
        apis: ["distortionEffect", "DragGesture", "Shader.Argument.float2", "Metal"],
        tags: ["magnifier", "lens", "bulge", "loupe", "放大镜", "透镜", "凸起", "鱼眼"],
        params: [
            .slider("radius", L("Radius", "半径"), 40...120, default: 70, decimals: 0, unit: "pt"),
            .slider("strength", L("Magnification", "放大强度"), 0.1...0.8, default: 0.5),
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
            "Pressing and dragging on the surface twists the content into a vortex centered on the finger. Rotation is strongest at the core and falls off quadratically to zero at a ≈110 pt radius, so the pattern spirals smoothly without tearing. Horizontal drag distance maps to twist angle (up to ±2.5 rad). Releasing lets the vortex unwind with an underdamped spring (response 0.6 s, damping 0.5), overshooting slightly the other way before settling — playful, liquid and tactile.",
            "在画面上按住拖动，内容会以手指为中心被拧成漩涡。旋转在中心最强，并以二次方衰减至约 110pt 半径处为零，因此图案平滑盘旋而不撕裂。水平拖动距离映射为扭转角度（最大 ±2.5 弧度）。松手后漩涡以欠阻尼弹簧（响应 0.6 秒、阻尼 0.5）解旋，并轻微反向过冲后稳定——俏皮、流体、富有触感。"
        ),
        implementation: L(
            "A Metal distortion shader rotates sample coordinates by an angle that decays with distance. The angle lives in an Animatable ViewModifier so a spring can animate it back to zero.",
            "Metal distortionEffect 以随距离衰减的角度旋转采样坐标；角度放在遵循 Animatable 的 ViewModifier 中，以便用弹簧动画回到零。"
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
            ShaderArtwork()
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
        let duration: TimeInterval = 3
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
        ShaderClock { time in
            ShaderArtwork(variant: 1)
                .padding(20)
                .distortionEffect(
                    ShaderLibrary.mlWave(.float(time), .float(amplitude), .float(wavelength), .float(speed)),
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
    @State private var size: CGSize = CGSize(width: 340, height: 340)

    var body: some View {
        ShaderClock(paused: !ctx.isPreview) { time in
            let point = currentCenter(time: time)
            let radius = ctx["radius"]
            ShaderGridArtwork()
                .distortionEffect(
                    ShaderLibrary.mlBulge(.float2(point), .float(radius), .float(ctx["strength"])),
                    maxSampleOffset: CGSize(width: radius, height: radius)
                )
                .overlay {
                    Circle()
                        .strokeBorder(Color.white.opacity(0.7), lineWidth: 1)
                        .frame(width: radius * 2, height: radius * 2)
                        .shadow(color: .black.opacity(0.35), radius: 10, y: 6)
                        .position(point)
                }
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in center = value.location }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { center = nil }
                }
        )
    }

    private func currentCenter(time: Double) -> CGPoint {
        if let center { return center }
        let mid = CGPoint(x: size.width / 2, y: size.height / 2)
        guard ctx.isPreview else { return mid }
        return CGPoint(x: mid.x + cos(time * 1.2) * 80, y: mid.y + sin(time * 1.6) * 60)
    }
}

// MARK: - Swirl demo

private struct SwirlDemo: View {
    let ctx: DemoContext
    @State private var center = CGPoint(x: 130, y: 150)
    @State private var angle: Double = 0

    var body: some View {
        VStack(spacing: 14) {
            ShaderArtwork()
                .modifier(SwirlModifier(center: center, radius: ctx["radius"], angle: angle))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            center = value.startLocation
                            let maxAngle = ctx["maxAngle"]
                            angle = (Double(value.translation.width) / 60).clamped(to: -maxAngle...maxAngle)
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) { angle = 0 }
                        }
                )
            DemoHint(text: L("Press and drag sideways", "按住并左右拖动"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.6, delay: 0.2) {
            center = CGPoint(x: 130, y: 150)
            withAnimation(.easeInOut(duration: 0.5)) { angle = ctx["maxAngle"] }
            Task {
                try? await Task.sleep(for: .seconds(0.6))
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) { angle = 0 }
            }
        }
    }
}

private struct SwirlModifier: ViewModifier, Animatable {
    var center: CGPoint
    var radius: Double
    var angle: Double

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    func body(content: Content) -> some View {
        content.distortionEffect(
            ShaderLibrary.mlSwirl(.float2(center), .float(radius), .float(angle)),
            maxSampleOffset: CGSize(width: radius, height: radius),
            isEnabled: abs(angle) > 0.001
        )
    }
}
