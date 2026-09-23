import SwiftUI

extension Effect {
    static let textElasticLetters = Effect(
        id: "text.elastic-letters",
        category: .text,
        interaction: .tap,
        name: L("Elastic Letters", "弹性字母"),
        summary: L("Each character pops up from a tilted seed and wobbles into place.", "每个字符从倾斜的小点弹出，摇摆着落位。"),
        prompt: L(
            "A two-line greeting (a 40 pt heavy rounded headline over a secondary 17 pt line) enters one character at a time. Every glyph starts at 20% scale, 24 pt below its baseline and tilted −25°, invisible, then springs to full size, upright, on an under-damped spring (response 0.5 s, damping 0.55) so it overshoots to ~110%, wobbles once and settles; characters follow each other every 40 ms and the second line begins after the first finishes. On replay the letters fade out in 200 ms before popping in again. A soft haptic ticks on start. The effect is buoyant and friendly, like letters inflating.",
            "一段两行问候语（上方 40 pt 粗圆体标题，下方 17 pt 次要文字）逐字入场。每个字形起始时缩到 20%、低于基线 24 pt、向左倾斜 25° 且完全透明，随后以欠阻尼弹簧（响应 0.5 秒、阻尼 0.55）弹到原大小并摆正——先冲到约 110%，摇晃一下再稳住；字符之间间隔 40 毫秒，第二行在第一行结束后开始。重播时字母先在 200 毫秒内淡出，再重新弹入，开始时伴随轻柔触感。整体轻盈友好，像字母被一个个吹鼓起来。"
        ),
        implementation: L(
            "The strings are split into characters laid out in an HStack; each Text gets scale, rotation, offset and opacity driven by one Bool through .animation(_:value:) with a spring delayed by its global index.",
            "将字符串拆成单个字符放进 HStack；每个 Text 的缩放、旋转、位移与透明度都由同一个 Bool 驱动，并通过 .animation(_:value:) 使用按全局序号延迟的弹簧。"
        ),
        apis: ["HStack", "scaleEffect(_:anchor:)", "rotationEffect(_:anchor:)", "spring(response:dampingFraction:)", "Animation.delay"],
        tags: ["letters", "pop", "elastic", "stagger", "逐字", "弹出", "弹性", "文字入场"],
        params: [
            .slider("stagger", L("Letter stagger", "字间隔"), 0.01...0.12, default: 0.04, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.3...1.0, default: 0.55),
            .slider("tilt", L("Start tilt", "起始倾角"), 0...60, default: 25, decimals: 0, unit: "°"),
        ]
    ) { ctx in
        ElasticLettersDemo(ctx: ctx)
    }
}

private struct ElasticLettersDemo: View {
    let ctx: DemoContext
    @State private var shown = true

    private var headline: [String] { (ctx.language == .zh ? "你好，世界！" : "Hello, world!").map { String($0) } }
    private var subline: [String] { (ctx.language == .zh ? "每一个字都在弹跳" : "every letter bounces in").map { String($0) } }

    var body: some View {
        VStack(spacing: 14) {
            letters(headline, offset: 0, size: 40, weight: .heavy, primary: true)
            letters(subline, offset: headline.count + 4, size: 17, weight: .semibold, primary: false)
            DemoHint(text: L("Tap to replay", "点击重播"), ctx: ctx)
                .padding(.top, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { replay() }
        .autoplay(ctx.isPreview, every: 3.0) { replay() }
    }

    private func letters(_ chars: [String], offset: Int, size: CGFloat, weight: Font.Weight, primary: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(chars.indices, id: \.self) { index in
                ElasticGlyph(
                    char: chars[index],
                    shown: shown,
                    tilt: ctx["tilt"],
                    animation: animation(for: offset + index)
                )
                .font(.system(size: size, weight: weight, design: .rounded))
                .foregroundStyle(primary ? AnyShapeStyle(Palette.sunset) : AnyShapeStyle(.secondary))
            }
        }
        .fixedSize()
    }

    private func animation(for index: Int) -> Animation {
        guard shown else { return .easeOut(duration: 0.2) }
        return .spring(response: 0.5, dampingFraction: ctx["damping"]).delay(Double(index) * ctx["stagger"])
    }

    private func replay() {
        if !ctx.isPreview { Haptics.tap(.soft) }
        shown = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            shown = true
        }
    }
}

private struct ElasticGlyph: View {
    let char: String
    let shown: Bool
    let tilt: Double
    let animation: Animation

    var body: some View {
        Text(verbatim: char)
            .scaleEffect(shown ? 1 : 0.2, anchor: .bottom)
            .rotationEffect(.degrees(shown ? 0 : -tilt), anchor: .bottom)
            .offset(y: shown ? 0 : 24)
            .opacity(shown ? 1 : 0)
            .animation(animation, value: shown)
    }
}
