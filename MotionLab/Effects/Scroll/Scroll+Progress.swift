import SwiftUI

extension Effect {
    static let scrollProgress = Effect(
        id: "scroll.progress-indicator",
        category: .scroll,
        interaction: .scroll,
        name: L("Reading Progress", "阅读进度"),
        summary: L("A glowing top bar and a floating ring that fill as you read.", "随阅读进度填充的发光顶部进度条与悬浮圆环。"),
        prompt: L(
            "An article scrolls beneath a frosted header bar showing the section title and a live percentage in monospaced digits. A 4 pt gradient progress line (mint → sky → violet) along the header's bottom edge fills from the left in exact proportion to how far the reader has scrolled, with a soft same-color glow. In the bottom-right corner a 44 pt floating ring traces the same progress as a rounded stroke starting from 12 o'clock; when the article is finished the ring turns into an arrow-up button with a quick spring pop, and tapping it glides the article back to the top. Values are computed from scroll geometry every frame, so the indicators never lag the finger. Quiet, useful, delightful.",
            "文章在一条磨砂标题栏下滚动，标题栏显示章节名与等宽数字的实时百分比。标题栏底边有一条4 pt的渐变进度线（薄荷→天蓝→紫），从左向右按读者已滚动的比例精确填充，并带同色柔光。右下角悬浮一个44 pt圆环，以圆头描边从12点方向同步绘制进度；读完时圆环以快速弹簧弹出切换为向上箭头按钮，点击后文章平滑回到顶部。数值每帧由滚动几何计算，指示器永远不会滞后于手指。安静、实用、令人愉悦。"
        ),
        implementation: L(
            "onScrollGeometryChange maps contentOffset / (contentSize − containerSize) to a 0…1 progress that drives a scaled gradient capsule and a trimmed Circle; ScrollPosition.scrollTo(edge: .top) powers the back-to-top button.",
            "onScrollGeometryChange 将 contentOffset / (contentSize − containerSize) 映射为 0…1 的进度，驱动缩放的渐变胶囊与 trim 后的 Circle；ScrollPosition.scrollTo(edge: .top) 实现回到顶部按钮。"
        ),
        apis: ["onScrollGeometryChange", "ScrollGeometry", "Circle().trim", "ScrollPosition", "Material"],
        tags: ["progress", "reading", "indicator", "scroll", "进度", "阅读", "指示器", "回到顶部"],
        params: [
            .slider("barHeight", L("Bar thickness", "进度条粗细"), 2...8, default: 4, step: 1, decimals: 0, unit: "pt"),
            .toggle("ring", L("Floating ring", "悬浮圆环"), default: true),
        ]
    ) { ctx in
        ScrollProgressDemo(ctx: ctx)
    }
}

/// Height of the frosted header (title row + progress track).
private let scrollProgressHeaderHeight: CGFloat = 44

private struct ScrollProgressDemo: View {
    let ctx: DemoContext
    @State private var progress: Double = 0
    @State private var position = ScrollPosition(edge: .top)
    @State private var down = false

    var body: some View {
        ScrollView {
            ScrollArticle(language: ctx.language)
                .padding(.horizontal, 22)
                // Clears the frosted header overlay, then the usual 16 pt gutter.
                .padding(.top, scrollProgressHeaderHeight + 16)
                .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .scrollPosition($position)
        .onScrollGeometryChange(for: Double.self, of: { geometry in
            let range = geometry.contentSize.height - geometry.containerSize.height
            guard range > 0 else { return 0 }
            let offset = geometry.contentOffset.y + geometry.contentInsets.top
            return Double(offset / range).clamped(to: 0...1)
        }, action: { _, newValue in
            progress = newValue
        })
        .overlay(alignment: .top) {
            ScrollProgressHeader(progress: progress, barHeight: ctx.cg("barHeight"), language: ctx.language)
        }
        .overlay(alignment: .bottomTrailing) {
            if ctx.bool("ring") {
                ScrollProgressRing(progress: progress) {
                    withAnimation(.smooth(duration: 0.8)) { position.scrollTo(edge: .top) }
                }
                .padding(16)
            }
        }
        .autoplay(ctx.isPreview, every: 3.0) {
            down.toggle()
            withAnimation(.smooth(duration: 2.4)) {
                position.scrollTo(edge: down ? .bottom : .top)
            }
        }
    }
}

private struct ScrollProgressHeader: View {
    let progress: Double
    let barHeight: CGFloat
    let language: AppLanguage

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L("The Art of Motion", "动效的艺术"), language)
                    .font(.footnote.weight(.semibold))
                Spacer(minLength: 0)
                Text(verbatim: "\(Int((progress * 100).rounded()))%")
                    .font(.footnote.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 18)
            .frame(height: scrollProgressHeaderHeight - 4)
            Capsule()
                .fill(LinearGradient(colors: [Palette.mint, Palette.sky, Palette.violet], startPoint: .leading, endPoint: .trailing))
                .frame(height: barHeight)
                .scaleEffect(x: max(progress, 0.001), y: 1, anchor: .leading)
                .shadow(color: Palette.sky.opacity(0.6), radius: 6)
        }
        .background(.ultraThinMaterial)
    }
}

