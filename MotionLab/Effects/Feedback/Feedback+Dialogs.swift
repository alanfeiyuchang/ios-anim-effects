import SwiftUI

// MARK: - Alert pop

extension Effect {
    static let feedbackAlertPop = Effect(
        id: "feedback.alert-pop",
        category: .feedback,
        interaction: .tap,
        name: L("Alert Pop", "弹窗浮现"),
        summary: L("A destructive-action alert that pops in over a dimmed, blurred backdrop.", "危险操作确认框在变暗、模糊的背景上弹出。"),
        prompt: L(
            "Tapping a red 'Delete Account' row presents a 270 pt frosted alert card (22 pt corners) with a red trash badge, a bold title, a two-line explanation and Cancel / Delete buttons split by hairlines. The page behind recedes: it blurs to about 8 pt, scales to 96% and a 28% black scrim fades in. The card enters from 112% scale and 0 opacity on a quick, lightly damped spring (response 0.35 s, damping 0.82) — or, in 'Pop' style, bounces up from 60%. Dismissal is faster and quieter: the card fades while shrinking to 94% over 0.2 s as the backdrop sharpens. Focused, serious and calm.",
            "点击红色“删除账户”行，弹出一张 270 pt 宽、22 pt 圆角的磨砂确认卡片：红色垃圾桶徽标、粗体标题、两行说明，以及由细分隔线隔开的“取消 / 删除”按钮。背后的页面随之退后：模糊到约 8 pt、缩小到 96%，并淡入 28% 的黑色遮罩。卡片从 112% 缩放、0 透明度以轻快、微阻尼的弹簧（响应 0.35 秒、阻尼 0.82）进入；切换到“弹跳”风格时则从 60% 弹起。关闭更快更安静：0.2 秒内边缩小到 94% 边淡出，背景重新变得清晰。专注、郑重而平静。"
        ),
        implementation: L(
            "One Boolean drives backdrop blur/scale, the scrim and the card's scale/opacity; a separate flag makes dismissal shrink rather than re-grow.",
            "一个布尔值驱动背景的模糊与缩放、遮罩以及卡片的缩放与透明度；另设标志让关闭时缩小而不是反向放大。"
        ),
        apis: ["blur(radius:)", "scaleEffect", "thickMaterial", "spring(response:dampingFraction:)"],
        tags: ["alert", "dialog", "modal", "confirm", "弹窗", "对话框", "确认", "模态"],
        params: [
            .choice("style", L("Entrance", "入场风格"), [L("iOS", "系统"), L("Pop", "弹跳")], default: 0),
            .slider("blur", L("Backdrop blur", "背景模糊"), 0...20, default: 8, decimals: 0, unit: "pt"),
            .slider("dim", L("Scrim", "遮罩浓度"), 0...0.6, default: 0.28),
        ]
    ) { ctx in
        AlertPopDemo(ctx: ctx)
    }
}

private struct AlertPopDemo: View {
    let ctx: DemoContext
    @State private var presented: Bool
    @State private var closing = false

    init(ctx: DemoContext) {
        self.ctx = ctx
        // Still thumbnails show the alert presented over the blurred card.
        _presented = State(initialValue: ctx.isStill)
    }

    var body: some View {
        let pop = ctx.int("style") == 1
        let hiddenScale: CGFloat = closing ? 0.94 : (pop ? 0.6 : 1.12)
        ZStack {
            AlertBackdropCard(language: ctx.language, onDelete: present)
                .blur(radius: presented ? ctx["blur"] : 0)
                .scaleEffect(presented ? 0.96 : 1)
            Color.black
                .opacity(presented ? ctx["dim"] : 0)
                .contentShape(Rectangle())
                .allowsHitTesting(presented)
                .onTapGesture { dismiss() }
            AlertCardView(language: ctx.language, onCancel: dismiss, onDelete: dismiss)
                .scaleEffect(presented ? 1 : hiddenScale)
                .opacity(presented ? 1 : 0)
                .allowsHitTesting(presented)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap Delete Account", "点击“删除账户”"), ctx: ctx)
                .padding(.bottom, 14)
                .opacity(presented ? 0 : 1)
                .allowsHitTesting(false)
        }
        .autoplay(ctx.isPreview, every: 1.8, delay: 0.6) {
            if presented { dismiss() } else { present() }
        }
    }

    private func present() {
        closing = false
        if !ctx.isPreview { Haptics.tap(.medium) }
        let pop = ctx.int("style") == 1
        withAnimation(pop ? Animation.spring(response: 0.42, dampingFraction: 0.62) : Animation.spring(response: 0.35, dampingFraction: 0.82)) {
            presented = true
        }
    }

