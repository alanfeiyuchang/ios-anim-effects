import SwiftUI

extension Effect {
    static let navigationTraceTab = Effect(
        id: "navigation.trace-tab",
        category: .navigation,
        interaction: .tap,
        name: L("Outline Trace Tabs", "描边追踪标签"),
        summary: L(
            "The old tab's outline unwinds while a new outline draws itself around the chosen tab, then fills in.",
            "旧标签的描边被收回，新描边绕着所选标签自行画出，再填充底色。"
        ),
        prompt: L(
            "A segmented range picker (Day, Week, Month, Year) above a seven-bar chart. The selected segment is marked by a 2 pt gradient outline, not a moving thumb. On a new selection the old outline retracts toward its bottom centre over ≈0.3 s while the new one draws on from the bottom centre of the new segment, growing both ways around the pill and meeting at the top in ≈0.6 s (ease-in-out, starting ≈200 ms after the retraction begins). Once closed, a 12% tint fills the pill and the label turns to the accent colour. The chart bars below re-grow to the new data on a bouncy spring, staggered 30 ms left to right. Precise, drafted and technical — like a pen tracing the choice.",
            "一个时间范围分段选择器（日、周、月、年），下方是七根柱状图。选中态不是滑动的滑块，而是一圈 2pt 的渐变描边。切换时，旧描边在约 0.3 秒内向底部中点收回；新描边从新分段的底部中点起笔，沿胶囊两侧同时生长，约 0.6 秒后在顶部闭合（缓入缓出，比收回晚约 200 毫秒开始）。闭合后胶囊内填入 12% 的色调，文字变为强调色。下方柱状图以弹跳弹簧长到新数据，自左向右错峰 30 毫秒。精确、带草图感与技术感，像一支笔描出了你的选择。"
        ),
        implementation: L(
            "Each segment owns a custom pill Shape whose path starts at the top centre, so trim(from: 0.5 − p/2, to: 0.5 + p/2) grows from the bottom centre both ways; p animates per segment with animation(_:value:) and a delay only for the incoming one.",
            "每个分段都有一个自定义胶囊 Shape，其路径从顶部中点起笔，因此 trim(from: 0.5 − p/2, to: 0.5 + p/2) 会从底部中点向两侧生长；p 通过 animation(_:value:) 按分段动画，仅新分段带延迟。"
        ),
        apis: ["trim(from:to:)", "Shape", "animation(_:value:)", "AngularGradient", "spring(response:dampingFraction:)"],
        tags: ["segmented control", "outline", "stroke draw", "tabs", "分段控件", "描边", "路径绘制", "标签页"],
        params: [
            .slider("duration", L("Trace duration", "描边时长"), 0.3...1.2, default: 0.6, unit: "s"),
            .slider("line", L("Line width", "线宽"), 1...4, default: 2, decimals: 1, unit: "pt"),
            .toggle("fill", L("Fill after trace", "描完后填充"), default: true),
        ]
    ) { ctx in
        TraceTabDemo(ctx: ctx)
    }
}

private let traceTabs: [LocalizedText] = [L("Day", "日"), L("Week", "周"), L("Month", "月"), L("Year", "年")]

private struct TraceTabDemo: View {
    let ctx: DemoContext
    @State private var selected = 1

    var body: some View {
        VStack(spacing: 26) {
            segments
            chart
            DemoHint(text: L("Tap a range", "点击任一范围"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.4) { select((selected + 1) % traceTabs.count) }
    }

    private var segments: some View {
        HStack(spacing: 6) {
            ForEach(0..<traceTabs.count, id: \.self) { index in
                segment(index)
            }
        }
        .padding(5)
        .background(Palette.surface, in: Capsule())
    }

    private func segment(_ index: Int) -> some View {
        let isSelected = index == selected
        let duration: Double = ctx["duration"]
        let progress: CGFloat = isSelected ? 1 : 0
        let trace: Animation = isSelected
            ? .easeInOut(duration: duration).delay(0.2)
            : .easeIn(duration: duration * 0.5)
        let fillAnimation: Animation = isSelected
            ? .easeOut(duration: 0.25).delay(0.2 + duration * 0.85)
            : .easeOut(duration: 0.15)
        return Text(traceTabs[index], ctx.language)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSelected ? Palette.indigo : Color.secondary)
            .frame(width: 64, height: 36)
            .background {
                TracePill()
                    .fill(Palette.indigo.opacity(isSelected && ctx.bool("fill") ? 0.12 : 0))
                    .animation(fillAnimation, value: selected)
            }
            .overlay {
                TracePill()
                    .trim(from: 0.5 - progress / 2, to: 0.5 + progress / 2)
                    .stroke(
                        AngularGradient(colors: [Palette.indigo, Palette.violet, Palette.pink, Palette.indigo], center: .center),
                        style: StrokeStyle(lineWidth: ctx.cg("line"), lineCap: .round)
                    )
                    .animation(trace, value: selected)
            }
            .contentShape(Capsule())
            .onTapGesture { select(index) }
            .animation(.easeInOut(duration: 0.25), value: selected)
    }

    private var chart: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ForEach(0..<7, id: \.self) { bar in
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(bar == 4 ? AnyShapeStyle(Palette.primary) : AnyShapeStyle(Palette.indigo.opacity(0.22)))
                    .frame(width: 22, height: barHeight(bar))
                    .animation(.spring(response: 0.45, dampingFraction: 0.62).delay(Double(bar) * 0.03), value: selected)
            }
        }
        .frame(height: 130, alignment: .bottom)
    }

    private func barHeight(_ bar: Int) -> CGFloat {
        let seed: Double = Double(bar * 7 + selected * 13)
        let wave: Double = (sin(seed * 1.7) + 1) / 2
        return CGFloat(28 + wave * 100)
    }

    private func select(_ index: Int) {
        guard index != selected else { return }
        if !ctx.isPreview { Haptics.selection() }
        selected = index
    }
}

/// A capsule outline whose path starts at the top centre and runs clockwise, so its midpoint is the bottom centre.
private struct TracePill: Shape {
    func path(in rect: CGRect) -> Path {
        let r: CGFloat = rect.height / 2
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.midY), radius: r, startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + r, y: rect.midY), radius: r, startAngle: .degrees(90), endAngle: .degrees(270), clockwise: false)
        path.closeSubpath()
        return path
    }
}
