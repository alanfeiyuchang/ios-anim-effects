import SwiftUI

extension Effect {
    static let cardsPressTilt = Effect(
        id: "cards.press-tilt",
        category: .cards,
        interaction: .tap,
        name: L("Press Tilt", "按压倾斜"),
        summary: L("Press any point of a card: that spot sinks, then the card wobbles back like a sprung plate.", "按下卡片任意位置，该点下沉，松手后卡片像弹簧托盘一样晃动回正。"),
        prompt: L(
            "A glossy 250×158 pt payment card rests flat with a 18 pt soft shadow. Touching down at any point tilts the card so that exact spot sinks away from the viewer — up to 12° on each axis in perspective — within a stiff 180 ms spring, while the card scales to 96.5%, its shadow tightens to 8 pt and a dark radial dent (≈110 pt) blooms under the fingertip. On release the card is let go on an under-damped spring (response 0.6 s, damping 0.3), so it overshoots through flat and rocks back and forth two or three times before settling, like a plate balanced on a spring. A soft haptic marks the press. Tactile, springy and alive.",
            "一张250×158 pt的光泽支付卡平放，带18 pt柔和阴影。手指按在任意位置，卡片便以透视倾斜，让被按下的那一点向远离观者的方向下沉——每个轴最多12°——由180毫秒的硬弹簧完成；同时卡片缩至96.5%，阴影收紧到8 pt，指尖下晕开约110 pt的深色径向凹痕。松手后卡片交给欠阻尼弹簧（响应0.6秒、阻尼0.3），越过水平位置反向摆动，来回晃动两三次后才停稳，就像放在弹簧上的托盘。按下时伴随轻柔触感。触感真实、弹性十足、充满生命力。"
        ),
        implementation: L(
            "A zero-distance DragGesture converts the touch point to a −1…1 tilt that drives two rotation3DEffects; release hands the tilt back to zero through a low-damping spring, and a RadialGradient centered on the touch point fakes the dent.",
            "零距离 DragGesture 将触点换算为 −1…1 的倾斜量，驱动两个 rotation3DEffect；松手时以低阻尼弹簧把倾斜归零，并用以触点为圆心的 RadialGradient 模拟凹痕。"
        ),
        apis: ["DragGesture(minimumDistance: 0)", "rotation3DEffect", "spring(response:dampingFraction:)", "RadialGradient"],
        tags: ["press", "tilt", "wobble", "spring", "按压", "倾斜", "晃动", "弹簧"],
        params: [
            .slider("depth", L("Press depth", "按压深度"), 4...20, default: 12, step: 1, decimals: 0, unit: "°"),
            .slider("response", L("Release response", "回弹响应"), 0.3...1.0, default: 0.6, unit: "s"),
            .slider("wobble", L("Release damping", "回弹阻尼"), 0.15...0.9, default: 0.3),
        ]
    ) { ctx in
        CardsPressTiltDemo(ctx: ctx)
    }
}

private struct CardsPressTiltDemo: View {
    let ctx: DemoContext
    /// Normalised press point, −1…1 on both axes (0 = center).
    @State private var press: CGSize = .zero
    @State private var pressed = false
    /// Dent center in unit coordinates (0…1).
    @State private var dent = UnitPoint(x: 0.5, y: 0.5)
    @State private var step = 0
    /// True while a real finger presses the card.
    @State private var held = false
    /// The scripted press-and-release, cancelled on the first real touch.
    @State private var script: Task<Void, Never>?
    /// Resets on system cancellation too, so a stolen touch never leaves the card dented.
    @GestureState private var pressing = false

    private let size = CGSize(width: 250, height: 158)
    private static let previewPoints: [CGPoint] = [
        CGPoint(x: 0.85, y: -0.7), CGPoint(x: -0.8, y: 0.6), CGPoint(x: 0.1, y: 0.9), CGPoint(x: -0.6, y: -0.8),
    ]

    var body: some View {
        VStack(spacing: 30) {
            card
                .gesture(pressGesture)
            DemoHint(text: L("Press anywhere on the card", "按压卡片任意位置"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.5) { autoPress() }
        .onChange(of: pressing) { _, isPressing in
            if !isPressing { endHold() }
        }
        .onDisappear { script?.cancel() }
    }

    private var card: some View {
        let depth: Double = ctx["depth"]
        let x = Double(press.width)
        let y = Double(press.height)
        let shadowX: CGFloat = -press.width * 8
        return CardsCreditCard(theme: 3, last4: "2046")
            .overlay { dentLayer }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .rotation3DEffect(.degrees(-y * depth), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
            .rotation3DEffect(.degrees(x * depth), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
            .scaleEffect(pressed ? 0.965 : 1)
            .shadow(color: .black.opacity(pressed ? 0.16 : 0.24), radius: pressed ? 8 : 18, x: shadowX, y: pressed ? 5 : 14)
    }

    private var dentLayer: some View {
        RadialGradient(colors: [Color.black.opacity(0.3), .clear], center: dent, startRadius: 0, endRadius: 110)
            .opacity(pressed ? 1 : 0)
            .allowsHitTesting(false)
    }

    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($pressing) { _, state, _ in state = true }
            .onChanged { value in
                let x = (value.location.x / size.width - 0.5) * 2
                let y = (value.location.y / size.height - 0.5) * 2
                if !held {
                    held = true
                    script?.cancel()
                    script = nil
                    Haptics.tap(.soft)
                }
                pressDown(at: CGPoint(x: x.clamped(to: -1...1), y: y.clamped(to: -1...1)))
            }
            .onEnded { _ in endHold() }
    }

    /// Release or system cancellation: the card springs back flat.
    private func endHold() {
        guard held else { return }
        held = false
        release()
    }

    private func pressDown(at point: CGPoint) {
        dent = UnitPoint(x: (point.x + 1) / 2, y: (point.y + 1) / 2)
        withAnimation(.spring(response: 0.18, dampingFraction: 0.86)) {
            press = CGSize(width: point.x, height: point.y)
            pressed = true
        }
    }

    private func release() {
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["wobble"])) {
            press = .zero
            pressed = false
        }
    }

    private func autoPress() {
        guard !held else { return }
        let point = Self.previewPoints[step % Self.previewPoints.count]
        step += 1
        pressDown(at: point)
        script?.cancel()
        script = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.3))
            guard !Task.isCancelled else { return }
            release()
        }
    }
}
