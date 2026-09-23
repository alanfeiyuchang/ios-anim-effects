import SwiftUI

extension Effect {
    static let buttonsLikeBurst = Effect(
        id: "buttons.like-burst",
        category: .buttons,
        interaction: .tap,
        name: L("Like Burst", "点赞爆发"),
        summary: L("The heart pops while a ring and confetti dots burst out.", "爱心弹跳的同时，冲击环与彩色粒子向外迸发。"),
        prompt: L(
            "A social post card (avatar, caption, photo) whose action row holds an outlined heart in a soft 60 pt chip next to its like count. On tap the outline swaps to a filled pink-to-coral heart with a symbol replace transition while it squashes to 60% in 100 ms, overshoots to 125% and settles on a bouncy spring. At the same time a pink shock ring expands from 40 to 150 pt as its stroke thins and fades (~450 ms), and two rings of confetti burst out over 600 ms: 10 outer dots flying ~70 pt past the chip and 10 smaller inner dots at half the distance, each with a little random jitter in angle (±12°), distance (75–115%) and size, shrinking to 40% and fading after 300 ms. The count rolls up one digit with a success haptic; un-liking swaps back without the burst. Celebratory and joyful.",
            "动态卡片操作栏里，60pt 柔和圆形底座中是空心爱心与点赞数。点击后爱心经符号替换变为粉到珊瑚色实心，100 毫秒内压到 60%，再以弹性弹簧过冲到 125% 后回落。同时粉色冲击环约 450 毫秒从 40pt 扩到 150pt，描边变细淡出；两圈彩点在 600 毫秒内迸发：外圈 10 颗飞出约 70pt，内圈 10 颗更小、飞一半距离，角度（±12°）、距离与大小略带随机，途中缩到 40% 并在 300 毫秒后淡出。计数上滚并触发成功触觉；取消点赞则安静切回。"
        ),
        implementation: L(
            "keyframeAnimator scales the heart on a trigger counter; a KeyframeAnimator view drives a shared progress/opacity value that positions the ring and two particle rings, jittered by a hash of (burst, index) so every burst differs; numericText animates the counter.",
            "keyframeAnimator 以触发计数驱动爱心缩放；KeyframeAnimator 视图驱动共享的进度与透明度，定位冲击环和内外两圈粒子，并用（爆发次数、序号）的哈希值做抖动，让每次爆发都不同；计数使用 numericText 滚动。"
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
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            post
            Spacer(minLength: 0)
            DemoHint(text: L("Tap the heart to like the post", "点击爱心为动态点赞"), ctx: ctx)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.4, delay: 0.4) { toggle() }
    }

    private var post: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(verbatim: "MC")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Palette.sunset, in: Circle())
                VStack(alignment: .leading, spacing: 1) {
                    Text(verbatim: "Mia Chen")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(L("2 h · Nordkette", "2 小时前 · Nordkette"), ctx.language)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            Text(L("First powder day of the season. Who's in tomorrow?", "今季第一场粉雪，明天谁一起？"), ctx.language)
                .font(.footnote)
                .foregroundStyle(.primary)
            LandscapeArt(seed: 2)
                .frame(height: 92)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            actionRow
        }
        .padding(16)
        .frame(width: 300)
        .demoCard()
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            heartChip
                .zIndex(1)
            Text("\(count)")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(liked ? Palette.pink : Color.secondary)
                .contentTransition(.numericText(value: Double(count)))
            Spacer(minLength: 0)
            Label {
                Text(verbatim: "24")
            } icon: {
                Image(systemName: "bubble.right")
            }
            .font(.footnote.weight(.medium).monospacedDigit())
            .foregroundStyle(.secondary)
            Image(systemName: "paperplane")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    private var heartChip: some View {
        let particles = ctx.int("particles")
        let radius = ctx.cg("radius")
        return ZStack {
            KeyframeAnimator(initialValue: ButtonBurstFrame(), trigger: bursts) { frame in
                ButtonBurstLayer(frame: frame, count: particles, radius: radius, seed: bursts)
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
        .frame(width: 60, height: 60)
    }

    private var heartButton: some View {
        let overshoot = ctx["overshoot"]
        return Button(action: toggle) {
            Image(systemName: liked ? "heart.fill" : "heart")
                .font(.system(size: 26, weight: .semibold))
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
                .frame(width: 60, height: 60)
                .background(liked ? Palette.pink.opacity(0.12) : Color.primary.opacity(0.05), in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(liked ? L("Unlike", "取消点赞") : L("Like", "点赞"), ctx.language))
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
    /// Changes every burst so the jitter pattern is never the same twice.
    let seed: Int

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Palette.pink, lineWidth: CGFloat(max(0.5, 12 * (1 - frame.ring))))
                .frame(width: ringSize, height: ringSize)
                .opacity(1 - frame.ring)
            ForEach(0..<max(count, 1), id: \.self) { index in
                particle(index, inner: false)
                particle(index, inner: true)
            }
        }
        .opacity(frame.opacity)
        .allowsHitTesting(false)
    }

    private var ringSize: CGFloat {
        CGFloat(40 + 110 * frame.ring)
    }

    /// Deterministic 0..<1 noise.
    private func noise(_ index: Int, _ channel: Int) -> Double {
        let n = sin(Double(seed) * 91.7 + Double(index) * 12.9898 + Double(channel) * 78.233) * 43758.5453
        return n - n.rounded(.down)
    }

    private func particle(_ index: Int, inner: Bool) -> some View {
        let total = Double(max(count, 1))
        let step = 2 * Double.pi / total
        let channel = inner ? 3 : 0
        let jitterAngle = (noise(index, channel) - 0.5) * (24 * .pi / 180)
        // The inner ring sits half a step round so the two rings interleave.
        let angle = Double(index) * step - .pi / 2 + (inner ? step / 2 : 0) + jitterAngle
        let reach = 0.75 + 0.4 * noise(index, channel + 1)
        let base = inner ? (24 + radius * 0.5) : (30 + radius)
        let distance = base * CGFloat(reach * frame.progress)
        let size: CGFloat = (inner ? 5 : 7) + CGFloat(noise(index, channel + 2)) * (inner ? 3 : 4)
        let colors = Palette.spectrum
        return Circle()
            .fill(colors[(index + (inner ? 3 : 0)) % colors.count])
            .frame(width: size, height: size)
            .scaleEffect(CGFloat(1 - 0.6 * frame.progress))
            .offset(x: CGFloat(cos(angle)) * distance, y: CGFloat(sin(angle)) * distance)
    }
}
