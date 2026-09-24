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
            "An onboarding card (icon, title, one-line body) above four 8 pt page dots. The current dot stretches into a 28 pt capsule on a spring (response 0.4 s, damping 0.75) and fills over the page's 2.4 s dwell on an ease-in-out curve: a slow start, a confident middle and a soft landing. When full, the card blur-replaces to the next page while the capsule shrinks back to a dot and the next one widens. Press and hold the card to pause: the fill freezes and the capsule breathes (opacity 60–100%, 1.6 s cycle) until release, when it resumes from where it stopped. A quick tap on the left or right half skips; tapping a dot jumps and restarts its timer. Calm, patient, in your control.",
            "引导卡片（图标、标题、一行说明）下方有四个 8 pt 页码圆点。当前圆点以弹簧（响应 0.4 秒、阻尼 0.75）拉成 28 pt 胶囊，在每页 2.4 秒的停留里按缓入缓出曲线填满：起步从容，中段利落，收尾轻柔。填满后卡片以模糊替换翻到下一页，胶囊缩回圆点，下一颗随之展宽。按住卡片即可暂停：填充冻结，胶囊轻轻呼吸（透明度 60%–100%，1.6 秒一周），松手后从停下处继续。轻点左右两半可前后跳页，点圆点则直接跳转并重新计时。从容不迫，节奏由你掌控。"
        ),
        implementation: L(
            "Elapsed time is banked on pause and resumed from a new run start, so the fill is (banked + running) / dwell passed through smoothstep; a task keyed on page and pause state sleeps for the remaining time, a never-completing onLongPressGesture's onPressingChanged pauses while held (and resumes on release or cancellation), and a SpatialTapGesture skips by side.",
            "暂停时把已播放时长存入“余额”，恢复时从新的起点继续计时，填充 = (余额 + 本段时长) / 停留时长，再经 smoothstep 缓动；以页码与暂停状态为 id 的 task 休眠剩余时间后翻页；永不完成的 onLongPressGesture 通过 onPressingChanged 在按住时暂停、松手或被系统取消时恢复，SpatialTapGesture 按左右跳页。"
        ),
        apis: ["task(id:)", "TimelineView(.animation(minimumInterval:))", "onLongPressGesture(onPressingChanged:)", "SpatialTapGesture", "transition(.blurReplace)", "animation(_:value:)"],
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

private struct TimerRunKey: Hashable {
    let page: Int
    let paused: Bool
    let dwell: Double
}

private struct TimerDotsDemo: View {
    let ctx: DemoContext
    @State private var page = 0
    @State private var runStart = Date()
    @State private var banked: Double = 0
    @State private var paused = false
    @State private var pressStart: Date?
    /// How long the last finished press lasted, for a tap that is reported after the press ended.
    @State private var lastHeld: Double = 0

    private var dwell: Double { max(ctx["dwell"], 0.1) }

    var body: some View {
        VStack(spacing: 24) {
            card
            dots
            DemoHint(text: L("Hold the card to pause · tap its edges or a dot", "按住卡片暂停 · 点击两侧或圆点跳页"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: TimerRunKey(page: page, paused: paused, dwell: dwell)) {
            guard !paused else { return }
            // Count the time already run since `runStart` too: the task restarts when the page re-appears
            // while @State (and the fill drawn from it) survives, so sleeping a full `dwell - banked`
            // would leave the capsule sitting full for a whole extra dwell.
            let elapsed: Double = banked + Date().timeIntervalSince(runStart)
            try? await Task.sleep(for: .seconds(max(dwell - elapsed, 0.05)))
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
        .scaleEffect(paused ? 0.98 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: paused)
        .contentShape(Rectangle())
        // Holding pauses until release. The never-completing press reports `false` on release *and* on system
        // cancellation (scroll takeover, Control Center pull), so the timer always resumes; a swipe past 12 pt
        // fails the press and scrolls the page instead of being captured.
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: 12, perform: {}, onPressingChanged: pressChanged)
        // A quick tap skips by side.
        .simultaneousGesture(
            SpatialTapGesture()
                .onEnded { value in tapped(at: value.location) }
        )
    }

    private func pressChanged(_ isPressing: Bool) {
        if isPressing {
            pressStart = Date()
            pause()
        } else {
            lastHeld = Date().timeIntervalSince(pressStart ?? Date())
            pressStart = nil
            resume()
        }
    }

    private func tapped(at location: CGPoint) {
        // The tap may land before or after the press reports its release.
        let held: Double = pressStart.map { Date().timeIntervalSince($0) } ?? lastHeld
        guard held < 0.25 else { return }
        let forward: Bool = location.x > 135
        show((page + (forward ? 1 : timerPages.count - 1)) % timerPages.count)
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
            let running: Double = paused ? 0 : timeline.date.timeIntervalSince(runStart)
            let linear: Double = min(max((banked + running) / dwell, 0), 1)
            let eased: Double = linear * linear * (3 - 2 * linear)
            let breath: Double = paused ? 0.8 + 0.2 * cos(timeline.date.timeIntervalSince(runStart) * 2 * .pi / 1.6) : 1
            Capsule()
                .fill(timerPages[page].color)
                .frame(width: max(width * CGFloat(eased), height), height: height)
                .opacity(breath)
        }
    }

    private func pause() {
        guard !paused else { return }
        banked += Date().timeIntervalSince(runStart)
        runStart = Date()
        paused = true
    }

    private func resume() {
        guard paused else { return }
        runStart = Date()
        paused = false
    }

    private func show(_ index: Int, byUser: Bool = true) {
        guard index != page else { return }
        if byUser && !ctx.isPreview { Haptics.selection() }
        runStart = Date()
        banked = 0
        paused = false
        withAnimation(.easeInOut(duration: 0.35)) { page = index }
    }
}
