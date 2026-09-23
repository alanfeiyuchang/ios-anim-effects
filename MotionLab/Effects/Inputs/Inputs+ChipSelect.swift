import SwiftUI

extension Effect {
    static let inputsChipSelect = Effect(
        id: "inputs.chip-select",
        category: .inputs,
        interaction: .tap,
        name: L("Morphing Tag Chips", "形变标签选择"),
        summary: L("Chips fill, grow a checkmark and reflow their neighbours.", "标签被选中时填充颜色、长出对勾，并推动周围标签重新排布。"),
        prompt: L(
            "A wrapping cloud of capsule tags (15 pt medium text, 14 pt horizontal padding) on quiet gray fills. Selecting a tag morphs it in one spring (response 0.4 s, damping 0.7): the fill crossfades to an indigo-to-violet gradient, the label turns white, and a small checkmark scales in from 30% at the leading edge, widening the capsule; neighbouring chips smoothly reflow to their new positions instead of jumping. The chip dips to 94% under the finger and rebounds. A header counter (\"3 selected\") rolls its digit. Deselecting reverses the morph. Light, flexible and satisfying to tap through during onboarding.",
            "一组自动换行的胶囊标签（15pt 中等字重、左右内边距 14pt），底色为安静的浅灰。选中某个标签时，由同一条弹簧（响应 0.4 秒、阻尼 0.7）完成形变：底色交叉过渡为靛蓝到紫罗兰渐变，文字变白，左侧一个小对勾从 30% 缩放出现，把胶囊撑宽；相邻标签平滑流动到新位置而不是跳变。手指按下时标签缩到 94% 再回弹。顶部计数（“已选 3 个”）数字滚动更新。取消选择则反向形变。轻盈灵活，特别适合引导页中连续点选兴趣。"
        ),
        implementation: L(
            "Chips live in a custom flow Layout; toggling selection inside withAnimation lets SwiftUI animate each chip's size change and the resulting layout reflow, while the checkmark uses an insertion transition.",
            "标签放在自定义流式 Layout 中；在 withAnimation 中切换选中状态，SwiftUI 会同时动画每个标签的尺寸变化与随之而来的重新排布，对勾使用插入过渡。"
        ),
        apis: ["Layout", "withAnimation", "transition(.scale)", "numericText", "ButtonStyle"],
        tags: ["chips", "tags", "filter", "select", "标签", "筛选", "多选", "兴趣"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.9, default: 0.4, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.4...1.0, default: 0.7),
        ]
    ) { ctx in
        InputChipSelectDemo(ctx: ctx)
    }
}

private struct InputChipSelectDemo: View {
    let ctx: DemoContext
    @State private var selected: Set<Int> = [1, 4]
    @State private var step = 0

    private var topics: [LocalizedText] {
        [
            L("Design", "设计"), L("Motion", "动效"), L("Swift", "Swift"),
            L("Typography", "字体排印"), L("3D", "3D"), L("Color", "色彩"),
            L("Prototyping", "原型"), L("Sound", "声音"), L("AI", "AI"),
        ]
    }

    private static let previewOrder = [0, 5, 1, 7, 3, 4, 8, 0, 5, 7, 3, 8]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 4) {
                Text(L("Pick your interests", "选择你的兴趣"), ctx.language)
                    .font(.headline)
                Spacer()
                if ctx.language == .zh {
                    counterCaption("已选")
                }
                Text("\(selected.count)")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Palette.indigo)
                    .contentTransition(.numericText(value: Double(selected.count)))
                if ctx.language == .en {
                    counterCaption("selected")
                }
            }
            FlowLayout(spacing: 8) {
                ForEach(topics.indices, id: \.self) { index in
                    InputChip(
                        title: topics[index](ctx.language),
                        isSelected: selected.contains(index)
                    ) {
                        toggle(index)
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 310)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 0.8, delay: 0.4) { previewTick() }
    }

    private func counterCaption(_ text: String) -> some View {
        Text(verbatim: text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private func toggle(_ index: Int) {
        if !ctx.isPreview { Haptics.selection() }
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            if selected.contains(index) {
                selected.remove(index)
            } else {
                selected.insert(index)
            }
        }
    }

    private func previewTick() {
        toggle(Self.previewOrder[step % Self.previewOrder.count])
        step += 1
    }
}

private struct InputChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                }
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background {
                ZStack {
                    Capsule().fill(Color.primary.opacity(0.07))
                    Capsule()
                        .fill(Palette.primary)
                        .opacity(isSelected ? 1 : 0)
                }
            }
            .shadow(color: Palette.indigo.opacity(isSelected ? 0.3 : 0), radius: 8, y: 4)
        }
        .buttonStyle(InputChipPressStyle())
    }
}

private struct InputChipPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