private struct ScrollProgressRing: View {
    let progress: Double
    let action: () -> Void

    private var done: Bool { progress > 0.985 }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(colors: [Palette.mint, Palette.sky, Palette.violet], center: .center, angle: .zero),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Image(systemName: done ? "arrow.up" : "book.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(done ? Palette.violet : Color.secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(width: 44, height: 44)
            .padding(4)
            .background(.regularMaterial, in: Circle())
            .scaleEffect(done ? 1.12 : 1)
            .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.55), value: done)
    }
}

private struct ScrollArticle: View {
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(L("The Art of Motion", "动效的艺术"), language)
                .font(.title2.weight(.bold))
            HStack(spacing: 10) {
                ScrollKitIcon(index: 1, size: 30)
                    .clipShape(Circle())
                Text(L("Lena Park · 6 min read", "朴莉娜 · 6 分钟阅读"), language)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            ForEach(scrollProgressParagraphs.indices, id: \.self) { i in
                Text(scrollProgressParagraphs[i], language)
                    .font(.subheadline)
                    .foregroundStyle(Color.primary.opacity(0.82))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                if i == 1 {
                    ScrollKitArt(index: 5, language: language, showsTitle: false)
                        .frame(height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                if i == 3 {
                    quote
                }
            }
        }
    }

    private var quote: some View {
        HStack(spacing: 12) {
            Capsule()
                .fill(Palette.primary)
                .frame(width: 3)
            Text(L("Good motion is felt before it is seen.", "好的动效，先被感受，后被看见。"), language)
                .font(.callout.italic())
                .foregroundStyle(.secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private let scrollProgressParagraphs: [LocalizedText] = [
    L(
        "Motion is the grammar of an interface. Before a person reads a single word, they have already felt whether a screen is calm or restless, heavy or light.",
        "动效是界面的语法。在读到第一个字之前，人们就已经感受到这个页面是沉静还是焦躁、厚重还是轻盈。"
    ),
    L(
        "Good transitions answer three questions at once: where did this come from, where is it going, and what can I do with it now?",
        "好的转场会同时回答三个问题：它从哪里来，要到哪里去，现在我能拿它做什么？"
    ),
    L(
        "Springs feel natural because they carry momentum. A card that overshoots by a few points and settles tells the eye it has weight.",
        "弹簧之所以自然，是因为它带着惯性。一张卡片多冲出几个点再回落，眼睛就知道它有分量。"
    ),
    L(
        "Timing is a budget. Most feedback should land within 100 ms; larger choreography can take 300 to 500 ms before it starts to feel slow.",
        "时长是一种预算。大多数反馈应在 100 毫秒内到达；更大的编排可以用 300 到 500 毫秒，再长就会显得拖沓。"
    ),
    L(
        "Let the finger lead. When motion is scrubbed by a gesture instead of a timer, the interface stops performing and starts responding.",
        "让手指来主导。当动效由手势驱动而不是由计时器播放，界面就从“表演”变成了“回应”。"
    ),
    L(
        "Finally, restraint. The best motion is often the one nobody notices — it simply makes the product feel inevitable.",
        "最后是克制。最好的动效往往无人察觉——它只是让产品显得理所当然。"
    ),
]
