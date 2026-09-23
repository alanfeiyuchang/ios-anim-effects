import SwiftUI

extension Effect {
    static let inputsFloodToggle = Effect(
        id: "inputs.flood-toggle",
        category: .inputs,
        interaction: .tap,
        name: L("Radial Flood Toggle", "径向漫染开关"),
        summary: L("Colour floods out of the knob to fill the track, and drains back into it.", "颜色从旋钮处向外漫开铺满轨道，关闭时再收回旋钮。"),
        prompt: L(
            "A 96 × 52 pt switch on a Wi-Fi settings card. When turned on, the knob slides right on a snappy spring (response 0.32 s, damping 0.78) and, 50 ms later, a violet-to-indigo circle floods outward from the knob's landing point, scaling from 0 to cover the whole capsule in 420 ms on an ease-out curve, while a thin ring of the same colour keeps expanding beyond the track to 1.6× and fades — a ripple that says 'connected'. The Wi-Fi glyph fills in its bars one after another. Turning off reverses the choreography: the colour drains back into the right-hand point in 260 ms while the knob returns, leaving the neutral track. Liquid, confident and centred on the point of contact.",
            "Wi-Fi 设置卡片上的一枚 96 × 52pt 开关。开启时，旋钮以利落弹簧（响应 0.32 秒、阻尼 0.78）滑向右侧；50 毫秒后，一个紫到靛蓝的圆从旋钮落点向外漫开，在 420 毫秒内以缓出曲线从 0 放大到覆盖整个胶囊；同时一圈同色细环继续扩散到轨道之外 1.6 倍并淡出，像一次“已连接”的涟漪。Wi-Fi 图标的信号格依次填满。关闭时编排反向：颜色在 260 毫秒内收回到右侧落点，旋钮同步返回，只留下中性轨道。液态、笃定，一切围绕接触点展开。"
        ),
        implementation: L(
            "A Circle centred on the knob's on-position is scaled with scaleEffect and clipped to the Capsule track; a separate stroked ring outside the clip scales and fades, and the Wi-Fi glyph uses a variable-color symbol effect.",
            "以旋钮开启位置为圆心的 Circle 通过 scaleEffect 放大并被裁剪在 Capsule 轨道内；裁剪之外另有一圈描边环放大并淡出，Wi-Fi 图标使用 variableColor 符号特效。"
        ),
        apis: ["scaleEffect", "clipShape(Capsule())", "symbolEffect(.variableColor)", "spring(response:dampingFraction:)"],
        tags: ["toggle", "switch", "flood", "ripple", "开关", "漫染", "涟漪", "径向"],
        params: [
            .slider("flood", L("Flood duration", "漫染时长"), 0.2...0.9, default: 0.42, unit: "s"),
            .slider("response", L("Knob response", "旋钮响应"), 0.15...0.7, default: 0.32, unit: "s"),
            .toggle("ripple", L("Outer ripple", "外圈涟漪"), default: true),
        ]
    ) { ctx in
        FloodToggleDemo(ctx: ctx)
    }
}

private struct FloodToggleDemo: View {
    let ctx: DemoContext
    @State private var isOn = false
    @State private var flooded = false
    @State private var ripples = 0
    @State private var generation = 0

    private let trackWidth: CGFloat = 96
    private let trackHeight: CGFloat = 52
    private let inset: CGFloat = 5
    private var knob: CGFloat { trackHeight - inset * 2 }
    private var onCenterX: CGFloat { trackWidth - inset - knob / 2 }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            card
            Spacer()
            DemoHint(text: L("Tap the switch", "点击开关"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.6, delay: 0.4) { toggle() }
    }

    private var card: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .symbolEffect(.variableColor.iterative, options: .nonRepeating, value: isOn)
                .frame(width: 38, height: 38)
                .background(Palette.primary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: "Wi-Fi")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(isOn ? L("Connected · Studio 5G", "已连接 · Studio 5G") : L("Off", "已关闭"), ctx.language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .contentTransition(.opacity)
            }
            Spacer(minLength: 0)
            track
        }
        .padding(16)
        .frame(width: 310)
        .demoCard(cornerRadius: 24)
    }

    private var track: some View {
        let cover: CGFloat = trackWidth * 2.1
        return ZStack(alignment: .leading) {
            Capsule().fill(Color.primary.opacity(0.12))
            Circle()
                .fill(LinearGradient(colors: [Palette.violet, Palette.indigo], startPoint: .topTrailing, endPoint: .bottomLeading))
                .frame(width: cover, height: cover)
                .scaleEffect(flooded ? 1 : 0.001)
                .position(x: onCenterX, y: trackHeight / 2)
            Circle()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.18), radius: 5, y: 2)
                .frame(width: knob, height: knob)
                .offset(x: isOn ? trackWidth - inset - knob : inset)
        }
        .frame(width: trackWidth, height: trackHeight)
        .clipShape(Capsule())
        .background { ripple }
        .contentShape(Capsule())
        .onTapGesture { toggle() }
    }

    private var ripple: some View {
        Capsule()
            .strokeBorder(Palette.indigo, lineWidth: 2)
            .frame(width: trackWidth, height: trackHeight)
            .keyframeAnimator(initialValue: FloodRipple(), trigger: ripples) { content, value in
                content
                    .scaleEffect(value.scale)
                    .opacity(value.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    LinearKeyframe(1, duration: 0.01)
                    CubicKeyframe(1.6, duration: 0.6)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(0.7, duration: 0.01)
                    LinearKeyframe(0, duration: 0.6)
                }
            }
            .allowsHitTesting(false)
    }

    private func toggle() {
        generation += 1
        let current = generation
        let turningOn = !isOn
        let floodDuration = ctx["flood"]
        withAnimation(.spring(response: ctx["response"], dampingFraction: 0.78)) {
            isOn = turningOn
        }
        if !turningOn {
            withAnimation(.easeIn(duration: floodDuration * 0.62)) { flooded = false }
            return
        }
        let muted = ctx.isPreview || Haptics.isMuted
        Task {
            try? await Task.sleep(for: .seconds(0.05))
            guard current == generation else { return }
            if !muted { Haptics.tap() }
            withAnimation(.easeOut(duration: floodDuration)) { flooded = true }
            if ctx.bool("ripple") { ripples += 1 }
        }
    }
}

private struct FloodRipple {
    var scale: CGFloat = 1
    var opacity: Double = 0
}
