import SwiftUI

extension Effect {
    static let buttonsNeonBreath = Effect(
        id: "buttons.neon-breath",
        category: .buttons,
        interaction: .loop,
        name: L("Neon Breath", "霓虹呼吸"),
        summary: L("A neon tube glow that slowly breathes and flickers on tap.", "缓慢呼吸的霓虹灯管辉光，点击时闪烁。"),
        prompt: L(
            "A dark capsule outlined by a 2 pt neon tube in electric cyan, with the label set in the same glowing color. The glow breathes on a slow sine wave (~2.4 s per cycle): stacked shadows swell from a tight 4 pt halo to a 22 pt bloom and back, while the tube’s brightness lifts by 0.25 at the peak; a blurred reflection pools on the floor below and pulses in sync. Tapping the button triggers a quick neon-sign flicker — opacity stutters 1 → 0.35 → 1 → 0.6 → 1 within ~350 ms — plus a light haptic. It feels atmospheric and nocturnal, like a sign humming in a rainy alley.",
            "深色胶囊按钮，外圈是一条 2pt 的电光青色霓虹灯管，文字也使用同色发光。辉光以缓慢的正弦节奏呼吸（每周期约 2.4 秒）：多层阴影从紧贴的 4pt 光晕扩散到 22pt 的柔光再收回，灯管在峰值时亮度提升 0.25；下方地面有一片模糊的倒影同步明暗。点击按钮会触发一次霓虹招牌般的闪烁——不透明度在约 350 毫秒内按 1 → 0.35 → 1 → 0.6 → 1 抖动——并伴随轻触觉。氛围感十足，像雨夜小巷里嗡嗡作响的霓虹招牌。"
        ),
        implementation: L(
            "TimelineView computes a sine-based breath value that scales layered shadows and stroke brightness; a keyframeAnimator keyed on a tap counter plays the flicker on opacity.",
            "TimelineView 计算基于正弦的呼吸值，用于缩放多层阴影与描边亮度；以点击计数为触发的 keyframeAnimator 在不透明度上播放闪烁。"
        ),
        apis: ["TimelineView", "shadow", "keyframeAnimator", "blur"],
        tags: ["neon", "glow", "breathing", "pulse", "霓虹", "呼吸灯", "辉光", "赛博"],
        params: [
            .slider("period", L("Breath period", "呼吸周期"), 1.0...5.0, default: 2.4, unit: "s"),
            .slider("bloom", L("Max bloom", "最大光晕"), 8...36, default: 22, decimals: 0, unit: "pt"),
            .choice("color", L("Tube color", "灯管颜色"), [L("Cyan", "青"), L("Magenta", "洋红"), L("Lime", "荧光绿")], default: 0),
        ]
    ) { ctx in
        ButtonNeonBreathDemo(ctx: ctx)
    }
}

private struct ButtonNeonBreathDemo: View {
    let ctx: DemoContext
    @State private var flickers = 0

    private var neon: Color {
        switch ctx.int("color") {
        case 1: return Color(hex: 0xFF4FD8)
        case 2: return Color(hex: 0x9DFF4F)
        default: return Color(hex: 0x3CF2FF)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            TimelineView(.animation) { timeline in
                ButtonNeonTube(
                    breath: breath(at: timeline.date),
                    bloom: ctx.cg("bloom"),
                    neon: neon,
                    title: ctx.language == .zh ? "进入夜场" : "ENTER"
                )
            }
            .keyframeAnimator(initialValue: 1.0, trigger: flickers) { content, value in
                content.opacity(value)
            } keyframes: { _ in
                KeyframeTrack(\.self) {
                    LinearKeyframe(0.35, duration: 0.05)
                    LinearKeyframe(1, duration: 0.06)
                    LinearKeyframe(0.6, duration: 0.08)
                    LinearKeyframe(1, duration: 0.16)
                }
            }
            .contentShape(Capsule())
            .onTapGesture {
                flickers += 1
                Haptics.tap()
            }
            Spacer()
            DemoHint(text: L("Tap to flicker", "点击让它闪烁"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func breath(at date: Date) -> Double {
        let period = max(ctx["period"], 0.2)
        let t = date.timeIntervalSinceReferenceDate
        return (sin(t / period * 2 * .pi) + 1) / 2
    }
}

private struct ButtonNeonTube: View {
    let breath: Double
    let bloom: CGFloat
    let neon: Color
    let title: String

    var body: some View {
        let glow = 4 + (bloom - 4) * CGFloat(breath)
        VStack(spacing: 14) {
            face(glow: glow)
            Capsule()
                .fill(neon)
                .frame(width: 180, height: 14)
                .blur(radius: 16)
                .opacity(0.15 + 0.25 * breath)
        }
    }

    private func face(glow: CGFloat) -> some View {
        Text(title)
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .tracking(4)
            .foregroundStyle(neon)
            .shadow(color: neon.opacity(0.9), radius: glow * 0.35)
            .frame(width: 210, height: 62)
            .background(Color(hex: 0x0A0B12), in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(neon, lineWidth: 2)
                    .brightness(0.25 * breath)
                    .shadow(color: neon, radius: glow * 0.25)
                    .shadow(color: neon.opacity(0.7), radius: glow)
            )
    }
}
