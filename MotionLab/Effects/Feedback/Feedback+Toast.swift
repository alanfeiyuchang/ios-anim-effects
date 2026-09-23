import SwiftUI

// MARK: - Toast

extension Effect {
    static let feedbackToast = Effect(
        id: "feedback.toast",
        category: .feedback,
        interaction: .tap,
        name: L("Blur-In Toast", "模糊滑入吐司"),
        summary: L("A frosted capsule toast that springs in out of a blur and slips away.", "磨砂胶囊吐司从模糊中弹入，再悄然滑走。"),
        prompt: L(
            "A compact frosted capsule toast (green check badge, bold title, secondary caption) waits just off the top or bottom edge. On trigger it travels 110 pt into view on a spring (response 0.45 s, damping 0.72), sharpening from a 10 pt blur, scaling 86% → 100% and fading in, landing with a slight overshoot; a success haptic fires at launch. After a 2 s hold it retreats the same way on a 0.35 s smooth curve, blurring out. Swiping toward its edge tracks the finger 1:1: past 30 pt or with a flick it leaves on a 0.3 s curve, a shorter drag springs back, and the other direction rubber-bands. Re-triggering restarts the timer instead of stacking. Light and polished, never in the way.",
            "磨砂胶囊吐司（绿色对勾、粗体标题、灰色说明）藏在画面顶部或底部边缘外。一触发，它就从 10 pt 的模糊里清晰起来，边放大（86% → 100%）边淡入，乘着弹簧（响应 0.45 秒、阻尼 0.72）滑进 110 pt，落位略带过冲；出发瞬间给一次成功触感。停 2 秒后按原路以 0.35 秒平滑曲线退回，重新变糊。朝边缘划它会 1:1 跟手：超过 30 pt 或快速一甩，0.3 秒离场；不够就弹回，反向拖则有橡皮筋阻尼。连续触发只会重新计时，不会叠加。轻巧精致，从不挡路。"
        ),
        implementation: L(
            "Offset, blur, scale and opacity are all driven by one Boolean inside a spring; a tokenized Task handles auto-dismiss, and a DragGesture adds swipe-to-dismiss that cancels the token.",
            "位移、模糊、缩放与透明度都由同一个布尔值在弹簧动画中驱动；带令牌的 Task 负责自动消失，DragGesture 提供划走关闭并作废该令牌。"
        ),
        apis: ["offset(y:)", "blur(radius:)", "regularMaterial", "Task.sleep(for:)", "DragGesture"],
        tags: ["toast", "snackbar", "notification", "blur", "吐司", "轻提示", "通知", "模糊"],
        params: [
            .choice("edge", L("Edge", "出现位置"), [L("Top", "顶部"), L("Bottom", "底部")], default: 0),
            .slider("hold", L("Hold time", "停留时长"), 1...4, default: 2, decimals: 1, unit: "s"),
            .slider("blur", L("Entry blur", "入场模糊"), 0...20, default: 10, decimals: 0, unit: "pt"),
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.9, default: 0.45, unit: "s"),
        ]
    ) { ctx in
        ToastDemo(ctx: ctx)
    }
}

private struct ToastDemo: View {
    let ctx: DemoContext
    @State private var shown = false
    @State private var token = 0
    @State private var dragY: CGFloat = 0

    var body: some View {
        let fromTop = ctx.int("edge") == 0
        ZStack(alignment: fromTop ? .top : .bottom) {
            Color.clear
            ToastPill(language: ctx.language)
                .scaleEffect(shown ? 1 : 0.86)
                .blur(radius: shown ? 0 : ctx["blur"])
                .opacity(shown ? 1 : 0)
                .offset(y: (shown ? 0 : (fromTop ? -110 : 110)) + dragY)
                .gesture(swipeAway(fromTop: fromTop))
                .allowsHitTesting(shown)
                .padding(fromTop ? .top : .bottom, 28)
        }
        .overlay {
            VStack(spacing: 14) {
                Button(action: show) {
                    Label(ctx.language == .zh ? "保存图片" : "Save Photo", systemImage: "square.and.arrow.down")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .frame(height: 50)
                        .background(Palette.primary, in: Capsule())
                        .shadow(color: Palette.indigo.opacity(0.35), radius: 12, y: 6)
                }
                .buttonStyle(.plain)
                DemoHint(text: L("Tap Save Photo, then swipe the toast away", "点击“保存图片”，再把吐司划走"), ctx: ctx)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: ctx["hold"] + 1.4, delay: 0.4) { show() }
    }

    /// Swiping toward the toast's own edge dismisses it early; the other way rubber-bands.
    private func swipeAway(fromTop: Bool) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                let toward = fromTop ? -value.translation.height : value.translation.height
                let travel = toward > 0 ? toward : rubberBand(toward, limit: 14)
                dragY = fromTop ? -travel : travel
            }
            .onEnded { value in
                let predicted = fromTop ? -value.predictedEndTranslation.height : value.predictedEndTranslation.height
                let toward = fromTop ? -value.translation.height : value.translation.height
                if toward > 30 || predicted > 90 {
                    token += 1 // cancel the pending auto-dismiss
                    if !ctx.isPreview { Haptics.tap(.soft) }
                    withAnimation(.smooth(duration: 0.3)) {
                        shown = false
                        dragY = 0
                    }
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { dragY = 0 }
                }
            }
    }

    private func show() {
        dragY = 0
        token += 1
        let current = token
        let hold = ctx["hold"]
        if !ctx.isPreview { Haptics.success() }
        withAnimation(.spring(response: ctx["response"], dampingFraction: 0.72)) { shown = true }
        Task {
            try? await Task.sleep(for: .seconds(hold))
            guard token == current else { return }
            withAnimation(.smooth(duration: 0.35)) { shown = false }
        }
    }
}

