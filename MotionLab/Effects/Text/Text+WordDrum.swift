import SwiftUI

extension Effect {
    static let textWordDrum = Effect(
        id: "text.word-drum",
        category: .text,
        interaction: .loop,
        name: L("3D Word Drum", "3D 词语滚筒"),
        summary: L("Words sit on a turning cylinder that clicks forward with a slight overshoot.", "词语排在一个转动的圆柱上，逐格转动并略微过冲。"),
        prompt: L(
            "A two-line hero statement: a static first line, and beneath it a keyword printed around a horizontal cylinder of five words in gradient colour. Every 1.8 s the drum turns one face (72°) in 0.55 s on an ease-out-back curve (overshoot ≈10%), so the next word rolls up from below, tips past upright and clicks back into place. Each word is rotated in 3D about the x-axis to match its position on the drum, displaced by radius × sin(angle) and faded by cos(angle), and the top and bottom of the window fade through a gradient mask, selling the curvature. Tapping advances immediately with a light haptic. It is a confident, mechanical take on the rotating-word hero.",
            "一段两行的主标题：第一行固定不动，第二行的关键词印在一个横向圆柱的五个面上，文字带渐变色。滚筒每 1.8 秒转过一个面（72°），用时 0.55 秒、采用回弹缓出曲线（过冲约 10%），于是下一个词从下方滚上来，略微越过正位再「咔嗒」回正。每个词按自己在滚筒上的角度绕 x 轴做 3D 旋转，纵向位移为半径 × sin(角度)，透明度随 cos(角度) 衰减；窗口上下边缘用渐变遮罩淡出，强化圆柱的曲面感。点击可立即转到下一个词并伴随轻触感。这是轮播关键词标题的机械感版本，干脆而自信。"
        ),
        implementation: L(
            "A TimelineView computes a continuous drum position — whole steps plus an eased fraction during the last 0.55 s of each hold — and every word derives its angle, rotation3DEffect, y offset and opacity from it, inside a gradient-masked window.",
            "TimelineView 计算连续的滚筒位置——整步数加上每次停留最后 0.55 秒内的缓动小数——每个词据此推算自己的角度、rotation3DEffect、纵向位移与透明度，并放在带渐变遮罩的窗口里。"
        ),
        apis: ["TimelineView", "rotation3DEffect(_:axis:perspective:)", "mask", "LinearGradient"],
        tags: ["rotating words", "drum", "3D", "cylinder", "轮播词", "滚筒", "三维", "标题"],
        params: [
            .slider("hold", L("Hold", "停留"), 0.9...4.0, default: 1.8, unit: "s"),
            .slider("overshoot", L("Overshoot", "过冲"), 0...3, default: 1.7),
            .slider("radius", L("Drum radius", "滚筒半径"), 20...70, default: 38, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        WordDrumDemo(ctx: ctx)
    }
}

private struct WordDrumDemo: View {
    let ctx: DemoContext
    @State private var start = Date()

    private var words: [LocalizedText] {
        [L("fast.", "飞快。"), L("alive.", "鲜活。"), L("human.", "有温度。"), L("calm.", "从容。"), L("magic.", "神奇。")]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L("Build apps that feel", "做出让人感觉"), ctx.language)
                .font(.system(size: 26, weight: .bold))
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let position: Double = drumPosition(elapsed: timeline.date.timeIntervalSince(start))
                drum(position: position)
            }
            DemoHint(text: L("Tap to turn", "点击转动"), ctx: ctx)
                .padding(.top, 20)
        }
        .frame(width: 280, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            advance()
        }
    }

    /// Jumps the clock to the start of the next turn so the drum rolls forward right away.
    private func advance() {
        Haptics.tap(.light)
        let hold: Double = max(ctx["hold"], 0.6)
        let turn: Double = min(0.55, hold * 0.8)
        let elapsed: Double = Date().timeIntervalSince(start)
        let steps: Double = (elapsed / hold).rounded(.down)
        let inStep: Double = elapsed - steps * hold
        // Mid-turn, jump to the start of the *next* turn so the drum never rolls backwards.
        let base: Double = inStep > hold - turn ? steps + 1 : steps
        let target: Double = base * hold + (hold - turn)
        start = Date().addingTimeInterval(-target)
    }

    /// Whole steps plus an ease-out-back fraction during the last `turn` seconds of each hold.
    private func drumPosition(elapsed: Double) -> Double {
        let hold: Double = max(ctx["hold"], 0.6)
        let turn: Double = min(0.55, hold * 0.8)
        let steps: Double = (elapsed / hold).rounded(.down)
        let inStep: Double = elapsed - steps * hold
        let moveStart: Double = hold - turn
        guard inStep > moveStart else { return steps }
        let x: Double = (inStep - moveStart) / turn
        return steps + easeOutBack(x)
    }

    private func easeOutBack(_ x: Double) -> Double {
        let c1: Double = ctx["overshoot"]
        let c3: Double = c1 + 1
        let t: Double = x - 1
        return 1 + c3 * t * t * t + c1 * t * t
    }

    private func drum(position: Double) -> some View {
        let count = words.count
        return ZStack {
            ForEach(0..<count, id: \.self) { index in
                face(index: index, position: position, count: count)
            }
        }
        .frame(width: 280, height: 110, alignment: .leading)
        .mask {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.22),
                    .init(color: .black, location: 0.78),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private func face(index: Int, position: Double, count: Int) -> some View {
        let step: Double = 360 / Double(count)
        var angle: Double = (Double(index) - position) * step
        angle = angle.truncatingRemainder(dividingBy: 360)
        if angle > 180 { angle -= 360 }
        if angle < -180 { angle += 360 }
        let radians: Double = angle * Double.pi / 180
        let visible: Double = max(cos(radians), 0)
        let y: CGFloat = ctx.cg("radius") * CGFloat(sin(radians))
        return Text(words[index], ctx.language)
            .font(.system(size: 40, weight: .heavy))
            .foregroundStyle(Palette.sunset)
            .fixedSize()
            .rotation3DEffect(.degrees(-angle), axis: (x: 1, y: 0, z: 0), anchor: .center, perspective: 0.6)
            .offset(y: y)
            .opacity(visible)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