    private func dismiss() {
        closing = true
        withAnimation(.easeOut(duration: 0.2)) { presented = false }
    }
}

private struct AlertBackdropCard: View {
    let language: AppLanguage
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            row("person.crop.circle.fill", Palette.blue, language == .zh ? "个人资料" : "Profile")
            Divider().padding(.leading, 52)
            row("lock.fill", Palette.green, language == .zh ? "隐私与安全" : "Privacy & Security")
            Divider().padding(.leading, 52)
            row("bell.badge.fill", Palette.coral, language == .zh ? "通知" : "Notifications")
            Divider()
            Button(action: onDelete) {
                Text(language == .zh ? "删除账户" : "Delete Account")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Palette.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(width: 290)
        .demoCard(cornerRadius: 20)
    }

    private func row(_ symbol: String, _ tint: Color, _ title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(tint, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            Text(title)
                .font(.body)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .frame(height: 48)
    }
}

private struct AlertCardView: View {
    let language: AppLanguage
    let onCancel: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(Palette.red.gradient, in: Circle())
                    .padding(.bottom, 4)
                Text(language == .zh ? "删除账户？" : "Delete account?")
                    .font(.headline)
                Text(language == .zh ? "你的所有数据将被永久移除，且无法恢复。" : "All of your data will be permanently removed. This can't be undone.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
            Divider()
            HStack(spacing: 0) {
                alertButton(language == .zh ? "取消" : "Cancel", color: .primary, weight: .regular, action: onCancel)
                Divider()
                alertButton(language == .zh ? "删除" : "Delete", color: Palette.red, weight: .semibold, action: onDelete)
            }
            .frame(height: 46)
        }
        .frame(width: 270)
        .demoGlass(RoundedRectangle(cornerRadius: 22, style: .continuous), material: .thickMaterial)
        .shadow(color: .black.opacity(0.22), radius: 30, y: 16)
    }

    private func alertButton(_ title: String, color: Color, weight: Font.Weight, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(weight))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Undo snackbar

extension Effect {
    static let feedbackUndoSnackbar = Effect(
        id: "feedback.undo-snackbar",
        category: .feedback,
        interaction: .tap,
        name: L("Undo Snackbar", "撤销提示条"),
        summary: L("Deleting slides a row away and raises a snackbar with a countdown ring.", "删除时条目滑走，底部升起带倒计时环的撤销条。"),
        prompt: L(
            "A mail list card with two rows; the first has a trash button. Deleting slides that row out to the left while fading, and the row below springs up to close the gap (response 0.45 s, damping 0.85). At the same time an inverted, high-contrast snackbar rises 120 pt from the bottom edge: 'Conversation deleted', a bold 'Undo' action and a 26 pt countdown ring whose stroke drains linearly over 5 s around a number that ticks down with a rolling digit transition. Undo reverses both motions on the same spring; if the ring empties, the snackbar slips away and the deletion commits. Forgiving, clear and unhurried.",
            "一张邮件列表卡片有两行，第一行带垃圾桶按钮。删除时，该行边向左滑出边淡出，下方条目以弹簧（响应 0.45 秒、阻尼 0.85）上移补位。与此同时，一条反色、高对比的提示条从底部升起 120 pt：左侧“会话已删除”，右侧粗体“撤销”，以及一枚 26 pt 的倒计时环——描边在 5 秒内线性流失，中心数字以滚动过渡逐秒递减。点击撤销，两段动作沿同一弹簧反向复原；若圆环耗尽，提示条悄然滑走，删除正式生效。宽容、清晰、从容不迫。"
        ),
        implementation: L(
            "Row removal uses a move + opacity transition; the ring is a trim animated with .linear(duration:) while a Task ticks the numericText countdown and commits on expiry.",
            "条目移除使用 move + opacity 过渡；倒计时环是以 .linear(duration:) 动画的 trim，Task 逐秒驱动 numericText 倒数并在到期时提交。"
        ),
        apis: ["transition(.move(edge:))", "trim(from:to:)", "contentTransition(.numericText(countsDown:))", "withTransaction"],
        tags: ["undo", "snackbar", "countdown", "delete", "撤销", "提示条", "倒计时", "删除"],
        params: [
            .slider("duration", L("Countdown", "倒计时"), 3...8, default: 5, step: 1, decimals: 0, unit: "s"),
            .slider("response", L("Spring response", "弹簧响应"), 0.25...0.8, default: 0.45, unit: "s"),
        ]
    ) { ctx in
        UndoSnackbarDemo(ctx: ctx)
    }
}

private struct UndoSnackbarDemo: View {
    let ctx: DemoContext
    @State private var deleted = false
    @State private var snack = false
    @State private var remaining: CGFloat = 1
    @State private var seconds = 5
    @State private var token = 0

