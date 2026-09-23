import SwiftUI

extension Effect {
    static let textWave = Effect(
        id: "text.wave",
        category: .text,
        interaction: .loop,
        name: L("Glyph Wave", "字符波浪"),
        summary: L("Every glyph bobs and tilts on a travelling sine wave.", "每个字形沿行进的正弦波起伏、轻轻摆动。"),
        prompt: L(
            "A bold, rounded headline filled with a sunset gradient ripples like a flag: every glyph rises and falls on a continuous sine wave that travels left-to-right, each character phase-shifted from its neighbour so a smooth crest rolls through the word. As a glyph crests it also tilts a few degrees around its own centre, following the slope of the wave, and an optional slow hue drift shifts colour along the line. The loop is seamless and frame-locked at 60/120 fps — playful yet controlled, like type floating on water.",
            "粗体圆角标题填充日落渐变，像旗帜一样荡漾：每个字形沿一条从左向右行进的连续正弦波上下起伏，相邻字符之间存在相位差，让一道平滑的波峰滚过整个单词。字形到达波峰时，还会围绕自身中心顺着波形斜率轻微倾斜数度；可选的缓慢色相漂移让颜色沿着文字流动。循环无缝，与 60/120 帧刷新同步——俏皮而不失控制，仿佛文字漂浮在水面上。"
        ),
        implementation: L(
            "A custom TextRenderer (iOS 18) iterates Text.Layout lines → runs → glyphs and offsets/rotates each glyph's GraphicsContext; a TimelineView(.animation) feeds it the time.",
            "自定义 TextRenderer（iOS 18）遍历 Text.Layout 的行 → Run → 字形，对每个字形的 GraphicsContext 施加位移与旋转；TimelineView(.animation) 提供时间。"
        ),
        apis: ["TextRenderer", "Text.Layout", "GraphicsContext", "TimelineView(.animation)"],
        tags: ["wave", "kinetic", "sine", "glyph", "波浪", "律动", "动态文字", "逐字"],
        params: [
            .slider("amplitude", L("Amplitude", "振幅"), 0...20, default: 8, decimals: 0, unit: "pt"),
            .slider("speed", L("Speed", "速度"), 0.3...3, default: 1.2),
            .slider("spread", L("Phase per glyph", "字符相位差"), 0.1...1.2, default: 0.45),
            .toggle("hue", L("Hue drift", "色相漂移"), default: false),
        ]
    ) { ctx in
        WaveDemo(ctx: ctx)
    }
}

private struct WaveDemo: View {
    let ctx: DemoContext

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 10_000)
            VStack(spacing: 6) {
                Text(ctx.language == .zh ? "律动文字" : "Good Vibes")
                    .font(.system(size: 58, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.sunset)
                    .textRenderer(renderer(time: time, scale: 1))
                Text(ctx.language == .zh ? "每个字形都在呼吸" : "every glyph is alive")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .textRenderer(renderer(time: time - 0.4, scale: 0.4))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func renderer(time: Double, scale: Double) -> WaveRenderer {
        WaveRenderer(
            time: time * ctx["speed"],
            amplitude: ctx["amplitude"] * scale,
            spread: ctx["spread"],
            hueDrift: ctx.bool("hue")
        )
    }
}

private struct WaveRenderer: TextRenderer {
    var time: Double
    var amplitude: Double
    var spread: Double
    var hueDrift: Bool

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        var index = 0
        for line in layout {
            for run in line {
                for glyph in run {
                    let phase = time * 4 - Double(index) * spread
                    let rect = glyph.typographicBounds.rect
                    var copy = context
                    copy.translateBy(x: 0, y: CGFloat(sin(phase) * amplitude))
                    copy.translateBy(x: rect.midX, y: rect.midY)
                    copy.rotate(by: .degrees(cos(phase) * amplitude * 0.6))
                    copy.translateBy(x: -rect.midX, y: -rect.midY)
                    if hueDrift {
                        copy.addFilter(.hueRotation(.degrees(Double(index) * 14 + time * 40)))
                    }
                    copy.draw(glyph)
                    index += 1
                }
            }
        }
    }
}
