import SwiftUI

extension Effect {
    static let buttonsParallaxTilt = Effect(
        id: "buttons.parallax-tilt",
        category: .buttons,
        interaction: .gesture,
        name: L("Parallax Tilt Button", "视差倾斜按钮"),
        summary: L("A layered tile button tilts under the finger while its layers drift in parallax.", "分层的卡片按钮随手指倾斜，内部图层产生视差漂移。"),
        prompt: L(
            "A 260 × 120 pt tile button: a sunset gradient backdrop with soft blobs, a glyph and a title on separate depth layers. While the finger rests on it, the tile rotates in 3D so the touched side sinks away — up to 12° around each axis with a 0.5 perspective — and grows to 104%. The layers slide in parallax: the backdrop shifts 12 pt against the tilt, the glyph 0.6× and the title 0.3× with it, while a white specular glare glides to the opposite corner and the drop shadow swings the other way. Every movement follows a smooth spring (response 0.3 s, damping 0.7); on release the tile levels out and the glare fades, with a light haptic on touch-down. Physical, deep and responsive.",
            "一块 260 × 120pt 的海报式卡片按钮：日落渐变背景配柔和光斑，图标与标题分处不同景深图层。手指按住时，卡片做 3D 旋转，被按住的一侧向里沉——每个轴最多 12°、透视 0.5——并放大到 104%。各图层产生视差：背景逆着倾斜方向移动 12pt，图标顺着方向移动 0.6 倍、标题 0.3 倍，一道白色镜面高光滑向对角，投影向相反方向摆动。所有运动都跟随平滑弹簧（响应 0.3 秒、阻尼 0.7）；松手后卡片回正、高光淡出，按下时伴随轻触感。立体、有景深、跟手。"
        ),
        implementation: L(
            "A zero-distance DragGesture normalises the finger position to −1…1 on each axis; two rotation3DEffect calls tilt the tile, offsets scaled per layer create the parallax, and a RadialGradient glare is positioned opposite the finger, all driven by one spring.",
            "零距离 DragGesture 把手指位置归一化到每个轴的 −1…1；两个 rotation3DEffect 让卡片倾斜，按图层比例缩放的偏移产生视差，RadialGradient 高光放在手指的对侧，全部由同一个弹簧驱动。"
        ),
        apis: ["rotation3DEffect", "DragGesture", "RadialGradient", "offset", "spring(response:dampingFraction:)"],
        tags: ["parallax", "tilt", "3d", "tv", "视差", "倾斜", "立体", "海报"],
        params: [
            .slider("tilt", L("Max tilt", "最大倾角"), 4...20, default: 12, decimals: 0, unit: "°"),
            .slider("depth", L("Parallax depth", "视差深度"), 4...24, default: 12, decimals: 0, unit: "pt"),
            .toggle("glare", L("Specular glare", "镜面高光"), default: true),
        ]
    ) { ctx in
        ButtonParallaxTiltDemo(ctx: ctx)
    }
}

private struct ButtonParallaxTiltDemo: View {
    let ctx: DemoContext
    /// Normalised finger position, −1…1 on each axis.
    @State private var tilt: CGSize = .zero
    @State private var active = false
    @State private var step = 0

    private let size = CGSize(width: 260, height: 120)

    private static let previewPath: [CGSize] = [
        CGSize(width: 0.8, height: -0.6), CGSize(width: -0.7, height: 0.5), CGSize(width: 0.2, height: 0.9),
        CGSize(width: -0.9, height: -0.7), CGSize(width: 0, height: 0),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            tile
            Spacer()
            DemoHint(text: L("Press and drag over the tile", "按住卡片并拖动"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 0.9, delay: 0.3) { previewStep() }
    }

    private var tile: some View {
        let maxTilt = ctx["tilt"]
        let depth = ctx.cg("depth")
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        return ZStack {
            ButtonParallaxBackdrop()
                .frame(width: size.width + depth * 2, height: size.height + depth * 2)
                .offset(x: -tilt.width * depth, y: -tilt.height * depth)
            content(depth: depth)
            if ctx.bool("glare") {
                glare
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
        .shadow(
            color: Palette.coral.opacity(active ? 0.45 : 0.25),
            radius: active ? 22 : 14,
            x: -tilt.width * 10,
            y: 10 - tilt.height * 8
        )
        .scaleEffect(active ? 1.04 : 1)
        .rotation3DEffect(.degrees(Double(tilt.height) * maxTilt), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
        .rotation3DEffect(.degrees(Double(-tilt.width) * maxTilt), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
        .contentShape(shape)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in track(value.location) }
                .onEnded { _ in release() }
        )
        .accessibilityAddTraits(.isButton)
    }

    private func content(depth: CGFloat) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "play.tv.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.25), radius: 6, y: 4)
                .offset(x: tilt.width * depth * 0.6, y: tilt.height * depth * 0.6)
            VStack(alignment: .leading, spacing: 3) {
                Text(L("NEW SEASON", "全新一季"), ctx.language)
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.2)
                    .foregroundStyle(Color.white.opacity(0.8))
                Text(L("Golden Hour", "黄金时刻"), ctx.language)
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(.white)
            }
            .offset(x: tilt.width * depth * 0.3, y: tilt.height * depth * 0.3)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
    }

    private var glare: some View {
        Circle()
            .fill(RadialGradient(colors: [Color.white.opacity(0.55), .clear], center: .center, startRadius: 0, endRadius: 110))
            .frame(width: 220, height: 220)
            .offset(x: -tilt.width * size.width * 0.5, y: -tilt.height * size.height * 0.5)
            .blendMode(.plusLighter)
            .opacity(active ? 0.8 : 0)
            .allowsHitTesting(false)
    }

    private func track(_ point: CGPoint) {
        let nx = ((point.x / size.width) * 2 - 1).clamped(to: -1...1)
        let ny = ((point.y / size.height) * 2 - 1).clamped(to: -1...1)
        if !active { Haptics.tap() }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            active = true
            tilt = CGSize(width: nx, height: ny)
        }
    }

    private func release() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
            active = false
            tilt = .zero
        }
    }

    private func previewStep() {
        let target = Self.previewPath[step % Self.previewPath.count]
        step += 1
        if target == .zero {
            release()
            return
        }
        withAnimation(.smooth(duration: 0.8)) {
            active = true
            tilt = target
        }
    }
}

private struct ButtonParallaxBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Palette.amber, Palette.coral, Palette.pink], startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle()
                .fill(Color.white.opacity(0.28))
                .frame(width: 120, height: 120)
                .blur(radius: 20)
                .offset(x: 80, y: -40)
            Circle()
                .fill(Palette.violet.opacity(0.5))
                .frame(width: 140, height: 140)
                .blur(radius: 26)
                .offset(x: -90, y: 50)
        }
    }
}
