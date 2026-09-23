import SwiftUI

extension Effect {
    static let buttonsInkRipple = Effect(
        id: "buttons.ink-ripple",
        category: .buttons,
        interaction: .tap,
        name: L("Ink Ripple", "墨水涟漪"),
        summary: L("A soft wave of light spreads from the exact touch point.", "从手指触点扩散开的一圈柔光涟漪。"),
        prompt: L(
            "A rounded-rectangle button with a sky-to-blue gradient and a faint glossy top highlight. Each tap spawns a translucent white circle exactly at the touch point that expands with an ease-out curve until it covers the farthest corner of the button (about 600 ms), while its opacity fades from 35% to zero on an ease-in over the same duration, so the wave dissolves as it reaches the edges. Ripples are clipped to the button shape and can overlap when tapped rapidly. A bright 28 pt glint flashes at the touch point and melts within ~300 ms, while a thin sky-blue outline leaves the button's edge, growing 14 pt outward as it fades. The button itself dips to 96% and springs back with a bouncy keyframe, plus a light haptic. It feels liquid, precise and responsive to exactly where you touched.",
            "天蓝到湛蓝渐变的圆角按钮，顶部有淡淡高光。每次点击都在精确落点生成一个半透明白圆，以缓出曲线约 600 毫秒扩散到最远的角，透明度同时以缓入曲线从 35% 降到 0，恰好在触及边缘时消散。涟漪裁切在按钮内，连点可叠加。触点处闪现一粒 28pt 亮光，约 300 毫秒融化；一圈天蓝细描边从按钮边缘脱离，外扩 14pt 并淡出。按钮下沉到 96% 并以弹性关键帧回弹，伴随轻触觉。如液体般细腻，精准回应触点。"
        ),
        implementation: L(
            "onTapGesture's location closure appends a ripple model; each ripple view animates its own scale and opacity on appear and is removed after the duration, all clipped to the button shape.",
            "带位置参数的 onTapGesture 追加一个涟漪模型；每个涟漪视图在出现时自行驱动缩放与透明度动画，结束后被移除，整体裁切在按钮形状内。"
        ),
        apis: ["onTapGesture(coordinateSpace:perform:)", "clipShape", "keyframeAnimator", "position"],
        tags: ["ripple", "ink", "material", "涟漪", "水波纹", "点击反馈", "touch", "扩散"],
        params: [
            .slider("duration", L("Ripple duration", "扩散时长"), 0.3...1.2, default: 0.6, unit: "s"),
            .slider("opacity", L("Ripple opacity", "涟漪不透明度"), 0.1...0.6, default: 0.35),
            .toggle("bounce", L("Press bounce", "按压回弹"), default: true),
        ]
    ) { ctx in
        ButtonInkRippleDemo(ctx: ctx)
    }
}

private struct ButtonRippleModel: Identifiable {
    let id = UUID()
    let point: CGPoint
}

private struct ButtonInkRippleDemo: View {
    let ctx: DemoContext
    @State private var ripples: [ButtonRippleModel] = []
    @State private var taps = 0
    @State private var previewIndex = 0

    private let size = CGSize(width: 250, height: 68)
    private static let previewPoints: [CGPoint] = [
        CGPoint(x: 40, y: 20), CGPoint(x: 200, y: 50), CGPoint(x: 125, y: 34), CGPoint(x: 230, y: 14),
    ]

    var body: some View {
        let dip = ctx.bool("bounce") ? 0.96 : 1.0
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                ForEach(ripples) { ripple in
                    ButtonRippleHalo(size: size, cornerRadius: 20, duration: ctx["duration"] * 1.3)
                        .id(ripple.id)
                }
                face
            }
                .keyframeAnimator(initialValue: 1.0, trigger: taps) { content, scale in
                    content.scaleEffect(scale)
                } keyframes: { _ in
                    KeyframeTrack(\.self) {
                        CubicKeyframe(dip, duration: 0.09)
                        SpringKeyframe(1, duration: 0.45, spring: .bouncy)
                    }
                }
            Spacer()
            DemoHint(text: L("Tap anywhere on the button", "点击按钮的任意位置"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.0, delay: 0.3) { previewTap() }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
    }

    private var face: some View {
        ZStack {
            shape.fill(Palette.ocean)
            LinearGradient(colors: [Color.white.opacity(0.28), .clear], startPoint: .top, endPoint: .center)
            ForEach(ripples) { ripple in
                ButtonRippleCircle(
                    point: ripple.point,
                    radius: maxRadius(from: ripple.point),
                    duration: ctx["duration"],
                    peak: ctx["opacity"]
                )
            }
            HStack(spacing: 8) {
                Image(systemName: "drop.fill")
                Text(ctx.language == .zh ? "轻点一下" : "Tap anywhere")
            }
            .font(.headline)
            .foregroundStyle(.white)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(shape)
        .contentShape(shape)
        .shadow(color: Palette.blue.opacity(0.35), radius: 16, y: 10)
        .onTapGesture { location in
            addRipple(at: location)
        }
    }

    private func maxRadius(from point: CGPoint) -> CGFloat {
        let dx = max(point.x, size.width - point.x)
        let dy = max(point.y, size.height - point.y)
        return hypot(dx, dy)
    }

    private func addRipple(at point: CGPoint) {
        let ripple = ButtonRippleModel(point: point)
        ripples.append(ripple)
        taps += 1
        if !ctx.isPreview { Haptics.tap() }
        let lifetime = ctx["duration"] + 0.15
        Task {
            try? await Task.sleep(for: .seconds(lifetime))
            ripples.removeAll { $0.id == ripple.id }
        }
    }

    private func previewTap() {
        let point = Self.previewPoints[previewIndex % Self.previewPoints.count]
        previewIndex += 1
        addRipple(at: point)
    }
}

private struct ButtonRippleCircle: View {
    let point: CGPoint
    let radius: CGFloat
    let duration: Double
    let peak: Double
    @State private var grown = false
    @State private var faded = false
    @State private var glintFaded = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: radius * 2, height: radius * 2)
                .scaleEffect(grown ? 1 : 0.02)
                .opacity(faded ? 0 : peak)
            // A small, bright glint marks the exact touch point, then melts away quickly.
            Circle()
                .fill(RadialGradient(colors: [Color.white, Color.white.opacity(0)], center: .center, startRadius: 0, endRadius: 14))
                .frame(width: 28, height: 28)
                .scaleEffect(glintFaded ? 1.6 : 0.6)
                .opacity(glintFaded ? 0 : 0.9)
        }
        .position(point)
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: duration)) { grown = true }
            withAnimation(.easeIn(duration: duration)) { faded = true }
            withAnimation(.easeOut(duration: min(duration * 0.5, 0.35))) { glintFaded = true }
        }
    }
}

/// A thin outline that leaves the button's edge on every tap, like a pressure wave escaping the surface.
private struct ButtonRippleHalo: View {
    let size: CGSize
    let cornerRadius: CGFloat
    let duration: Double
    @State private var out = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(Palette.sky.opacity(0.7), lineWidth: 1.5)
            .frame(width: size.width, height: size.height)
            .scaleEffect(x: out ? 1 + 28 / size.width : 1, y: out ? 1 + 28 / size.height : 1)
            .opacity(out ? 0 : 0.8)
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.easeOut(duration: duration)) { out = true }
            }
    }
}
