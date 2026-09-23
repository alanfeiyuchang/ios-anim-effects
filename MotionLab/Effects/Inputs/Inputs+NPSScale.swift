import SwiftUI

extension Effect {
    static let inputsNPSScale = Effect(
        id: "inputs.nps-scale",
        category: .inputs,
        interaction: .gesture,
        name: L("0–10 Score Bars", "0–10 分柱状打分"),
        summary: L("An NPS scale of rising bars: a wave grows up to your score and a bubble glides to it.", "NPS 打分的柱状阶梯：波浪般长到所选分数，气泡随之滑过去。"),
        prompt: L(
            "A \"How likely are you to recommend us?\" card with eleven bars (0–10) whose resting heights ramp gently from 18 to 38 pt. Tapping or scrubbing picks a score: every bar up to it rises to its full ramp height plus 14 pt in a wave that travels outward from the previous score with a 25 ms stagger on a bouncy spring (response 0.4 s, damping 0.62), and takes the category colour — coral for 0–6, amber for 7–8, mint for 9–10 — while bars above it sink back to a faint tint. A score bubble glides above the chosen bar on a matched-geometry spring, and the caption (Detractor / Passive / Promoter) swaps with a blur transition. A selection haptic ticks per score. Clear, quantified and lively.",
            "“您有多大可能推荐我们？”卡片上有 11 根柱子（0–10），静止高度从 18pt 缓升到 38pt。点击或拖动打分：所选分数及以下的柱子升到各自高度再加 14pt，以 25 毫秒错峰、从上次分数处向外传播的波浪方式，由弹性弹簧（响应 0.4 秒、阻尼 0.62）驱动，并染上区间色：0–6 珊瑚红、7–8 琥珀、9–10 薄荷绿；更高的柱子退回淡色。分数气泡借共享几何滑到所选柱上方，说明文字（贬损者 / 被动者 / 推荐者）模糊切换，每换一分一次选择触觉。"
        ),
        implementation: L(
            "Each bar has its own animation(_:value:) delayed by its distance from the previous score; the bubble uses matchedGeometryEffect inside the selected bar's overlay, and a DragGesture maps x-position to a score.",
            "每根柱子都有独立的 animation(_:value:)，延迟取决于与上一次分数的距离；气泡在所选柱子的 overlay 中使用 matchedGeometryEffect，DragGesture 把横向位置映射为分数。"
        ),
        apis: ["matchedGeometryEffect", "animation(_:value:)", "DragGesture", "transition(.blurReplace)"],
        tags: ["rating", "NPS", "survey", "score", "评分", "NPS", "问卷", "打分"],
        params: [
            .slider("stagger", L("Wave stagger", "波浪错峰"), 0...0.08, default: 0.025, decimals: 3, unit: "s"),
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.8, default: 0.4, unit: "s"),
            .slider("damping", L("Spring damping", "弹簧阻尼"), 0.3...1.0, default: 0.62),
        ]
    ) { ctx in
        NPSScaleDemo(ctx: ctx)
    }
}

private struct NPSScaleDemo: View {
    let ctx: DemoContext
    @State private var score: Int?
    @State private var previous = 0
    @State private var step = 0
    @Namespace private var bubbleSpace

    private let barWidth: CGFloat = 20
    private let gap: CGFloat = 5
    private var rowWidth: CGFloat { barWidth * 11 + gap * 10 }
    private static let previewScores: [Int] = [9, 4, 7, 10, 2, 8]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            card
            Spacer()
            DemoHint(text: L("Tap or drag across the bars", "点击或横向拖过柱子"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.3, delay: 0.3) { previewTick() }
    }

    private func color(for value: Int) -> Color {
        if value >= 9 { return Palette.mint }
        if value >= 7 { return Palette.amber }
        return Palette.coral
    }

    private var caption: LocalizedText {
        guard let score else { return L("Pick a score", "选择一个分数") }
        if score >= 9 { return L("Promoter", "推荐者") }
        if score >= 7 { return L("Passive", "被动者") }
        return L("Detractor", "贬损者")
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L("How likely are you to recommend us?", "您有多大可能向朋友推荐我们？"), ctx.language)
                .font(.headline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            bars
            HStack {
                Text(L("Not likely", "不太可能"), ctx.language)
                Spacer(minLength: 0)
                Text(caption, ctx.language)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(score.map { color(for: $0) } ?? Color.secondary)
                    .id(caption)
                    .transition(.blurReplace)
                Spacer(minLength: 0)
                Text(L("Very likely", "非常可能"), ctx.language)
            }
            .font(.caption2.weight(.medium))
            .foregroundStyle(.tertiary)
            .animation(.smooth(duration: 0.3), value: caption)
        }
        .padding(18)
        .frame(width: rowWidth + 36)
        .demoCard(cornerRadius: 24)
    }

    private var bars: some View {
        HStack(alignment: .bottom, spacing: gap) {
            ForEach(0...10, id: \.self) { value in
                bar(value)
            }
        }
        .frame(width: rowWidth, height: 96, alignment: .bottom)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { drag in
                    let index = Int(drag.location.x / (barWidth + gap))
                    select(index.clamped(to: 0...10))
                }
        )
    }

    private func bar(_ value: Int) -> some View {
        let selected = score ?? -1
        let on = value <= selected
        let base: CGFloat = 18 + CGFloat(value) * 2
        let height: CGFloat = on ? base + 14 : base
        let distance = abs(value - previous)
        let delay = Double(distance) * ctx["stagger"]
        let fill: Color = on ? color(for: selected) : Color.primary.opacity(0.1)
        return VStack(spacing: 4) {
            ZStack {
                if value == selected {
                    Text("\(value)")
                        .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 24)
                        .background(color(for: value), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .matchedGeometryEffect(id: "bubble", in: bubbleSpace)
                }
            }
            .frame(height: 24)
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(fill)
                .frame(width: barWidth, height: height)
                .animation(.spring(response: ctx["response"], dampingFraction: ctx["damping"]).delay(delay), value: on)
                .animation(.smooth(duration: 0.25), value: selected)
            Text("\(value)")
                .font(.system(size: 10, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(value == selected ? Color.primary : Color.secondary)
        }
        .frame(width: barWidth)
    }

    private func select(_ value: Int) {
        guard value != score else { return }
        if !ctx.isPreview { Haptics.selection() }
        previous = score ?? 0
        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) { score = value }
    }

    private func previewTick() {
        let target = Self.previewScores[step % Self.previewScores.count]
        step += 1
        select(target)
    }
}
