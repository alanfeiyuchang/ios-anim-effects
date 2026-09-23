import SwiftUI

extension Effect {
    static let textNewsTicker = Effect(
        id: "text.news-ticker",
        category: .text,
        interaction: .loop,
        name: L("Live Headline Ticker", "实时头条轮播"),
        summary: L("Headlines are pushed aside by a red wipe edge on a timer, with a live dot and a countdown hairline.", "头条按计时被一道红色擦除线推走换新，配合直播红点与倒计时细线。"),
        prompt: L(
            "A compact news card: a red LIVE pill with a pulsing dot, a category label and a timestamp above one headline slot, and a 2 pt countdown hairline along the bottom. Every 2.6 s the hairline completes and a 2 pt red wipe edge sweeps the slot left to right in 0.5 s on an ease-in-out cubic: behind the edge the new headline is revealed, sliding in from 24 pt right, while the old one is cropped away ahead of it and pushed 24 pt left, like a page shoved off a desk. The category and time cross-fade with it and the hairline refills linearly. Tapping skips ahead with a selection haptic. Editorial, crisp and urgent: a newsroom that never stops.",
            "一张紧凑的新闻卡片：顶部是带脉冲红点的 LIVE 胶囊、分类与时间，下方为单条头条槽位，底部一条 2pt 倒计时细线。每 2.6 秒细线走满，一道 2pt 红色擦除线以三次缓入缓出曲线在 0.5 秒内从左扫到右：线后露出新标题，从右侧 24pt 滑入；线前的旧标题被逐步裁掉，同时向左推开 24pt，像被推下桌面的一页纸。分类与时间同步淡变，细线归零后匀速重走。点击跳到下一条并伴随选择触感。利落、克制又紧迫。"
        ),
        implementation: L(
            "A TimelineView(.animation) derives the current index, the hairline fraction and an eased wipe progress from elapsed time; the old and new headlines are offset in opposite directions and cropped by complementary leading/trailing masks, with a red capsule riding the seam.",
            "TimelineView(.animation) 根据经过时间推算当前序号、细线进度与缓动后的擦除进度；新旧标题向相反方向位移，并由互补的左右对齐遮罩裁切，接缝处跟随一枚红色胶囊。"
        ),
        apis: ["TimelineView(.animation)", "mask(alignment:_:)", "offset(x:y:)", "symbolEffect(.pulse)", "AnyTransition.animation(_:)"],
        tags: ["ticker", "headline", "news", "wipe", "push", "轮播", "头条", "新闻", "擦除"],
        params: [
            .slider("interval", L("Interval", "间隔"), 1.2...6.0, default: 2.6, unit: "s"),
            .slider("wipe", L("Wipe time", "擦除时长"), 0.2...1.0, default: 0.5, unit: "s"),
            .slider("push", L("Push", "推移"), 0...60, default: 24, decimals: 0, unit: "pt"),
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
                let inTick: Double = elapsed - Double(ticks) * interval
                let fraction = CGFloat(inTick / interval)
                let step = ticks + skipped
                // The very first headline is already in place; every later one arrives with the wipe.
                let wipe: CGFloat = step == 0 ? 1 : Self.eased(inTick / max(ctx["wipe"], 0.05))
                card(index: step % headlines.count, fraction: fraction, wipe: wipe)
            }
            DemoHint(text: L("Tap to skip", "点击跳过"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.selection()
            // Fold the ticks already shown into `skipped` before restarting the clock,
            // so a skip always moves exactly one headline forward.
            let now = Date()
            let ticks = Int(now.timeIntervalSince(start) / max(ctx["interval"], 0.5))
            skipped += ticks + 1
            start = now
        }
    }

    /// Ease-in-out cubic on 0...1.
    private static func eased(_ raw: Double) -> CGFloat {
        let x = raw.clamped(to: 0...1)
        let y = x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2
        return CGFloat(y)
    }

    private func card(index: Int, fraction: CGFloat, wipe: CGFloat) -> some View {
        let item = headlines[index]
        let old = headlines[(index + headlines.count - 1) % headlines.count]
        return VStack(alignment: .leading, spacing: 12) {
            header(item)
                .id(index)
                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.3)))
            headlineSlot(new: item, old: old, wipe: wipe)
            hairline(fraction)
        }
        .padding(18)
        .frame(width: 300)
        .demoCard()
    }

    private func headlineSlot(new: Headline, old: Headline, wipe: CGFloat) -> some View {
        let width: CGFloat = 264
        let push = ctx.cg("push")
        let shown: CGFloat = width * wipe
        let hidden: CGFloat = width - shown
        let oldShift: CGFloat = -push * wipe
        let newShift: CGFloat = push * (1 - wipe)
        let edgeOpacity: Double = wipe > 0.001 && wipe < 0.999 ? 1 : 0
        return ZStack(alignment: .topLeading) {
            title(old)
                .offset(x: oldShift)
                .mask(alignment: .trailing) { Rectangle().frame(width: hidden) }
            title(new)
                .offset(x: newShift)
                .mask(alignment: .leading) { Rectangle().frame(width: shown) }
            Capsule()
                .fill(Palette.red)
                .frame(width: 2, height: 54)
                .shadow(color: Palette.red.opacity(0.5), radius: 4)
                .offset(x: shown - 1)
                .opacity(edgeOpacity)
        }
        .frame(width: width, height: 58, alignment: .topLeading)
        .clipped()
    }

    private func title(_ item: Headline) -> some View {
        Text(item.title, ctx.language)
            .font(.system(size: 21, weight: .bold))
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(width: 264, height: 58, alignment: .topLeading)
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
