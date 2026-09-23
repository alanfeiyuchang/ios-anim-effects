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
            "A compact frosted-glass capsule toast — a green check badge, a bold title and a secondary caption — lives just off the top (or bottom) edge. On trigger it travels 110 pt into view on a spring (response ≈0.45 s, damping 0.72) while simultaneously sharpening from a 10 pt blur, scaling from 86% to 100% and fading in, landing with a slight overshoot; a success haptic fires on arrival. After a ~2 s hold it retreats along the same path on a 0.35 s smooth curve, blurring out as it goes. Re-triggering while visible restarts the timer instead of stacking. It feels light, polished and never interrupts.",
            "一枚紧凑的磨砂玻璃胶囊吐司——绿色对勾徽标、粗体标题与次级说明——停在画面顶部（或底部）外侧。触发后它以弹簧（响应约 0.45 秒、阻尼 0.72）滑入画面 110 pt，同时从 10 pt 模糊逐渐清晰、从 86% 放大到 100% 并淡入，落位时带一点轻微过冲；到位瞬间触发成功触感。停留约 2 秒后，沿原路以 0.35 秒平滑曲线退出，边走边重新模糊。显示期间再次触发只会重置计时，不会叠加。轻盈、精致，从不打断用户。"
        ),
        implementation: L(
            "Offset, blur, scale and opacity are all driven by one Boolean inside a spring; a tokenised Task handles auto-dismiss.",
            "位移、模糊、缩放与透明度都由同一个布尔值在弹簧动画中驱动；带令牌的 Task 负责自动消失。"
        ),
        apis: ["offset(y:)", "blur(radius:)", "regularMaterial", "Task.sleep(for:)"],
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

    var body: some View {
        let fromTop = ctx.int("edge") == 0
        ZStack(alignment: fromTop ? .top : .bottom) {
            Color.clear
            ToastPill(language: ctx.language)
                .scaleEffect(shown ? 1 : 0.86)
                .blur(radius: shown ? 0 : ctx["blur"])
                .opacity(shown ? 1 : 0)
                .offset(y: shown ? 0 : (fromTop ? -110 : 110))
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
                DemoHint(text: L("Tap to save", "点击保存"), ctx: ctx)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: ctx["hold"] + 1.4, delay: 0.4) { show() }
    }

    private func show() {
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
        name: L("Island Expansion", "灵动岛展开"),
        summary: L("A black pill that stretches into a rich live-activity card.", "黑色胶囊弹性伸展为信息丰富的实时活动卡片。"),
        prompt: L(
            "A pure-black 124 × 36 pt pill sits at the top center, showing a tiny tinted glyph on the left and a mini progress ring on the right. On tap it stretches into a 300 × 84 pt continuous-corner card (corner radius 19 → 34 pt) on an under-damped spring (response 0.5 s, damping 0.72), overshooting slightly in both width and height like elastic material, while its shadow deepens. The compact glyphs fade out immediately; the expanded content — a 44 pt icon, title, subtitle and a larger ring — fades in 120 ms later from a 6 pt blur and 90% scale. Tapping again reverses it with the content leaving first. Organic, fluid and alive.",
            "顶部居中是一枚纯黑 124 × 36 pt 胶囊，左侧显示着色小图标，右侧是一枚迷你进度环。点击后它以欠阻尼弹簧（响应 0.5 秒、阻尼 0.72）伸展为 300 × 84 pt 的连续圆角卡片（圆角 19 → 34 pt），宽高都带轻微过冲，像有弹性的材质，投影同时加深。紧凑态图标立即淡出；展开内容——44 pt 图标、标题、副标题与更大的进度环——延迟 120 毫秒后从 6 pt 模糊、90% 缩放中浮现。再次点击则反向收回，内容先行退场。有机、流畅、充满生命力。"
        ),
        implementation: L(
            "A RoundedRectangle's frame and corner radius animate on a spring; compact and expanded layers cross-fade with separate delayed animations.",
            "RoundedRectangle 的尺寸与圆角随弹簧动画变化；紧凑层与展开层用各自带延迟的动画交叉淡入。"
        ),
        apis: ["RoundedRectangle(style: .continuous)", "spring(response:dampingFraction:)", "animation(_:value:)", "blur(radius:)"],
        tags: ["dynamic island", "live activity", "pill", "expand", "灵动岛", "实时活动", "胶囊", "展开"],
        params: [
            .choice("content", L("Activity", "活动类型"), [L("Headphones", "耳机"), L("Timer", "计时"), L("Payment", "支付")], default: 0),
            .slider("response", L("Spring response", "弹簧响应"), 0.25...0.9, default: 0.5, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.45...1.0, default: 0.72),
        ]
    ) { ctx in
        IslandDemo(ctx: ctx)
    }
}

