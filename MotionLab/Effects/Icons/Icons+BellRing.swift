import SwiftUI

extension Effect {
    static let iconsBellRing = Effect(
        id: "icons.bell-ring",
        category: .icons,
        interaction: .tap,
        name: L("Bell Ring", "铃铛摇响"),
        summary: L("A pendulum swing with decaying keyframes and a popping badge.", "钟摆式摇动，关键帧逐渐衰减，角标随之弹出。"),
        prompt: L(
            "A notification bell hangs from its top hinge. On a new alert it rings like a real pendulum, swinging to +18°, −15°, +11°, −7°, +3° and back to rest about 0.12 s apart with cubic easing so the energy visibly decays, while the whole bell pulses to 112% on the first strike. Sound-wave arcs flare out on both sides and fade by 0.55 s, the red count badge punches to 125% and springs back as its number rolls up, and a frosted notification pill drops in 18 pt from above (growing from 92%) as the previous one sinks away. A medium haptic lands on the first strike: lively and physical, attention-getting without being alarming.",
            "通知铃铛以顶部为铰点悬挂。收到新提醒时，它像真正的钟摆一样摇响：依次摆到+18°、−15°、+11°、−7°、+3°再回到静止，每摆间隔约0.12秒，三次缓动让能量肉眼可见地衰减；第一下敲击时整只铃铛放大到112%。两侧声波弧线迸发，约0.55秒淡尽；红色角标弹到125%再回落，数字向上滚动；一枚磨砂通知胶囊从上方18 pt落下（由92%放大），旧通知向下沉没。第一下敲击伴随中等触感，生动有物理感，引人注意却不吓人。"
        ),
        implementation: L(
            "keyframeAnimator(initialValue:trigger:) with separate KeyframeTracks for angle (CubicKeyframes), scale and wave opacity (SpringKeyframes); rotationEffect is anchored at .top.",
            "keyframeAnimator(initialValue:trigger:) 为角度（CubicKeyframe）、缩放与声波透明度（SpringKeyframe）分别设置 KeyframeTrack；rotationEffect 以 .top 为锚点。"
        ),
        apis: ["keyframeAnimator", "KeyframeTrack", "CubicKeyframe", "SpringKeyframe"],
        tags: ["bell", "notification", "ring", "keyframes", "铃铛", "通知", "摇晃", "关键帧"],
        params: [
            .slider("amplitude", L("Swing angle", "摆动角度"), 6...30, default: 18, decimals: 0, unit: "°"),
            .slider("tempo", L("Tempo", "节奏"), 0.5...1.8, default: 1),
        ]
    ) { ctx in
        BellRingDemo(ctx: ctx)
    }
}

private let bellMessages: [(symbol: String, text: LocalizedText)] = [
    ("message.fill", L("Mia sent you a photo", "Mia 给你发了一张照片")),
    ("calendar", L("Design review in 10 min", "设计评审 10 分钟后开始")),
    ("shippingbox.fill", L("Your order has shipped", "你的订单已发货")),
    ("bubble.left.and.bubble.right.fill", L("3 new comments on “Aurora”", "「极光」有 3 条新评论")),
]

private let bellBannerTransition: AnyTransition = .asymmetric(
    insertion: .offset(y: -18).combined(with: .scale(scale: 0.92)).combined(with: .opacity),
    removal: .offset(y: 10).combined(with: .opacity)
)

private struct BellBanner: View {
    let message: (symbol: String, text: LocalizedText)
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: message.symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Palette.sunset, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(message.text, language)
                .font(.footnote.weight(.semibold))
                .lineLimit(1)
        }
        .padding(.leading, 8)
        .padding(.trailing, 14)
        .frame(height: 42)
        .demoGlass(Capsule(), material: .regularMaterial)
        .overlay(Capsule().strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(0.1), radius: 12, y: 6)
    }
}

private struct BellValues {
    var angle: Double = 0
    var scale: Double = 1
    var waves: Double = 0
    var badgeScale: Double = 1
}

