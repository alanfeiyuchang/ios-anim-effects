import SwiftUI

extension Effect {
    static let buttonsHoldCharge = Effect(
        id: "buttons.hold-charge",
        category: .buttons,
        interaction: .gesture,
        name: L("Charge & Launch", "蓄力发射"),
        summary: L("Holding compresses and rattles the button with growing energy until it launches.", "按住时按钮被压缩并越抖越厉害，蓄满后一飞冲天。"),
        prompt: L(
            "A 120 pt rounded-square launch key with a paper-plane glyph on a violet-to-pink gradient,. While held for 1.4 s the key compresses with an ease-in from 100% to 86%, its glow swells from 10 to 30 pt, and a jitter builds with the charge: a fast ~40 Hz shake whose amplitude grows from 0 to 3 pt and a ±2° wobble, so it visibly strains. Releasing early lets it spring back with a bouncy overshoot (response 0.4 s, damping 0.5). When fully charged the key snaps to 115% and settles, the plane shoots 140 pt up while fading, leaving a short gradient exhaust trail, and a heavy then success haptic fire; after 1.2 s a fresh plane drops back in. Energetic, playful and physical.",
            "一枚 120pt 的圆角方形发射键，紫罗兰到粉色渐变，中间是纸飞机。按住 1.4 秒期间，按键以 ease-in 从 100% 压到 86%，辉光从 10pt 涨到 30pt，并随蓄力抖动：约 40 Hz 震颤幅度从 0 增至 3pt，外加 ±2° 摇晃，像在憋劲。中途松手则带过冲弹回（响应 0.4 秒、阻尼 0.5）。蓄满时按键弹到 115% 再落定，纸飞机拖着渐变尾焰向上冲出 140pt 并淡出，先后触发重触感与成功触感；1.2 秒后新纸飞机落回。充满能量。"
        ),
        implementation: L(
            "onLongPressGesture's onPressingChanged records the hold start; a TimelineView derives charge = elapsed / duration and turns it into sine jitter, wobble and glow, while scale uses a separate easeIn animation. Completion runs a keyframeAnimator for the launch.",
            "onLongPressGesture 的 onPressingChanged 记录按住开始的时间；TimelineView 由此计算蓄力值 = 已用时长 / 总时长，并转换为正弦抖动、摇晃与辉光，缩放则由独立的 easeIn 动画驱动。完成时由 keyframeAnimator 播放发射。"
        ),
        apis: ["onLongPressGesture(minimumDuration:perform:onPressingChanged:)", "TimelineView", "keyframeAnimator", "easeIn(duration:)", "rotationEffect"],
        tags: ["hold", "charge", "launch", "shake", "长按", "蓄力", "发射", "抖动"],
        params: [
            .slider("duration", L("Charge time", "蓄力时长"), 0.6...2.5, default: 1.4, unit: "s"),
            .slider("shake", L("Max shake", "最大抖动"), 0...6, default: 3, decimals: 1, unit: "pt"),
            .slider("squeeze", L("Squeeze", "压缩程度"), 0.75...0.98, default: 0.86),
        ]
    ) { ctx in
        ButtonHoldChargeDemo(ctx: ctx)
    }
}

private struct ButtonLaunchFrame {
    var rise: CGFloat = 0
    var rocketOpacity: Double = 1
    var trail: CGFloat = 0
}

