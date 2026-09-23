import SwiftUI

extension Effect {
    static let inputsCheckboxDraw = Effect(
        id: "inputs.checkbox-draw",
        category: .inputs,
        interaction: .tap,
        name: L("Drawn Checkbox", "手绘勾选框"),
        summary: L("The box pops, the checkmark draws itself and the task strikes through.", "方框弹起，对勾自行描绘，任务文字被划掉。"),
        prompt: L(
            "A to-do list card whose rows each have a 28 pt rounded checkbox (8 pt continuous corners, 2 pt outline). Checking a row: the gradient fill blooms from 30% to full size inside the box while the box squashes to 85% and rebounds to 100% on a bouncy spring; after an 80 ms delay a white checkmark stroke (3 pt, round caps) draws itself from start to end over ~280 ms ease-out. The row's title dims to secondary and a 2 pt strike-through line grows left to right across it on the same curve. Unchecking rewinds the stroke in about 60% of the time and shrinks the fill away. A light haptic ticks each time. It feels crisp, handmade and rewarding to complete.",
            "待办清单卡片，每行左侧是 28pt 的圆角勾选框（8pt 连续圆角，2pt 描边）。勾选时：渐变填充在框内从 30% 扩展到满格，方框以弹性弹簧先压缩到 85% 再回弹到 100%；延迟 80 毫秒后，一条白色对勾笔画（3pt、圆头）以约 280 毫秒的缓出曲线从起点描绘到终点。该行标题同时褪为次级色，一条 2pt 删除线以相同曲线从左到右划过。取消勾选时笔画以约 60% 的时长反向擦除，填充随之收缩。每次切换伴随轻触觉。干脆利落，带手作感，完成任务时格外有成就感。"
        ),
        implementation: L(
            "A custom checkmark Shape is revealed with trim(from:to:) under a delayed ease-out animation; the fill and a keyframeAnimator provide the pop, and a leading-anchored scaleEffect(x:) draws the strike-through.",
            "自定义对勾 Shape 通过 trim(from:to:) 配合延迟缓出动画描绘；填充与 keyframeAnimator 提供弹跳，前对齐的 scaleEffect(x:) 绘制删除线。"
        ),
        apis: ["Shape", "trim(from:to:)", "keyframeAnimator", "scaleEffect(x:anchor:)"],
        tags: ["checkbox", "checkmark", "todo", "strike", "勾选", "复选框", "待办", "删除线"],
        params: [
            .slider("draw", L("Draw duration", "描绘时长"), 0.1...0.8, default: 0.28, unit: "s"),
            .slider("squash", L("Press squash", "按压收缩"), 0.6...1.0, default: 0.85),
            .toggle("strike", L("Strike-through", "删除线"), default: true),
        ]
    ) { ctx in
        InputCheckboxDemo(ctx: ctx)
    }
}

private struct InputCheckboxDemo: View {
    let ctx: DemoContext
    @State private var checked: [Bool] = [true, false, false]
    @State private var step = 0

    private var titles: [LocalizedText] {
        [
            L("Sketch onboarding flow", "绘制引导流程草图"),
            L("Tune spring curves", "调整弹簧曲线"),
            L("Ship the prototype", "发布交互原型"),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(alignment: .leading, spacing: 18) {
                ForEach(titles.indices, id: \.self) { index in
                    InputCheckRow(
                        title: titles[index](ctx.language),
                        checked: checked[index],
                        draw: ctx["draw"],
                        squash: ctx["squash"],
                        strike: ctx.bool("strike")
                    ) {
                        toggle(index)
                    }
                }
            }
            .padding(22)
            .frame(width: 290)
            .demoCard()
            Spacer()
            DemoHint(text: L("Tap a task to check it off", "点击任务即可勾选"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.0, delay: 0.4) { previewTick() }
    }

    private func toggle(_ index: Int) {
        if !ctx.isPreview { Haptics.tap() }
        checked[index].toggle()
    }

    private func previewTick() {
        toggle((step + 1) % checked.count)
        step += 1
    }
}

private struct InputCheckRow: View {
    let title: String
    let checked: Bool
    let draw: Double
    let squash: Double
    let strike: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            InputCheckBox(checked: checked, draw: draw, squash: squash)
            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(checked ? Color.secondary : Color.primary)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary)
                        .frame(height: 2)
                        .scaleEffect(x: checked && strike ? 1 : 0, anchor: .leading)
                        .animation(.easeOut(duration: draw).delay(checked ? 0.08 : 0), value: checked)
                }
                .animation(.easeOut(duration: 0.25), value: checked)
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}

private struct InputCheckBox: View {
    let checked: Bool
    let draw: Double
    let squash: Double

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
    }

    var body: some View {
        let dip = squash
        ZStack {
            shape.strokeBorder(Color.primary.opacity(0.25), lineWidth: 2)
            shape
                .fill(Palette.primary)
                .scaleEffect(checked ? 1 : 0.3)
                .opacity(checked ? 1 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.65), value: checked)
            InputCheckmarkShape()
                .trim(from: 0, to: checked ? 1 : 0)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .padding(6)
                .animation(checked ? .easeOut(duration: draw).delay(0.08) : .easeIn(duration: draw * 0.6), value: checked)
        }
        .frame(width: 28, height: 28)
        .keyframeAnimator(initialValue: 1.0, trigger: checked) { content, scale in
            content.scaleEffect(scale)
        } keyframes: { _ in
            KeyframeTrack(\.self) {
                CubicKeyframe(dip, duration: 0.08)
                SpringKeyframe(1, duration: 0.4, spring: .bouncy)
            }
        }
    }
}

private struct InputCheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.midY + rect.height * 0.04))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.maxY - rect.height * 0.12))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.06, y: rect.minY + rect.height * 0.14))
        return path
    }
}
