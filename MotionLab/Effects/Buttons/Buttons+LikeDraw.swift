import SwiftUI

extension Effect {
    static let buttonsLikeDraw = Effect(
        id: "buttons.like-draw",
        category: .buttons,
        interaction: .tap,
        name: L("Stroke-Drawn Heart", "描线爱心"),
        summary: L("A pen traces the heart's outline, then it floods with colour and sparks.", "一笔勾勒出爱心轮廓，随后填满颜色并迸出光芒。"),
        prompt: L(
            "An editorial bookmark bar with a 72 pt heart drawn as a thin grey outline. On tap a 3 pt pink stroke traces the heart's contour from the bottom tip, both lobes and back around in 0.45 s (ease-in-out), like a pen signing. Just before the line closes, the interior floods with a pink-to-coral fill that scales from 60% to 100% on a bouncy spring (response 0.35 s, damping 0.55), and eight short radial spark lines shoot from 40 pt to 58 pt from the centre, shortening and fading over 0.4 s. A success haptic lands with the fill and the label switches to \"Saved to favourites\". Tapping again shrinks the fill away and un-draws the outline in reverse with a light tick. Crafted, calligraphic and precise.",
            "图文收藏栏左侧是一枚 72pt 的细灰空心爱心。点击后，一条 3pt 粉色描边从爱心底尖出发，沿两瓣绕回原点，在 0.45 秒内（ease-in-out）勾完轮廓，像用笔签名。线条将要闭合时，内部被粉到珊瑚色填满：填充以弹性弹簧（响应 0.35 秒、阻尼 0.55）从 60% 放大到 100%，八道放射短线从距中心 40pt 射到 58pt，边飞边缩短，0.4 秒内淡出。填满时触发成功触感，文字变为“已加入收藏”。再次点击，填充缩走、描边反向擦除，并轻触一下。"
        ),
        implementation: L(
            "A hand-built heart Shape is stroked with trim(from:to:) animated by withAnimation; a delayed spring scales the filled copy in, and a keyframeAnimator on a like counter holds for the draw time before pushing the spark capsules outward.",
            "手绘的爱心 Shape 使用 trim(from:to:) 描边，由 withAnimation 驱动；带延迟的弹簧放大实心副本，以点赞计数触发的 keyframeAnimator 先等待描线时长，再把光线短条向外推出。"
        ),
        apis: ["Shape", "trim(from:to:)", "keyframeAnimator", "spring(response:dampingFraction:)", "transition(.blurReplace)"],
        tags: ["like", "draw", "stroke", "outline", "点赞", "描线", "勾勒", "收藏"],
        params: [
            .slider("draw", L("Draw duration", "描线时长"), 0.2...1.2, default: 0.45, unit: "s"),
            .slider("sparks", L("Spark count", "光线数量"), 0...12, default: 8, step: 1, decimals: 0),
            .slider("line", L("Stroke width", "描边粗细"), 1.5...5, default: 3, decimals: 1, unit: "pt"),
        ]
    ) { ctx in
        ButtonLikeDrawDemo(ctx: ctx)
    }
}

/// A heart that starts and ends at its bottom tip, so trim draws it in one continuous stroke.
private struct ButtonDrawnHeart: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.92))
        path.addCurve(
            to: CGPoint(x: w * 0.03, y: h * 0.34),
            control1: CGPoint(x: w * 0.2, y: h * 0.72),
            control2: CGPoint(x: w * 0.03, y: h * 0.56)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.2),
            control1: CGPoint(x: w * 0.03, y: h * 0.04),
            control2: CGPoint(x: w * 0.4, y: 0)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.97, y: h * 0.34),
            control1: CGPoint(x: w * 0.6, y: 0),
            control2: CGPoint(x: w * 0.97, y: h * 0.04)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.92),
            control1: CGPoint(x: w * 0.97, y: h * 0.56),
            control2: CGPoint(x: w * 0.8, y: h * 0.72)
        )
        path.closeSubpath()
        return path.offsetBy(dx: rect.minX, dy: rect.minY)
    }
}

