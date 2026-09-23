import SwiftUI

extension Effect {
    static let textNewsTicker = Effect(
        id: "text.news-ticker",
        category: .text,
        interaction: .loop,
        name: L("Live Headline Ticker", "实时头条轮播"),
        summary: L("Headlines rise out of blur on a timer, with a live dot and a countdown hairline.", "头条按计时从模糊中升起，配合直播红点与倒计时细线。"),
        prompt: L(
            "A compact news card: a red LIVE pill with a pulsing dot, a category label and a timestamp above one headline slot, and a 2 pt countdown hairline along the bottom. Every 2.6 s the hairline completes and the headline changes: the old one lifts 22 pt, shrinks to 96%, blurs 6 pt and fades in 250 ms, while the new one rises from 22 pt below out of the same blur on a spring (response 0.5 s, damping 0.82); the category and time cross-fade with it. The hairline resets to zero and fills linearly again. Tapping skips ahead with a selection haptic. It feels calm but urgent — a newsroom that never stops.",
            "一张紧凑的新闻卡片：顶部是带脉冲红点的 LIVE 胶囊、分类标签与时间，下面是单条头条槽位，底部一条 2 pt 的倒计时细线。每 2.6 秒细线走满，头条随之更换：旧标题上移 22 pt、缩小到 96%、模糊 6 pt 并在 250 毫秒内淡出；新标题从下方 22 pt 处穿过同样的模糊，以弹簧（响应 0.5 秒、阻尼 0.82）升起就位，分类与时间同步交叉淡变。细线归零后再次匀速走满。点击可跳到下一条，并伴随选择触感。平静中带着紧迫——一间永不停歇的新闻编辑室。"
        ),
        implementation: L(
            "A TimelineView(.animation) derives the current index and the hairline fraction from elapsed time; the headline is keyed with .id(index) and swapped with a custom blur-rise Transition animated by .animation(_:value: index).",
            "TimelineView(.animation) 根据经过时间推算当前序号与细线进度；头条以 .id(序号) 标识，通过自定义的模糊上升 Transition 替换，由 .animation(_:value: 序号) 驱动动画。"
        ),
        apis: ["TimelineView(.animation)", "Transition", "id(_:)", "animation(_:value:)", "symbolEffect(.pulse)"],
        tags: ["ticker", "headline", "news", "rotating", "轮播", "头条", "新闻", "计时"],
        params: [
            .slider("interval", L("Interval", "间隔"), 1.2...6.0, default: 2.6, unit: "s"),
            .slider("distance", L("Travel", "位移"), 6...40, default: 22, decimals: 0, unit: "pt"),
            .slider("blur", L("Blur", "模糊"), 0...14, default: 6, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        NewsTickerDemo(ctx: ctx)
    }
}

private struct Headline {
    let category: LocalizedText
    let title: LocalizedText
    let time: LocalizedText
}

private let headlines: [Headline] = [
    Headline(category: L("Markets", "财经"), title: L("Chip makers lead a late-session rally", "芯片股尾盘领涨，大盘翻红"), time: L("2 min ago", "2 分钟前")),
    Headline(category: L("Weather", "天气"), title: L("First snow expected in the hills tonight", "今夜山区将迎来初雪"), time: L("6 min ago", "6 分钟前")),
    Headline(category: L("Sport", "体育"), title: L("Underdogs force a decisive game seven", "黑马逆袭，系列赛进入抢七"), time: L("11 min ago", "11 分钟前")),
    Headline(category: L("Science", "科学"), title: L("Probe sends back its closest photos yet", "探测器传回迄今最近距离照片"), time: L("18 min ago", "18 分钟前")),
]

private struct TickerRiseTransition: Transition {
    var distance: CGFloat
    var blur: CGFloat

    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .offset(y: offset(for: phase))
            .scaleEffect(phase == .didDisappear ? 0.96 : 1, anchor: .leading)
            .blur(radius: phase.isIdentity ? 0 : blur)
            .opacity(phase.isIdentity ? 1 : 0)
    }

    private func offset(for phase: TransitionPhase) -> CGFloat {
        switch phase {
        case .willAppear: return distance
        case .didDisappear: return -distance
        default: return 0
        }
    }
}

private struct NewsTickerDemo: View {
    let ctx: DemoContext
    @State private var start = Date()
    @State private var skipped = 0

    var body: some View {
        VStack(spacing: 16) {
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let elapsed: Double = timeline.date.timeIntervalSince(start)
                let interval: Double = max(ctx["interval"], 0.5)
                let ticks = Int(elapsed / interval)
                let fraction = CGFloat((elapsed / interval) - Double(ticks))
                card(index: (ticks + skipped) % headlines.count, fraction: fraction)
            }
            DemoHint(text: L("Tap to skip", "点击跳过"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.selection()
            skipped += 1
            start = Date()
        }
    }

    private func card(index: Int, fraction: CGFloat) -> some View {
        let item = headlines[index]
        let rise = TickerRiseTransition(distance: ctx.cg("distance"), blur: ctx.cg("blur"))
        return VStack(alignment: .leading, spacing: 12) {
            header(item)
                .id(index)
                .transition(.opacity)
            ZStack(alignment: .topLeading) {
                Text(item.title, ctx.language)
                    .font(.system(size: 21, weight: .bold))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .id(index)
                    .transition(
                        .asymmetric(
                            insertion: AnyTransition(rise).animation(.spring(response: 0.5, dampingFraction: 0.82)),
                            removal: AnyTransition(rise).animation(.easeIn(duration: 0.25))
                        )
                    )
            }
            .frame(height: 58, alignment: .topLeading)
            .clipped()
            hairline(fraction)
        }
        .padding(18)
        .frame(width: 300)
        .demoCard()
        .animation(.spring(response: 0.5, dampingFraction: 0.82), value: index)
    }

    private func header(_ item: Headline) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 6))
                    .symbolEffect(.pulse, isActive: true)
                Text(verbatim: "LIVE")
                    .font(.caption2.weight(.heavy))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .frame(height: 20)
            .background(Palette.red, in: Capsule())
            Text(item.category, ctx.language)
                .font(.caption.weight(.bold))
                .foregroundStyle(Palette.red)
            Spacer()
            Text(item.time, ctx.language)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func hairline(_ fraction: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Color.primary.opacity(0.08))
            Capsule()
                .fill(Palette.red.opacity(0.8))
                .frame(width: 264 * fraction)
        }
        .frame(width: 264, height: 2)
    }
}
