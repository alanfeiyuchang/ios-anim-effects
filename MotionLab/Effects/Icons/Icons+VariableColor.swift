import SwiftUI

extension Effect {
    static let iconsVariableColor = Effect(
        id: "icons.variable-color",
        category: .icons,
        interaction: .state,
        name: L("Variable Color Signal", "可变颜色信号"),
        summary: L("Wi-Fi, speaker and signal bars sweep while searching.", "Wi-Fi、扬声器与信号格在搜索时逐层扫动。"),
        prompt: L(
            "A connection card shows three signal glyphs — Wi-Fi, cellular bars and a speaker with sound waves — beside a status label. While the device is searching, the symbol layers light up one after another from the innermost arc outward and then dim back, a continuous variable-colour sweep (≈1 s per cycle) with inactive layers at ~35% opacity. When the connection lands, the sweep stops on the fully lit state, the status icon swaps to a green checkmark with a replace transition and a success haptic fires. Informative, calm and system-native.",
            "连接卡片中并排显示三个信号图标——Wi-Fi、蜂窝信号格和带声波的扬声器——旁边是状态文字。设备搜索时，符号的各个图层从最内侧的弧线开始逐层点亮再回落变暗，形成连续的可变颜色扫动（约 1 秒一个周期），未激活图层保持约 35% 的不透明度。连接成功后扫动停在全部点亮的状态，状态图标以替换过渡切换为绿色对勾，并触发成功触感。信息清晰、冷静，完全系统原生。"
        ),
        implementation: L(
            "An indefinite .symbolEffect(.variableColor.iterative.reversing, options: .speed(_:), isActive:) bound to a searching flag; the status glyph uses .contentTransition(.symbolEffect(.replace)).",
            "无限循环的 .symbolEffect(.variableColor.iterative.reversing, options: .speed(_:), isActive:) 绑定到搜索状态；状态图标使用 .contentTransition(.symbolEffect(.replace))。"
        ),
        apis: ["symbolEffect(_:options:isActive:)", "VariableColorSymbolEffect", "contentTransition(.symbolEffect(.replace))"],
        tags: ["variable color", "wifi", "signal", "searching", "可变颜色", "信号", "无线", "搜索中"],
        params: [
            .choice("mode", L("Fill mode", "填充方式"), [L("Iterative", "逐层"), L("Cumulative", "累积")], default: 0),
            .toggle("reversing", L("Reversing", "往返"), default: true),
            .slider("speed", L("Speed", "速度"), 0.5...2, default: 1),
        ]
    ) { ctx in
        VariableColorDemo(ctx: ctx)
    }
}

private struct VariableColorDemo: View {
    let ctx: DemoContext
    @State private var searching = true

    private var effect: VariableColorSymbolEffect {
        let base: VariableColorSymbolEffect = ctx.int("mode") == 1 ? .variableColor.cumulative : .variableColor.iterative
        return ctx.bool("reversing") ? base.reversing : base.nonReversing
    }

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 22) {
                HStack(spacing: 30) {
                    glyph("wifi", tint: Palette.blue)
                    glyph("cellularbars", tint: Palette.mint)
                    glyph("speaker.wave.3.fill", tint: Palette.violet)
                }
                statusRow
            }
            .padding(.vertical, 26)
            .frame(width: 280)
            .demoCard(cornerRadius: 26)
            DemoHint(text: L("Tap to toggle searching", "点击切换搜索状态"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { toggle() }
        .autoplay(ctx.isPreview, every: 2.4) { toggle() }
    }

    private func glyph(_ name: String, tint: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: 40, weight: .semibold))
            .foregroundStyle(tint)
            .symbolEffect(effect, options: .speed(ctx["speed"]), isActive: searching)
            .frame(width: 56, height: 50)
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Image(systemName: searching ? "antenna.radiowaves.left.and.right" : "checkmark.circle.fill")
                .foregroundStyle(searching ? Color.secondary : Palette.green)
                .contentTransition(.symbolEffect(.replace))
            Text(searching ? L("Searching…", "正在搜索…") : L("Connected", "已连接"), ctx.language)
                .foregroundStyle(searching ? Color.secondary : Color.primary)
                .contentTransition(.opacity)
        }
        .font(.headline)
    }

    private func toggle() {
        withAnimation(.snappy) { searching.toggle() }
        if !ctx.isPreview && !searching { Haptics.success() }
    }
}
