import SwiftUI

extension Effect {
    static let buttonsSpotlight = Effect(
        id: "buttons.spotlight",
        category: .buttons,
        interaction: .gesture,
        name: L("Spotlight Follow", "聚光跟随"),
        summary: L("A soft radial light tracks the finger and lights up the border.", "柔和径向光斑跟随手指移动，并点亮边框。"),
        prompt: L(
            "A wide card-style button with an icon tile, title and caption on a quiet elevated surface with a hairline border. Wherever the finger (or pointer) rests, a soft radial violet spotlight about 180 pt across glows beneath the content, fading to transparent at its edge; the same radial mask brightens the nearby stretch of the 1.5 pt border, so the rim lights up locally. The light fades in over 200 ms with a soft haptic on first touch and glides after the finger with ~150 ms of smoothing (longer lag feels heavier); on touch-down the card also dips to 97% and springs back on release (response 0.3 s, damping 0.6) as the light fades out. Minimal and refined — the hover language of modern developer tools.",
            "宽幅卡片式按钮，含图标块、标题与说明，底色为安静的浮起表面加细描边。手指（或指针）停在哪里，内容下方就亮起一团直径约 180pt 的柔和紫色径向光斑，向边缘渐隐；同一径向遮罩也点亮附近一段 1.5pt 描边，像轮廓光局部发亮。首次触碰时光斑在 200 毫秒内淡入并轻触一下，之后以约 150 毫秒的平滑跟随手指（延迟越长越显厚重）；按下时卡片轻压到 97%，松手以弹簧（响应 0.3 秒、阻尼 0.6）回弹，光斑随之淡出。极简而精致。"
        ),
        implementation: L(
            "A zero-distance DragGesture (plus onContinuousHover for pointers) stores the local point; a radial-gradient circle is positioned there under the content and reused as a mask over a tinted strokeBorder.",
            "零距离 DragGesture（指针设备另加 onContinuousHover）记录局部坐标；在该点放置径向渐变圆作为内容下方的光斑，并复用为着色描边的遮罩。"
        ),
        apis: ["DragGesture", "onContinuousHover", "RadialGradient", "mask"],
        tags: ["spotlight", "hover", "glow", "follow", "聚光", "光斑", "跟随", "悬停"],
        params: [
            .slider("radius", L("Light radius", "光斑半径"), 40...160, default: 90, decimals: 0, unit: "pt"),
            .slider("intensity", L("Intensity", "亮度"), 0.1...0.8, default: 0.4),
            .slider("lag", L("Follow lag", "跟随延迟"), 0.05...0.4, default: 0.15, unit: "s"),
        ]
    ) { ctx in
        ButtonSpotlightDemo(ctx: ctx)
    }
}

private struct ButtonSpotlightDemo: View {
    let ctx: DemoContext
    @State private var spot = CGPoint(x: 60, y: 40)
    @State private var active = false
    @State private var pressed = false
    @State private var step = 0
    /// The detail intro's scripted sweep; cancelled by the first real touch and on disappear.
    @State private var introTask: Task<Void, Never>?
    /// Resets on system cancellation too (Control Center pull, incoming call), so a cancelled touch still releases.
    @GestureState private var touching = false

    private let size = CGSize(width: 290, height: 96)
    private static let previewPoints: [CGPoint] = [
        CGPoint(x: 250, y: 30), CGPoint(x: 150, y: 80), CGPoint(x: 30, y: 20), CGPoint(x: 200, y: 60),
    ]

    private let tint = Palette.violet

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            card
            Spacer()
            DemoHint(text: L("Drag across the card", "在卡片上拖动手指"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.0, delay: 0.2) {
            // Previews keep the light roaming; the detail intro sweeps once and switches it off again.
            if ctx.isPreview { previewMove() } else { introSweep() }
        }
        .onDisappear { stopIntro() }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
    }

    private var card: some View {
        ZStack {
            shape.fill(Palette.elevated)
            light(opacity: ctx["intensity"])
            shape.strokeBorder(Palette.stroke, lineWidth: 1)
            shape
                .strokeBorder(tint, lineWidth: 1.5)
                .mask { light(opacity: 1) }
            ButtonSpotlightContent(tint: tint, language: ctx.language)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(shape)
        .shadow(color: .black.opacity(0.1), radius: 16, y: 10)
        .scaleEffect(pressed ? 0.97 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: pressed)
        .contentShape(shape)
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($touching) { _, state, _ in state = true }
                .onChanged { value in
                    stopIntro()
                    if !pressed { pressed = true }
                    move(to: value.location)
                }
                .onEnded { _ in endTouch() }
        )
        .onChange(of: touching) { _, isTouching in
            if !isTouching { endTouch() }
        }
        .onContinuousHover { phase in
            switch phase {
            case .active(let point):
                move(to: point)
            case .ended:
                withAnimation(.easeOut(duration: 0.3)) { active = false }
            }
        }
    }

    private func light(opacity: Double) -> some View {
        let radius = ctx.cg("radius")
        return Circle()
            .fill(
                RadialGradient(
                    colors: [tint.opacity(opacity), tint.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: radius
                )
            )
            .frame(width: radius * 2, height: radius * 2)
            .position(spot)
            .opacity(active ? 1 : 0)
            .allowsHitTesting(false)
    }

    private func move(to point: CGPoint) {
        if !active {
            spot = point
            Haptics.tap(.soft)
            withAnimation(.easeOut(duration: 0.2)) { active = true }
        } else {
            withAnimation(.smooth(duration: max(ctx["lag"], 0.05))) { spot = point }
        }
    }

    /// Single cleanup for a lifted or cancelled finger.
    private func endTouch() {
        guard pressed else { return }
        pressed = false
        withAnimation(.easeOut(duration: 0.3)) { active = false }
    }

    private func introSweep() {
        stopIntro()
        introTask = Task { @MainActor in
            for _ in 0..<3 {
                previewMove()
                try? await Task.sleep(for: .seconds(0.9))
                guard !Task.isCancelled else { return }
            }
            withAnimation(.easeOut(duration: 0.3)) { active = false }
            introTask = nil
        }
    }

    private func stopIntro() {
        introTask?.cancel()
        introTask = nil
    }

    private func previewMove() {
        let point = Self.previewPoints[step % Self.previewPoints.count]
        step += 1
        active = true
        withAnimation(.smooth(duration: 0.9)) { spot = point }
    }
}

private struct ButtonSpotlightContent: View {
    let tint: Color
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "bolt.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(tint.gradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(language == .zh ? "部署到生产环境" : "Deploy to production")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(language == .zh ? "约 42 秒 · 3 个区域" : "~42 s · 3 regions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 20)
    }
}