    private var spring: Animation {
        .spring(response: ctx["response"], dampingFraction: 0.85)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 14) {
                mailCard
                if !deleted {
                    DemoHint(text: L("Tap the trash to delete the email", "点击垃圾桶删除邮件"), ctx: ctx)
                        .transition(.opacity)
                }
                if deleted && !snack {
                    Button(ctx.language == .zh ? "重置演示" : "Reset demo", action: undo)
                        .font(.footnote.weight(.semibold))
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            UndoSnackbar(
                language: ctx.language,
                remaining: remaining,
                seconds: seconds,
                onUndo: undo
            )
            .padding(.bottom, 22)
            .offset(y: snack ? 0 : 120)
            .opacity(snack ? 1 : 0)
        }
        .autoplay(ctx.isPreview, every: 2.2, delay: 0.6) {
            if deleted { undo() } else { delete() }
        }
    }

    private var mailCard: some View {
        VStack(spacing: 0) {
            if !deleted {
                MailRow(
                    tint: Palette.violet,
                    initials: "LS",
                    title: ctx.language == .zh ? "周报汇总" : "Weekly Digest",
                    subtitle: ctx.language == .zh ? "本周设计进展已整理好" : "Your design recap is ready",
                    onDelete: delete
                )
                .transition(AnyTransition.move(edge: .leading).combined(with: .opacity))
                Divider().padding(.leading, 64)
            }
            MailRow(
                tint: Palette.sky,
                initials: "AK",
                title: ctx.language == .zh ? "旅行计划" : "Trip Plans",
                subtitle: ctx.language == .zh ? "机票已确认，周五出发" : "Flights confirmed for Friday",
                onDelete: nil
            )
        }
        .frame(width: 300)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .demoCard(cornerRadius: 20)
    }

    private func delete() {
        guard !deleted else { return }
        token += 1
        let current = token
        let total = max(ctx.int("duration"), 1)
        if !ctx.isPreview { Haptics.tap(.medium) }
        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) {
            remaining = 1
            seconds = total
        }
        withAnimation(spring) {
            deleted = true
            snack = true
        }
        withAnimation(.linear(duration: Double(total))) { remaining = 0 }
        Task {
            for value in stride(from: total - 1, through: 0, by: -1) {
                try? await Task.sleep(for: .seconds(1))
                guard token == current else { return }
                withAnimation(.snappy) { seconds = value }
            }
            withAnimation(.smooth(duration: 0.35)) { snack = false }
        }
    }

    private func undo() {
        token += 1
        if !ctx.isPreview && snack { Haptics.success() }
        withAnimation(spring) {
            deleted = false
            snack = false
            // Refill the ring so the next delete animates 1 → 0 (a same-tick reset would be coalesced away).
            remaining = 1
        }
    }
}

private struct MailRow: View {
    let tint: Color
    let initials: String
    let title: String
    let subtitle: String
    let onDelete: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Text(initials)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(tint.gradient, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 4)
            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.red)
                        .frame(width: 36, height: 36)
                        .background(Palette.red.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 64)
        .background(Palette.elevated)
    }
}

private struct UndoSnackbar: View {
    let language: AppLanguage
    let remaining: CGFloat
    let seconds: Int
    let onUndo: () -> Void

    var body: some View {
        let ink = Color(uiColor: .systemBackground)
        HStack(spacing: 12) {
            ZStack {
                Circle().stroke(ink.opacity(0.2), lineWidth: 2.5)
                Circle()
                    .trim(from: 0, to: remaining)
                    .stroke(ink, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(seconds)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .contentTransition(.numericText(countsDown: true))
            }
            .frame(width: 26, height: 26)
            Text(language == .zh ? "会话已删除" : "Conversation deleted")
                .font(.subheadline.weight(.medium))
            Spacer(minLength: 8)
            Button(action: onUndo) {
                Text(language == .zh ? "撤销" : "Undo")
                    .font(.subheadline.weight(.bold))
                    // The snackbar is inverted (black in light mode, white in dark), so the accent flips too.
                    .foregroundStyle(Color.adaptive(light: 0x3AC4FF, dark: 0x2A6DF4))
                    .padding(.horizontal, 6)
                    .frame(height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(ink)
        .padding(.leading, 14)
        .padding(.trailing, 10)
        .frame(width: 300, height: 52)
        .background(Color.primary.opacity(0.92), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
    }
}
