import SwiftUI

extension Effect {
    static let scrollChapterRail = Effect(
        id: "scroll.chapter-rail",
        category: .scroll,
        interaction: .scroll,
        name: L("Chapter Rail", "章节导轨"),
        summary: L("A scroll-spy rail of chapter dots fills as you read; the active dot stretches into a pill and names its chapter.", "随阅读填充的章节导轨：当前章节的圆点拉伸成胶囊，并显示章节名。"),
        prompt: L(
            "A long article with five chapters scrolls beside a slim vertical rail on the right: five 8 pt dots, 44 pt apart, joined by a 2 pt track. A gradient line fills the track continuously, so it sits exactly between two dots when the reader is halfway through a chapter. Dots already passed turn solid; the active dot stretches into a 10×24 pt gradient pill on a springy animation (response 0.35 s, damping 0.62) and a floating chip at the top slides its label to the chapter name with a numeric roll on the chapter number. Tapping a dot glides the article to that chapter's start. Oriented, calm and helpful for long reads.",
            "一篇有五个章节的长文在右侧一条细长的纵向导轨旁滚动：五个8 pt圆点，间隔44 pt，由一条2 pt轨道相连。一条渐变线连续填充轨道，读到某章一半时，它恰好停在两个圆点正中间。已读过的圆点变为实心；当前章节的圆点以富有弹性的动画（响应0.35秒、阻尼0.62）拉伸成10×24 pt的渐变胶囊，顶部悬浮的标签滑动切换为该章节名，章节序号以数字滚动过渡。点击圆点，文章会平滑滚到该章节开头。方向清晰、沉静，是长文阅读的好帮手。"
        ),
        implementation: L(
            "Chapters have known heights, so onScrollGeometryChange converts the offset into a continuous chapter position (index + fraction); it fills a scaled track, picks the active dot and drives a numericText label, while ScrollPosition.scrollTo(y:) powers dot taps.",
            "各章节高度已知，因此 onScrollGeometryChange 可以把偏移换算为连续的章节位置（序号 + 小数部分）；它驱动缩放的填充轨道、决定当前圆点并驱动 numericText 标签，点击圆点则调用 ScrollPosition.scrollTo(y:)。"
        ),
        apis: ["onScrollGeometryChange", "ScrollPosition", "contentTransition(.numericText(value:))", "spring(response:dampingFraction:)", "scaleEffect(anchor:)"],
        tags: ["scroll spy", "chapters", "table of contents", "progress", "章节", "目录", "导轨", "进度"],
        params: [
            .slider("gap", L("Dot spacing", "圆点间距"), 30...60, default: 44, step: 2, decimals: 0, unit: "pt"),
            .toggle("chip", L("Chapter chip", "章节标签"), default: true),
        ]
    ) { ctx in
        ScrollChapterRailDemo(ctx: ctx)
    }
}

private let scrollChapterTitles: [LocalizedText] = [
    L("Timing", "时长"), L("Easing", "缓动"), L("Springs", "弹簧"), L("Choreography", "编排"), L("Restraint", "克制"),
]
/// Height of each chapter block (title + body) in points.
private let scrollChapterHeights: [CGFloat] = [300, 340, 300, 360, 320]
private let scrollChapterSpacing: CGFloat = 24
private let scrollChapterTop: CGFloat = 56

private func scrollChapterStart(_ i: Int) -> CGFloat {
    var y: CGFloat = scrollChapterTop
    for k in 0..<i { y += scrollChapterHeights[k] + scrollChapterSpacing }
    return y
}

private struct ScrollChapterRailDemo: View {
    let ctx: DemoContext
    @State private var position = ScrollPosition(edge: .top)
    /// Continuous chapter position: 2.5 = halfway through chapter 3.
    @State private var reading: CGFloat = 0
    @State private var step = 0

