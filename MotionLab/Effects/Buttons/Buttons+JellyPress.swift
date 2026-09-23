import SwiftUI

extension Effect {
    static let buttonsJellyPress = Effect(
        id: "buttons.jelly-press",
        category: .buttons,
        interaction: .tap,
        name: L("Jelly Press", "果冻按压"),
        summary: L("The button squashes flat under your finger, then wobbles like jelly on release.", "按下时像软糖一样被压扁，松手后果冻般晃动回弹。"),
        prompt: L(
            "A plump 210 × 64 pt mint-to-sky capsule \"Play\" button resting on a soft contact shadow. On touch-down it squashes toward its bottom edge in ~180 ms — about 110% wide and 84% tall — while the ground shadow spreads wider and darker, like a gummy pressed into a table. On release a squash-and-stretch wobble plays over ~0.7 s: it shoots up to ~114% tall and 90% wide, dips back to 95% / 105%, overshoots once more slightly and settles on a spring, the scale always anchored to the bottom so it never leaves the floor. The play glyph lags a few points behind the body for secondary motion. A soft haptic lands on press, a light one on release. Cartoonish, squishy and joyful.",
            "一枚 210 × 64pt 的圆润胶囊“播放”按钮，薄荷绿到天蓝渐变，下方有一片柔和的接触阴影。手指按下后约 180 毫秒内，按钮朝底边被压扁——宽约 110%、高约 84%，地面阴影同时变宽变深，像一颗软糖被按在桌面上。松手后播放一段约 0.7 秒的挤压-拉伸晃动：先向上拉长到约 114% 高、90% 宽，再回落到 95% / 105%，又轻微过冲一次，最后以弹簧落定；缩放始终以底边为锚点，按钮从不离开“地面”。播放图标比本体慢几个点，形成跟随的次级运动。按下时柔和触感，松手时轻触感。卡通、Q 弹、充满快乐。"
        ),
        implementation: L(
            "A zero-distance DragGesture flips a pressed flag that squashes the face with a stiff spring via scaleEffect(x:y:anchor: .bottom); a release counter triggers a keyframeAnimator whose independent x/y tracks multiply in the wobble.",
            "零距离 DragGesture 切换按压状态，以硬弹簧通过 scaleEffect(x:y:anchor: .bottom) 压扁按钮；松手计数触发 keyframeAnimator，其独立的 x / y 轨道叠加出果冻晃动。"
        ),
        apis: ["keyframeAnimator", "KeyframeTrack", "scaleEffect(x:y:anchor:)", "DragGesture", "spring(response:dampingFraction:)"],
        tags: ["jelly", "squash", "stretch", "wobble", "果冻", "挤压", "拉伸", "Q弹"],
        params: [
            .slider("squash", L("Squash depth", "压扁程度"), 0.05...0.3, default: 0.16),
            .slider("stretch", L("Release stretch", "回弹拉伸"), 0.04...0.25, default: 0.14),
            .slider("wobble", L("Wobble time", "晃动时长"), 0.4...1.2, default: 0.7, unit: "s"),
        ]
    ) { ctx in
        ButtonJellyPressDemo(ctx: ctx)
    }
}

private struct ButtonJellyScale {
    var x: CGFloat = 1
    var y: CGFloat = 1
}

private struct ButtonJellyPressDemo: View {
    let ctx: DemoContext
    @State private var pressed = false
    @State private var releases = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 18) {
                Text(L("Lo-fi beats · 42 tracks", "Lo-fi 节拍 · 42 首"), ctx.language)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                ZStack(alignment: .bottom) {
                    shadow
                    face
                }
                .frame(width: 240, height: 100, alignment: .bottom)
            }
            Spacer()
            DemoHint(text: L("Press and release the button", "按下按钮再松开"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.5, delay: 0.4) { simulate() }
    }

    private var squashX: CGFloat { 1 + ctx.cg("squash") * 0.6 }
    private var squashY: CGFloat { 1 - ctx.cg("squash") }

    private var shadow: some View {
        Ellipse()
            .fill(Color.black.opacity(pressed ? 0.22 : 0.12))
            .frame(width: pressed ? 220 : 180, height: 14)
            .blur(radius: 6)
            .offset(y: 6)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: pressed)
    }

    private var face: some View {
        let stretch = ctx.cg("stretch")
        let total = ctx["wobble"]
        return HStack(spacing: 10) {
            Image(systemName: "play.fill")
                .offset(y: pressed ? 3 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.5), value: pressed)
            Text(ctx.language == .zh ? "播放" : "Play")
        }
        .font(.title3.weight(.bold))
        .foregroundStyle(.white)
        .frame(width: 210, height: 64)
        .background(
            LinearGradient(colors: [Palette.mint, Palette.sky], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: Capsule()
        )
        .overlay {
            Capsule()
                .fill(LinearGradient(colors: [Color.white.opacity(0.35), .clear], startPoint: .top, endPoint: .center))
                .padding(3)
                .allowsHitTesting(false)
        }
        .scaleEffect(x: pressed ? squashX : 1, y: pressed ? squashY : 1, anchor: .bottom)
        .animation(.spring(response: 0.18, dampingFraction: 0.8), value: pressed)
        .keyframeAnimator(initialValue: ButtonJellyScale(), trigger: releases) { content, scale in
            content.scaleEffect(x: scale.x, y: scale.y, anchor: .bottom)
        } keyframes: { _ in
            KeyframeTrack(\.y) {
                CubicKeyframe(1 + stretch, duration: total * 0.18)
                CubicKeyframe(1 - stretch * 0.35, duration: total * 0.2)
                CubicKeyframe(1 + stretch * 0.12, duration: total * 0.2)
                SpringKeyframe(1, duration: total * 0.42, spring: .bouncy)
            }
            KeyframeTrack(\.x) {
                CubicKeyframe(1 - stretch * 0.7, duration: total * 0.18)
                CubicKeyframe(1 + stretch * 0.35, duration: total * 0.2)
                CubicKeyframe(1 - stretch * 0.1, duration: total * 0.2)
                SpringKeyframe(1, duration: total * 0.42, spring: .bouncy)
            }
        }
        .contentShape(Capsule())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in press() }
                .onEnded { _ in release() }
        )
        .accessibilityAddTraits(.isButton)
    }

    private func press() {
        guard !pressed else { return }
        pressed = true
        Haptics.tap(.soft)
    }

    private func release() {
        guard pressed else { return }
        pressed = false
        releases += 1
        Haptics.tap(.light)
    }

    private func simulate() {
        press()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.28))
            Haptics.isMuted = true
            release()
            Haptics.isMuted = false
        }
    }
}
