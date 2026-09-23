import SwiftUI

extension Effect {
    static let iconsSearchClose = Effect(
        id: "icons.search-close",
        category: .icons,
        interaction: .tap,
        name: L("Magnifier → Close", "放大镜 → 关闭"),
        summary: L("The lens unwinds into the handle, which becomes one stroke of an X.", "镜圈沿着手柄回卷消失，手柄化作 X 的一笔。"),
        prompt: L(
            "A round search button holds a stroked magnifier, lens plus handle in 3 pt round caps. Tapping expands the button into a 270 pt search pill while the glyph morphs into a close icon in one continuous stroke: the lens unwinds from the handle's side until it vanishes, the handle slides and lengthens into the ‘\\’ diagonal of an X, and from 40% progress the opposite ‘/’ diagonal grows out from the centre. Morph and pill width share one spring (response 0.5 s, damping 0.78) as a placeholder and blinking caret fade in. Tapping the X plays it all backwards and collapses the field, each way with a light haptic, so the icon itself explains the state change.",
            "圆形搜索按钮里是一个描边放大镜（镜圈加手柄，3 pt 圆头）。点击后按钮展开成 270 pt 宽的搜索胶囊，图标以一笔连续的变形变成关闭符号：镜圈从手柄一侧回卷直到消失，手柄滑动并拉长成 X 的「\\」对角线，进度到 40% 时，另一条「/」对角线从中心向两端长出。变形与胶囊宽度共用一个弹簧（响应 0.5 秒、阻尼 0.78），占位文字和闪烁光标随之淡入。点 X 则整段倒放、输入框收起，两个方向都有轻触感。简洁巧妙，图标自己讲清了状态变化。"
        ),
        implementation: L(
            "An Animatable Shape takes one progress value: it trims the lens arc by (1 − progress), linearly interpolates the handle's endpoints onto the first diagonal, and grows the second diagonal from the centre after 40%; the field's width animates with the same spring.",
            "Animatable Shape 只接收一个进度值：按 (1 − 进度) 裁剪镜圈圆弧，把手柄两端线性插值到第一条对角线上，并在 40% 之后从中心长出第二条对角线；输入框宽度使用同一个弹簧动画。"
        ),
        apis: ["Shape", "animatableData", "Path.addArc", "spring(response:dampingFraction:)", "StrokeStyle"],
        tags: ["search", "close", "morph", "magnifier", "搜索", "关闭", "图标形变", "放大镜"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.2...1.0, default: 0.5, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.4...1.0, default: 0.78),
            .slider("weight", L("Stroke weight", "描边粗细"), 1.5...5, default: 3, decimals: 1, unit: "pt"),
        ]
    ) { ctx in
        SearchCloseDemo(ctx: ctx)
    }
}

/// progress 0 = magnifier, 1 = X.
private struct SearchCloseGlyph: Shape {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let p: CGFloat = min(max(progress, 0), 1.08)
        let w: CGFloat = rect.width
        let h: CGFloat = rect.height
        let center = CGPoint(x: rect.minX + w * 0.42, y: rect.minY + h * 0.42)
        let radius: CGFloat = w * 0.27
        let diagonal: CGFloat = 0.70710678
        var path = Path()

        // Lens: an arc that starts at the handle (45°) and shrinks away from it.
        let lens: CGFloat = max(0, 1 - p)
        if lens > 0.001 {
            let start = Angle.degrees(45)
            let end = Angle.degrees(45 + 360 * Double(lens))
            path.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
        }

        // Handle → "\" diagonal.
        let handleStart = CGPoint(x: center.x + radius * diagonal, y: center.y + radius * diagonal)
        let handleEnd = CGPoint(x: rect.minX + w * 0.86, y: rect.minY + h * 0.86)
        let crossStart = CGPoint(x: rect.minX + w * 0.2, y: rect.minY + h * 0.2)
        let crossEnd = CGPoint(x: rect.minX + w * 0.8, y: rect.minY + h * 0.8)
        let t: CGFloat = min(p, 1)
        path.move(to: mix(handleStart, crossStart, t))
        path.addLine(to: mix(handleEnd, crossEnd, t))

        // "/" diagonal grows from the centre after 40%.
        let grow: CGFloat = max(0, (p - 0.4) / 0.6)
        if grow > 0.001 {
            let mid = CGPoint(x: rect.midX, y: rect.midY)
            let half: CGFloat = w * 0.3 * grow
            path.move(to: CGPoint(x: mid.x + half, y: mid.y - half))
            path.addLine(to: CGPoint(x: mid.x - half, y: mid.y + half))
        }
        return path
    }

    private func mix(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }
}

private struct SearchCloseDemo: View {
    let ctx: DemoContext
    @State private var open = false

    private var spring: Animation { .spring(response: ctx["response"], dampingFraction: ctx["damping"]) }

    var body: some View {
        VStack(spacing: 22) {
            field
            DemoHint(text: L("Tap the icon", "点击图标"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.8) { toggle() }
    }

    private var field: some View {
        HStack(spacing: 10) {
            if open {
                HStack(spacing: 2) {
                    Text(L("Search places", "搜索地点"), ctx.language)
                        .foregroundStyle(.tertiary)
                    caret
                }
                .font(.body)
                .padding(.leading, 20)
                .transition(.opacity.combined(with: .offset(x: -12)))
                Spacer(minLength: 0)
            }
            Button { toggle() } label: {
                SearchCloseGlyph(progress: open ? 1 : 0)
                    .stroke(open ? Color.secondary : Color.white, style: StrokeStyle(lineWidth: ctx.cg("weight"), lineCap: .round, lineJoin: .round))
                    .frame(width: 24, height: 24)
                    .frame(width: 56, height: 56)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .frame(width: open ? 270 : 56, height: 56)
        .background(open ? AnyShapeStyle(Palette.elevated) : AnyShapeStyle(Palette.primary), in: Capsule())
        .overlay(Capsule().strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(0.14), radius: 16, y: 8)
        .animation(spring, value: open)
    }

    private var caret: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { timeline in
            let on = Int(timeline.date.timeIntervalSinceReferenceDate * 2) % 2 == 0
            Rectangle()
                .fill(Palette.indigo)
                .frame(width: 2, height: 20)
                .opacity(on ? 1 : 0)
        }
    }

    private func toggle() {
        Haptics.tap(.light)
        withAnimation(spring) {
            open.toggle()
        }
    }
}
