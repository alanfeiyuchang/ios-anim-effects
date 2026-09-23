import SwiftUI

extension Effect {
    static let buttonsMagnetic = Effect(
        id: "buttons.magnetic",
        category: .buttons,
        interaction: .gesture,
        name: L("Magnetic Button", "磁吸按钮"),
        summary: L("The button leans toward your finger, then snaps home.", "按钮被手指吸引靠近，离开后弹回原位。"),
        prompt: L(
            "A gradient capsule button sits inside a magnetic field about 120 pt in radius. The field has no hard edge: pull strength ramps in with a smoothstep falloff from the rim to ~55% of the radius, then holds, so the button is drawn toward the touch point by up to a third of the distance, grows to 106% and deepens its tinted shadow in proportion; the label drifts a little further than the body for a subtle parallax. Every move is chased by a soft spring (response 0.42 s, damping 0.55), trailing the finger with a slight lag. When the finger lifts or drifts out, the button eases back to center with a gentle overshoot, and a soft haptic marks entering and leaving. Alive, curious and physically attracted.",
            "渐变胶囊按钮周围有一个半径约 120pt 的磁场，但没有生硬的边界：吸力从边缘到约 55% 半径处按 smoothstep 曲线渐强、之后保持，按钮被拉向触点，最多移动距离的三分之一，并按吸力比例放大到 106%、加深彩色投影；按钮文字比本体多移动一点，形成细微视差。每次位移都由柔和弹簧（响应 0.42 秒、阻尼 0.55）追随，略带滞后地跟手。手指抬起或移出磁场时，按钮带轻微过冲缓缓回到中心；进出磁场各有一次柔和触觉。像被磁力吸引一样灵动、有生命感。"
        ),
        implementation: L(
            "A zero-distance DragGesture over the whole stage measures the finger's offset from the button center; a smoothstep falloff of that distance weights the pull, scale and shadow, all applied through a spring.",
            "覆盖整个舞台的零距离 DragGesture 计算手指相对按钮中心的偏移；按距离做 smoothstep 衰减得到吸力权重，同时驱动位移、缩放与投影，并通过弹簧应用。"
        ),
        apis: ["DragGesture", "offset", "spring(response:dampingFraction:)", "onGeometryChange"],
        tags: ["magnetic", "attract", "hover", "磁吸", "吸附", "跟随", "cursor", "悬停"],
        params: [
            .slider("radius", L("Field radius", "磁场半径"), 60...160, default: 120, decimals: 0, unit: "pt"),
            .slider("strength", L("Pull strength", "吸引强度"), 0.1...0.6, default: 0.35),
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.8, default: 0.42, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.3...1.0, default: 0.55),
        ]
    ) { ctx in
        ButtonMagneticDemo(ctx: ctx)
    }
}

private struct ButtonMagneticDemo: View {
    let ctx: DemoContext
    @State private var stageSize: CGSize = .zero
    @State private var pull: CGSize = .zero
    @State private var finger: CGPoint?
    @State private var captured = false
    /// 0…1 field influence after the smoothstep falloff.
    @State private var influence: CGFloat = 0
    @State private var step = 0
    /// Bumped when the finger lifts on the button itself: plays the press pulse.
    @State private var presses = 0

    private static let previewPath: [CGSize] = [
        CGSize(width: 70, height: -40),
        CGSize(width: 150, height: -110),
        CGSize(width: -60, height: 34),
        CGSize(width: -24, height: -56),
        CGSize(width: -150, height: 100),
    ]

    /// Thumbnails cap the field so the dashed ring never touches the preview edge.
    private var radius: CGFloat { ctx.isPreview ? min(ctx.cg("radius"), 100) : ctx.cg("radius") }
    private var strength: CGFloat { ctx.cg("strength") }
    private var spring: Animation { .spring(response: ctx["response"], dampingFraction: ctx["damping"]) }

