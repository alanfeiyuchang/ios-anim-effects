import SwiftUI

extension Effect {
    static let textScribbleCircle = Effect(
        id: "text.scribble-circle",
        category: .text,
        interaction: .tap,
        name: L("Hand-Drawn Annotation", "手绘圈注"),
        summary: L("A pen loop circles a keyword, then a wavy underline scribbles under another.", "一支笔先圈住关键词，再在另一个词下面画出波浪线。"),
        prompt: L(
            "A three-line statement in 30 pt bold type sits on the stage. On trigger, a coral marker loop draws itself around one keyword: a slightly wobbly ellipse that travels 1.15 turns so its tail overshoots past the start like a real pen, drawn over 0.7 s with ease-in-out and 3 pt round-capped strokes. As the loop closes the keyword warms to coral. 100 ms later an indigo wavy underline (four crests, 3 pt amplitude) scribbles left-to-right under a second phrase in 0.5 s. Replaying erases both strokes instantly. A light haptic marks each stroke start. It feels human and editorial — a designer marking up a slide.",
            "舞台上是一段三行、30 pt 粗体的陈述句。触发后，一支珊瑚色马克笔绕着关键词画出一个圈：略带抖动的椭圆，走过 1.15 圈，结尾像真实笔迹一样越过起笔处；以缓入缓出在 0.7 秒内画完，笔画 3 pt、圆头。圈合拢时关键词变成珊瑚色。100 毫秒后，一条靛蓝色波浪下划线（四个波峰、振幅 3 pt）在 0.5 秒内从左到右划过第二个短语。重播时两条笔迹瞬间擦除，每一笔开始时伴随轻触感。像设计师在幻灯片上随手批注，充满人味和编辑感。"
        ),
        implementation: L(
            "Two custom Shapes — a wobbly multi-turn ellipse and a sine squiggle — are stroked and revealed with .trim(from:to:), whose end value animates; they sit in overlays on the exact Text runs they annotate.",
            "两个自定义 Shape——一个带抖动、超过一圈的椭圆和一条正弦波浪线——描边后用 .trim(from:to:) 揭示，动画驱动 trim 的终点；它们作为 overlay 精确贴在所标注的文字上。"
        ),
        apis: ["Shape", "Path.addLines", "trim(from:to:)", "StrokeStyle", "overlay"],
        tags: ["annotation", "scribble", "circle", "underline", "手绘", "圈注", "下划线", "强调"],
        params: [
            .slider("duration", L("Draw duration", "绘制时长"), 0.3...1.5, default: 0.7, unit: "s"),
            .slider("turns", L("Loop turns", "绕圈圈数"), 1.0...1.5, default: 1.15),
            .slider("width", L("Stroke width", "笔画粗细"), 1.5...6, default: 3, decimals: 1, unit: "pt"),
        ]
    ) { ctx in
        ScribbleCircleDemo(ctx: ctx)
    }
}

private struct ScribbleCircleDemo: View {
    let ctx: DemoContext
    @State private var loop: CGFloat = 1
    @State private var underline: CGFloat = 1
    @State private var marked = true

    private var stroke: StrokeStyle {
        StrokeStyle(lineWidth: ctx.cg("width"), lineCap: .round, lineJoin: .round)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L("Great design", "好的设计"), ctx.language)
            HStack(spacing: 0) {
                Text(L("is ", "是"), ctx.language)
                keyword
                Text(L(",", "的，"), ctx.language)
            }
            HStack(spacing: 0) {
                Text(L("until it ", "直到它"), ctx.language)
                underlined
                Text(L(".", "。"), ctx.language)
            }
            DemoHint(text: L("Tap to annotate", "点击批注"), ctx: ctx)
                .padding(.top, 24)
        }
        .font(.system(size: 30, weight: .bold))
        .fixedSize()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { replay() }
        .autoplay(ctx.isPreview, every: ctx["duration"] + 2.0) { replay() }
    }

    private var keyword: some View {
        Text(L("invisible", "隐形"), ctx.language)
            .foregroundStyle(marked ? AnyShapeStyle(Palette.coral) : AnyShapeStyle(.primary))
            .overlay {
                ScribbleLoop(turns: ctx["turns"])
                    .trim(from: 0, to: loop)
                    .stroke(Palette.coral, style: stroke)
                    .padding(.horizontal, -14)
                    .padding(.vertical, -8)
                    .allowsHitTesting(false)
            }
    }

    private var underlined: some View {
        Text(L("moves", "动起来"), ctx.language)
            .overlay(alignment: .bottom) {
                Squiggle()
                    .trim(from: 0, to: underline)
                    .stroke(Palette.indigo, style: stroke)
                    .frame(height: 8)
                    .offset(y: 8)
                    .allowsHitTesting(false)
            }
    }

    private func replay() {
        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) {
            loop = 0
            underline = 0
            marked = false
        }
        let duration: Double = ctx["duration"]
        let muted = Haptics.isMuted || ctx.isPreview
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if !muted { Haptics.tap(.light) }
            withAnimation(.easeInOut(duration: duration)) { loop = 1 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + duration) {
            if !muted { Haptics.tap(.light) }
            withAnimation(.easeOut(duration: 0.25)) { marked = true }
            withAnimation(.easeInOut(duration: 0.5)) { underline = 1 }
        }
    }
}

/// A slightly wobbly ellipse that runs past a full turn, like a marker loop.
private struct ScribbleLoop: Shape {
    var turns: Double

    func path(in rect: CGRect) -> Path {
        let steps = 90
        let total: Double = turns * 2 * Double.pi
        let start: Double = -Double.pi * 0.35
        var points: [CGPoint] = []
        points.reserveCapacity(steps + 1)
        for step in 0...steps {
            let t: Double = total * Double(step) / Double(steps)
            let wobble: Double = 1 + 0.035 * sin(t * 3) + 0.05 * t / total
            let angle: Double = start + t
            let x: CGFloat = rect.midX + rect.width / 2 * CGFloat(wobble * cos(angle))
            let y: CGFloat = rect.midY + rect.height / 2 * CGFloat(wobble * sin(angle) * 0.95)
            points.append(CGPoint(x: x, y: y))
        }
        var path = Path()
        path.addLines(points)
        return path
    }
}

/// Four crests of a sine wave across the rect.
private struct Squiggle: Shape {
    func path(in rect: CGRect) -> Path {
        let steps = 60
        var points: [CGPoint] = []
        for step in 0...steps {
            let p: Double = Double(step) / Double(steps)
            let x: CGFloat = rect.minX + rect.width * CGFloat(p)
            let y: CGFloat = rect.midY + CGFloat(sin(p * Double.pi * 8)) * rect.height * 0.38
            points.append(CGPoint(x: x, y: y))
        }
        var path = Path()
        path.addLines(points)
        return path
    }
}
