import SwiftUI

extension Effect {
    static let inputsSquashToggle = Effect(
        id: "inputs.squash-toggle",
        category: .inputs,
        interaction: .state,
        name: L("Squash & Stretch Toggle", "弹性形变开关"),
        summary: L("The knob stretches under your finger and bounces across.", "按住时旋钮被拉伸，松手后弹跳滑到另一端。"),
        prompt: L(
            "An oversized 84 × 48 pt pill switch heads a Notifications settings card; its white knob, lifted by a soft shadow, carries a tiny x / check glyph. On touch-down the knob stretches to ~130% width and squashes to ~90% height on a quick 250 ms spring, anchored to its current edge like jelly under a fingertip. On release it slides to the opposite end on a lively spring (response 0.42 s, damping 0.68), regaining its round shape and landing with a small overshoot; the track cross-fades from neutral grey to a mint-to-green gradient, the knob glyph and the row's bell icon swap via symbol replace, and a light haptic ticks. The two dependent rows below then wake in sequence (60 ms stagger), brightening from 40% as green checkmarks spring in. Squishy and cartoon-physical, yet crisp.",
            "“通知”设置卡片顶部是一枚加大的 84 × 48pt 胶囊开关，白色旋钮带柔和投影，嵌着小小的叉号/对勾。按下时旋钮以 250 毫秒快速弹簧横向拉到约 130%、纵向压到约 90%，贴住当前一端，像被按住的果冻。松手后以活泼弹簧（响应 0.42 秒、阻尼 0.68）滑向另一端并恢复圆形，落点轻微过冲；轨道由中性灰过渡为薄荷到绿的渐变，旋钮图标与铃铛经符号替换切换，并轻触一下。随后两条从属设置以 60 毫秒错峰苏醒，从 40% 透明度提亮，绿色对勾弹出。"
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

    private let trackSize = CGSize(width: 84, height: 48)
    private let inset: CGFloat = 5

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            card
            Spacer()
            DemoHint(text: L("Press, hold, then release the switch", "按住开关再松手"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.3, delay: 0.4) { simulateTap() }
    }

    private var card: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: isOn ? "bell.badge.fill" : "bell.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 38, height: 38)
                    .background(
                        LinearGradient(colors: [Palette.amber, Palette.coral], startPoint: .top, endPoint: .bottom),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("Notifications", "通知"), ctx.language)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(isOn ? L("On · Instant", "已开启 · 即时") : L("Off", "已关闭"), ctx.language)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .contentTransition(.opacity)
                }
                Spacer(minLength: 0)
                toggle
            }
            Rectangle()
                .fill(Palette.stroke)
                .frame(height: 1)
            ForEach(0..<2, id: \.self) { row in
                dependentRow(row)
            }
        }
        .padding(16)
        .frame(width: 310)
        .demoCard(cornerRadius: 24)
    }

    /// Child settings wake up one after another once the master switch lands.
    private func dependentRow(_ row: Int) -> some View {
        let titles = [L("Sounds", "声音"), L("Lock screen", "锁定屏幕")]
        return HStack {
            Text(titles[row], ctx.language)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Palette.green)
                .scaleEffect(isOn ? 1 : 0.5)
                .opacity(isOn ? 1 : 0)
        }
        .opacity(isOn ? 1 : 0.4)
        .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(isOn ? 0.12 + Double(row) * 0.06 : 0), value: isOn)
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
                .overlay {
                    Image(systemName: isOn ? "checkmark" : "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isOn ? Palette.green : Color.gray.opacity(0.6))
                        .contentTransition(.symbolEffect(.replace))
                }
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

    private func release(silent: Bool = false) {
        if !ctx.isPreview && !silent { Haptics.tap() }
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            isOn.toggle()
            pressing = false
        }
    }

    private func simulateTap() {
        // Captured now: autoplay mutes haptics only for the synchronous part of the action.
        let muted = Haptics.isMuted
        press()
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            release(silent: muted)
        }
    }
}
