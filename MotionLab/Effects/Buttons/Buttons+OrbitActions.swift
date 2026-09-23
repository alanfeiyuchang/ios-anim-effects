import SwiftUI

extension Effect {
    static let buttonsOrbitActions = Effect(
        id: "buttons.orbit-actions",
        category: .buttons,
        interaction: .tap,
        name: L("Orbit Actions", "环绕轨道操作"),
        summary: L("Satellite actions spiral out of a central button onto a full orbit.", "卫星般的操作按钮从中心螺旋飞出，落在一整圈轨道上。"),
        prompt: L(
            "A 68 pt glowing violet core button sits at the centre of the stage. On tap it spins its sparkle glyph 180° while five 48 pt satellite actions spiral out onto a full 92 pt orbit: each travels on a polar path — its radius grows from 0 while its angle sweeps 140° into place — so they swirl out like a galaxy rather than sliding straight, 40 ms apart, on a spring (response 0.5 s, damping 0.72), and each stays upright while it travels. A dashed orbit ring draws itself behind them (trim 0 → 1 in 0.5 s). Tapping a satellite pulses it and collapses the orbit back into the core in reverse, with a success haptic; tapping the core toggles with a light one. Cosmic and playful.",
            "舞台中央有一枚 68pt 的发光紫罗兰核心按钮。点击后，核心的闪光图标旋转 180°，五个 48pt 的卫星操作沿极坐标轨迹螺旋飞出，落到一整圈半径 92pt 的轨道上：每个卫星的半径从 0 增长，同时角度扫过 140° 就位，因此它们像星系一样旋出，而不是直线滑出；彼此错开 40 毫秒，使用弹簧（响应 0.5 秒、阻尼 0.72），飞行中始终保持正立。身后一圈虚线轨道随之绘制（trim 0 → 1，0.5 秒）。点击某个卫星会让它脉冲一下，并让整条轨道反向收回核心，伴随成功触感；点击核心则以轻触感切换。充满宇宙感、俏皮且令人印象深刻。"
        ),
        implementation: L(
            "Each satellite is offset by the radius and then rotated by its angle with rotationEffect, and counter-rotated inside, so animating radius and angle together with a delayed spring traces a true spiral; the dashed ring is a trimmed Circle stroke.",
            "每个卫星先按半径偏移，再用 rotationEffect 按角度旋转，内部再反向旋转保持正立，因此用带延迟的弹簧同时动画半径与角度即可得到真正的螺旋轨迹；虚线轨道是 trim 过的 Circle 描边。"
        ),
        apis: ["rotationEffect", "offset", "spring(response:dampingFraction:)", "Circle().trim", "StrokeStyle(dash:)"],
        tags: ["orbit", "radial", "fab", "spiral", "轨道", "环形菜单", "螺旋", "悬浮按钮"],
        params: [
            .slider("radius", L("Orbit radius", "轨道半径"), 70...120, default: 92, decimals: 0, unit: "pt"),
            .slider("sweep", L("Spiral sweep", "螺旋角度"), 0...270, default: 140, decimals: 0, unit: "°"),
            .slider("stagger", L("Stagger", "错峰间隔"), 0...0.12, default: 0.04, unit: "s"),
        ]
    ) { ctx in
        ButtonOrbitActionsDemo(ctx: ctx)
    }
}

private struct ButtonSatellite {
    let symbol: String
    let color: Color
    let name: LocalizedText
}

private struct ButtonOrbitActionsDemo: View {
    let ctx: DemoContext
    @State private var open = false
    @State private var pulses: [Int] = [0, 0, 0, 0, 0]
    @State private var step = 0

    private static let satellites: [ButtonSatellite] = [
        ButtonSatellite(symbol: "camera.fill", color: Palette.coral, name: L("Camera", "相机")),
        ButtonSatellite(symbol: "mic.fill", color: Palette.pink, name: L("Voice", "语音")),
        ButtonSatellite(symbol: "photo.fill", color: Palette.mint, name: L("Photo", "照片")),
        ButtonSatellite(symbol: "location.fill", color: Palette.sky, name: L("Place", "位置")),
        ButtonSatellite(symbol: "doc.fill", color: Palette.amber, name: L("File", "文件")),
    ]

    var body: some View {
        ZStack {
            orbitRing
            ForEach(Self.satellites.indices, id: \.self) { index in
                satellite(index)
            }
            core
            VStack {
                Spacer()
                DemoHint(text: L("Tap the core, then a satellite", "点击核心，再点一个卫星"), ctx: ctx)
                    .padding(.bottom, 14)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.4, delay: 0.4) { previewStep() }
    }

    private var orbitRing: some View {
        let radius = ctx.cg("radius")
        return Circle()
            .trim(from: 0, to: open ? 1 : 0)
            .stroke(Color.primary.opacity(0.18), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [3, 6]))
            .rotationEffect(.degrees(-90))
            .frame(width: radius * 2, height: radius * 2)
            .animation(.easeInOut(duration: 0.5), value: open)
    }

    private var core: some View {
        Button(action: toggle) {
            Image(systemName: "sparkles")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(open ? 180 : 0))
                .frame(width: 68, height: 68)
                .background(Palette.primary, in: Circle())
                .overlay(Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
                .shadow(color: Palette.violet.opacity(open ? 0.6 : 0.35), radius: open ? 22 : 12)
        }
        .buttonStyle(SportPressStyle(scale: 0.9, dim: 0.05))
        .animation(.spring(response: 0.5, dampingFraction: 0.72), value: open)
        .accessibilityLabel(Text(open ? L("Close actions", "收起操作") : L("Show actions", "展开操作"), ctx.language))
    }

    private func satellite(_ index: Int) -> some View {
        let count = Self.satellites.count
        let item = Self.satellites[index]
        let home = Double(index) / Double(count) * 360
        let angle = open ? home : home - ctx["sweep"]
        let radius: CGFloat = open ? ctx.cg("radius") : 0
        let order = open ? index : count - 1 - index
        let delay = Double(order) * ctx["stagger"]
        return Button { pick(index) } label: {
            Image(systemName: item.symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(item.color.gradient, in: Circle())
                .shadow(color: item.color.opacity(0.4), radius: 8, y: 4)
                .keyframeAnimator(initialValue: CGFloat(1), trigger: pulses[index]) { content, scale in
                    content.scaleEffect(scale)
                } keyframes: { _ in
                    KeyframeTrack(\.self) {
                        CubicKeyframe(1.25, duration: 0.1)
                        SpringKeyframe(1, duration: 0.35, spring: .bouncy)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(item.name, ctx.language))
        .rotationEffect(.degrees(-angle))
        .offset(y: -radius)
        .rotationEffect(.degrees(angle))
        .scaleEffect(open ? 1 : 0.3)
        .opacity(open ? 1 : 0)
        .allowsHitTesting(open)
        .animation(.spring(response: 0.5, dampingFraction: 0.72).delay(delay), value: open)
    }

    private func toggle() {
        open.toggle()
        Haptics.tap()
    }

    private func pick(_ index: Int) {
        guard open else { return }
        pulses[index] += 1
        Haptics.success()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            open = false
        }
    }

    private func previewStep() {
        if open {
            pick(step % Self.satellites.count)
        } else {
            toggle()
        }
        step += 1
    }
}
