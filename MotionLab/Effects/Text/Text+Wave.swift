import SwiftUI

extension Effect {
    static let textWave = Effect(
        id: "text.wave",
        category: .text,
        interaction: .loop,
        name: L("Glyph Wave", "字符波浪"),
        summary: L("Every glyph bobs and tilts on a travelling sine wave.", "每个字形沿行进的正弦波起伏、轻轻摆动。"),
        prompt: L(
            "A bold, rounded headline filled with a sunset gradient ripples like a flag: every glyph rises and falls on a continuous sine wave that travels left-to-right, each character phase-shifted from its neighbour so a smooth crest rolls through the word. As a glyph crests it also tilts a few degrees around its own centre, following the slope of the wave, and an optional slow hue drift shifts colour along the line. Touching and holding swells the amplitude by up to 90% within ~0.2 s, easing back on release. The loop is seamless and frame-locked at 60/120 fps — playful yet controlled, like type floating on water.",
            "粗体圆角标题填充日落渐变，像旗帜一样荡漾：每个字形沿一条从左向右行进的连续正弦波上下起伏，相邻字符之间存在相位差，让一道平滑的波峰滚过整个单词。字形到达波峰时，还会围绕自身中心顺着波形斜率轻微倾斜数度；可选的缓慢色相漂移让颜色沿着文字流动。按住舞台时振幅约0.2秒内增大至多90%，松手后回落。循环无缝，与60/120帧刷新同步——俏皮而不失控制，仿佛文字漂浮在水面上。"
        ),
        implementation: L(
            "A custom TextRenderer (iOS 18) iterates Text.Layout lines → runs → glyphs and offsets/rotates each glyph's GraphicsContext; a TimelineView(.animation) feeds it the time. A long press reports onPressingChanged to set a swell target that the timeline approaches exponentially.",
            "自定义 TextRenderer（iOS 18）遍历 Text.Layout 的行 → Run → 字形，对每个字形的 GraphicsContext 施加位移与旋转；TimelineView(.animation) 提供时间。长按手势的 onPressingChanged 设定涌起目标，由时间线按指数曲线逼近。"
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
    /// Swell level (0 at rest, 1 while held) approaches its target exponentially from `swellFrom`,
    /// evaluated per frame inside the timeline so the amplitude never jumps.
    @State private var swellFrom: Double = 0
    @State private var swellTarget: Double = 0
    @State private var swellChanged = Date.distantPast
    /// Wave phase carried over from earlier speeds, so moving the Speed slider changes the pace, not the shape.
    @State private var phaseShift: Double = 0

    var body: some View {
        VStack(spacing: 18) {
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let phase = Self.clock(timeline.date) * ctx["speed"] + phaseShift
                let gain = 1 + 0.9 * swell(at: timeline.date)
                // Leave room for both lines' vertical travel so they never collide, even fully swollen.
                VStack(spacing: 6 + ctx.cg("amplitude") * 1.4 * 1.9) {
                    Text(L("Good Vibes", "律动文字"), ctx.language)
                        .font(.system(size: 50, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.sunset)
                        .textRenderer(renderer(phase: phase, scale: gain))
                    Text(L("every glyph is alive", "每个字形都在呼吸"), ctx.language)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .textRenderer(renderer(phase: phase - 0.4 * ctx["speed"], scale: 0.4 * gain))
                }
            }
            DemoHint(text: L("Touch and hold to swell the wave", "按住让波浪涌起"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        // A long press never claims a pan, so vertical swipes still scroll the page. The very long
        // minimum duration keeps it "pressing" for as long as the finger stays down.
        .onLongPressGesture(minimumDuration: 30, maximumDistance: 24) {} onPressingChanged: { pressing in
            setSwell(pressing)
        }
        .onChange(of: ctx["speed"]) { old, new in
            phaseShift += Self.clock(Date()) * (old - new)
        }
    }

    private static func clock(_ date: Date) -> Double {
        date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 10_000)
    }

    private func swell(at date: Date) -> Double {
        let elapsed = max(date.timeIntervalSince(swellChanged), 0)
        return swellTarget + (swellFrom - swellTarget) * exp(-elapsed / 0.18)
    }

    private func setSwell(_ pressing: Bool) {
        guard !ctx.isPreview else { return }
        let now = Date()
        swellFrom = swell(at: now)
        swellTarget = pressing ? 1 : 0
        swellChanged = now
        if pressing { Haptics.tap(.soft) }
    }

    private func renderer(phase: Double, scale: Double) -> WaveRenderer {
        WaveRenderer(
            time: phase,
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
