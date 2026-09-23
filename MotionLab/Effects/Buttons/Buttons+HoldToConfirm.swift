import SwiftUI

extension Effect {
    static let buttonsHoldToConfirm = Effect(
        id: "buttons.hold-to-confirm",
        category: .buttons,
        interaction: .gesture,
        name: L("Hold to Confirm", "长按确认"),
        summary: L("A fill sweeps across while you hold; let go early and it drains.", "按住时填充逐渐铺满，提前松手则回落。"),
        prompt: L(
            "A neutral capsule button reading \"Hold to delete\" with a trash glyph. When the finger presses and holds, a red-to-coral fill grows linearly from the left edge over 1.5 s while the button eases down to 97%; the label is duplicated in white and masked by the fill, so text flips from dark to white exactly where the fill passes. Releasing early drains the fill back to zero on a soft spring (response 0.45 s, no overshoot). Completing the hold snaps the fill full, crossfades the label to a checkmark and \"Deleted\", fires a success haptic, then resets after ~1.4 s. It feels deliberate and safe — friction exactly where a destructive action needs it.",
            "中性色胶囊按钮，文字为“长按删除”并带垃圾桶图标。手指按住后，红到珊瑚色的填充从左侧以线性速度在 1.5 秒内铺满，按钮同时轻压到 97%；文字复制一份白色版本并以填充区域做遮罩，填充经过之处文字由深色精确切换为白色。中途松手时，填充以柔和无过冲的弹簧（响应 0.45 秒）回落到零；按满后填充定格，文字交叉淡入为对勾与“已删除”，触发成功触觉，约 1.4 秒后复位。刻意而安心——恰好在危险操作处加入必要的阻力。"
        ),
        implementation: L(
            "onLongPressGesture's onPressingChanged starts a linear fill animation for the hold duration or springs it back; perform marks completion. A leading-aligned mask reveals a white copy of the label over the fill.",
            "onLongPressGesture 的 onPressingChanged 启动时长等于按住时间的线性填充动画，或将其弹回；perform 标记完成。前对齐的 mask 让白色文字副本只在填充区域显示。"
        ),
        apis: ["onLongPressGesture(minimumDuration:perform:onPressingChanged:)", "mask(alignment:)", "withAnimation", "blurReplace"],
        tags: ["hold", "long press", "confirm", "destructive", "长按", "确认", "删除", "进度"],
        params: [
            .slider("duration", L("Hold duration", "按住时长"), 0.6...3.0, default: 1.5, unit: "s"),
            .slider("drain", L("Drain response", "回落响应"), 0.2...1.0, default: 0.45, unit: "s"),
        ]
    ) { ctx in
        ButtonHoldToConfirmDemo(ctx: ctx)
    }
}

private struct ButtonHoldToConfirmDemo: View {
    let ctx: DemoContext
    @State private var progress: CGFloat = 0
    @State private var pressing = false
    @State private var confirmed = false

    private let size = CGSize(width: 260, height: 62)

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            control
            Spacer()
            DemoHint(text: L("Press and hold, or let go early", "长按完成，或中途松手"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: ctx["duration"] + 2.4, delay: 0.4) { simulateHold() }
    }

    private var control: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Palette.elevated)
            ButtonHoldLabel(confirmed: confirmed, color: .primary, language: ctx.language)
            ZStack {
                LinearGradient(colors: [Palette.red, Palette.coral], startPoint: .leading, endPoint: .trailing)
                ButtonHoldLabel(confirmed: confirmed, color: .white, language: ctx.language)
            }
            .mask(alignment: .leading) {
                Rectangle().frame(width: size.width * progress)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(0.1), radius: 14, y: 8)
        .scaleEffect(pressing && !confirmed ? 0.97 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: pressing)
        .onLongPressGesture(minimumDuration: ctx["duration"], maximumDistance: 40) {
            confirm()
        } onPressingChanged: { isPressing in
            if isPressing { beginHold() } else { endHold() }
        }
    }

    private func beginHold() {
        guard !confirmed else { return }
        pressing = true
        if !ctx.isPreview { Haptics.tap() }
        withAnimation(.linear(duration: ctx["duration"])) { progress = 1 }
    }

    private func endHold() {
        pressing = false
        guard !confirmed else { return }
        withAnimation(.spring(response: ctx["drain"], dampingFraction: 1)) { progress = 0 }
    }

    private func confirm() {
        guard !confirmed else { return }
        pressing = false
        withAnimation(.snappy(duration: 0.25)) {
            progress = 1
            confirmed = true
        }
        if !ctx.isPreview { Haptics.success() }
        Task {
            try? await Task.sleep(for: .seconds(1.4))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                confirmed = false
                progress = 0
            }
        }
    }

    private func simulateHold() {
        guard !confirmed else { return }
        beginHold()
        let hold = ctx["duration"]
        Task {
            try? await Task.sleep(for: .seconds(hold))
            confirm()
        }
    }
}

private struct ButtonHoldLabel: View {
    let confirmed: Bool
    let color: Color
    let language: AppLanguage

    var body: some View {
        ZStack {
            if confirmed {
                Label(language == .zh ? "已删除" : "Deleted", systemImage: "checkmark")
                    .transition(.blurReplace)
            } else {
                Label(language == .zh ? "长按删除" : "Hold to delete", systemImage: "trash")
                    .transition(.blurReplace)
            }
        }
        .font(.headline)
        .foregroundStyle(color)
        .frame(maxWidth: .infinity)
    }
}
