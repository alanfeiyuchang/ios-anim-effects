import SwiftUI

extension Effect {
    static let iconsVariableColor = Effect(
        id: "icons.variable-color",
        category: .icons,
        interaction: .state,
        name: L("Variable Color On Air", "可变颜色直播"),
        summary: L("Broadcast waves fill up cumulatively like a live level meter while on air, then rest at the volume level.", "直播时广播声波像电平表一样累积填满，暂停后停在当前音量档位。"),
        prompt: L(
            "An “On Air” card holds three broadcast glyphs — a speaker with sound waves, a radio-wave dot and an antenna — above a status row with a pulsing red dot. While live, the layers fill cumulatively from the source outward and drain back, like a level meter breathing with the audio (≈1 s per cycle, unlit layers at ~35% opacity). Tapping pauses the broadcast: the sweep stops and each glyph rests at the current volume level, e.g. two of three waves lit, while the status icon swaps from a waveform to a pause symbol with a replace transition and a soft tap haptic. No connect, no success check — just a calm, steady pulse of live sound.",
            "「直播中」卡片里有三枚广播图标——带声波的扬声器、发射电波的圆点和天线——下方是带红点脉动的状态行。直播时各图层从声源向外累积点亮再回落，像随声音呼吸的电平表（约1秒一个周期，未亮图层约35%不透明度）。轻点暂停：扫动停止，每个图标停在当前音量档位（例如三道声波亮两道），状态图标以替换过渡从波形切换为暂停符号，并伴随轻柔触感。没有连接、没有成功对勾，只有平稳而冷静的现场声音脉动。"
        ),
        implementation: L(
            "An indefinite .symbolEffect(.variableColor.cumulative.reversing, options: .speed(_:), isActive:) bound to an on-air flag; paused glyphs use Image(systemName:variableValue:) for the volume level and the status glyph uses .contentTransition(.symbolEffect(.replace)).",
            "无限循环的 .symbolEffect(.variableColor.cumulative.reversing, options: .speed(_:), isActive:) 绑定到直播状态；暂停时用 Image(systemName:variableValue:) 显示音量档位，状态图标使用 .contentTransition(.symbolEffect(.replace))。"
        ),
        apis: ["symbolEffect(_:options:isActive:)", "VariableColorSymbolEffect", "Image(systemName:variableValue:)", "contentTransition(.symbolEffect(.replace))"],
        tags: ["variable color", "on air", "broadcast", "volume", "level meter", "可变颜色", "直播", "音量"],
        params: [
            .choice("mode", L("Fill mode", "填充方式"), [L("Iterative", "逐层"), L("Cumulative", "累积")], default: 1),
            .toggle("reversing", L("Reversing", "往返"), default: true),
            .slider("speed", L("Speed", "速度"), 0.5...2, default: 1),
            .slider("level", L("Paused volume", "暂停音量"), 0...1, default: 0.66),
        ]
    ) { ctx in
        VariableColorDemo(ctx: ctx)
    }
}

private struct VariableColorDemo: View {
    let ctx: DemoContext
    @State private var live = true

    private var effect: VariableColorSymbolEffect {
        let base: VariableColorSymbolEffect = ctx.int("mode") == 1 ? .variableColor.cumulative : .variableColor.iterative
        return ctx.bool("reversing") ? base.reversing : base.nonReversing
    }

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 22) {
                HStack(spacing: 30) {
                    glyph("speaker.wave.3.fill", tint: Palette.violet)
                    glyph("dot.radiowaves.left.and.right", tint: Palette.pink)
                    glyph("antenna.radiowaves.left.and.right", tint: Palette.coral)
                }
                statusRow
            }
            .padding(.vertical, 26)
            .frame(width: 280)
            .demoCard(cornerRadius: 26)
            DemoHint(text: L("Tap to pause or go live", "点击暂停或开始直播"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { toggle() }
        .autoplay(ctx.isPreview, every: 2.4) { toggle() }
    }

    private func glyph(_ name: String, tint: Color) -> some View {
        // Paused: the layers rest at the volume level. Live: the variable-colour sweep takes over.
        let level: Double = live ? 1 : ctx["level"]
        return Image(systemName: name, variableValue: level)
            .font(.system(size: 40, weight: .semibold))
            .foregroundStyle(tint)
            .symbolEffect(effect, options: .speed(ctx["speed"]), isActive: live)
            .frame(width: 56, height: 50)
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Image(systemName: live ? "waveform" : "pause.circle.fill")
                .foregroundStyle(live ? Palette.red : Color.secondary)
                .contentTransition(.symbolEffect(.replace))
            Text(live ? L("On Air", "直播中") : L("Paused", "已暂停"), ctx.language)
                .foregroundStyle(live ? Color.primary : Color.secondary)
                .contentTransition(.opacity)
            Circle()
                .fill(Palette.red)
                .frame(width: 8, height: 8)
                .phaseAnimator([1.0, 0.35]) { dot, phase in
                    dot.opacity(live ? phase : 0)
                } animation: { _ in
                    .easeInOut(duration: 0.6)
                }
        }
        .font(.headline)
    }

    private func toggle() {
        withAnimation(.snappy) { live.toggle() }
        if !ctx.isPreview { Haptics.tap(.soft) }
    }
}
