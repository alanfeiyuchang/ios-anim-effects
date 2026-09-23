import SwiftUI

extension Effect {
    static let buttonsNeonBreath = Effect(
        id: "buttons.neon-breath",
        category: .buttons,
        interaction: .loop,
        name: L("Neon Breath", "霓虹呼吸"),
        summary: L("A neon tube glow that slowly breathes and flickers now and then, or on tap.", "缓慢呼吸的霓虹灯管辉光，不时自己闪烁，点击也会闪。"),
        prompt: L(
            "Mounted on a near-black wall panel (so it reads in light mode too), a dark capsule is outlined by a 2 pt electric-cyan neon tube, its label glowing in the same colour. The glow breathes on a slow sine (~2.4 s per cycle): stacked shadows swell from a tight 4 pt halo to a 22 pt bloom and back, the tube brightens by 0.25 at the peak, and a blurred floor reflection and a faint wash on the panel pulse in sync. Every few seconds (a random 2.8–5.5 s) the tube stutters on its own like an ageing sign. Tapping triggers the same flicker on demand — opacity 1 → 0.35 → 1 → 0.6 → 1 within ~350 ms — plus a light haptic. Atmospheric and nocturnal, like a sign humming in a rainy alley.",
            "按钮装在近黑墙面面板上（浅色模式同样醒目）：深色胶囊外圈是 2pt 电光青霓虹灯管，文字同色发光。辉光以约 2.4 秒一周期的正弦呼吸：多层阴影从 4pt 贴身光晕扩到 22pt 柔光再收回，峰值时灯管亮度提升 0.25，地面倒影与面板上的淡彩光晕同步明暗。每隔随机 2.8–5.5 秒，灯管会像老化的招牌一样自己闪一下；点击则随时触发同样的闪烁——约 350 毫秒内不透明度 1 → 0.35 → 1 → 0.6 → 1——并伴随轻触觉。像雨夜小巷里嗡嗡作响的招牌。"
        ),
        implementation: L(
            "TimelineView computes a sine-based breath value that scales layered shadows and stroke brightness; a keyframeAnimator keyed on a flicker counter plays the stutter on opacity, bumped by taps and by a task that sleeps a random 2.8–5.5 s between idle flickers.",
            "TimelineView 计算基于正弦的呼吸值，用于缩放多层阴影与描边亮度；以闪烁计数为触发的 keyframeAnimator 在不透明度上播放抖动，计数由点击以及一个每隔随机 2.8–5.5 秒唤醒的 task 递增。"
        ),
        apis: ["TimelineView", "shadow", "keyframeAnimator", "blur"],
        tags: ["neon", "glow", "breathing", "pulse", "霓虹", "呼吸灯", "辉光", "赛博"],
        params: [
            .slider("period", L("Breath period", "呼吸周期"), 1.0...5.0, default: 2.4, unit: "s"),
            .slider("bloom", L("Max bloom", "最大光晕"), 8...36, default: 22, decimals: 0, unit: "pt"),
            .toggle("flicker", L("Idle flicker", "待机闪烁"), default: true),
        ]
    ) { ctx in
        ButtonNeonBreathDemo(ctx: ctx)
    }
}

private struct ButtonNeonBreathDemo: View {
    let ctx: DemoContext
    @State private var flickers = 0

    private let neon = Color(hex: 0x3CF2FF)

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
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
            .padding(.horizontal, 36)
            .padding(.top, 58)
            .padding(.bottom, 34)
            .background { ButtonNeonPanel(language: ctx.language) }
            // Keep the coloured wash on the wall.
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            Spacer()
            DemoHint(text: L("Tap to flicker", "点击让它闪烁"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: ctx.bool("flicker")) { await idleFlicker() }
    }

    /// A failing-tube stutter every few seconds while idle; silent, unlike the tap.
    private func idleFlicker() async {
        guard ctx.bool("flicker") else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(Double.random(in: 2.8...5.5)))
            guard !Task.isCancelled else { return }
            flickers += 1
        }
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
                .background {
                    // Coloured wash spilling onto the wall, breathing with the tube.
                    RadialGradient(
                        colors: [neon.opacity(0.1 + 0.1 * breath), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 170
                    )
                    .frame(width: 320, height: 240)
                    .allowsHitTesting(false)
                }
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

/// The dark wall the sign hangs on, so the neon reads in light mode as well as dark.
private struct ButtonNeonPanel: View {
    let language: AppLanguage

    var body: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(LinearGradient(colors: [Color(hex: 0x161824), Color(hex: 0x06070B)], startPoint: .top, endPoint: .bottom))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08))
            )
            .overlay(alignment: .topLeading) {
                Text(L("Open late", "营业至深夜"), language)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.white.opacity(0.4))
                    .padding(18)
            }
    }
}
