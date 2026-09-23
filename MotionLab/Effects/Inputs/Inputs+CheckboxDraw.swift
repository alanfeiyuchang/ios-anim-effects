import SwiftUI

extension Effect {
    static let inputsCheckboxDraw = Effect(
        id: "inputs.checkbox-draw",
        category: .inputs,
        interaction: .tap,
        name: L("Drawn Checkbox", "手绘勾选框"),
        summary: L("A hand-inked tick flicks past the box with a spray of ink, and a wavy line scribbles through the task.", "手绘对勾一挥而出、冲出方框并溅起墨点，波浪删除线随手划过任务。"),
        prompt: L(
            "A to-do card whose rows each have a 28 pt rounded checkbox (8 pt corners, 2 pt outline). Checking a row squashes the box to 85% and rebounds on a bouncy spring as it tints indigo; 80 ms later a hand-drawn tick — a short curved down-stroke, then a long flicked up-stroke — inks itself over ~280 ms on a pen-like curve (slow start, fast flick), overshooting past the box's top-right corner as if written in a hurry. At its tip six ink specks spray 12 pt outward and fade within 400 ms. The title dims and a slightly wavy, hand-drawn strike line scribbles across it on the same curve. Unchecking erases the ink in ~60% of the time. A light haptic ticks each time. Handmade, loose and satisfying.",
            "待办清单卡片，每行左侧是 28pt 圆角勾选框（8pt 圆角、2pt 描边）。勾选时方框先压到 85% 再以弹性弹簧回弹，并染上靛蓝；80 毫秒后一笔手绘对勾——短而弯的下笔接一道长长的上挑——以约 280 毫秒、先慢后快的笔势描出，末端冲出方框右上角，像随手一挥。笔尖处六粒墨点向外溅开 12pt，并在 400 毫秒内淡去。标题变暗，一条略带波动的手绘删除线以同样笔势划过。取消勾选时墨迹以约 60% 的时长擦除。每次切换伴随轻触觉。随性而满足。"
        ),
        implementation: L(
            "Hand-drawn tick and wavy strike Shapes built from quad/cubic curves (the tick deliberately leaves its rect) are revealed with trim(from:to:) under a delayed timingCurve; a keyframeAnimator squashes the box, and a second one keyed on the checked flag sprays the ink specks.",
            "手绘对勾与波浪删除线是由二次/三次曲线构成的自定义 Shape（对勾刻意越出自身矩形），在延迟的 timingCurve 下用 trim(from:to:) 描出；一个 keyframeAnimator 压缩方框，另一个以勾选状态为触发溅出墨点。"
        ),
        apis: ["Shape", "trim(from:to:)", "timingCurve", "keyframeAnimator"],
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
                    InputScribbleShape()
                        .trim(from: 0, to: checked && strike ? 1 : 0)
                        .stroke(Color.secondary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .frame(height: 6)
                        .animation(checked ? InputInk.pen(draw).delay(0.08) : .easeIn(duration: draw * 0.6), value: checked)
                }
                .animation(.easeOut(duration: 0.25), value: checked)
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}

/// Pen-like pacing: a hesitant start, then a quick flick.
private enum InputInk {
    static func pen(_ duration: Double) -> Animation {
        .timingCurve(0.55, 0, 0.25, 1, duration: duration)
    }
}

private struct InputCheckBox: View {
    let checked: Bool
    let draw: Double
    let squash: Double

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
    }

    private var tickAnimation: Animation {
        checked ? InputInk.pen(draw).delay(0.08) : .easeIn(duration: draw * 0.6)
    }

    var body: some View {
        let dip = squash
        ZStack {
            shape.fill(Palette.indigo.opacity(checked ? 0.14 : 0))
            shape.strokeBorder(checked ? Palette.indigo.opacity(0.7) : Color.primary.opacity(0.25), lineWidth: 2)
        }
        .frame(width: 28, height: 28)
        .animation(.easeOut(duration: 0.2), value: checked)
        .keyframeAnimator(initialValue: 1.0, trigger: checked) { content, scale in
            content.scaleEffect(scale)
        } keyframes: { _ in
            KeyframeTrack(\.self) {
                CubicKeyframe(dip, duration: 0.08)
                SpringKeyframe(1, duration: 0.4, spring: .bouncy)
            }
        }
        .overlay {
            InputTickShape()
                .trim(from: 0, to: checked ? 1 : 0)
                .stroke(Palette.primary, style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
                .animation(tickAnimation, value: checked)
        }
        .overlay(alignment: .topLeading) {
            InputInkBurst(checked: checked, delay: draw + 0.08)
                .offset(x: 32, y: -3)
        }
    }
}

/// Six ink specks sprayed from the tick's tip once it lands.
private struct InputInkBurst: View {
    let checked: Bool
    let delay: Double

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(index % 2 == 0 ? Palette.indigo : Palette.violet)
                    .frame(width: 3.5, height: 3.5)
                    .keyframeAnimator(initialValue: 0.0, trigger: checked) { content, t in
                        speck(content, index: index, t: t)
                    } keyframes: { _ in
                        KeyframeTrack(\.self) {
                            LinearKeyframe(0, duration: 0.001 + delay * 0.8)
                            CubicKeyframe(1, duration: 0.4)
                        }
                    }
            }
        }
        .opacity(checked ? 1 : 0)
        .allowsHitTesting(false)
    }

    private func speck(_ content: some View, index: Int, t: Double) -> some View {
        let angle: Double = -120 + Double(index) * 36
        let radians: Double = angle * .pi / 180
        let distance: Double = 12 * t
        let x = CGFloat(cos(radians) * distance)
        let y = CGFloat(sin(radians) * distance)
        let alpha: Double = t > 0 && t < 1 ? 1 - t : 0
        let size: CGFloat = CGFloat(1 - t * 0.5)
        return content
            .scaleEffect(size)
            .offset(x: x, y: y)
            .opacity(alpha)
    }
}

/// A quick hand-drawn tick: curved down-stroke, then a long flick that overshoots the box's top-right corner.
private struct InputTickShape: Shape {
    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
        }
        var path = Path()
        path.move(to: point(0.2, 0.5))
        path.addQuadCurve(to: point(0.42, 0.8), control: point(0.3, 0.6))
        path.addCurve(to: point(1.15, -0.1), control1: point(0.55, 0.5), control2: point(0.85, 0.1))
        return path
    }
}

/// A slightly wavy strike line, like a pen stroke through the text.
private struct InputScribbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let midY = rect.midY
        let w = rect.width
        var path = Path()
        path.move(to: CGPoint(x: rect.minX - 2, y: midY + 1))
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.5, y: midY),
            control1: CGPoint(x: rect.minX + w * 0.15, y: midY - 2.5),
            control2: CGPoint(x: rect.minX + w * 0.3, y: midY + 2.5)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX + 3, y: midY - 1.5),
            control1: CGPoint(x: rect.minX + w * 0.7, y: midY - 2.5),
            control2: CGPoint(x: rect.minX + w * 0.85, y: midY + 2)
        )
        return path
    }
}
