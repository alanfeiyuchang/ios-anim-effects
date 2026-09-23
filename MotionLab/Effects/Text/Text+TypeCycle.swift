import SwiftUI

extension Effect {
    static let textTypeCycle = Effect(
        id: "text.type-cycle",
        category: .text,
        interaction: .loop,
        name: L("Type & Replace Cycle", "打字轮换"),
        summary: L("A keyword types itself, holds, then backspaces or gets selected and replaced.", "关键词逐字打出、停留，再退格删除或被选中替换。"),
        prompt: L(
            "A hero line ends in a rotating keyword set in gradient type, followed by a 3 pt rounded caret. Each keyword types in at 70 ms per character with the caret solid and riding the last glyph, holds for 1.4 s while the caret blinks at ~1.9 Hz, then leaves in one of two styles: Backspace deletes one character every 35 ms (twice as fast as typing), or Select & replace flashes a translucent accent selection over the whole word for 300 ms before it vanishes at once. A 250 ms pause with a blinking caret precedes the next word. The rhythm — quick in, patient hold, brisk out — feels human, like someone live-editing a headline.",
            "主标题末尾是一个轮换的关键词，使用渐变文字，后面跟着一根 3 pt 的圆角光标。每个关键词以每字 70 毫秒的速度打出，打字时光标常亮并紧贴最后一个字；随后停留 1.4 秒，光标以约 1.9 Hz 闪烁；接着以两种方式之一离场：「退格」每 35 毫秒删除一个字（比打字快一倍），或「全选替换」——整词覆盖一层半透明强调色选区，持续 300 毫秒后一次性消失。下一个词出现前还有 250 毫秒的光标闪烁停顿。快进、耐心停留、利落退出的节奏很有人味，像有人在实时修改标题。"
        ),
        implementation: L(
            "A TimelineView(.animation) walks a per-word schedule (type, hold, erase, pause) built from each word's length and returns the visible prefix, caret state and selection flag; no animation state is stored.",
            "TimelineView(.animation) 按每个词的长度生成日程（打字、停留、删除、停顿），据此返回可见前缀、光标状态与选区标记，不保存任何动画状态。"
        ),
        apis: ["TimelineView(.animation)", "Text(verbatim:)", "prefix(_:)", "RoundedRectangle"],
        tags: ["typewriter", "typing", "rotating words", "caret", "打字", "轮换", "光标", "关键词"],
        params: [
            .slider("typeSpeed", L("Per character", "每字时长"), 0.03...0.2, default: 0.07, unit: "s"),
            .slider("hold", L("Hold", "停留"), 0.4...3.0, default: 1.4, unit: "s"),
            .choice("erase", L("Exit style", "离场方式"), [L("Backspace", "退格"), L("Select & replace", "全选替换")], default: 0),
        ]
    ) { ctx in
        TypeCycleDemo(ctx: ctx)
    }
}

private struct TypeCycleFrame {
    var word: [String] = []
    var visible: Int = 0
    var caretOn = true
    var selected = false
}

private struct TypeCycleDemo: View {
    let ctx: DemoContext

    private var words: [String] {
        ctx.language == .zh
            ? ["动效", "体验", "惊喜", "细节"]
            : ["motion", "delight", "clarity", "details"]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L("We sweat the", "我们死磕每一处"), ctx.language)
                .font(.system(size: 28, weight: .bold))
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                line(schedule(at: timeline.date.timeIntervalSinceReferenceDate))
            }
        }
        .frame(width: 280, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func line(_ frame: TypeCycleFrame) -> some View {
        let text = frame.word.prefix(frame.visible).joined()
        return HStack(spacing: 3) {
            Text(verbatim: text)
                .font(.system(size: 44, weight: .heavy))
                .foregroundStyle(Palette.primary)
                .padding(.horizontal, 2)
                .background(
                    Palette.indigo.opacity(frame.selected ? 0.25 : 0),
                    in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                )
                .fixedSize()
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(Palette.indigo)
                .frame(width: 3, height: 44)
                .opacity(frame.caretOn ? 1 : 0)
        }
        .frame(height: 60)
    }

    private func schedule(at time: Double) -> TypeCycleFrame {
        let perChar: Double = max(ctx["typeSpeed"], 0.01)
        let hold: Double = ctx["hold"]
        let selectMode = ctx.int("erase") == 1
        let pause: Double = 0.25
        let list = words.map { word in word.map { String($0) } }
        var durations: [Double] = []
        for chars in list {
            let count = Double(chars.count)
            let typing: Double = count * perChar
            let erasing: Double = selectMode ? 0.3 : count * perChar * 0.5
            durations.append(typing + hold + erasing + pause)
        }
        let total: Double = durations.reduce(0, +)
        var t: Double = time.truncatingRemainder(dividingBy: max(total, 0.1))
        let blink = time.truncatingRemainder(dividingBy: 0.52) < 0.26
        for (index, chars) in list.enumerated() {
            guard t >= durations[index] else {
                return phase(chars: chars, t: t, perChar: perChar, hold: hold, selectMode: selectMode, blink: blink)
            }
            t -= durations[index]
        }
        return TypeCycleFrame(word: list.first ?? [], visible: 0, caretOn: blink, selected: false)
    }

    private func phase(chars: [String], t: Double, perChar: Double, hold: Double, selectMode: Bool, blink: Bool) -> TypeCycleFrame {
        let count = chars.count
        let typing: Double = Double(count) * perChar
        var result = TypeCycleFrame(word: chars)
        if t < typing {
            result.visible = min(Int(t / perChar) + 1, count)
            result.caretOn = true
            return result
        }
        let afterHold: Double = t - typing - hold
        if afterHold < 0 {
            result.visible = count
            result.caretOn = blink
            return result
        }
        if selectMode {
            let visibleSelection = afterHold < 0.3
            result.visible = visibleSelection ? count : 0
            result.selected = visibleSelection
            result.caretOn = !visibleSelection && blink
            return result
        }
        let eraseStep: Double = perChar * 0.5
        let removed = Int(afterHold / eraseStep) + 1
        result.visible = max(count - removed, 0)
        result.caretOn = result.visible > 0 ? true : blink
        return result
    }
}