private struct ButtonHoldChargeDemo: View {
    let ctx: DemoContext
    @State private var holdStart: Date?
    @State private var squeezed = false
    @State private var launches = 0
    @State private var launching = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 22) {
                key
                Text(launching ? L("Liftoff!", "发射！") : L("Hold to launch", "长按发射"), ctx.language)
                    .font(.headline)
                    .foregroundStyle(launching ? Palette.pink : Color.secondary)
                    .contentTransition(.opacity)
                    .animation(.smooth(duration: 0.25), value: launching)
            }
            Spacer()
            DemoHint(text: L("Hold until it launches", "一直按住直到发射"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: ctx["duration"] + 2.2, delay: 0.4) { simulate() }
    }

    private var key: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview), paused: holdStart == nil)) { timeline in
            let charge = chargeLevel(at: timeline.date)
            let t = timeline.date.timeIntervalSinceReferenceDate
            ButtonChargeKey(
                charge: charge,
                time: t,
                maxShake: ctx.cg("shake"),
                launches: launches
            )
        }
        .scaleEffect(squeezed ? ctx.cg("squeeze") : 1)
        .frame(width: 200, height: 200)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: ctx["duration"], maximumDistance: 50) {
            launch()
        } onPressingChanged: { isPressing in
            if isPressing { begin() } else { cancel() }
        }
        .accessibilityAddTraits(.isButton)
    }

    private func chargeLevel(at date: Date) -> CGFloat {
        guard let holdStart else { return 0 }
        let elapsed = date.timeIntervalSince(holdStart) / max(ctx["duration"], 0.1)
        return CGFloat(min(max(elapsed, 0), 1))
    }

    private func begin() {
        guard !launching else { return }
        holdStart = Date()
        Haptics.tap(.soft)
        withAnimation(.easeIn(duration: ctx["duration"])) { squeezed = true }
    }

    private func cancel() {
        guard holdStart != nil else { return }
        holdStart = nil
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { squeezed = false }
    }

    private func launch() {
        guard !launching else { return }
        holdStart = nil
        launching = true
        withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { squeezed = false }
        launches += 1
        Haptics.tap(.heavy)
        let muted = Haptics.isMuted
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            if !muted { Haptics.success() }
            try? await Task.sleep(for: .seconds(1.2))
            launching = false
        }
    }

    private func simulate() {
        guard !launching else { return }
        begin()
        let hold = ctx["duration"]
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(hold))
            Haptics.isMuted = true
            launch()
            Haptics.isMuted = false
        }
    }
}

private struct ButtonChargeKey: View {
    let charge: CGFloat
    let time: Double
    let maxShake: CGFloat
    let launches: Int

    var body: some View {
        let jitterX = CGFloat(sin(time * 251)) * maxShake * charge
        let jitterY = CGFloat(cos(time * 197)) * maxShake * charge * 0.6
        let wobble = sin(time * 90) * 2 * Double(charge)
        let glow = 10 + 20 * charge
        let shape = RoundedRectangle(cornerRadius: 34, style: .continuous)
        ZStack {
            shape
                .fill(LinearGradient(colors: [Palette.violet, Palette.pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(shape.strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
                .shadow(color: Palette.pink.opacity(0.35 + 0.35 * Double(charge)), radius: glow, y: 8)
            rocket
        }
        .frame(width: 120, height: 120)
        .keyframeAnimator(initialValue: CGFloat(1), trigger: launches) { content, pop in
            content.scaleEffect(pop)
        } keyframes: { _ in
            KeyframeTrack(\.self) {
                CubicKeyframe(1.15, duration: 0.12)
                SpringKeyframe(1, duration: 0.5, spring: .bouncy)
            }
        }
        .rotationEffect(.degrees(wobble))
        .offset(x: jitterX, y: jitterY)
    }

    private var rocket: some View {
        Image(systemName: "paperplane.fill")
            .font(.system(size: 40, weight: .semibold))
            .foregroundStyle(.white)
            .rotationEffect(.degrees(-45))
            .keyframeAnimator(initialValue: ButtonLaunchFrame(), trigger: launches) { content, frame in
                content
                    .overlay(alignment: .bottom) {
                        Capsule()
                            .fill(LinearGradient(colors: [Palette.amber.opacity(0.9), Palette.pink.opacity(0)], startPoint: .top, endPoint: .bottom))
                            .frame(width: 8, height: 60 * frame.trail)
                            .offset(y: 60 * frame.trail)
                            .opacity(Double(frame.trail))
                    }
                    .offset(y: -frame.rise)
                    .opacity(frame.rocketOpacity)
            } keyframes: { _ in
                KeyframeTrack(\.rise) {
                    CubicKeyframe(-6, duration: 0.1)
                    CubicKeyframe(140, duration: 0.45)
                    MoveKeyframe(60)
                    LinearKeyframe(60, duration: 0.6)
                    SpringKeyframe(0, duration: 0.5, spring: .bouncy)
                }
                KeyframeTrack(\.rocketOpacity) {
                    LinearKeyframe(1, duration: 0.3)
                    LinearKeyframe(0, duration: 0.25)
                    LinearKeyframe(0, duration: 0.6)
                    LinearKeyframe(1, duration: 0.2)
                }
                KeyframeTrack(\.trail) {
                    LinearKeyframe(0, duration: 0.1)
                    CubicKeyframe(1, duration: 0.2)
                    CubicKeyframe(0, duration: 0.3)
                }
            }
    }
}
