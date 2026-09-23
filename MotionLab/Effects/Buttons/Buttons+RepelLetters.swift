import SwiftUI

extension Effect {
    static let buttonsRepelLetters = Effect(
        id: "buttons.repel-letters",
        category: .buttons,
        interaction: .gesture,
        name: L("Letter Repel", "字母避让"),
        summary: L("The label's letters scatter away from your finger and spring back into line.", "按钮文字逐个躲开手指，离开后弹回原位。"),
        prompt: L(
            "A 290 × 68 pt near-black capsule with a monospaced label \"EXPLORE MORE\" set letter by letter on a 16 pt grid. As the finger slides across the button, every letter within a 56 pt radius is pushed directly away from the touch point — up to 18 pt at the centre, fading linearly to zero at the rim — while tilting up to 25° away and growing to 120%, so the word parts like a school of fish around the fingertip. Each letter chases its target on its own spring (response 0.35 s, damping 0.55) with a 10 ms left-to-right stagger, so the ripple feels fluid; on release they all regroup into a perfect line with a soft overshoot. Tapping fires a light haptic. Playful, curious and typographic.",
            "一枚 290 × 68pt 的近黑胶囊，等宽字体“EXPLORE MORE”按 16pt 网格逐字排列。手指滑过时，触点 56pt 内的每个字母被径直推开——中心处最多 18pt，向边缘线性衰减为零——同时向外倾斜至多 25°、放大到 120%，整行字像鱼群一样绕开指尖。每个字母以各自的弹簧（响应 0.35 秒、阻尼 0.55）追随，从左到右错开 10 毫秒，涟漪流畅；松手后所有字母带轻微过冲重新排齐。点击有轻触感。俏皮、好奇，充满字体趣味。"
        ),
        implementation: L(
            "Letters sit on a fixed-advance grid so each centre is known; a zero-distance DragGesture stores the finger point and every letter derives its offset, rotation and scale from its distance to that point, animated by a per-letter spring keyed on the finger.",
            "字母排在固定步进的网格上，因此每个字母的中心已知；零距离 DragGesture 记录手指位置，每个字母根据与该点的距离计算偏移、旋转与缩放，并以手指位置为 key 使用逐字弹簧动画。"
        ),
        apis: ["DragGesture", "offset", "rotationEffect", "spring(response:dampingFraction:)", "delay"],
        tags: ["repel", "letters", "typography", "hover", "避让", "字母", "排版", "跟随"],
        params: [
            .slider("radius", L("Influence radius", "影响半径"), 30...90, default: 56, decimals: 0, unit: "pt"),
            .slider("strength", L("Push distance", "推开距离"), 8...30, default: 18, decimals: 0, unit: "pt"),
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.7, default: 0.35, unit: "s"),
        ]
    ) { ctx in
        ButtonRepelLettersDemo(ctx: ctx)
    }
}

private struct ButtonRepelLettersDemo: View {
    let ctx: DemoContext
    @State private var finger: CGPoint?
    @State private var step = 0
    /// The detail intro's scripted sweep; cancelled by the first real touch and on disappear.
    @State private var introTask: Task<Void, Never>?

    private let size = CGSize(width: 290, height: 68)

    private static let previewPath: [CGPoint] = [
        CGPoint(x: 60, y: 30), CGPoint(x: 120, y: 44), CGPoint(x: 180, y: 26), CGPoint(x: 240, y: 40),
    ]

    private var letters: [String] {
        let text = ctx.language == .zh ? "探索更多内容" : "EXPLORE MORE"
        return text.map { String($0) }
    }

    private var advance: CGFloat { ctx.language == .zh ? 30 : 16 }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 16) {
                Text(L("Spring collection", "春季系列"), ctx.language)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                button
            }
            Spacer()
            DemoHint(text: L("Slide your finger across the label", "手指在文字上滑动"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 0.7, delay: 0.3) {
            // The detail intro slides across once and lifts off, so the letters always regroup.
            if ctx.isPreview { previewStep() } else { introSweep() }
        }
        .onDisappear { stopIntro() }
    }

    private var button: some View {
        ZStack {
            Capsule()
                .fill(LinearGradient(colors: [Color(hex: 0x2A2A33), Color(hex: 0x111116)], startPoint: .top, endPoint: .bottom))
            glow
            ZStack {
                ForEach(letters.indices, id: \.self) { index in
                    letter(index)
                }
            }
            .frame(width: size.width, height: size.height)
        }
        .frame(width: size.width, height: size.height)
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.14), lineWidth: 1))
        .shadow(color: .black.opacity(0.25), radius: 16, y: 10)
        .contentShape(Capsule())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    stopIntro()
                    if finger == nil { Haptics.tap() }
                    finger = value.location
                }
                .onEnded { _ in finger = nil }
        )
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var glow: some View {
        if let finger {
            Circle()
                .fill(RadialGradient(colors: [Palette.violet.opacity(0.45), .clear], center: .center, startRadius: 0, endRadius: 50))
                .frame(width: 100, height: 100)
                .position(finger)
                .allowsHitTesting(false)
                .transition(.opacity)
        }
    }

    private func home(_ index: Int) -> CGPoint {
        let total = CGFloat(letters.count) * advance
        let x = (size.width - total) / 2 + advance * (CGFloat(index) + 0.5)
        return CGPoint(x: x, y: size.height / 2)
    }

    private func letter(_ index: Int) -> some View {
        let center = home(index)
        let push = displacement(for: center)
        return Text(letters[index])
            .font(.system(size: ctx.language == .zh ? 20 : 19, weight: .bold, design: .monospaced))
            .foregroundStyle(Color.white)
            .frame(width: advance)
            .rotationEffect(.degrees(push.tilt))
            .scaleEffect(1 + 0.2 * push.weight)
            .position(center)
            .offset(x: push.dx, y: push.dy)
            .animation(.spring(response: ctx["response"], dampingFraction: 0.55).delay(Double(index) * 0.01), value: finger)
    }

    private func displacement(for center: CGPoint) -> (dx: CGFloat, dy: CGFloat, tilt: Double, weight: CGFloat) {
        guard let finger else { return (0, 0, 0, 0) }
        let dx = center.x - finger.x
        let dy = center.y - finger.y
        let distance = max(hypot(dx, dy), 0.5)
        let radius = ctx.cg("radius")
        let weight = max(0, 1 - distance / radius)
        let push = ctx.cg("strength") * weight
        let ux = dx / distance
        let uy = dy / distance
        let tilt = Double(ux * weight) * 25
        return (ux * push, uy * push, tilt, weight)
    }

    private func introSweep() {
        stopIntro()
        introTask = Task { @MainActor in
            for point in Self.previewPath {
                finger = point
                try? await Task.sleep(for: .seconds(0.45))
                guard !Task.isCancelled else { return }
            }
            finger = nil
            introTask = nil
        }
    }

    private func stopIntro() {
        introTask?.cancel()
        introTask = nil
    }

    private func previewStep() {
        let point = Self.previewPath[step % Self.previewPath.count]
        step += 1
        if step % 5 == 0 {
            finger = nil
        } else {
            finger = point
        }
    }
}
