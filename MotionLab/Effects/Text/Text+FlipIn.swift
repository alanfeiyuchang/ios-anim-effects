import SwiftUI

extension Effect {
    static let textFlipIn = Effect(
        id: "text.flip-in-3d",
        category: .text,
        interaction: .loop,
        name: L("3D Flip-in Letters", "3D 翻转入场"),
        summary: L("Letters hinge into place in 3D, one after another.", "字母依次以 3D 铰链翻转落位。"),
        prompt: L(
            "A heavy, rounded display word in a warm sunset gradient assembles itself letter by letter: each glyph starts rotated −100° around the horizontal axis (flipping top-to-bottom; the alternative hinges left-to-right around the vertical axis) with strong perspective, 12 pt low, blurred and transparent, then hinges upright on a lively spring (≈0.55 s response, 0.7 damping) with a 60 ms stagger in reading order, overshooting a few degrees before settling. After a beat the word exits with the same stagger, flipping forward to +100° and dissolving, and the next word flips in while a small chapter pill beneath glides to mark its place in the sequence — bold, rhythmic kinetic typography, like a title sequence.",
            "暖色日落渐变的粗圆体大字逐字组装：每个字形起始时绕水平轴旋转 −100°（上下翻转；另一选项为绕竖直轴左右翻转），带强烈透视，下沉 12pt、模糊且透明；随后以富有活力的弹簧（响应约 0.55 秒、阻尼 0.7）按阅读顺序每隔 60 毫秒依次翻起立正，先过冲几度再稳定。停留片刻后，整词以同样的错开节奏向前翻转到 +100° 并消散，下一个词接着翻入，下方的小章节胶囊随之滑动标示当前位置——大胆、有节奏的动态排版，宛如片头字幕。"
        ),
        implementation: L(
            "Each character is its own Text with rotation3DEffect, offset, blur and opacity keyed to a phase enum, animated via .animation(.spring(...).delay(i × stagger), value: phase).",
            "每个字符都是独立的 Text，rotation3DEffect、位移、模糊和透明度都绑定到一个阶段枚举，并通过 .animation(.spring(...).delay(i × 错开), value: phase) 驱动。"
        ),
        apis: ["rotation3DEffect", "animation(_:value:)", "Animation.delay", "withTransaction"],
        tags: ["3d", "flip", "kinetic typography", "stagger", "翻转", "3D", "动态排版", "入场"],
        params: [
            .slider("stagger", L("Stagger", "错开"), 0.02...0.15, default: 0.06, unit: "s"),
            .slider("response", L("Spring response", "弹簧响应"), 0.3...1, default: 0.55, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.4...1, default: 0.7),
            .choice("axis", L("Flip direction", "翻转方向"), [L("Flip top-bottom", "上下翻转"), L("Flip left-right", "左右翻转")], default: 0),
        ]
    ) { ctx in
        FlipInDemo(ctx: ctx)
    }
}

private enum FlipPhase: Equatable {
    case hidden
    case shown
    case exited

    var angle: Double {
        switch self {
        case .hidden: return -100
        case .shown: return 0
        case .exited: return 100
        }
    }
}

private struct FlipInDemo: View {
    let ctx: DemoContext
    @State private var phase: FlipPhase
    @State private var index = 0
    /// Mirrors `index` outside the animation-disabled reset so the chapter dots can glide.
    @State private var shownIndex = 0

    init(ctx: DemoContext) {
        self.ctx = ctx
        // Still snapshots never run the loop: show the word at rest.
        _phase = State(initialValue: ctx.isStill ? .shown : .hidden)
    }

    private var words: [String] {
        ctx.language == .zh ? ["让文字跃动", "每帧都讲究", "质感即品牌"] : ["KINETIC", "MOTION", "DELIGHT"]
    }

    var body: some View {
        let letters = Array(words[index % words.count])
        VStack(spacing: 30) {
            HStack(spacing: ctx.language == .zh ? 2 : 1) {
                ForEach(0..<letters.count, id: \.self) { i in
                    FlipLetter(
                        letter: letters[i],
                        phase: phase,
                        horizontalAxis: ctx.int("axis") == 0,
                        size: ctx.language == .zh ? 46 : 54
                    )
                    .animation(letterAnimation(i), value: phase)
                }
            }
            .foregroundStyle(Palette.sunset)
            .shadow(color: Palette.coral.opacity(0.28), radius: 14, y: 10)
            pageDots
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { await loop() }
    }

    /// Which title card of the sequence is showing — a small chapter marker under the word.
    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<words.count, id: \.self) { i in
                Capsule()
                    .fill(i == shownIndex % words.count ? AnyShapeStyle(Palette.sunset) : AnyShapeStyle(Color.primary.opacity(0.15)))
                    .frame(width: i == shownIndex % words.count ? 20 : 6, height: 6)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: shownIndex)
    }

    private func letterAnimation(_ i: Int) -> Animation {
        .spring(response: ctx["response"], dampingFraction: ctx["damping"])
            .delay(Double(i) * ctx["stagger"])
    }

    private func loop() async {
        try? await Task.sleep(for: .seconds(0.3))
        while !Task.isCancelled {
            phase = .shown
            shownIndex = index
            try? await Task.sleep(for: .seconds(2.2))
            if Task.isCancelled { return }
            phase = .exited
            try? await Task.sleep(for: .seconds(0.9))
            if Task.isCancelled { return }
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                phase = .hidden
                index += 1
            }
            try? await Task.sleep(for: .seconds(0.08))
        }
    }
}

private struct FlipLetter: View {
    let letter: Character
    let phase: FlipPhase
    let horizontalAxis: Bool
    let size: CGFloat

    var body: some View {
        let visible = phase == .shown
        let axis: (x: CGFloat, y: CGFloat, z: CGFloat) = horizontalAxis ? (x: 1, y: 0, z: 0) : (x: 0, y: 1, z: 0)
        Text(verbatim: String(letter))
            .font(.system(size: size, weight: .black, design: .rounded))
            .rotation3DEffect(
                .degrees(phase.angle),
                axis: axis,
                anchor: .center,
                perspective: 0.6
            )
            .offset(y: visible ? 0 : 12)
            .blur(radius: visible ? 0 : 5)
            .opacity(visible ? 1 : 0)
    }
}
