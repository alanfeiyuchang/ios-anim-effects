import SwiftUI

extension Effect {
    static let feedbackPullRefresh = Effect(
        id: "feedback.pull-refresh",
        category: .feedback,
        interaction: .gesture,
        name: L("Custom Pull-to-Refresh", "自定义下拉刷新"),
        summary: L("A rubber-banded list reveals an arc that fills, flips and spins.", "带橡皮筋阻尼的列表下拉，露出逐渐填满、翻转并旋转的圆弧。"),
        prompt: L(
            "A message list scrolls inside a rounded card; pulled past its top, it follows the finger with the native rubber-band resistance (it moves less the further you pull). Behind it, centered in the revealed gap, a 28 pt indicator grows from 60% to 100% scale while a gradient arc fills clockwise in proportion to the pull; its arrow flips 180° with a springy snap and a medium haptic the moment the 72 pt threshold is crossed. Releasing past the threshold settles the list at a 60 pt hold on a spring while the arc becomes a continuously spinning 270° loader; when the data arrives, a new row springs in at the top and the list glides back to rest with a success haptic. Releasing early simply springs back. Tactile, responsive and satisfying.",
            "圆角卡片中的消息列表可独立滚动；到顶后继续下拉，列表带着系统原生的橡皮筋阻尼跟随手指（拉得越远越“沉”）。列表背后、露出的缝隙中央，是一个 28 pt 的指示器：随下拉距离从 60% 放大到 100%，渐变圆弧按比例顺时针填满；越过 72 pt 阈值的瞬间，箭头以弹性快速翻转 180°，并伴随中等强度触感。越过阈值后松手，列表以弹簧停在 60 pt 的等待位，圆弧变成持续旋转的 270° 加载环；数据返回时，新条目从顶部弹入，列表平滑回到原位，并伴随成功触感。未达阈值就松手则直接弹回。手感扎实、令人满足。"
        ),
        implementation: L(
            "The rows live in their own always-bouncing ScrollView: onScrollGeometryChange reads the top overscroll (contentOffset.y + contentInsets.top < 0) as the pull, so the page never moves with it; threshold crossings flip the arrow with a haptic, onScrollPhaseChange catches the release past the threshold, and an offset holds the list while an async refresh inserts a row with a transition.",
            "条目放在独立且始终可回弹的 ScrollView 中：onScrollGeometryChange 把顶部越界量（contentOffset.y + contentInsets.top < 0）作为下拉距离，页面不会跟着移动；越过阈值时翻转箭头并触发触感，onScrollPhaseChange 捕捉越过阈值后的松手，再以偏移让列表停住，异步刷新后以过渡插入新条目。"
        ),
        apis: ["ScrollView", "onScrollGeometryChange", "onScrollPhaseChange", "trim(from:to:)", "TimelineView", "transition"],
        tags: ["pull to refresh", "refresh", "rubber band", "list", "下拉刷新", "刷新", "橡皮筋", "列表"],
        params: [
            .slider("duration", L("Refresh time", "刷新时长"), 0.5...3.0, default: 1.2, decimals: 1, unit: "s"),
            .slider("resistance", L("Trigger distance", "触发距离"), 56...100, default: 72, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        PullRefreshDemo(ctx: ctx)
    }
}

private struct RefreshSample {
    let initials: String
    let tint: Color
    let name: LocalizedText
    let message: LocalizedText

    static let all: [RefreshSample] = [
        RefreshSample(initials: "MJ", tint: Palette.pink, name: L("Mia Jensen", "米娅"), message: L("Loved the new prototype!", "新原型太棒了！")),
        RefreshSample(initials: "DK", tint: Palette.sky, name: L("Daniel Kim", "金丹尼"), message: L("Can we sync at 3?", "三点对一下？")),
        RefreshSample(initials: "SL", tint: Palette.mint, name: L("Sara Lopez", "萨拉"), message: L("Shipped the motion specs", "动效规范已交付")),
        RefreshSample(initials: "RT", tint: Palette.amber, name: L("Ryo Tanaka", "田中亮"), message: L("Photos from the offsite", "团建照片来啦")),
        RefreshSample(initials: "AN", tint: Palette.violet, name: L("Ava Novak", "艾娃"), message: L("Invoice approved", "报销已批准")),
    ]
}

private struct PullRefreshDemo: View {
    let ctx: DemoContext
    /// The list's own top overscroll (native rubber band), reported by its scroll view.
    @State private var overscroll: CGFloat = 0
    /// Extra shift of the rows: the scripted pull of previews and the hold height while refreshing.
    @State private var shift: CGFloat = 0
    @State private var refreshing = false
    @State private var armed = false
    @State private var items: [Int] = [3, 2, 1, 0]
    @State private var nextItem = 4
    @State private var token = 0
    /// Set by a real pull, cleared by the autoplay: only a real pull plays haptics.
    @State private var userDriven = false

    private let holdHeight: CGFloat = 60
    private var threshold: CGFloat { ctx.cg("resistance") }
    private var pull: CGFloat { overscroll + shift }
    private var live: Bool { !ctx.isPreview && !ctx.isStill }

    init(ctx: DemoContext) {
        self.ctx = ctx
        // Still thumbnails show the indicator mid-pull, just short of the threshold.
        _shift = State(initialValue: ctx.isStill ? 72 * 0.85 : 0)
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .top) {
                PullIndicator(progress: min(pull / threshold, 1), armed: armed, refreshing: refreshing, preview: ctx.isPreview)
                    .frame(height: max(pull, 1))
                    .opacity(pull > 6 ? 1 : 0)
                // The list scrolls on its own: its top overscroll is the pull, like a native refresh control.
                FeedbackRefreshList(live: live, hold: shift, onPull: pullChanged, onRelease: release) {
                    list
                }
            }
            .frame(width: 300, height: 250, alignment: .top)
            .background(Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .demoCard(cornerRadius: 22)
            DemoHint(text: L("Pull the list down", "向下拖动列表"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 3.6, delay: 0.6) { simulate() }
    }

    private var list: some View {
        VStack(spacing: 0) {
            ForEach(items, id: \.self) { item in
                RefreshRow(sample: RefreshSample.all[item % RefreshSample.all.count], language: ctx.language)
                    .transition(
                        AnyTransition.asymmetric(
                            insertion: AnyTransition.scale(scale: 0.92, anchor: .top).combined(with: .opacity),
                            removal: .opacity
                        )
                    )
            }
            Spacer(minLength: 0)
        }
        .frame(width: 300, height: 250, alignment: .top)
        .background(Palette.elevated)
    }

    /// Every change of the list's top overscroll; `byFinger` is true while a finger is on the list.
    private func pullChanged(_ value: CGFloat, byFinger: Bool) {
        overscroll = value
        if byFinger { userDriven = true }
        guard !refreshing else { return }
        updateArmed(pull, buzz: byFinger)
    }

    private func updateArmed(_ value: CGFloat, buzz: Bool) {
        let nowArmed = value >= threshold
        guard nowArmed != armed else { return }
        if nowArmed && buzz && live { Haptics.tap(.medium) }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) { armed = nowArmed }
    }

    /// Finger lifted (or the touch was cancelled), or the scripted pull ended: refresh if armed. Otherwise the
    /// scroll view's own bounce takes the list home.
    private func release() {
        guard !refreshing else { return }
        guard pull >= threshold else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { shift = 0 }
            updateArmed(0, buzz: false)
            return
        }
        refreshing = true
        // The native bounce removes the overscroll while the shift grows to the hold height.
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) { shift = holdHeight }
        let wait = ctx["duration"]
        // Only a real pull buzzes; the autoplay's simulated pull stays silent.
        let buzz: Bool = live && userDriven
        token += 1
        let current = token
        Task {
            try? await Task.sleep(for: .seconds(wait))
            guard token == current else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                items.insert(nextItem, at: 0)
                if items.count > 4 { items.removeLast() }
                shift = 0
                refreshing = false
                armed = false
            }
            nextItem += 1
            if buzz { Haptics.success() }
        }
    }

    private func simulate() {
        guard !refreshing else { return }
        userDriven = false
        token += 1
        let current = token
        withAnimation(.easeOut(duration: 0.5)) { shift = threshold * 0.7 }
        Task {
            try? await Task.sleep(for: .seconds(0.5))
            guard token == current, !refreshing else { return }
            withAnimation(.easeOut(duration: 0.3)) { shift = threshold + 14 }
            updateArmed(threshold + 14, buzz: false)
            try? await Task.sleep(for: .seconds(0.35))
            guard token == current else { return }
            release()
        }
    }
}

private struct PullIndicator: View {
    let progress: CGFloat
    let armed: Bool
    let refreshing: Bool
    let preview: Bool

    var body: some View {
        ZStack {
            if refreshing {
                PullSpinner(preview: preview)
                    .transition(AnyTransition.scale(scale: 0.6).combined(with: .opacity))
            } else {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Palette.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: "arrow.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Palette.indigo)
                    .rotationEffect(.degrees(armed ? 180 : 0))
            }
        }
        .frame(width: 28, height: 28)
        .scaleEffect(0.6 + 0.4 * progress)
    }
}

private struct PullSpinner: View {
    let preview: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview))) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Palette.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(t.truncatingRemainder(dividingBy: 0.8) / 0.8 * 360))
        }
    }
}

private struct RefreshRow: View {
    let sample: RefreshSample
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 12) {
            Text(sample.initials)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(sample.tint.gradient, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(sample.name, language)
                    .font(.subheadline.weight(.semibold))
                Text(sample.message, language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(height: 60)
        .overlay(alignment: .bottom) {
            Divider().padding(.leading, 64)
        }
    }
}