private struct ToastPill: View {
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Palette.green, in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(language == .zh ? "已保存到相册" : "Saved to Photos")
                    .font(.subheadline.weight(.semibold))
                Text(language == .zh ? "1 张图片" : "1 item")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.leading, 10)
        .padding(.trailing, 20)
        .padding(.vertical, 9)
        .background(.regularMaterial, in: Capsule())
        .overlay { Capsule().strokeBorder(Palette.stroke) }
        .shadow(color: .black.opacity(0.15), radius: 18, y: 8)
    }
}

// MARK: - Dynamic Island pill

extension Effect {
    static let feedbackIsland = Effect(
        id: "feedback.island-pill",
        category: .feedback,
        interaction: .tap,
        name: L("Island Alert", "灵动岛提示"),
        summary: L(
            "System-style alerts: the island bulges sideways to announce an event, then shrinks back on its own.",
            "系统级提示：灵动岛横向鼓起播报一条事件，随后自动缩回。"
        ),
        prompt: L(
            "A plain black 124 × 36 pt capsule sits at the top of a lock screen. When an event arrives (AirPods connected, payment done, timer finished) the island bulges outward like a system alert: it widens to 250 × 44 pt on a lively spring (response 0.45 s, damping 0.62) while the whole pill pumps to 107% in 140 ms and springs back. A tinted glyph bounces in on the left and a short label and value fade in on the right, 100 ms after the growth starts; a success haptic lands with it. After a 1.5 s hold the content fades first and the pill contracts to its resting size on a calm spring (0.4 s, damping 0.85). Glanceable, self-dismissing, never needs a tap.",
            "锁屏顶部静置着一枚 124 × 36 pt 的纯黑胶囊。每当有事件到来（耳机已连接、支付完成、计时结束），灵动岛就像系统提示那样向外鼓起：以活泼的弹簧（响应 0.45 秒、阻尼 0.62）横向撑到 250 × 44 pt，整体同时在 140 毫秒内鼓到 107% 再弹回。生长开始 100 毫秒后，左侧着色图标弹跳入场，右侧短标签与数值淡入，并伴随成功触感。停留 1.5 秒后内容先淡出，胶囊再以平缓弹簧（0.4 秒、阻尼 0.85）缩回原尺寸。一眼即懂，自动消失，无需点击。"
        ),
        implementation: L(
            "An optional event index drives the capsule's frame on a spring, and a keyframeAnimator keyed on an event counter adds the 107% pump; content uses an asymmetric transition with a delayed insertion, and a tokenized Task collapses it after the hold.",
            "可选的事件索引在弹簧动画中驱动胶囊尺寸，以事件计数为触发器的 keyframeAnimator 叠加 107% 的鼓动；内容使用插入带延迟的非对称转场，带令牌的 Task 在停留结束后将其收回。"
        ),
        apis: ["keyframeAnimator(initialValue:trigger:)", "spring(response:dampingFraction:)", "transition(.asymmetric)", "symbolEffect(.bounce)", "Task.sleep(for:)"],
        tags: ["dynamic island", "alert", "notification", "system", "灵动岛", "系统提示", "通知", "反馈"],
        params: [
            .slider("hold", L("Hold time", "停留时长"), 0.8...3.0, default: 1.5, decimals: 1, unit: "s"),
            .slider("response", L("Spring response", "弹簧响应"), 0.25...0.9, default: 0.45, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.4...1.0, default: 0.62),
        ]
    ) { ctx in
        IslandDemo(ctx: ctx)
    }
}

