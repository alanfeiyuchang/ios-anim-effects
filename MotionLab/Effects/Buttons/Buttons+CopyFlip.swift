import SwiftUI

extension Effect {
    static let buttonsCopyFlip = Effect(
        id: "buttons.copy-flip",
        category: .buttons,
        interaction: .tap,
        name: L("Flip to Copied", "翻转复制"),
        summary: L("The Copy button tumbles forward to a green Copied face, then rolls on back.", "“复制”按钮向前翻滚成绿色“已复制”，稍后继续翻回原样。"),
        prompt: L(
            "A dark code-snippet card (a terminal command in monospaced type) with a 104 × 36 pt \"Copy\" key in its header. On tap the key tumbles forward around its horizontal axis like a split-flap tile: a 180° roll on a spring (response 0.5 s, damping 0.72) with strong perspective reveals a green \"Copied\" face with a checkmark on its back, the face swapping exactly edge-on. At the same moment a translucent selection highlight sweeps across the code line from left to right (0.35 s). After 1.6 s the key keeps rolling in the same direction — another 180° — back to \"Copy\", so it never rewinds. A success haptic confirms the copy. Crisp, mechanical and developer-friendly.",
            "一张深色代码片段卡片（等宽字体的终端命令），头部有一枚 104 × 36pt 的“复制”按键。点击后，按键像翻页牌一样绕水平轴向前翻滚：以弹簧（响应 0.5 秒、阻尼 0.72）翻转 180°，透视感强烈，露出背面带对勾的绿色“已复制”，正反面恰好在侧立时切换。同时一道半透明的选中高光从左到右扫过代码行（0.35 秒）。1.6 秒后，按键沿同一方向继续翻滚 180° 回到“复制”，从不倒放。复制成功伴随成功触感。干脆、机械感强、对开发者友好。"
        ),
        implementation: L(
            "An Animatable view takes an ever-increasing roll angle and chooses the visible face (the back is pre-rotated 180° around x) under rotation3DEffect with perspective; a Task adds the second 180° after the hold, and a leading-anchored scaleEffect paints the selection sweep.",
            "Animatable 视图接收不断累加的翻滚角度并选择可见面（背面预先绕 x 轴旋转 180°），外层是带透视的 rotation3DEffect；Task 在停留后再加 180°，选中高光通过以左侧为锚点的 scaleEffect 绘制。"
        ),
        apis: ["Animatable", "rotation3DEffect", "scaleEffect(x:y:anchor:)", "Task.sleep", "spring(response:dampingFraction:)"],
        tags: ["copy", "flip", "clipboard", "code", "复制", "翻转", "剪贴板", "代码"],
        params: [
            .slider("response", L("Roll response", "翻滚响应"), 0.3...1.0, default: 0.5, unit: "s"),
            .slider("hold", L("Copied hold", "停留时长"), 0.6...3.0, default: 1.6, unit: "s"),
            .slider("perspective", L("Perspective", "透视强度"), 0.1...1.0, default: 0.7),
        ]
    ) { ctx in
        ButtonCopyFlipDemo(ctx: ctx)
    }
}

private struct ButtonCopyFlipDemo: View {
    let ctx: DemoContext
    @State private var roll: Double = 0
    @State private var copied = false
    @State private var sweep: CGFloat = 0
    @State private var sweepOpacity: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            card
            Spacer()
            DemoHint(text: L("Tap Copy", "点击复制"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: ctx["hold"] + 1.4, delay: 0.4) { copy() }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    ForEach([Palette.red, Palette.amber, Palette.green], id: \.self) { color in
                        Circle().fill(color).frame(width: 9, height: 9)
                    }
                }
                Spacer(minLength: 0)
                Button(action: copy) {
                    ButtonCopyKey(angle: roll, perspective: ctx.cg("perspective"), language: ctx.language)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(copied ? L("Copied", "已复制") : L("Copy", "复制"), ctx.language))
            }
            codeLine
            Text(verbatim: "# 42 packages · 3.1 s")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.4))
        }
        .padding(18)
        .frame(width: 300)
        .background(Color(hex: 0x16181D), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.white.opacity(0.08)))
        .shadow(color: .black.opacity(0.25), radius: 18, y: 10)
    }

    private var codeLine: some View {
        HStack(spacing: 8) {
            Text(verbatim: "$")
                .foregroundStyle(Palette.mint)
            Text(verbatim: "npm install motion-lexicon")
                .foregroundStyle(Color.white)
        }
        .font(.system(size: 14, weight: .medium, design: .monospaced))
        .padding(.vertical, 6)
        .padding(.horizontal, 6)
        .background(alignment: .leading) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Palette.sky.opacity(0.28))
                .scaleEffect(x: sweep, y: 1, anchor: .leading)
                .opacity(sweepOpacity)
        }
    }

    private func copy() {
        guard !copied else { return }
        copied = true
        Haptics.success()
        withAnimation(.spring(response: ctx["response"], dampingFraction: 0.72)) { roll += 180 }
        sweepOpacity = 1
        withAnimation(.easeOut(duration: 0.35)) { sweep = 1 }
        let hold = ctx["hold"]
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(hold))
            withAnimation(.spring(response: ctx["response"], dampingFraction: 0.72)) { roll += 180 }
            withAnimation(.easeOut(duration: 0.4)) { sweepOpacity = 0 }
            try? await Task.sleep(for: .seconds(0.45))
            // Reset the sweep while it is invisible, so the next copy animates from the left again.
            sweep = 0
            copied = false
        }
    }
}

private struct ButtonCopyKey: View, Animatable {
    var angle: Double
    let perspective: CGFloat
    let language: AppLanguage

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    var body: some View {
        let remainder = angle.truncatingRemainder(dividingBy: 360)
        let normalized = remainder < 0 ? remainder + 360 : remainder
        let showBack = normalized > 90 && normalized < 270
        ZStack {
            face(copied: false)
                .opacity(showBack ? 0 : 1)
            face(copied: true)
                .rotation3DEffect(.degrees(180), axis: (x: 1, y: 0, z: 0))
                .opacity(showBack ? 1 : 0)
        }
        .rotation3DEffect(.degrees(angle), axis: (x: 1, y: 0, z: 0), perspective: perspective)
    }

    private func face(copied: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                .font(.system(size: 12, weight: .bold))
            Text(copied ? L("Copied", "已复制") : L("Copy", "复制"), language)
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundStyle(Color.white)
        .frame(width: 104, height: 36)
        .background(
            copied ? AnyShapeStyle(Palette.successStrong) : AnyShapeStyle(Color.white.opacity(0.12)),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.white.opacity(copied ? 0.25 : 0.14), lineWidth: 1)
        )
    }
}
