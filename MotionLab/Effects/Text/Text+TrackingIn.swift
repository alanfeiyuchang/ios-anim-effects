import SwiftUI

extension Effect {
    static let textTrackingIn = Effect(
        id: "text.tracking-in",
        category: .text,
        interaction: .tap,
        name: L("Tracking-In Contract", "字距收拢入场"),
        summary: L("Wide-spaced, blurred letters contract into a tight wordmark.", "字距拉开、模糊的字母收拢成紧凑的字标。"),
        prompt: L(
            "A logotype-style wordmark in 46 pt black caps starts with its letters spread 26 pt apart, blurred by 12 pt, scaled to 115% and fully transparent. On trigger, the letter spacing collapses to 2 pt over 0.9 s on an ease-out-cubic curve (cubic-bezier 0.215, 0.61, 0.355, 1) while the blur clears and opacity climbs to 100%, so the word appears to condense out of fog. The outermost letters travel furthest; the centre stays nearly fixed. A thin gradient rule then draws outward from the centre and a small tagline tracks in 250 ms later with the same motion at half the spacing. It reads as premium brand-film typography: calm, confident, expensive.",
            "一个46 pt粗黑大写的字标，起始时字母间距拉开到26 pt，模糊12 pt、放大到115%且完全透明。触发后，字距以三次缓出曲线（cubic-bezier 0.215, 0.61, 0.355, 1）在0.9秒内收拢到2 pt，同时模糊散去、不透明度升至100%，仿佛文字从雾中凝结出来。最外侧的字母移动最远，中间几乎不动。随后一条细渐变线从中心向两侧画出，250毫秒后一行小标语以同样的动作、一半的字距收拢入场。像高端品牌片的字体动画：沉稳、有质感。"
        ),
        implementation: L(
            "Letters sit in a fixed-size HStack whose spacing animates between two values, so SwiftUI interpolates each glyph's position symmetrically around the centre; blur, scale and opacity share the same timing curve.",
            "字母放在固定尺寸的 HStack 中，间距在两个数值之间动画，SwiftUI 会围绕中心对称地插值每个字形的位置；模糊、缩放与透明度共用同一条时间曲线。"
        ),
        apis: ["HStack(spacing:)", "timingCurve(_:_:_:_:duration:)", "blur(radius:)", "fixedSize()", "scaleEffect"],
        tags: ["tracking", "letter spacing", "logo", "wordmark", "字距", "字标", "品牌", "入场"],
        params: [
            .slider("spread", L("Start spacing", "起始字距"), 8...40, default: 26, decimals: 0, unit: "pt"),
            .slider("duration", L("Duration", "时长"), 0.4...2.0, default: 0.9, unit: "s"),
            .slider("blur", L("Start blur", "起始模糊"), 0...24, default: 12, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        TrackingInDemo(ctx: ctx)
    }
}

private struct TrackingInDemo: View {
    let ctx: DemoContext
    @State private var shown = true

    private var word: [String] { (ctx.language == .zh ? "动效词典" : "MOTIONARY").map { String($0) } }
    private var tagline: [String] { (ctx.language == .zh ? "让界面动起来" : "MOTION, DEFINED").map { String($0) } }

    var body: some View {
        VStack(spacing: 14) {
            TrackingLine(
                chars: word,
                shown: shown,
                spread: ctx.cg("spread"),
                blur: ctx.cg("blur"),
                animation: curve(delay: 0)
            )
            .font(.system(size: 46, weight: .black))
            .foregroundStyle(.primary)
            rule
            TrackingLine(
                chars: tagline,
                shown: shown,
                spread: ctx.cg("spread") * 0.5,
                blur: ctx.cg("blur") * 0.5,
                animation: curve(delay: 0.25)
            )
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.secondary)
            DemoHint(text: L("Tap to replay", "点击重播"), ctx: ctx)
                .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { replay() }
        .autoplay(ctx.isPreview, every: ctx["duration"] + 1.8) { replay() }
    }

    private var rule: some View {
        Capsule()
            .fill(LinearGradient(colors: [Palette.amber.opacity(0), Palette.coral, Palette.amber.opacity(0)], startPoint: .leading, endPoint: .trailing))
            .frame(width: 180, height: 2)
            .scaleEffect(x: shown ? 1 : 0, y: 1)
            .animation(shown ? .spring(response: 0.6, dampingFraction: 0.9).delay(ctx["duration"] * 0.6) : .easeOut(duration: 0.2), value: shown)
    }

    private func curve(delay: Double) -> Animation {
        guard shown else { return .easeOut(duration: 0.2) }
        return .timingCurve(0.215, 0.61, 0.355, 1, duration: ctx["duration"]).delay(delay)
    }

    private func replay() {
        if !ctx.isPreview { Haptics.tap(.soft) }
        shown = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            shown = true
        }
    }
}

private struct TrackingLine: View {
    let chars: [String]
    let shown: Bool
    let spread: CGFloat
    let blur: CGFloat
    let animation: Animation

    var body: some View {
        HStack(spacing: shown ? 2 : spread) {
            ForEach(chars.indices, id: \.self) { index in
                Text(verbatim: chars[index])
            }
        }
        .fixedSize()
        .scaleEffect(shown ? 1 : 1.15)
        .blur(radius: shown ? 0 : blur)
        .opacity(shown ? 1 : 0)
        .animation(animation, value: shown)
    }
}