private struct IslandActivity {
    let symbol: String
    let tint: Color
    let title: LocalizedText
    let value: LocalizedText

    static let all: [IslandActivity] = [
        IslandActivity(symbol: "airpodspro", tint: Palette.green, title: L("Connected", "已连接"), value: L("82%", "82%")),
        IslandActivity(symbol: "creditcard.fill", tint: Palette.sky, title: L("Payment", "支付"), value: L("Done ✓", "完成 ✓")),
        IslandActivity(symbol: "timer", tint: Palette.amber, title: L("Timer", "计时器"), value: L("0:00", "0:00")),
    ]
}

private struct IslandDemo: View {
    let ctx: DemoContext
    @State private var event: Int?
    @State private var next = 0
    @State private var pulses = 0
    @State private var token = 0

    var body: some View {
        let screen = RoundedRectangle(cornerRadius: 44, style: .continuous)
        VStack(spacing: 14) {
            ZStack(alignment: .top) {
                IslandLockScreen(language: ctx.language)
                IslandAlertPill(event: event, pulses: pulses, language: ctx.language)
                    .padding(.top, 11)
            }
            .frame(width: 316, height: 300)
            .clipShape(screen)
            .overlay { screen.strokeBorder(Color.black.opacity(0.12), lineWidth: 1) }
            .shadow(color: Color(hex: 0x4B3AA8).opacity(0.28), radius: 24, y: 14)
            .contentShape(screen)
            .onTapGesture { fire() }
            DemoHint(text: L("Tap the screen to send an event", "点击屏幕推送一条事件"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: ctx["hold"] + 1.4, delay: 0.5) { fire() }
    }

    private func fire() {
        token += 1
        let current = token
        let hold = ctx["hold"]
        let index = next % IslandActivity.all.count
        next += 1
        Haptics.success()
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) { event = index }
        pulses += 1
        Task {
            try? await Task.sleep(for: .seconds(hold))
            guard token == current else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { event = nil }
        }
    }
}

/// Lock-screen wallpaper, clock and quick buttons so the island has a real home.
private struct IslandLockScreen: View {
    let language: AppLanguage

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x2B2F77), Color(hex: 0x6E4BD8), Color(hex: 0xE86BB0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(colors: [.white.opacity(0.28), .clear], center: UnitPoint(x: 0.85, y: 0.1), startRadius: 0, endRadius: 220)
            VStack(spacing: 0) {
                Text(language == .zh ? "9月23日 星期三" : "Wednesday, September 23")
                    .font(.subheadline.weight(.semibold))
                Text(verbatim: "9:41")
                    .font(.system(size: 66, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Spacer(minLength: 0)
                HStack {
                    quickButton("flashlight.off.fill")
                    Spacer()
                    quickButton("camera.fill")
                }
                .padding(.horizontal, 26)
                .padding(.bottom, 20)
            }
            .foregroundStyle(.white.opacity(0.92))
            .padding(.top, 108)
        }
    }

    private func quickButton(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(Color.black.opacity(0.28), in: Circle())
    }
}

private struct IslandAlertPill: View {
    let event: Int?
    let pulses: Int
    let language: AppLanguage

    var body: some View {
        let open = event != nil
        ZStack {
            Capsule().fill(Color.black)
            if let event {
                content(IslandActivity.all[event])
                    .id(event)
                    .transition(.asymmetric(
                        insertion: AnyTransition.opacity.combined(with: .scale(scale: 0.7))
                            .animation(.smooth(duration: 0.3).delay(0.1)),
                        removal: AnyTransition.opacity.animation(.easeIn(duration: 0.12))
                    ))
            }
        }
        .frame(width: open ? 250 : 124, height: open ? 44 : 36)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(open ? 0.3 : 0.12), radius: open ? 16 : 6, y: open ? 8 : 3)
        .keyframeAnimator(initialValue: CGFloat(1), trigger: pulses) { content, scale in
            content.scaleEffect(scale)
        } keyframes: { _ in
            KeyframeTrack(\.self) {
                CubicKeyframe(1.07, duration: 0.14)
                SpringKeyframe(1, duration: 0.5, spring: .bouncy)
            }
        }
    }

    private func content(_ activity: IslandActivity) -> some View {
        HStack(spacing: 8) {
            Image(systemName: activity.symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(activity.tint)
                .symbolEffect(.bounce, value: pulses)
            Text(activity.title, language)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Spacer(minLength: 0)
            Text(activity.value, language)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(activity.tint)
        }
        .padding(.horizontal, 16)
        .frame(width: 250, height: 44)
    }
}
