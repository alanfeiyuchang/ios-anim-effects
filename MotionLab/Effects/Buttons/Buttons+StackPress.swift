import SwiftUI

extension Effect {
    static let buttonsStackPress = Effect(
        id: "buttons.stack-press",
        category: .buttons,
        interaction: .tap,
        name: L("Layered Stack Press", "叠层按压"),
        summary: L("A brutalist button of offset layers that collapse on press and fan back out.", "由错位叠层组成的粗野风按钮，按下时层层塌缩，松手后依次弹开。"),
        prompt: L(
            "A bold neo-brutalist 220 × 60 pt button built from three identical rounded slabs with 2 pt ink outlines: a pink back slab offset 12 pt down-right, a coral middle slab offset 6 pt, and an amber face on top with the label \"Publish\". On touch-down the slabs collapse into one — the face travels first, the middle slab 40 ms later — each on a quick spring (response 0.3 s), so the stack visibly telescopes shut. On release they fan back out in the same order: the face pops up first and the lower layers trail behind with the 40 ms stagger and a lively bounce (damping 0.55), like a deck of cards springing open. A rigid haptic confirms the press. Graphic, loud and satisfyingly mechanical.",
            "一枚 220 × 60pt 的新粗野主义按钮，由三块带 2pt 墨色描边的相同圆角板叠成：粉色底板向右下偏移 12pt，珊瑚色中板偏移 6pt，最上面是写着“发布”的琥珀色面板。按下时三层塌成一层——面板先动，中板晚 40 毫秒——各走一段利落弹簧（响应 0.3 秒），像望远镜层层收拢。松手后按同样顺序展开：面板先弹起，下层错开 40 毫秒跟上，带活泼回弹（阻尼 0.55），像一叠卡片被弹开。按下时一次清脆的硬触感。图形感强，机械感十足。"
        ),
        implementation: L(
            "A ButtonStyle draws the three slabs itself: each rests at its own depth and, while pressed, travels to the back slab's depth; every layer carries its own delayed spring keyed on the pressed state, so upper layers lead and lower ones trail.",
            "ButtonStyle 自行绘制三层板：每层静止时位于各自深度，按下时移动到底板的深度；每层带有各自延迟的弹簧并以按压状态为 key，上层先动、下层跟随。"
        ),
        apis: ["ButtonStyle", "offset", "spring(response:dampingFraction:)", "delay", "ZStack(alignment:)"],
        tags: ["brutalist", "layers", "stack", "offset", "粗野主义", "叠层", "错位", "按压"],
        params: [
            .slider("gap", L("Layer gap", "层间距"), 3...10, default: 6, decimals: 0, unit: "pt"),
            .slider("stagger", L("Stagger", "错峰间隔"), 0...0.12, default: 0.04, unit: "s"),
            .slider("damping", L("Release damping", "回弹阻尼"), 0.35...1.0, default: 0.55),
        ]
    ) { ctx in
        ButtonStackPressDemo(ctx: ctx)
    }
}

private struct ButtonStackPressDemo: View {
    let ctx: DemoContext
    @State private var autoPressed = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 22) {
                VStack(spacing: 4) {
                    Text(L("DRAFT · 1,240 words", "草稿 · 1,240 字"), ctx.language)
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Text(L("Ready to ship?", "准备好发布了吗？"), ctx.language)
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                        .foregroundStyle(.primary)
                }
                Button {
                    Haptics.tap(.rigid)
                } label: {
                    HStack(spacing: 8) {
                        Text(ctx.language == .zh ? "发布" : "Publish")
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.black)
                }
                .buttonStyle(
                    ButtonStackStyle(
                        gap: ctx.cg("gap"),
                        stagger: ctx["stagger"],
                        damping: ctx["damping"],
                        forcePressed: autoPressed
                    )
                )
            }
            Spacer()
            DemoHint(text: L("Press and hold, then release", "按住再松开"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 0.8, delay: 0.3) {
            // The detail intro presses once and lets go, so the key never stays held down.
            if ctx.isPreview { autoPressed.toggle() } else { introPress() }
        }
    }

    private func introPress() {
        autoPressed = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.4))
            autoPressed = false
        }
    }
}

private struct ButtonStackStyle: ButtonStyle {
    let gap: CGFloat
    let stagger: Double
    let damping: Double
    let forcePressed: Bool

    private static let fills: [Color] = [Palette.pink, Palette.coral, Palette.amber]

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed || forcePressed
        return ZStack(alignment: .topLeading) {
            slab(0, pressed: pressed) { EmptyView() }
            slab(1, pressed: pressed) { EmptyView() }
            slab(2, pressed: pressed) { configuration.label }
        }
        .frame(width: 220 + gap * 2, height: 60 + gap * 2, alignment: .topLeading)
    }

    /// Layer 0 is the back slab (deepest), layer 2 the face.
    private func slab<Content: View>(_ layer: Int, pressed: Bool, @ViewBuilder content: () -> Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        let depth = CGFloat(2 - layer) * gap
        let travel: CGFloat = pressed ? gap * 2 - depth : 0
        let offset = depth + travel
        // Top layers lead in both directions, deeper layers trail.
        let delay = Double(layer == 2 ? 0 : (layer == 1 ? 1 : 2)) * stagger
        let spring: Animation = pressed
            ? .spring(response: 0.22, dampingFraction: 0.85).delay(delay)
            : .spring(response: 0.3, dampingFraction: damping).delay(delay)
        return shape
            .fill(Self.fills[layer])
            .overlay(shape.strokeBorder(Color.black, lineWidth: 2))
            .overlay { content() }
            .frame(width: 220, height: 60)
            .offset(x: offset, y: offset)
            .animation(spring, value: pressed)
    }
}