    private static func smoothstep(_ edge0: CGFloat, _ edge1: CGFloat, _ x: CGFloat) -> CGFloat {
        let t = ((x - edge0) / (edge1 - edge0)).clamped(to: 0...1)
        return t * t * (3 - 2 * t)
    }

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    Color.primary.opacity(0.08 + 0.14 * Double(influence)),
                    style: StrokeStyle(lineWidth: 1, dash: [4, 6])
                )
                .frame(width: radius * 2, height: radius * 2)
            ButtonMagneticFace(
                pull: pull,
                influence: influence,
                title: ctx.language == .zh ? "开始体验" : "Get started"
            )
            .keyframeAnimator(initialValue: 1.0, trigger: presses) { content, scale in
                content.scaleEffect(scale)
            } keyframes: { _ in
                KeyframeTrack(\.self) {
                    CubicKeyframe(0.94, duration: 0.08)
                    SpringKeyframe(1.0, duration: 0.4, spring: .bouncy)
                }
            }
            fingerDot
            VStack {
                Spacer()
                DemoHint(text: L("Move your finger near the button", "手指靠近按钮移动"), ctx: ctx)
                    .padding(.bottom, 18)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newSize in
            stageSize = newSize
        }
        .gesture(dragGesture)
        .autoplay(ctx.isPreview, every: 1.1, delay: 0.3) {
            // Previews keep roaming; the detail intro drifts past the button once and then lets go.
            if ctx.isPreview { stepPreview() } else { introSweep() }
        }
    }

    @ViewBuilder
    private var fingerDot: some View {
        if let finger {
            Circle()
                .fill(Color.primary.opacity(0.1))
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.25), lineWidth: 1))
                .frame(width: 34, height: 34)
                .position(finger)
                .allowsHitTesting(false)
                .transition(.opacity)
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in track(value.location, animateFinger: false) }
            .onEnded { value in
                if liftedOnButton(value.location) {
                    Haptics.tap(.medium)
                    presses += 1
                }
                release()
            }
    }

    private func track(_ point: CGPoint, animateFinger: Bool) {
        let dx = point.x - stageSize.width / 2
        let dy = point.y - stageSize.height / 2
        let distance = hypot(dx, dy)
        // Full strength inside ~55% of the radius, smoothly fading to zero at the rim — no boundary snap.
        let weight = 1 - Self.smoothstep(radius * 0.55, radius, distance)
        let inside = weight > 0.001
        // animateFinger marks a simulated finger (previews, the detail intro), which never buzzes.
        if inside != captured && !ctx.isPreview && !animateFinger { Haptics.tap(.soft) }
        if animateFinger {
            withAnimation(.smooth(duration: 0.8)) { finger = point }
        } else {
            finger = point
        }
        withAnimation(spring) {
            captured = inside
            influence = weight
            pull = CGSize(width: dx * strength * weight, height: dy * strength * weight)
        }
    }

    private func release() {
        withAnimation(spring) {
            captured = false
            influence = 0
            pull = .zero
        }
        withAnimation(.easeOut(duration: 0.2)) { finger = nil }
    }

    /// The capsule is 180 × 60 and rides the pull, so test against its displaced frame.
    private func liftedOnButton(_ point: CGPoint) -> Bool {
        let dx = point.x - (stageSize.width / 2 + pull.width)
        let dy = point.y - (stageSize.height / 2 + pull.height)
        return abs(dx) < 90 && abs(dy) < 30
    }

    private func introSweep() {
        Task { @MainActor in
            for _ in 0..<3 {
                stepPreview()
                try? await Task.sleep(for: .seconds(1.0))
            }
            release()
        }
    }

    private func stepPreview() {
        guard stageSize != .zero else { return }
        let offset = Self.previewPath[step % Self.previewPath.count]
        step += 1
        let point = CGPoint(x: stageSize.width / 2 + offset.width, y: stageSize.height / 2 + offset.height)
        track(point, animateFinger: true)
    }
}

private struct ButtonMagneticFace: View {
    let pull: CGSize
    let influence: CGFloat
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
            Text(title)
        }
        .font(.headline)
        .foregroundStyle(.white)
        .offset(x: pull.width * 0.35, y: pull.height * 0.35)
        .frame(width: 180, height: 60)
        .background(Palette.primary, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
        .shadow(
            color: Palette.indigo.opacity(0.3 + 0.2 * Double(influence)),
            radius: 14 + 8 * influence,
            y: 8 + 6 * influence
        )
        .scaleEffect(1 + 0.06 * influence)
        .offset(pull)
    }
}
