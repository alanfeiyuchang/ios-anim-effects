import SwiftUI

extension Effect {
    static let buttonsHoldToConfirm = Effect(
        id: "buttons.hold-to-confirm",
        category: .buttons,
        interaction: .gesture,
        name: L("Hold to Confirm", "长按确认"),
        summary: L("A fill sweeps across while you hold; let go early and it drains.", "按住时填充逐渐铺满，提前松手则回落。"),
        prompt: L(
            "A 260 × 62 pt capsule tinted 10% red, reading “Hold to delete” with a trash glyph, under the file card it will delete. While held, a red-to-coral fill grows linearly from the left over 1.5 s, led by a thin blurred white edge; the button eases to 97% and the card leans back to 96%. A white copy of the label is masked by the fill, so the text flips from red to white exactly where the fill passes. In the last ~28% of the hold the capsule jitters sideways with growing amplitude (~1.5 pt), like a latch about to give. Letting go early drains the fill on a soft, non-overshooting spring (response 0.45 s). Completing snaps the fill full, blur-replaces the label with a checkmark and “Deleted”, dissolves the card upward (90%, 8 pt blur) with a success haptic, and restores after ~1.4 s. Deliberate friction.",
            "260 × 62pt 淡红胶囊“长按删除”配垃圾桶图标，上方是待删文件卡片。按住后，红到珊瑚色的填充从左侧 1.5 秒线性铺满，前沿带模糊白边；按钮轻压到 97%，卡片后仰到 96%。白色文字副本以填充为遮罩，填充经过处文字由红变白。最后约 28% 行程按钮左右抖动、幅度渐增（约 1.5pt），像卡扣将松。中途松手，填充以无过冲弹簧（响应 0.45 秒）回落；按满则文字换成对勾与“已删除”，卡片向上消散（90%、模糊 8pt）并触发成功触觉，约 1.4 秒后复原。"
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
            .slider("shake", L("Edge shake", "临界抖动"), 0...4, default: 1.5, decimals: 1, unit: "pt"),
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
            VStack(spacing: 22) {
                fileRow
                control
            }
            Spacer()
            DemoHint(text: L("Press and hold, or let go early", "长按完成，或中途松手"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: ctx["duration"] + 2.4, delay: 0.4) { simulateHold() }
    }

    /// The item being deleted: it leans back while you hold and dissolves when the hold completes.
    private var fileRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.richtext.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(
                    LinearGradient(colors: [Palette.amber, Palette.coral], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                )
            VStack(alignment: .leading, spacing: 3) {
                Text(ctx.language == .zh ? "第三季度路线图.key" : "Q3 Roadmap.key")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(ctx.language == .zh ? "24 MB · 今天编辑" : "24 MB · Edited today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(width: size.width)
        .demoCard(cornerRadius: 18)
        .scaleEffect(confirmed ? 0.9 : 1 - progress * 0.04)
        .blur(radius: confirmed ? 8 : 0)
        .opacity(confirmed ? 0 : 1)
        .offset(y: confirmed ? -10 : 0)
    }

    private var control: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Palette.elevated)
            Capsule().fill(Palette.red.opacity(0.1))
            ButtonHoldLabel(confirmed: confirmed, color: Palette.red, language: ctx.language)
            ZStack {
                LinearGradient(colors: [Palette.red, Palette.coral], startPoint: .leading, endPoint: .trailing)
                ButtonHoldLabel(confirmed: confirmed, color: .white, language: ctx.language)
            }
            .mask(alignment: .leading) {
                Rectangle().frame(width: size.width * progress)
            }
            // Bright leading edge that rides the fill front.
            Capsule()
                .fill(Color.white.opacity(0.75))
                .frame(width: 3, height: size.height * 0.56)
                .blur(radius: 1.5)
                .offset(x: max(size.width * progress - 4, 0))
                // Keyed on the gesture state (the model value of `progress` jumps straight to 1).
                .opacity(pressing && !confirmed ? 1 : 0)
                .allowsHitTesting(false)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Palette.red.opacity(0.22)))
        .shadow(color: Palette.red.opacity(pressing || confirmed ? 0.3 : 0.12), radius: 16, y: 8)
        .scaleEffect(pressing && !confirmed ? 0.97 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: pressing)
        .modifier(HoldEdgeShake(active: pressing && !confirmed, hold: ctx["duration"], amount: ctx["shake"]))
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

    private func confirm(silent: Bool = false) {
        guard !confirmed else { return }
        pressing = false
        withAnimation(.snappy(duration: 0.25)) {
            progress = 1
            confirmed = true
        }
        if !ctx.isPreview && !silent { Haptics.success() }
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
        // Captured now: autoplay mutes haptics only for the synchronous part of the action.
        let muted = Haptics.isMuted
        beginHold()
        let hold = ctx["duration"]
        Task {
            try? await Task.sleep(for: .seconds(hold))
            confirm(silent: muted)
        }
    }
}

/// Jitters the button sideways during the last ~28% of a hold, like a latch about to give.
private struct HoldEdgeShake: ViewModifier {
    let active: Bool
    let hold: Double
    let amount: Double

    func body(content: Content) -> some View {
        let lead = hold * 0.72
        let beat = hold * 0.28 / 8
        return content.keyframeAnimator(initialValue: 0.0, trigger: active) { view, jitter in
            view.offset(x: active ? jitter : 0)
        } keyframes: { _ in
            KeyframeTrack(\.self) {
                LinearKeyframe(0, duration: lead)
                CubicKeyframe(amount * 0.4, duration: beat)
                CubicKeyframe(-amount * 0.5, duration: beat)
                CubicKeyframe(amount * 0.6, duration: beat)
                CubicKeyframe(-amount * 0.7, duration: beat)
                CubicKeyframe(amount * 0.8, duration: beat)
                CubicKeyframe(-amount * 0.9, duration: beat)
                CubicKeyframe(amount, duration: beat)
                CubicKeyframe(-amount, duration: beat)
                LinearKeyframe(0, duration: 0.05)
            }
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
