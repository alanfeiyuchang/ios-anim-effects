import SwiftUI

extension Effect {
    static let textTypewriter = Effect(
        id: "text.typewriter",
        category: .text,
        interaction: .loop,
        name: L("Typewriter", "打字机"),
        summary: L("Characters type in with a human rhythm and a blinking caret.", "字符以真人般的节奏逐字打出，光标柔和闪烁。"),
        prompt: L(
            "A monospaced headline inside a minimal terminal card types itself out one character at a time, with each keystroke landing after a slightly randomised interval (±30%) so the rhythm feels human rather than mechanical. A gradient caret sits flush after the last glyph: it stays solid while typing and, once the phrase completes, blinks with a soft 0.5 s ease-in-out fade. After a 1.4 s hold the line deletes backwards at roughly twice the typing speed and the next phrase begins; a tap backspaces in a quick burst and jumps to the next one — focused, alive, quietly confident.",
            "极简终端卡片中的等宽标题逐字打出，每次击键的间隔都带有约±30%的随机抖动，让节奏更像真人输入而非机械播放。渐变光标紧贴最后一个字符：输入过程中保持常亮，整句完成后以0.5秒缓入缓出的柔和淡入淡出闪烁。停留1.4秒后，文字以约两倍速度向后删除，随即开始下一句；轻点会快速退格并跳到下一句——专注、有生命力、从容而自信。"
        ),
        implementation: L(
            "An async .task loop appends characters with jittered Task.sleep delays; the caret blinks with phaseAnimator only while idle.",
            "在 .task 异步循环中按带抖动的 Task.sleep 间隔逐字追加字符；光标仅在空闲时通过 phaseAnimator 闪烁。"
        ),
        apis: [".task(id:)", "Task.sleep(for:)", "phaseAnimator", "monospaced font"],
        tags: ["typewriter", "typing", "caret", "cursor", "打字机", "打字", "光标", "逐字"],
        params: [
            .slider("speed", L("Typing speed", "打字速度"), 4...30, default: 14, step: 1, decimals: 0, unit: " cps"),
            .choice("caret", L("Caret", "光标样式"), [L("Bar", "竖线"), L("Block", "方块"), L("Underscore", "下划线")], default: 0),
        ]
    ) { ctx in
        TypewriterDemo(ctx: ctx)
    }
}

private struct TypewriterDemo: View {
    let ctx: DemoContext
    @State private var typed: String
    @State private var isTyping: Bool
    /// The phrase being typed; kept across restarts so a tap moves exactly one phrase forward.
    @State private var phraseIndex = 0
    /// Bumped by a tap: restarts the typing task on the next phrase.
    @State private var skips = 0

    init(ctx: DemoContext) {
        self.ctx = ctx
        // Still snapshots never run the typing task: show the first phrase fully typed.
        let first = ctx.language == .zh ? "好的设计，会在指尖轻轻呼吸。" : "Hello, world."
        _typed = State(initialValue: ctx.isStill ? first : "")
        _isTyping = State(initialValue: !ctx.isStill)
    }

    private var phrases: [String] {
        ctx.language == .zh
            // 14 full-width characters each: long enough to show the rhythm, short enough for one line at 17 pt.
            ? ["好的设计，会在指尖轻轻呼吸。", "让每一帧动效，都有它的理由。", "从灵感到上线，只差一次回车。"]
            : ["Hello, world.", "Design in motion.", "Every frame counts."]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            HStack(alignment: .center, spacing: 2) {
                Text(typed)
                    .font(.system(size: ctx.language == .zh ? 17 : 22, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Caret(style: ctx.int("caret"), isTyping: isTyping)
            }
            .frame(height: 40)
        }
        .padding(22)
        .frame(width: 316, alignment: .leading)
        .demoCard(cornerRadius: 24)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap for the next line", "点击输入下一句"), ctx: ctx)
                .offset(y: 34)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { skip() }
        .task(id: "\(ctx.language.rawValue)-\(ctx["speed"])-\(skips)") { await run() }
    }

    private func skip() {
        guard !ctx.isPreview, !ctx.isStill else { return }
        Haptics.tap(.light)
        phraseIndex += 1
        skips += 1
    }

    private var header: some View {
        HStack(spacing: 6) {
            ForEach([Palette.red, Palette.amber, Palette.green], id: \.self) { color in
                Circle().fill(color).frame(width: 9, height: 9)
            }
            Spacer()
            Text(verbatim: "~/motion")
                .font(.caption.monospaced())
                .foregroundStyle(.tertiary)
        }
    }

    private func run() async {
        let cps = max(ctx["speed"], 1)
        let list = phrases
        var index = phraseIndex
        // After a tap, backspace whatever is on the line in a quick burst before typing the next phrase.
        isTyping = true
        while !typed.isEmpty {
            typed.removeLast()
            try? await Task.sleep(for: .seconds(0.018))
            if Task.isCancelled { return }
        }
        while !Task.isCancelled {
            let characters = Array(list[index % list.count])
            isTyping = true
            for count in 1...max(characters.count, 1) {
                typed = String(characters.prefix(count))
                try? await Task.sleep(for: .seconds(Double.random(in: 0.7...1.3) / cps))
                if Task.isCancelled { return }
            }
            isTyping = false
            try? await Task.sleep(for: .seconds(1.4))
            if Task.isCancelled { return }
            isTyping = true
            while !typed.isEmpty {
                typed.removeLast()
                try? await Task.sleep(for: .seconds(0.5 / cps))
                if Task.isCancelled { return }
            }
            try? await Task.sleep(for: .seconds(0.25))
            if Task.isCancelled { return }
            index += 1
            phraseIndex = index
        }
    }
}

private struct Caret: View {
    let style: Int
    let isTyping: Bool

    var body: some View {
        shape
            .phaseAnimator([1.0, 0.0]) { view, phase in
                view.opacity(isTyping ? 1 : phase)
            } animation: { _ in
                .easeInOut(duration: 0.5)
            }
    }

    @ViewBuilder
    private var shape: some View {
        switch style {
        case 1:
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Palette.primary)
                .frame(width: 16, height: 30)
                .opacity(0.85)
        case 2:
            Capsule()
                .fill(Palette.primary)
                .frame(width: 16, height: 3.5)
                .frame(height: 30, alignment: .bottom)
        default:
            Capsule()
                .fill(Palette.primary)
                .frame(width: 3, height: 30)
        }
    }
}