private struct BellRingDemo: View {
    let ctx: DemoContext
    @State private var rings = 0
    @State private var badge = 2

    var body: some View {
        let badge = self.badge
        VStack(spacing: 24) {
            Color.clear
                .frame(width: 180, height: 150)
                .keyframeAnimator(initialValue: BellValues(), trigger: rings) { content, value in
                    content.overlay {
                        BellFace(value: value, badge: badge)
                    }
                } keyframes: { _ in
                    KeyframeTrack(\.angle) {
                        CubicKeyframe(amp, duration: step * 0.8)
                        CubicKeyframe(-amp * 0.85, duration: step)
                        CubicKeyframe(amp * 0.6, duration: step)
                        CubicKeyframe(-amp * 0.4, duration: step)
                        CubicKeyframe(amp * 0.18, duration: step)
                        CubicKeyframe(0, duration: step * 1.4)
                    }
                    KeyframeTrack(\.scale) {
                        SpringKeyframe(1.12, duration: 0.14 / tempo, spring: .snappy)
                        SpringKeyframe(1.0, duration: 0.5 / tempo, spring: .bouncy)
                    }
                    KeyframeTrack(\.badgeScale) {
                        LinearKeyframe(1, duration: 0.1 / tempo)
                        SpringKeyframe(1.25, duration: 0.12 / tempo, spring: .snappy)
                        SpringKeyframe(1.0, duration: 0.45 / tempo, spring: .bouncy)
                    }
                    KeyframeTrack(\.waves) {
                        LinearKeyframe(1, duration: 0.08 / tempo)
                        LinearKeyframe(1, duration: 0.18 / tempo)
                        CubicKeyframe(0, duration: 0.3 / tempo)
                    }
                }
            ZStack {
                BellBanner(message: bellMessages[badge % bellMessages.count], language: ctx.language)
                    .id(badge)
                    .transition(bellBannerTransition)
            }
            .frame(height: 50)
            DemoHint(text: L("Tap to ring", "点击摇铃"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { ring() }
        .autoplay(ctx.isPreview, every: 1.8, delay: 0.3) { ring() }
    }

    private var tempo: Double { max(ctx["tempo"], 0.1) }

    private var amp: Double { ctx["amplitude"] }
    private var step: Double { 0.12 / tempo }

    private func ring() {
        rings += 1
        withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
            badge = badge >= 99 ? 1 : badge + 1
        }
        if !ctx.isPreview { Haptics.tap(.medium) }
    }
}

private struct BellFace: View {
    let value: BellValues
    let badge: Int

    var body: some View {
        ZStack {
            HStack(spacing: 84) {
                Image(systemName: "wave.3.left")
                Image(systemName: "wave.3.right")
            }
            .font(.system(size: 26, weight: .semibold))
            .foregroundStyle(Palette.amber)
            .opacity(value.waves)
            .scaleEffect(CGFloat(0.85 + value.waves * 0.15))

            Image(systemName: "bell.fill")
                .font(.system(size: 76, weight: .semibold))
                .foregroundStyle(Palette.sunset)
                .overlay(alignment: .topTrailing) {
                    BadgeCount(count: badge)
                        .scaleEffect(CGFloat(value.badgeScale))
                        .offset(x: 12, y: -8)
                }
                .rotationEffect(.degrees(value.angle), anchor: .top)
                .scaleEffect(CGFloat(value.scale))
                .shadow(color: Palette.coral.opacity(0.35), radius: 16, y: 10)
        }
    }
}

private struct BadgeCount: View {
    let count: Int

    var body: some View {
        Text(verbatim: "\(count)")
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
            .contentTransition(.numericText(value: Double(count)))
            .padding(.horizontal, 7)
            .frame(minWidth: 26, minHeight: 26)
            .background(Palette.red, in: Capsule())
            .overlay(Capsule().strokeBorder(.white, lineWidth: 2))
    }
}