private struct IslandActivity {
    let symbol: String
    let tint: Color
    let title: LocalizedText
    let subtitle: LocalizedText
    let ring: Double
    let badge: String

    static let all: [IslandActivity] = [
        IslandActivity(symbol: "headphones", tint: Palette.green, title: L("Studio Buds", "录音室耳机"), subtitle: L("Connected", "已连接"), ring: 0.82, badge: "82"),
        IslandActivity(symbol: "timer", tint: Palette.amber, title: L("Focus Timer", "专注计时"), subtitle: L("Deep work", "深度工作"), ring: 0.6, badge: "15"),
        IslandActivity(symbol: "creditcard.fill", tint: Palette.sky, title: L("Payment", "支付"), subtitle: L("Done · $24.00", "完成 · ¥168.00"), ring: 1.0, badge: "✓"),
    ]
}

private struct IslandDemo: View {
    let ctx: DemoContext
    @State private var expanded = false

    var body: some View {
        let activity = IslandActivity.all[min(max(ctx.int("content"), 0), IslandActivity.all.count - 1)]
        VStack(spacing: 0) {
            IslandPill(expanded: expanded, activity: activity, language: ctx.language)
                .onTapGesture { toggle() }
                .padding(.top, 34)
            Spacer()
            DemoHint(text: L("Tap the island", "点击灵动岛"), ctx: ctx)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.2, delay: 0.6) { toggle() }
    }

    private func toggle() {
        if !ctx.isPreview { Haptics.tap(.soft) }
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) { expanded.toggle() }
    }
}

private struct IslandPill: View {
    let expanded: Bool
    let activity: IslandActivity
    let language: AppLanguage

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: expanded ? 34 : 19, style: .continuous)
        ZStack {
            shape.fill(Color.black)
            compact
                .opacity(expanded ? 0 : 1)
                .animation(.easeOut(duration: expanded ? 0.1 : 0.25).delay(expanded ? 0 : 0.18), value: expanded)
            expandedContent
                .opacity(expanded ? 1 : 0)
                .blur(radius: expanded ? 0 : 6)
                .scaleEffect(expanded ? 1 : 0.9)
                .animation(expanded ? .smooth(duration: 0.35).delay(0.12) : .easeIn(duration: 0.12), value: expanded)
        }
        .frame(width: expanded ? 300 : 124, height: expanded ? 84 : 36)
        .clipShape(shape)
        .overlay { shape.strokeBorder(Color.white.opacity(0.08)) }
        .shadow(color: .black.opacity(expanded ? 0.3 : 0.12), radius: expanded ? 20 : 6, y: expanded ? 10 : 3)
        .contentShape(shape)
    }

    private var compact: some View {
        HStack {
            Image(systemName: activity.symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(activity.tint)
            Spacer()
            IslandRing(progress: activity.ring, tint: activity.tint, lineWidth: 2.5)
                .frame(width: 16, height: 16)
        }
        .padding(.horizontal, 14)
        .frame(width: 124, height: 36)
    }

    private var expandedContent: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(activity.tint)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title, language)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(activity.subtitle, language)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer(minLength: 0)
            ZStack {
                IslandRing(progress: activity.ring, tint: activity.tint, lineWidth: 4)
                Text(activity.badge)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .frame(width: 300, height: 84)
    }
}

private struct IslandRing: View {
    let progress: Double
    let tint: Color
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle().stroke(tint.opacity(0.25), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}
