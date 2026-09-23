import SwiftUI

extension Effect {
    static let textTypeCycle = Effect(
        id: "text.type-cycle",
        category: .text,
        interaction: .loop,
        name: L("Type & Replace Cycle", "打字轮换"),
        summary: L("A keyword types itself, holds, then backspaces or gets selected and replaced.", "关键词逐字打出、停留，再退格删除或被选中替换。"),
        prompt: L(
            "A hero line ends in a rotating keyword set in gradient type, followed by a 3 pt rounded caret. Each keyword types in at 70 ms per character, every glyph popping up from 30% scale and 12 pt low with a back-ease overshoot over 140 ms while the solid caret rides it; it holds 1.4 s as the caret blinks at ~1.9 Hz, then leaves: by default Select & replace flashes a translucent accent selection over the whole word for 300 ms before it vanishes at once, or Backspace deletes a character every 35 ms. A 250 ms pause with a blinking caret precedes the next word. The rhythm — quick in, patient hold, brisk out — feels human, like someone live-editing a headline.",
            "主标题末尾是一个轮换的关键词，使用渐变文字，后面跟着一根 3 pt 的圆角光标。关键词以每字 70 毫秒打出，每个字在 140 毫秒内从 30% 大小、低 12 pt 处带回弹缓动跳出，光标常亮紧随；停留 1.4 秒，光标约 1.9 Hz 闪烁；随后默认「全选替换」：整词覆上半透明强调色选区 300 毫秒后一次性消失，也可改为「退格」每 35 毫秒删一字。下一个词出现前还有 250 毫秒的光标闪烁停顿。快进、耐心停留、利落退出的节奏很有人味，像有人在实时修改标题。"
        ),
        implementation: L(
            "A TimelineView(.animation) walks a per-word schedule (type, hold, erase, pause) built from each word's length and returns the visible prefix, the newest glyph's age, caret state and selection flag; the last three glyphs are drawn separately with an age-driven back-ease pop, and the gradient is masked over the whole line. No animation state is stored.",
            "TimelineView(.animation) 按每个词的长度生成日程（打字、停留、删除、停顿），据此返回可见前缀、最新字符的时长、光标状态与选区标记；最后三个字单独绘制，按时长做回弹缓动跳出，渐变以遮罩覆盖整行。不保存任何动画状态。"
        ),
        apis: ["TimelineView(.animation)", "Text(verbatim:)", "prefix(_:)", "RoundedRectangle"],
        tags: ["typewriter", "typing", "rotating words", "caret", "打字", "轮换", "光标", "关键词"],
        params: [
            .slider("typeSpeed", L("Per character", "每字时长"), 0.03...0.2, default: 0.07, unit: "s"),
            .slider("hold", L("Hold", "停留"), 0.4...3.0, default: 1.4, unit: "s"),
            .choice("erase", L("Exit style", "离场方式"), [L("Backspace", "退格"), L("Select & replace", "全选替换")], default: 1),
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
    /// Seconds since the newest glyph appeared (large once typing is done).
    var sinceLast: Double = 10
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
        let glyphs = glyphRow(frame)
        return HStack(spacing: 3) {
            glyphs
                .foregroundStyle(Palette.violet)
                .overlay { Palette.primary }
                .mask { glyphs }
                .padding(.horizontal, 2)
                .background(
                    Palette.indigo.opacity(frame.selected ? 0.25 : 0),
                    in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                )
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(Palette.indigo)
                .frame(width: 3, height: 44)
                .opacity(frame.caretOn ? 1 : 0)
        }
        .frame(height: 60)
    }

    /// Settled text plus the last few glyphs drawn one by one, so each can pop in.
    private func glyphRow(_ frame: TypeCycleFrame) -> some View {
        let count = frame.visible
        let tail = min(3, count)
        let settled = frame.word.prefix(count - tail).joined()
        return HStack(spacing: 0) {
            Text(verbatim: settled)
            ForEach(0..<tail, id: \.self) { k in
                pop(frame: frame, index: count - tail + k, newer: tail - 1 - k)
            }
        }
        .font(.system(size: 44, weight: .heavy))
        .fixedSize()
    }

    private func pop(frame: TypeCycleFrame, index: Int, newer: Int) -> some View {
        let perChar: Double = max(ctx["typeSpeed"], 0.01)
        let age: Double = frame.sinceLast + Double(newer) * perChar
        let p: Double = min(age / 0.14, 1)
        // Back ease-out: a small overshoot past full size before settling.
        let q: Double = p - 1
        let back: Double = 1 + 2.70158 * q * q * q + 1.70158 * q * q
        let scale: CGFloat = CGFloat(0.3 + 0.7 * back)
        let drop: CGFloat = CGFloat(12 * q * q)
        let alpha: Double = min(p * 3, 1)
        return Text(verbatim: frame.word[index])
            .scaleEffect(scale, anchor: .bottom)
            .offset(y: drop)
            .opacity(alpha)
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
            let shown = min(Int(t / perChar) + 1, count)
            result.visible = shown
            result.sinceLast = t - Double(shown - 1) * perChar
            result.caretOn = true
            return result
        }
        result.sinceLast = t - Double(max(count - 1, 0)) * perChar
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