private struct ButtonLikeDrawDemo: View {
    let ctx: DemoContext
    @State private var liked = false
    @State private var trim: CGFloat = 0
    @State private var filled = false
    @State private var likes = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            bar
            Spacer()
            DemoHint(text: L("Tap the heart", "点击爱心"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.6, delay: 0.4) { toggle() }
    }

    private var bar: some View {
        HStack(spacing: 16) {
            heart
            VStack(alignment: .leading, spacing: 4) {
                Text(L("The quiet art of easing", "缓动的安静艺术"), ctx.language)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                ZStack(alignment: .leading) {
                    if filled {
                        Text(L("Saved to favourites", "已加入收藏"), ctx.language)
                            .foregroundStyle(Palette.pink)
                            .transition(.blurReplace)
                    } else {
                        Text(L("8 min read", "阅读约 8 分钟"), ctx.language)
                            .foregroundStyle(.secondary)
                            .transition(.blurReplace)
                    }
                }
                .font(.subheadline.weight(.medium))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(width: 310)
        .demoCard()
    }

    private var heart: some View {
        let lineWidth = ctx.cg("line")
        let gradient = LinearGradient(colors: [Palette.pink, Palette.coral], startPoint: .top, endPoint: .bottom)
        return Button(action: toggle) {
            ZStack {
                ButtonDrawnHeart()
                    .stroke(Color.primary.opacity(0.18), style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
                ButtonDrawnHeart()
                    .fill(gradient)
                    .scaleEffect(filled ? 1 : 0.6)
                    .opacity(filled ? 1 : 0)
                ButtonDrawnHeart()
                    .trim(from: 0, to: trim)
                    .stroke(Palette.pink, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                ButtonDrawSparks(count: ctx.int("sparks"), trigger: likes, hold: ctx["draw"] * 0.85)
            }
            .frame(width: 72, height: 66)
            .padding(6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(liked ? L("Remove from favourites", "取消收藏") : L("Add to favourites", "加入收藏"), ctx.language))
    }

    private func toggle() {
        let draw = ctx["draw"]
        liked.toggle()
        if liked {
            likes += 1
            withAnimation(.easeInOut(duration: draw)) { trim = 1 }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55).delay(draw * 0.85)) { filled = true }
            let muted = Haptics.isMuted
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(draw * 0.85))
                if !muted && liked { Haptics.success() }
            }
        } else {
            withAnimation(.easeIn(duration: 0.2)) { filled = false }
            withAnimation(.easeInOut(duration: draw * 0.8).delay(0.1)) { trim = 0 }
            Haptics.tap()
        }
    }
}

private struct ButtonDrawSparks: View {
    let count: Int
    let trigger: Int
    let hold: Double

    var body: some View {
        ZStack {
            ForEach(0..<max(count, 0), id: \.self) { index in
                spark(index)
            }
        }
        .allowsHitTesting(false)
    }

    private func spark(_ index: Int) -> some View {
        let angle = Double(index) / Double(max(count, 1)) * 360
        return Capsule()
            .fill(index % 2 == 0 ? Palette.pink : Palette.amber)
            .frame(width: 3, height: 12)
            .keyframeAnimator(initialValue: CGFloat(0), trigger: trigger) { content, progress in
                content
                    .scaleEffect(x: 1, y: 1 - 0.7 * progress, anchor: .bottom)
                    .offset(y: -(40 + 18 * progress))
                    .opacity(progress > 0.001 && progress < 0.999 ? 1 - Double(progress) * 0.9 : 0)
            } keyframes: { _ in
                KeyframeTrack(\.self) {
                    LinearKeyframe(0, duration: max(hold, 0.001))
                    LinearKeyframe(0.01, duration: 0.01)
                    CubicKeyframe(1, duration: 0.4)
                }
            }
            .rotationEffect(.degrees(angle))
    }
}