    private var active: Int { min(Int(reading), scrollChapterTitles.count - 1) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: scrollChapterSpacing) {
                ForEach(scrollChapterTitles.indices, id: \.self) { i in
                    ScrollChapterBlock(index: i, language: ctx.language)
                        .frame(height: scrollChapterHeights[i], alignment: .top)
                }
            }
            .padding(.top, scrollChapterTop)
            .padding(.leading, 20)
            .padding(.trailing, 48)
            .padding(.bottom, 260)
        }
        .scrollIndicators(.hidden)
        .scrollPosition($position)
        .onScrollGeometryChange(for: CGFloat.self, of: { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        }, action: { _, newValue in
            reading = chapterPosition(for: newValue + 40)
        })
        .overlay(alignment: .trailing) {
            ScrollChapterRail(reading: reading, active: active, gap: ctx.cg("gap")) { i in
                withAnimation(.smooth(duration: 0.7)) {
                    position.scrollTo(y: scrollChapterStart(i) - 40)
                }
            }
            .padding(.trailing, 16)
        }
        .overlay(alignment: .top) {
            if ctx.bool("chip") {
                ScrollChapterChip(index: active, language: ctx.language)
                    .padding(.top, 10)
            }
        }
        .autoplay(ctx.isPreview, every: 1.5) { autoStep() }
    }

    private func chapterPosition(for y: CGFloat) -> CGFloat {
        let count = scrollChapterTitles.count
        for i in 0..<count {
            let start = scrollChapterStart(i)
            let length = scrollChapterHeights[i] + scrollChapterSpacing
            if y < start + length {
                return CGFloat(i) + ((y - start) / length).clamped(to: 0...1)
            }
        }
        return CGFloat(count - 1) + 1
    }

    private func autoStep() {
        let targets: [CGFloat] = [200, 480, 820, 1150, 1500, 0]
        let target = targets[step % targets.count]
        step += 1
        withAnimation(.smooth(duration: 1.1)) {
            position.scrollTo(y: target)
        }
    }
}

private struct ScrollChapterRail: View {
    let reading: CGFloat
    let active: Int
    let gap: CGFloat
    let onSelect: (Int) -> Void

    var body: some View {
        let count = scrollChapterTitles.count
        let length = gap * CGFloat(count - 1)
        let fill = (reading * gap).clamped(to: 0...length)
        ZStack(alignment: .top) {
            Capsule()
                .fill(Color.primary.opacity(0.1))
                .frame(width: 2, height: length)
            Capsule()
                .fill(LinearGradient(colors: [Palette.mint, Palette.sky, Palette.violet], startPoint: .top, endPoint: .bottom))
                .frame(width: 2, height: length)
                .scaleEffect(x: 1, y: max(fill / max(length, 1), 0.001), anchor: .top)
            ForEach(0..<count, id: \.self) { i in
                dot(i)
                    .offset(y: CGFloat(i) * gap - 12)
            }
        }
        .frame(width: 24, height: length, alignment: .top)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private func dot(_ i: Int) -> some View {
        let isActive = i == active
        let passed = i < active
        return Capsule()
            .fill(isActive || passed ? AnyShapeStyle(Palette.primary) : AnyShapeStyle(Palette.elevated))
            .overlay(Capsule().strokeBorder(Color.primary.opacity(isActive || passed ? 0 : 0.25), lineWidth: 1))
            .frame(width: isActive ? 10 : 8, height: isActive ? 24 : 8)
            .animation(.spring(response: 0.35, dampingFraction: 0.62), value: isActive)
            .frame(width: 24, height: 24)
            .contentShape(Rectangle())
            .onTapGesture { onSelect(i) }
    }
}

private struct ScrollChapterChip: View {
    let index: Int
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 6) {
            Text(verbatim: "\(index + 1)")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Palette.primary, in: Circle())
                .contentTransition(.numericText(value: Double(index)))
            Text(scrollChapterTitles[index], language)
                .font(.footnote.weight(.semibold))
                .contentTransition(.interpolate)
        }
        .padding(.leading, 5)
        .padding(.trailing, 12)
        .padding(.vertical, 5)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.1), radius: 8, y: 3)
        .animation(.snappy, value: index)
    }
}

private struct ScrollChapterBlock: View {
    let index: Int
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: String(format: "%02d", index + 1))
                .font(.caption.weight(.heavy).monospacedDigit())
                .foregroundStyle(Palette.accent)
            Text(scrollChapterTitles[index], language)
                .font(.title3.weight(.bold))
            PlaceholderLines(count: 4)
            ScrollKitArt(index: index + 2, language: language, showsTitle: false)
                .frame(height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            PlaceholderLines(count: 3)
        }
    }
}
