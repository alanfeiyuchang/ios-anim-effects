import SwiftUI

extension Effect {
    static let textHighlighter = Effect(
        id: "text.highlighter",
        category: .text,
        interaction: .tap,
        name: L("Highlighter Sweep", "荧光笔划重点"),
        summary: L("A marker stroke sweeps behind key phrases, one after another.", "荧光笔依次从关键短语下方扫过。"),
        prompt: L(
            "An editorial serif quote sits on the stage; the key phrases are emphasised by a hand-drawn marker that sweeps in behind the words from left to right. The stroke is a slightly rotated (−1.5°) rounded band covering roughly the lower half of the line, scaling horizontally from 0 to 100% with an ease-in-out curve over ~0.7 s; the second phrase starts when the first is 80% complete, so the eye is led through the sentence like a reader underlining it live. Variants swap the marker for a thick underline or a drawn box outline. Human, warm and intentional.",
            "舞台上是一段衬线体的编辑感引文，关键短语由一支手绘感的荧光笔从左到右在文字后方扫过来强调。笔触是一条略微倾斜（−1.5°）的圆角色带，覆盖行高的下半部分左右，以缓入缓出曲线在约 0.7 秒内沿水平方向从 0 伸展到 100%；第二个短语在前一笔完成 80% 时接力开始，引导视线像读者现场划重点一样读完整句。变体可换成粗下划线或手绘方框描边。富有人情味、温暖且有明确意图。"
        ),
        implementation: L(
            "Each phrase has a background shape scaled on X from the leading anchor (or a trimmed rounded-rect stroke for the box style); two progress states animate with staggered delays.",
            "每个短语都有一个背景形状，以前缘为锚点沿 X 轴缩放（方框样式则为 trim 的圆角矩形描边）；两个进度状态以错开的延迟分别动画。"
        ),
        apis: ["scaleEffect(x:y:anchor:)", "trim(from:to:)", "rotationEffect", "Animation.delay"],
        tags: ["highlight", "marker", "underline", "emphasis", "荧光笔", "高亮", "划重点", "下划线"],
        params: [
            .slider("duration", L("Stroke duration", "笔触时长"), 0.3...1.5, default: 0.7, unit: "s"),
            .choice("style", L("Style", "样式"), [L("Marker", "荧光笔"), L("Underline", "下划线"), L("Box", "方框")], default: 0),
            .choice("color", L("Color", "颜色"), [L("Amber", "琥珀"), L("Mint", "薄荷"), L("Pink", "粉")], default: 0),
        ]
    ) { ctx in
        HighlighterDemo(ctx: ctx)
    }
}

private struct HighlighterDemo: View {
    let ctx: DemoContext
    @State private var first: CGFloat
    @State private var second: CGFloat

    init(ctx: DemoContext) {
        self.ctx = ctx
        // Still snapshots never run onAppear: show both strokes drawn.
        let drawn: CGFloat = ctx.isStill ? 1 : 0
        _first = State(initialValue: drawn)
        _second = State(initialValue: drawn)
    }

    private var color: Color {
        switch ctx.int("color") {
        case 1: return Palette.mint
        case 2: return Palette.pink
        default: return Palette.amber
        }
    }

    private var zh: Bool { ctx.language == .zh }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: zh ? "设计不只是" : "Design is not just")
                .foregroundStyle(.secondary)
            MarkedPhrase(text: zh ? "它看起来怎样，" : "what it looks like —", progress: first, style: ctx.int("style"), color: color)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(verbatim: zh ? "而是" : "it's")
                    .foregroundStyle(.secondary)
                MarkedPhrase(text: zh ? "它如何运作。" : "how it works.", progress: second, style: ctx.int("style"), color: color)
            }
            DemoHint(text: L("Tap to replay", "点击重播"), ctx: ctx)
                .padding(.top, 16)
        }
        .font(.system(size: 28, weight: .bold, design: .serif))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { replay() }
        // The detail stage strokes once in onAppear, so no intro play restarting it mid-sweep.
        .autoplay(ctx.isPreview, every: 3.2, delay: 0.1, intro: false) { replay() }
        .onAppear {
            if !ctx.isPreview { replay() }
        }
    }

    private func replay() {
        let duration = ctx["duration"]
        Task { @MainActor in
            withAnimation(.easeOut(duration: 0.25)) {
                first = 0
                second = 0
            }
            try? await Task.sleep(for: .seconds(0.35))
            withAnimation(.easeInOut(duration: duration)) { first = 1 }
            withAnimation(.easeInOut(duration: duration).delay(duration * 0.8)) { second = 1 }
        }
    }
}

private struct MarkedPhrase: View {
    let text: String
    let progress: CGFloat
    let style: Int
    let color: Color

    var body: some View {
        Text(verbatim: text)
            .foregroundStyle(.primary)
            .padding(.horizontal, 4)
            .background { mark }
    }

    @ViewBuilder
    private var mark: some View {
        switch style {
        case 1:
            Capsule()
                .fill(color)
                .frame(height: 5)
                .scaleEffect(x: progress, y: 1, anchor: .leading)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .offset(y: 2)
        case 2:
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .padding(-4)
                .rotationEffect(.degrees(-1))
        default:
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(LinearGradient(colors: [color.opacity(0.55), color.opacity(0.38)], startPoint: .leading, endPoint: .trailing))
                .padding(.top, 14)
                .padding(.bottom, 2)
                .scaleEffect(x: progress, y: 1, anchor: .leading)
                .rotationEffect(.degrees(-1.5))
        }
    }
}
