import SwiftUI

extension Effect {
    static let buttonsLikeBurst = Effect(
        id: "buttons.like-burst",
        category: .buttons,
        interaction: .tap,
        name: L("Like Burst", "点赞爆发"),
        summary: L("The heart pops while a ring and confetti dots burst out.", "爱心弹跳的同时，冲击环与彩色粒子向外迸发。"),
        prompt: L(
            "An outlined heart inside a soft circular chip, with a like counter below. On tap the outline swaps to a filled pink-to-coral heart with a symbol replace transition while the heart squashes to 60% in 100 ms, overshoots to 125% and settles at 100% on a bouncy spring. Simultaneously a pink shock ring expands from 40 to 150 pt while its stroke thins and fades (~450 ms), and 10 multicolored dots shoot radially to about 70 pt beyond the chip’s edge over 600 ms, shrinking to 40% as they fly and fading out after 300 ms. The counter rolls up one digit and a success haptic fires. Un-liking simply swaps back without the burst. It feels celebratory, joyful and rewarding.",
            "柔和圆形底座中放置一个空心爱心，下方显示点赞数。点击后，空心图标以符号替换过渡变为粉到珊瑚色的实心爱心，同时爱心在 100 毫秒内压缩到 60%，再以弹性弹簧过冲到 125% 后回落至 100%。与此同时，一圈粉色冲击环从 40pt 扩散到 150pt，描边逐渐变细并淡出（约 450 毫秒）；10 颗彩色小圆点在 600 毫秒内沿径向飞到底座边缘外约 70pt，飞行中缩小到 40%，300 毫秒后开始淡出。计数向上滚动一位，并触发成功触觉。取消点赞仅切回空心、不播放爆发。整体欢快、有庆祝感，令人愉悦。"
        ),
        implementation: L(
            "keyframeAnimator scales the heart on a trigger counter; a KeyframeAnimator view drives a shared progress/opacity value that positions the ring and particles; numericText animates the counter.",
            "keyframeAnimator 以触发计数驱动爱心缩放；KeyframeAnimator 视图驱动共享的进度与透明度，用于冲击环与粒子的位置；计数使用 numericText 滚动。"
        ),
        apis: ["keyframeAnimator", "KeyframeAnimator", "contentTransition(.symbolEffect(.replace))", "numericText"],
        tags: ["like", "heart", "burst", "particles", "点赞", "爱心", "粒子", "庆祝"],
        params: [
            .slider("particles", L("Particle count", "粒子数量"), 6...16, default: 10, step: 1, decimals: 0),
            .slider("radius", L("Burst radius", "迸发半径"), 40...110, default: 70, decimals: 0, unit: "pt"),
            .slider("overshoot", L("Pop overshoot", "弹跳过冲"), 1.0...1.5, default: 1.25),
        ]
    ) { ctx in
        ButtonLikeBurstDemo(ctx: ctx)
    }
}

private struct ButtonBurstFrame {
    var progress: Double = 0
    var ring: Double = 0
    var opacity: Double = 0
}

private struct ButtonLikeBurstDemo: View {
    let ctx: DemoContext
    @State private var liked = false
    @State private var count = 128
    @State private var bursts = 0

    var body: some View {
        let particles = ctx.int("particles")
        let radius = ctx.cg("radius")
        VStack(spacing: 18) {
            Spacer()
            ZStack {
                KeyframeAnimator(initialValue: ButtonBurstFrame(), trigger: bursts) { frame in
                    ButtonBurstLayer(frame: frame, count: particles, radius: radius)
                } keyframes: { _ in
                    KeyframeTrack(\.progress) {
                        MoveKeyframe(0)
                        CubicKeyframe(1, duration: 0.6)
                    }
                    KeyframeTrack(\.ring) {
                        MoveKeyframe(0)
                        CubicKeyframe(1, duration: 0.45)
                    }
                    KeyframeTrack(\.opacity) {
                        MoveKeyframe(1)
                        LinearKeyframe(1, duration: 0.3)
                        LinearKeyframe(0, duration: 0.3)
                    }
                }
                heartButton
            }
            .frame(width: 240, height: 240)
            Text("\(count)")
                .font(.title3.weight(.semibold).monospacedDigit())
                .foregroundStyle(liked ? Palette.pink : Color.secondary)
                .contentTransition(.numericText(value: Double(count)))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.4, delay: 0.4) { toggle() }
    }

    private var heartButton: some View {
        let overshoot = ctx["overshoot"]
        return Button(action: toggle) {
            Image(systemName: liked ? "heart.fill" : "heart")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(heartStyle)
                .contentTransition(.symbolEffect(.replace))
                .keyframeAnimator(initialValue: 1.0, trigger: bursts) { content, scale in
                    content.scaleEffect(scale)
                } keyframes: { _ in
                    KeyframeTrack(\.self) {
                        CubicKeyframe(0.6, duration: 0.1)
                        SpringKeyframe(overshoot, duration: 0.18, spring: .snappy)
                        SpringKeyframe(1, duration: 0.5, spring: .bouncy)
                    }
                }
                .frame(width: 96, height: 96)
                .background(Palette.elevated, in: Circle())
                .overlay(Circle().strokeBorder(Palette.stroke))
                .shadow(color: .black.opacity(0.1), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var heartStyle: AnyShapeStyle {
        if liked {
            return AnyShapeStyle(
                LinearGradient(colors: [Palette.pink, Palette.coral], startPoint: .top, endPoint: .bottom)
            )
        }
        return AnyShapeStyle(Color.secondary)
    }

    private func toggle() {
        withAnimation(.snappy) {
            liked.toggle()
            count += liked ? 1 : -1
        }
        if liked { bursts += 1 }
        guard !ctx.isPreview else { return }
        if liked { Haptics.success() } else { Haptics.tap() }
    }
}

private struct ButtonBurstLayer: View {
    let frame: ButtonBurstFrame
    let count: Int
    let radius: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Palette.pink, lineWidth: CGFloat(max(0.5, 12 * (1 - frame.ring))))
                .frame(width: ringSize, height: ringSize)
                .opacity(1 - frame.ring)
            ForEach(0..<max(count, 1), id: \.self) { index in
                particle(index)
            }
        }
        .opacity(frame.opacity)
        .allowsHitTesting(false)
    }

    private var ringSize: CGFloat {
        CGFloat(40 + 110 * frame.ring)
    }

    private func particle(_ index: Int) -> some View {
        let angle = Double(index) / Double(max(count, 1)) * 2 * .pi - .pi / 2
        let distance = (48 + radius) * CGFloat(frame.progress)
        let colors = Palette.spectrum
        return Circle()
            .fill(colors[index % colors.count])
            .frame(width: 9, height: 9)
            .scaleEffect(CGFloat(1 - 0.6 * frame.progress))
            .offset(x: CGFloat(cos(angle)) * distance, y: CGFloat(sin(angle)) * distance)
    }
}
