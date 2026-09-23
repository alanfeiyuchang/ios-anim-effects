import SwiftUI

extension Effect {
    static let buttonsHoldRing = Effect(
        id: "buttons.hold-ring",
        category: .buttons,
        interaction: .gesture,
        name: L("Radial Hold", "环形长按"),
        summary: L("A ring draws itself around a round button while you hold, then blooms into a check.", "按住圆形按钮时外环逐渐画满，完成后绽放为对勾。"),
        prompt: L(
            "A 112 pt round payment button with a fingerprint glyph sits inside a 138 pt track ring, above \"Hold to pay €24.90\". While the finger holds, a 6 pt mint-to-sky arc draws clockwise from 12 o'clock over 1.2 s at constant speed, the button sinks to 94% and the glyph dims slightly, as if pressure builds. Releasing early retracts the arc on a soft spring (response 0.4 s, no overshoot). When the ring closes, the glyph blur-replaces with a bold checkmark, the button pops to 108% and back, a mint shockwave ring expands to 150% and fades over 0.6 s, the caption changes to \"Paid\" and a success haptic fires; ~1.5 s later it resets. Secure, deliberate and reassuring.",
            "一枚 112pt 的圆形支付按钮，中间是指纹图标，外围是 138pt 的轨道环，下方写着“长按支付 €24.90”。手指按住时，一条 6pt 的薄荷绿到天蓝色弧线从 12 点方向顺时针匀速绘制，1.2 秒画满；按钮随之下沉到 94%，图标略微变暗，像压力在积蓄。中途松手，弧线以柔和的弹簧（响应 0.4 秒、无过冲）收回。圆环闭合时，指纹图标模糊替换为粗对勾，按钮弹到 108% 再回落，一圈薄荷绿冲击波在 0.6 秒内扩张到 150% 并淡出，说明文字变为“已支付”，同时触发成功触感；约 1.5 秒后复位。安全、郑重、令人安心。"
        ),
        implementation: L(
            "onLongPressGesture(minimumDuration:perform:onPressingChanged:) starts a linear trim animation on a rotated Circle stroke or springs it back; completion swaps the glyph with a blurReplace transition and fires a keyframeAnimator for the pop and shockwave.",
            "onLongPressGesture(minimumDuration:perform:onPressingChanged:) 为旋转过的 Circle 描边启动线性 trim 动画，或将其弹回；完成时通过 blurReplace 过渡替换图标，并触发 keyframeAnimator 播放弹跳与冲击波。"
        ),
        apis: ["onLongPressGesture(minimumDuration:perform:onPressingChanged:)", "Circle().trim", "keyframeAnimator", "transition(.blurReplace)", "AngularGradient"],
        tags: ["hold", "ring", "payment", "confirm", "长按", "圆环", "支付", "确认"],
        params: [
            .slider("duration", L("Hold duration", "按住时长"), 0.5...2.5, default: 1.2, unit: "s"),
            .slider("width", L("Ring width", "圆环粗细"), 3...10, default: 6, decimals: 0, unit: "pt"),
            .toggle("shockwave", L("Shockwave", "冲击波"), default: true),
        ]
    ) { ctx in
        ButtonHoldRingDemo(ctx: ctx)
    }
}

private struct ButtonRingPop {
    var scale: CGFloat = 1
    var wave: CGFloat = 1
    var waveOpacity: Double = 0
}

private struct ButtonHoldRingDemo: View {
    let ctx: DemoContext
    @State private var progress: CGFloat = 0
    @State private var pressing = false
    @State private var done = false
    @State private var completions = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 20) {
                control
                caption
            }
            Spacer()
            DemoHint(text: L("Press and hold the button", "按住按钮不放"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: ctx["duration"] + 2.6, delay: 0.4) { simulate() }
    }

    private var caption: some View {
        ZStack {
            if done {
                Text(L("Paid · €24.90", "已支付 · €24.90"), ctx.language)
                    .foregroundStyle(Palette.mint)
                    .transition(.blurReplace)
            } else {
                Text(L("Hold to pay €24.90", "长按支付 €24.90"), ctx.language)
                    .foregroundStyle(.secondary)
                    .transition(.blurReplace)
            }
        }
        .font(.headline)
    }

    private var control: some View {
        let width = ctx.cg("width")
        return ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: width)
                .frame(width: 138, height: 138)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(colors: [Palette.mint, Palette.sky, Palette.mint], center: .center),
                    style: StrokeStyle(lineWidth: width, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 138, height: 138)
                .shadow(color: Palette.mint.opacity(0.5), radius: 6)
            face
        }
        .frame(width: 200, height: 200)
        .contentShape(Circle())
        .onLongPressGesture(minimumDuration: ctx["duration"], maximumDistance: 50) {
            complete()
        } onPressingChanged: { isPressing in
            if isPressing { begin() } else { end() }
        }
        .accessibilityAddTraits(.isButton)
    }

    private var face: some View {
        let showWave = ctx.bool("shockwave")
        return ZStack {
            Circle()
                .fill(LinearGradient(colors: [Palette.elevated, Palette.surface], startPoint: .top, endPoint: .bottom))
                .overlay(Circle().strokeBorder(Palette.stroke, lineWidth: 1))
                .shadow(color: .black.opacity(pressing ? 0.08 : 0.16), radius: pressing ? 6 : 14, y: pressing ? 3 : 8)
            ZStack {
                if done {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Palette.mint)
                        .transition(.blurReplace)
                } else {
                    Image(systemName: "touchid")
                        .foregroundStyle(pressing ? Palette.sky : Color.secondary)
                        .transition(.blurReplace)
                }
            }
            .font(.system(size: 42, weight: .semibold))
        }
        .frame(width: 112, height: 112)
        .scaleEffect(pressing && !done ? 0.94 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: pressing)
        .keyframeAnimator(initialValue: ButtonRingPop(), trigger: completions) { content, pop in
            content
                .scaleEffect(pop.scale)
                .background {
                    Circle()
                        .stroke(Palette.mint, lineWidth: 3)
                        .scaleEffect(pop.wave)
                        .opacity(showWave ? pop.waveOpacity : 0)
                }
        } keyframes: { _ in
            KeyframeTrack(\.scale) {
                CubicKeyframe(1.08, duration: 0.12)
                SpringKeyframe(1, duration: 0.4, spring: .bouncy)
            }
            KeyframeTrack(\.wave) {
                MoveKeyframe(1)
                CubicKeyframe(1.5, duration: 0.6)
            }
            KeyframeTrack(\.waveOpacity) {
                MoveKeyframe(0.9)
                CubicKeyframe(0, duration: 0.6)
            }
        }
    }

    private func begin() {
        guard !done else { return }
        pressing = true
        Haptics.tap(.soft)
        withAnimation(.linear(duration: ctx["duration"])) { progress = 1 }
    }

    private func end() {
        pressing = false
        guard !done else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 1)) { progress = 0 }
    }

    private func complete() {
        guard !done else { return }
        pressing = false
        withAnimation(.snappy(duration: 0.2)) {
            progress = 1
            done = true
        }
        completions += 1
        Haptics.success()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                done = false
                progress = 0
            }
        }
    }

    private func simulate() {
        guard !done else { return }
        begin()
        let hold = ctx["duration"]
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(hold))
            Haptics.isMuted = true
            complete()
            Haptics.isMuted = false
        }
    }
}
