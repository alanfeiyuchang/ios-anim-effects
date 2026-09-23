import SwiftUI

extension Effect {
    static let textMaskedLines = Effect(
        id: "text.masked-lines",
        category: .text,
        interaction: .loop,
        name: L("Masked Line Rise", "遮罩逐行升起"),
        summary: L("Headline lines rise out of invisible slots, one after another, then exit upward.", "标题逐行从隐形槽口中升起，随后向上退场。"),
        prompt: L(
            "An editorial headline of three short lines, each living in its own clipped slot so the type appears to rise out of an invisible baseline. On entry every line starts one full line-height below its slot, tilted 6° around its leading baseline, then springs up and straightens (response ≈0.7 s, damping ≈0.85) with a 90 ms stagger top to bottom; a small uppercase eyebrow fades in first and a gradient rule draws out from the left 200 ms after the last line lands. After a pause the lines exit upward through the top of their slots with the same stagger and the next headline rises in. Confident, magazine-grade kinetic type.",
            "三行简短的杂志式标题，每一行都位于自己的裁剪槽口中，文字仿佛从看不见的基线里升起。入场时，每行从槽口下方整整一行高处开始，绕行首基线倾斜 6°，随后以弹簧（响应约 0.7 秒、阻尼约 0.85）上升并回正，自上而下错开 90 毫秒；上方的小号大写眉标先淡入，最后一行落定 200 毫秒后，一道渐变细线从左向右画出。停留片刻后，各行以同样的错开节奏从槽口顶部向上退出，下一组标题随之升起。自信、有杂志水准的动态排版。"
        ),
        implementation: L(
            "Each line is offset by ±its height inside a .clipped() frame and rotated with an anchor at its bottom-leading corner; a phase enum drives per-line springs delayed by index, and a scaleEffect(x:anchor: .leading) draws the rule.",
            "每一行在 .clipped() 的框内按 ± 自身行高偏移，并以左下角为锚点旋转；阶段枚举驱动按行号延迟的弹簧，细线用 scaleEffect(x:anchor: .leading) 画出。"
        ),
        apis: ["clipped()", "offset", "rotationEffect(_:anchor:)", "Animation.delay", "withTransaction"],
        tags: ["mask", "reveal", "headline", "line by line", "editorial", "遮罩", "逐行", "标题", "入场"],
        params: [
            .slider("stagger", L("Line stagger", "逐行间隔"), 0.03...0.25, default: 0.09, unit: "s"),
            .slider("response", L("Spring response", "弹簧响应"), 0.3...1.2, default: 0.7, unit: "s"),
            .slider("tilt", L("Entry tilt", "入场倾角"), 0...12, default: 6, step: 1, decimals: 0, unit: "°"),
        ]
    ) { ctx in
        TextMaskedLinesDemo(ctx: ctx)
    }
}

private enum TextMaskedPhase: Equatable {
    case below
    case shown
    case above
}

private struct TextMaskedLinesDemo: View {
    let ctx: DemoContext
    @State private var phase: TextMaskedPhase = .below
    @State private var index = 0

    private var headlines: [(eyebrow: String, lines: [String])] {
        ctx.language == .zh
            ? [
                ("第 01 章 · 动效", ["好的动效", "从不喧宾夺主，", "只为意图服务。"]),
                ("第 02 章 · 节奏", ["节奏感", "来自每一次停顿", "与每一次出发。"]),
                ("第 03 章 · 质感", ["质感藏在", "毫秒之间，", "也藏在分寸里。"]),
            ]
            : [
                ("CHAPTER 01 · MOTION", ["Great motion", "never shouts.", "It explains."]),
                ("CHAPTER 02 · RHYTHM", ["Rhythm lives", "in every pause", "and every start."]),
                ("CHAPTER 03 · CRAFT", ["Craft hides", "between the", "milliseconds."]),
            ]
    }

    var body: some View {
        let headline = headlines[index % headlines.count]
        VStack(alignment: .leading, spacing: 10) {
            Text(verbatim: headline.eyebrow)
                .font(.caption.weight(.heavy))
                .tracking(1.6)
                .foregroundStyle(Palette.coral)
                .opacity(phase == .shown ? 1 : 0)
                .offset(y: phase == .shown ? 0 : 6)
                .animation(.easeOut(duration: 0.35), value: phase)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(headline.lines.indices, id: \.self) { i in
                    TextMaskedLine(text: headline.lines[i], phase: phase, tilt: ctx["tilt"])
                        .animation(lineAnimation(i, count: headline.lines.count), value: phase)
                }
            }
            Capsule()
                .fill(Palette.sunset)
                .frame(width: 96, height: 4)
                .scaleEffect(x: phase == .shown ? 1 : 0.001, anchor: .leading)
                .animation(ruleAnimation(count: headline.lines.count), value: phase)
                .padding(.top, 6)
        }
        .frame(width: 290, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { await loop() }
    }

    private func lineAnimation(_ i: Int, count: Int) -> Animation {
        // Exit keeps reading order too: the top line leaves first.
        .spring(response: ctx["response"], dampingFraction: 0.85)
            .delay(0.08 + Double(i) * ctx["stagger"])
    }

    private func ruleAnimation(count: Int) -> Animation {
        if phase == .shown {
            // Last line starts at 0.08 + (count − 1) × stagger and has visibly landed after
            // ~0.8 × its spring response; the rule follows 200 ms after that.
            let lastLineLands = 0.08 + Double(max(count - 1, 0)) * ctx["stagger"] + ctx["response"] * 0.8
            return .spring(response: 0.6, dampingFraction: 0.9).delay(lastLineLands + 0.2)
        }
        return .easeIn(duration: 0.25)
    }

    private func loop() async {
        try? await Task.sleep(for: .seconds(0.35))
        while !Task.isCancelled {
            phase = .shown
            try? await Task.sleep(for: .seconds(2.8))
            if Task.isCancelled { return }
            phase = .above
            try? await Task.sleep(for: .seconds(0.8 + ctx["stagger"] * 3))
            if Task.isCancelled { return }
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                phase = .below
                index += 1
            }
            try? await Task.sleep(for: .seconds(0.08))
        }
    }
}

private struct TextMaskedLine: View {
    let text: String
    let phase: TextMaskedPhase
    let tilt: Double

    private let lineHeight: CGFloat = 50

    var body: some View {
        Text(verbatim: text)
            .font(.system(size: 38, weight: .bold, design: .serif))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .foregroundStyle(.primary)
            .rotationEffect(.degrees(phase == .below ? tilt : 0), anchor: .bottomLeading)
            .offset(y: offset)
            .frame(height: lineHeight, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .clipped()
    }

    private var offset: CGFloat {
        switch phase {
        case .below: return lineHeight
        case .shown: return 0
        case .above: return -lineHeight
        }
    }
}
