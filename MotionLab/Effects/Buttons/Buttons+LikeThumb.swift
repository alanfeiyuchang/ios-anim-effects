import SwiftUI

extension Effect {
    static let buttonsLikeThumb = Effect(
        id: "buttons.like-thumb",
        category: .buttons,
        interaction: .tap,
        name: L("Thumbs-Up Flick", "点赞手势回弹"),
        summary: L("The thumb winds back, flicks forward and tosses a +1 into the air.", "大拇指先向后蓄力，再向前一弹，抛出一个 +1。"),
        prompt: L(
            "A comment row ends in a 116 × 44 pt pill holding a thumbs-up glyph and a like count. On tap the thumb plays a wind-up and flick anchored at its bottom-left knuckle: it cocks back −18° while shrinking to 88% (120 ms, ease-out), whips forward to +12° at 122% while lifting 6 pt (140 ms), then settles upright on a bouncy spring. The outline glyph swaps to a filled blue one mid-flick, the pill tints 12% blue, the count rolls up, and a small blue \"+1\" pops out above the thumb, rising 36 pt while scaling 0.6 → 1 and fading over 0.7 s. A light haptic lands at the flick's peak. Un-liking just drops the fill and count. Friendly, emphatic and quick.",
            "评论行末尾是 116 × 44pt 的胶囊，内有竖拇指与点赞数。点击后拇指以左下“指节”为锚先蓄力再甩出：后翘 −18° 并缩到 88%（120 毫秒，ease-out），再甩到 +12°、放大到 122%、上抬 6pt（140 毫秒），最后以弹性弹簧回正。途中空心图标换成蓝色实心，胶囊染上 12% 蓝，计数上滚，一个蓝色“+1”从拇指上方弹出，0.7 秒内上升 36pt、缩放 0.6 → 1 并淡出。甩到顶点时轻触一下；取消点赞只褪去填充与计数。友好、干脆。"
        ),
        implementation: L(
            "A keyframeAnimator on a like counter drives rotation (anchored .bottomLeading), scale and lift tracks; the glyph swaps with a symbol replace transition, a second keyframeAnimator floats the +1 label, and the count uses numericText.",
            "以点赞计数为触发的 keyframeAnimator 驱动旋转（锚点 .bottomLeading）、缩放与上抬轨道；图标通过符号替换过渡切换，另一个 keyframeAnimator 让“+1”飘起，计数使用 numericText。"
        ),
        apis: ["keyframeAnimator", "KeyframeTrack", "rotationEffect(_:anchor:)", "contentTransition(.symbolEffect(.replace))", "numericText"],
        tags: ["like", "thumbs up", "flick", "+1", "点赞", "大拇指", "回弹", "计数"],
        params: [
            .slider("windup", L("Wind-up angle", "蓄力角度"), 5...30, default: 18, decimals: 0, unit: "°"),
            .slider("flick", L("Flick scale", "甩出缩放"), 1.0...1.4, default: 1.22),
            .toggle("plusOne", L("Floating +1", "飘起 +1"), default: true),
        ]
    ) { ctx in
        ButtonLikeThumbDemo(ctx: ctx)
    }
}

private struct ButtonThumbPose {
    var angle: Double = 0
    var scale: CGFloat = 1
    var lift: CGFloat = 0
}

private struct ButtonThumbFloat {
    var rise: CGFloat = 0
    var scale: CGFloat = 0.6
    var opacity: Double = 0
}

private struct ButtonLikeThumbDemo: View {
    let ctx: DemoContext
    @State private var liked = false
    @State private var count = 41
    @State private var flicks = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            comment
            Spacer()
            DemoHint(text: L("Tap the thumb", "点击大拇指"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.3, delay: 0.4) { toggle() }
    }

    private var comment: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Text(verbatim: "JK")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Palette.ocean, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: "Jonas Kim")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(L("Replied · 12 min", "回复于 12 分钟前"), ctx.language)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Text(L("The easing on the second screen is perfect. Ship it!", "第二屏的缓动曲线太完美了，直接上线吧！"), ctx.language)
                .font(.subheadline)
                .foregroundStyle(.primary)
            HStack {
                Spacer(minLength: 0)
                pill
            }
        }
        .padding(18)
        .frame(width: 300)
        .demoCard()
    }

    private var pill: some View {
        Button(action: toggle) {
            HStack(spacing: 8) {
                thumb
                Text("\(count)")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(liked ? Palette.blue : Color.secondary)
                    .contentTransition(.numericText(value: Double(count)))
            }
            .frame(width: 116, height: 44)
            .background(liked ? Palette.blue.opacity(0.12) : Color.primary.opacity(0.05), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(liked ? L("Remove like", "取消点赞") : L("Like", "点赞"), ctx.language))
    }

    private var thumb: some View {
        let windup = ctx["windup"]
        let flick = ctx.cg("flick")
        return Image(systemName: liked ? "hand.thumbsup.fill" : "hand.thumbsup")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(liked ? Palette.blue : Color.secondary)
            .contentTransition(.symbolEffect(.replace))
            .keyframeAnimator(initialValue: ButtonThumbPose(), trigger: flicks) { content, pose in
                content
                    .scaleEffect(pose.scale, anchor: .bottomLeading)
                    .rotationEffect(.degrees(pose.angle), anchor: .bottomLeading)
                    .offset(y: -pose.lift)
            } keyframes: { _ in
                KeyframeTrack(\.angle) {
                    CubicKeyframe(-windup, duration: 0.12)
                    CubicKeyframe(12, duration: 0.14)
                    SpringKeyframe(0, duration: 0.5, spring: .bouncy)
                }
                KeyframeTrack(\.scale) {
                    CubicKeyframe(0.88, duration: 0.12)
                    CubicKeyframe(flick, duration: 0.14)
                    SpringKeyframe(1, duration: 0.5, spring: .bouncy)
                }
                KeyframeTrack(\.lift) {
                    CubicKeyframe(0, duration: 0.12)
                    CubicKeyframe(6, duration: 0.14)
                    SpringKeyframe(0, duration: 0.5, spring: .bouncy)
                }
            }
            .overlay(alignment: .top) {
                if ctx.bool("plusOne") {
                    plusOne
                }
            }
            .frame(width: 28, height: 28)
    }

    private var plusOne: some View {
        Text(verbatim: "+1")
            .font(.system(size: 13, weight: .heavy, design: .rounded))
            .foregroundStyle(Palette.blue)
            .fixedSize()
            .keyframeAnimator(initialValue: ButtonThumbFloat(), trigger: flicks) { content, value in
                content
                    .scaleEffect(value.scale)
                    .offset(y: -value.rise)
                    .opacity(value.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.rise) {
                    LinearKeyframe(0, duration: 0.2)
                    CubicKeyframe(36, duration: 0.7)
                }
                KeyframeTrack(\.scale) {
                    LinearKeyframe(0.6, duration: 0.2)
                    SpringKeyframe(1, duration: 0.3, spring: .bouncy)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(0, duration: 0.2)
                    LinearKeyframe(1, duration: 0.1)
                    LinearKeyframe(1, duration: 0.25)
                    LinearKeyframe(0, duration: 0.35)
                }
            }
            .allowsHitTesting(false)
    }

    private func toggle() {
        withAnimation(.snappy) {
            liked.toggle()
            count += liked ? 1 : -1
        }
        guard liked else {
            Haptics.tap(.soft)
            return
        }
        flicks += 1
        // Autoplay mutes haptics only while the action runs, so remember that for the delayed tick.
        let muted = Haptics.isMuted
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(260))
            if !muted { Haptics.tap() }
        }
    }
}
