import SwiftUI

extension Effect {
    static let inputsStarRating = Effect(
        id: "inputs.star-rating",
        category: .inputs,
        interaction: .gesture,
        name: L("Star Rating", "星级评分"),
        summary: L("Stars fill in a cascading wave and pop with a bounce.", "星星以波浪式依次点亮并弹跳。"),
        prompt: L(
            "Five 38 pt stars in a row with a caption beneath. Tapping or scrubbing across sets the rating: newly lit stars fill with a warm amber-to-coral gradient one after another with a 50 ms stagger, each punching up to 135% in 120 ms then settling with a bouncy spring, while stars being cleared shrink to 85% and dim back to a soft outline tint. The caption (\"Terrible\" … \"Amazing!\") swaps with a push transition from below. A selection haptic ticks on every change. The cascade makes a single tap feel like a small celebration while keeping the value unmistakable.",
            "一排五颗 38pt 星星，下方有一行说明文字。点击或横向拖动设置评分：新点亮的星星以 50 毫秒错峰依次填充琥珀到珊瑚色渐变，每颗先在 120 毫秒内弹到 135%，再以弹性弹簧回落；被取消的星星缩到 85% 并褪回柔和的空心色。说明文字（“很差”……“太棒了！”）以自下而上的推入过渡切换。每次评分变化触发一次选择触觉。依次点亮的节奏让一次点击也像一场小小的庆祝，同时数值一目了然。"
        ),
        implementation: L(
            "A zero-distance DragGesture maps x-position to a rating; each star runs a keyframeAnimator on the change trigger with an index-based delay, and a gradient layer fades in with the same delay via animation(_:value:).",
            "零距离 DragGesture 把横向位置映射为评分；每颗星星在变化触发时运行带索引延迟的 keyframeAnimator，渐变层通过 animation(_:value:) 以相同延迟淡入。"
        ),
        apis: ["keyframeAnimator", "animation(_:value:)", "DragGesture", "transition(.push(from:))"],
        tags: ["rating", "stars", "review", "feedback", "评分", "星级", "打分", "评价"],
        params: [
            .slider("stagger", L("Stagger", "错峰间隔"), 0...0.15, default: 0.05, unit: "s"),
            .slider("pop", L("Pop scale", "弹跳幅度"), 1.0...1.6, default: 1.35),
        ]
    ) { ctx in
        InputStarRatingDemo(ctx: ctx)
    }
}

private struct InputStarRatingDemo: View {
    let ctx: DemoContext
    @State private var rating = 0
    @State private var previous = 0
    @State private var changes = 0
    @State private var step = 0

    private let starSize: CGFloat = 38
    private let spacing: CGFloat = 12
    private static let previewRatings = [4, 2, 5, 3, 1]

    private var captions: [LocalizedText] {
        [
            L("Tap to rate", "点击评分"),
            L("Terrible", "很差"),
            L("Not great", "不太好"),
            L("Okay", "还行"),
            L("Good", "不错"),
            L("Amazing!", "太棒了！"),
        ]
    }

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            stars
            ZStack {
                Text(captions[rating], ctx.language)
                    .font(.headline)
                    .foregroundStyle(rating == 0 ? Color.secondary : Color.primary)
                    .id(rating)
                    .transition(.push(from: .bottom))
            }
            .animation(.snappy, value: rating)
            .clipped()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.3, delay: 0.4) { previewTick() }
    }

    private var stars: some View {
        HStack(spacing: spacing) {
            ForEach(0..<5, id: \.self) { index in
                InputStar(
                    index: index,
                    filled: index < rating,
                    changed: (index < rating) != (index < previous),
                    size: starSize,
                    delay: delay(for: index),
                    pop: ctx["pop"],
                    trigger: changes
                )
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let cell = starSize + spacing
                    let index = Int((value.location.x + spacing / 2) / cell) + 1
                    setRating(index.clamped(to: 1...5))
                }
        )
    }

    private func delay(for index: Int) -> Double {
        let stagger = ctx["stagger"]
        if rating >= previous {
            return Double(max(index - previous, 0)) * stagger
        }
        return Double(max(previous - 1 - index, 0)) * stagger
    }

    private func setRating(_ newValue: Int) {
        guard newValue != rating else { return }
        if !ctx.isPreview { Haptics.selection() }
        previous = rating
        rating = newValue
        changes += 1
    }

    private func previewTick() {
        let target = Self.previewRatings[step % Self.previewRatings.count]
        step += 1
        setRating(target)
    }
}

private struct InputStar: View {
    let index: Int
    let filled: Bool
    let changed: Bool
    let size: CGFloat
    let delay: Double
    let pop: Double
    let trigger: Int

    var body: some View {
        let lead = 0.001 + delay
        let peak = changed ? (filled ? pop : 0.85) : 1.0
        ZStack {
            Image(systemName: "star.fill")
                .foregroundStyle(Color.primary.opacity(0.14))
            Image(systemName: "star.fill")
                .foregroundStyle(
                    LinearGradient(colors: [Palette.amber, Palette.coral], startPoint: .top, endPoint: .bottom)
                )
                .opacity(filled ? 1 : 0)
                .animation(.easeOut(duration: 0.15).delay(delay), value: filled)
        }
        .font(.system(size: size, weight: .semibold))
        .shadow(color: Palette.amber.opacity(filled ? 0.35 : 0), radius: 8, y: 3)
        .keyframeAnimator(initialValue: 1.0, trigger: trigger) { content, scale in
            content.scaleEffect(scale)
        } keyframes: { _ in
            KeyframeTrack(\.self) {
                LinearKeyframe(1, duration: lead)
                CubicKeyframe(peak, duration: 0.12)
                SpringKeyframe(1, duration: 0.45, spring: .bouncy)
            }
        }
    }
}
