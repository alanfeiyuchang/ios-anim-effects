import SwiftUI

extension Effect {
    static let inputsSquashToggle = Effect(
        id: "inputs.squash-toggle",
        category: .inputs,
        interaction: .state,
        name: L("Squash & Stretch Toggle", "弹性形变开关"),
        summary: L("The knob stretches under your finger and bounces across.", "按住时旋钮被拉伸，松手后弹跳滑到另一端。"),
        prompt: L(
            "An oversized pill switch (96 × 56 pt) with a white knob and a soft drop shadow. On touch-down the knob stretches horizontally to ~130% of its width and squashes to ~90% of its height on a quick spring (250 ms), staying anchored to its current edge, like a drop of jelly pressed by the finger. On release it slides to the opposite end on a lively spring (response 0.42 s, damping 0.68) while restoring its round shape, landing with a small overshoot; the track crossfades from a neutral gray to a mint-to-green gradient and a light haptic ticks. The motion feels squishy, tactile and cartoon-physical while staying crisp.",
            "加大尺寸的胶囊开关（96 × 56pt），白色圆形旋钮带柔和投影。手指按下时，旋钮以快速弹簧（250 毫秒）横向拉伸到约 130%、纵向压扁到约 90%，并贴住当前所在的一端，像一团被手指按住的果冻。松手后，旋钮以活泼的弹簧（响应 0.42 秒、阻尼 0.68）滑向另一端，同时恢复圆形，落点带轻微过冲；轨道从中性灰交叉过渡为薄荷到绿色的渐变，并伴随一次轻触觉。动作软弹、可触，带有卡通物理感又不失利落。"
        ),
        implementation: L(
            "A zero-distance DragGesture sets a pressing flag that widens and flattens the knob's frame; release toggles the ZStack alignment between leading and trailing inside one spring transaction.",
            "零距离 DragGesture 设置按压状态，使旋钮 frame 变宽变扁；松手时在同一个弹簧事务中切换 ZStack 的前/后对齐。"
        ),
        apis: ["DragGesture", "ZStack(alignment:)", "spring(response:dampingFraction:)", "frame"],
        tags: ["toggle", "switch", "squash", "stretch", "开关", "拉伸", "果冻", "弹性"],
        params: [
            .slider("stretch", L("Stretch", "拉伸量"), 1.0...1.6, default: 1.3),
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.8, default: 0.42, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.4...1.0, default: 0.68),
        ]
    ) { ctx in
        InputSquashToggleDemo(ctx: ctx)
    }
}

private struct InputSquashToggleDemo: View {
    let ctx: DemoContext
    @State private var isOn = false
    @State private var pressing = false

    private let trackSize = CGSize(width: 96, height: 56)
    private let inset: CGFloat = 5

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            toggle
            Text(isOn ? L("Notifications on", "通知已开启") : L("Notifications off", "通知已关闭"), ctx.language)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .contentTransition(.opacity)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.3, delay: 0.4) { simulateTap() }
    }

    private var knobSide: CGFloat { trackSize.height - inset * 2 }

    private var toggle: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule().fill(Color.primary.opacity(0.12))
            Capsule()
                .fill(LinearGradient(colors: [Palette.mint, Palette.green], startPoint: .leading, endPoint: .trailing))
                .opacity(isOn ? 1 : 0)
            Capsule()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
                .frame(
                    width: knobSide * (pressing ? ctx.cg("stretch") : 1),
                    height: knobSide * (pressing ? 0.9 : 1)
                )
                .padding(inset)
        }
        .frame(width: trackSize.width, height: trackSize.height)
        .contentShape(Capsule())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in press() }
                .onEnded { _ in release() }
        )
    }

    private func press() {
        guard !pressing else { return }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { pressing = true }
    }

    private func release() {
        if !ctx.isPreview { Haptics.tap() }
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            isOn.toggle()
            pressing = false
        }
    }

    private func simulateTap() {
        press()
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            release()
        }
    }
}
