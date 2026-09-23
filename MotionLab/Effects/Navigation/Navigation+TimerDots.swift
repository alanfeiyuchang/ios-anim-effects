import SwiftUI

extension Effect {
    static let navigationTimerDots = Effect(
        id: "navigation.timer-dots",
        category: .navigation,
        interaction: .loop,
        name: L("Auto-Advance Dots", "计时自动翻页圆点"),
        summary: L(
            "The active dot stretches into a capsule that fills like a timer, then hands off to the next page.",
            "当前圆点伸展成胶囊并像计时器一样填满，然后交接给下一页。"
        ),
        prompt: L(
            "An onboarding card (icon, title, one-line body) above four 8 pt page dots. The current dot stretches into a 28 pt capsule on a spring (response ≈0.4 s, damping 0.75) and fills left to right in a linear sweep over the page's 2.4 s dwell time, like a story timer. When full, the card cross-fades with a blur-replace to the next page and the capsule shrinks back to a dot while the next dot widens and begins filling from empty. Tapping the right or left half of the card skips forward or back, and tapping a dot jumps straight to it, restarting its timer. Calm, self-driving, and always legible about what comes next.",
            "一张引导卡片（图标、标题、一行说明）下方有四个 8pt 页码圆点。当前圆点以弹簧（响应约 0.4 秒、阻尼 0.75）伸展为 28pt 的胶囊，并在每页 2.4 秒的停留时间内从左到右线性填满，像故事计时器一样。填满后，卡片以模糊替换过渡到下一页，胶囊收回成圆点，下一个圆点同时展宽并从空开始填充。点击卡片右半或左半可前进或后退，点击圆点可直接跳转并重新计时。安静、自驱动，始终清楚地告诉你接下来是什么。"
        ),
        implementation: L(
            "A task keyed on the page sleeps for the dwell time and then advances, so any manual jump cancels and restarts it; a TimelineView computes the fill from the page's start date, and the dot widths animate on the page value.",
            "以页码为 id 的 task 休眠一段停留时间后翻页，因此任何手动跳转都会取消并重新计时；TimelineView 根据当前页的开始时间计算填充，圆点宽度随页码值做动画。"
        ),
        apis: ["task(id:)", "TimelineView(.animation)", "Task.sleep(for:)", "transition(.blurReplace)", "animation(_:value:)"],
        tags: ["page dots", "onboarding", "timer", "stories", "页码圆点", "引导页", "计时", "快拍"],
        params: [
            .slider("dwell", L("Time per page", "每页停留"), 1.2...5.0, default: 2.4, unit: "s"),
            .slider("width", L("Active width", "激活宽度"), 16...44, default: 28, decimals: 0, unit: "pt"),
            .slider("dot", L("Dot size", "圆点尺寸"), 6...10, default: 8, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        TimerDotsDemo(ctx: ctx)
    }
}

private struct TimerPage {
    let symbol: String
    let title: LocalizedText
    let body: LocalizedText
    let color: Color
}

private let timerPages: [TimerPage] = [
    TimerPage(symbol: "sparkles", title: L("Welcome", "欢迎"), body: L("A calmer way to plan your week.", "用更从容的方式规划一周。"), color: Palette.violet),
    TimerPage(symbol: "calendar", title: L("Plan", "规划"), body: L("Drag tasks straight onto your day.", "把任务直接拖进日程。"), color: Palette.sky),
    TimerPage(symbol: "bell.badge.fill", title: L("Focus", "专注"), body: L("Only the reminders that matter.", "只保留真正重要的提醒。"), color: Palette.coral),
    TimerPage(symbol: "checkmark.seal.fill", title: L("Done", "完成"), body: L("Celebrate every small win.", "为每个小成就喝彩。"), color: Palette.green),
]

private struct TimerDotsDemo: View {
    let ctx: DemoContext
    @State private var page = 0
    @State private var pageStart = Date()

    var body: some View {
        VStack(spacing: 24) {
            card
            dots
            DemoHint(text: L("Tap the card's edges or a dot", "点击卡片左右两侧或圆点"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: page) {
            pageStart = Date()
            try? await Task.sleep(for: .seconds(ctx["dwell"]))
            guard !Task.isCancelled else { return }
            show((page + 1) % timerPages.count, byUser: false)
        }
    }

    private var card: some View {
        let item = timerPages[page]
        return VStack(spacing: 14) {
            Image(systemName: item.symbol)
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 80, height: 80)
                .background(item.color.gradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: item.color.opacity(0.35), radius: 14, y: 8)
            Text(item.title, ctx.language)
                .font(.title3.weight(.bold))
            Text(item.body, ctx.language)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .id(page)
        .transition(.blurReplace)
        .frame(width: 270, height: 210)
        .demoCard(cornerRadius: 26)
        .overlay {
            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { show((page + timerPages.count - 1) % timerPages.count) }
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { show((page + 1) % timerPages.count) }
            }
        }
    }

    private var dots: some View {
        let dot: CGFloat = ctx.cg("dot")
        let active: CGFloat = max(ctx.cg("width"), dot)
        return HStack(spacing: 8) {
            ForEach(0..<timerPages.count, id: \.self) { index in
                let isActive = index == page
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.16))
                    if isActive {
                        fill(width: active, height: dot)
                    }
                }
                .frame(width: isActive ? active : dot, height: dot)
                .clipShape(Capsule())
                .contentShape(Rectangle().inset(by: -8))
                .onTapGesture { show(index) }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: page)
    }

    private func fill(width: CGFloat, height: CGFloat) -> some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
            let elapsed: Double = timeline.date.timeIntervalSince(pageStart)
            let progress: Double = min(max(elapsed / max(ctx["dwell"], 0.1), 0), 1)
            Capsule()
                .fill(timerPages[page].color)
                .frame(width: max(width * CGFloat(progress), height), height: height)
        }
    }

    private func show(_ index: Int, byUser: Bool = true) {
        guard index != page else { return }
        if byUser && !ctx.isPreview { Haptics.selection() }
        pageStart = Date()
        withAnimation(.easeInOut(duration: 0.35)) { page = index }
    }
}
