import SwiftUI

extension Effect {
    static let buttonsLikeDoubleTap = Effect(
        id: "buttons.like-double-tap",
        category: .buttons,
        interaction: .gesture,
        name: L("Double-Tap to Like", "双击点赞飞入"),
        summary: L("Double-tap the photo: a big heart pops where you tapped, then flies into the like button.", "双击照片，大爱心在触点弹出，再飞进点赞按钮。"),
        prompt: L(
            "A photo post card: a 300 × 196 pt landscape image above an action row with a small heart button and a like count. Double-tapping anywhere on the photo pops a 90 pt white heart right under the finger — scale 0 → 118% → 100% on a bouncy spring (response 0.35 s, damping 0.5), tilted a random ±12° with a soft shadow. It hangs for ~0.45 s, then flies along a curved path into the small heart button while shrinking to 22% and straightening out (0.4 s, ease-in). On arrival the button fills pink, pops to 130% and settles, the count rolls up and a success haptic fires. A single tap on the small heart toggles it directly with a lighter pop. Social, direct and delightful.",
            "一张照片动态卡片：上方是 300 × 196pt 的风景照片，下方操作栏里有一枚小爱心按钮与点赞数。在照片任意位置双击，一枚 90pt 的白色大爱心就在指尖下弹出——以弹性弹簧（响应 0.35 秒、阻尼 0.5）从 0 放大到 118% 再落到 100%，随机倾斜 ±12°，带柔和投影。停留约 0.45 秒后，它沿一条弧线飞向下方的小爱心按钮，途中缩小到 22% 并摆正（0.4 秒，ease-in）。抵达时小按钮变为粉色实心，弹到 130% 再落定，计数上滚并触发成功触感。单击小爱心则直接切换状态，弹跳更轻。社交感强、直接、令人愉悦。"
        ),
        implementation: L(
            "onTapGesture(count: 2, coordinateSpace: .local) reports the tap point; an async Task springs a positioned heart in, then animates its position (split into x with ease-in and y with ease-out for a curved flight) and scale toward the button's known frame, before toggling the like state and a keyframe pop.",
            "onTapGesture(count: 2, coordinateSpace: .local) 给出触点；异步 Task 先用弹簧让定位好的爱心弹出，再把位置（x 用 ease-in、y 用 ease-out，合成弧线）与缩放动画到按钮的已知位置，最后切换点赞状态并播放关键帧弹跳。"
        ),
        apis: ["onTapGesture(count:coordinateSpace:perform:)", "position", "keyframeAnimator", "Task.sleep", "numericText"],
        tags: ["double tap", "like", "heart", "photo", "双击", "点赞", "爱心", "照片"],
        params: [
            .slider("hang", L("Hang time", "停留时长"), 0.1...1.0, default: 0.45, unit: "s"),
            .slider("flight", L("Flight time", "飞行时长"), 0.2...0.8, default: 0.4, unit: "s"),
            .slider("size", L("Heart size", "爱心尺寸"), 60...120, default: 90, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        ButtonLikeDoubleTapDemo(ctx: ctx)
    }
}

private struct ButtonLikeDoubleTapDemo: View {
    let ctx: DemoContext
    @State private var liked = false
    @State private var count = 864
    @State private var pops = 0
    @State private var heartX: CGFloat = 150
    @State private var heartY: CGFloat = 98
    @State private var heartScale: CGFloat = 0
    @State private var heartTilt: Double = 0
    @State private var heartVisible = false
    @State private var busy = false
    @State private var step = 0

    private static let photo = CGSize(width: 300, height: 196)
    /// Centre of the small heart button in card coordinates (row starts 10 pt under the photo).
    private static let target = CGPoint(x: 16 + 22, y: 196 + 10 + 22)
    private static let previewPoints: [CGPoint] = [CGPoint(x: 190, y: 80), CGPoint(x: 110, y: 110), CGPoint(x: 220, y: 130)]

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            card
            Spacer(minLength: 0)
            DemoHint(text: L("Double-tap the photo", "双击照片"), ctx: ctx)
                .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.4, delay: 0.4) { previewStep() }
    }

    private var card: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 10) {
                LandscapeArt(seed: 0)
                    .frame(width: Self.photo.width, height: Self.photo.height)
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 24, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 24, style: .continuous))
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2, coordinateSpace: .local) { location in
                        doubleTap(at: location)
                    }
                actionRow
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
            bigHeart
        }
        .frame(width: Self.photo.width)
        .demoCard(cornerRadius: 24)
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button(action: tapSmallHeart) {
                Image(systemName: liked ? "heart.fill" : "heart")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(liked ? Palette.pink : Color.primary)
                    .contentTransition(.symbolEffect(.replace))
                    .keyframeAnimator(initialValue: CGFloat(1), trigger: pops) { content, scale in
                        content.scaleEffect(scale)
                    } keyframes: { _ in
                        KeyframeTrack(\.self) {
                            CubicKeyframe(1.3, duration: 0.1)
                            SpringKeyframe(1, duration: 0.45, spring: .bouncy)
                        }
                    }
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(liked ? L("Unlike", "取消点赞") : L("Like", "点赞"), ctx.language))
            Text(L("\(count) likes", "\(count) 次赞"), ctx.language)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.primary)
                .contentTransition(.numericText(value: Double(count)))
            Spacer(minLength: 0)
            Image(systemName: "bookmark")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(height: 44)
    }

    private var bigHeart: some View {
        let size = ctx.cg("size")
        return Image(systemName: "heart.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
            .rotationEffect(.degrees(heartTilt))
            .scaleEffect(heartScale)
            .opacity(heartVisible ? 1 : 0)
            .position(x: heartX, y: heartY)
            .frame(width: Self.photo.width, height: Self.photo.height + 64, alignment: .topLeading)
            .allowsHitTesting(false)
    }

    private func doubleTap(at point: CGPoint) {
        guard !busy else { return }
        busy = true
        let hang = ctx["hang"]
        let flight = ctx["flight"]
        let muted = Haptics.isMuted
        var instant = Transaction()
        instant.disablesAnimations = true
        withTransaction(instant) {
            heartX = point.x
            heartY = point.y
            heartScale = 0
            heartTilt = Double(sportHash(Double(step) + Double(point.x)) * 24 - 12)
            heartVisible = true
        }
        if !muted { Haptics.tap(.medium) }
        Task { @MainActor in
            // Let the reset frame render first, so the pop starts from zero.
            try? await Task.sleep(for: .milliseconds(20))
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) { heartScale = 1 }
            try? await Task.sleep(for: .seconds(0.35 + hang))
            withAnimation(.easeIn(duration: flight)) {
                heartX = Self.target.x
                heartScale = 0.22
                heartTilt = 0
            }
            withAnimation(.easeOut(duration: flight)) { heartY = Self.target.y }
            try? await Task.sleep(for: .seconds(flight))
            var hide = Transaction()
            hide.disablesAnimations = true
            withTransaction(hide) {
                heartVisible = false
                heartScale = 0
            }
            if !liked {
                withAnimation(.snappy) {
                    liked = true
                    count += 1
                }
            }
            pops += 1
            if !muted { Haptics.success() }
            busy = false
        }
    }

    private func tapSmallHeart() {
        withAnimation(.snappy) {
            liked.toggle()
            count += liked ? 1 : -1
        }
        if liked { pops += 1 }
        Haptics.tap()
    }

    private func previewStep() {
        if liked && step % 2 == 1 {
            tapSmallHeart()
        } else {
            doubleTap(at: Self.previewPoints[step % Self.previewPoints.count])
        }
        step += 1
    }
}
