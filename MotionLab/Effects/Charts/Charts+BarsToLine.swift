import SwiftUI

extension Effect {
    static let chartsBarsToLine = Effect(
        id: "charts.bars-to-line",
        category: .charts,
        interaction: .tap,
        name: L("Bars ⇄ Line Morph", "柱状图 ⇄ 折线图形变"),
        summary: L("Each bar shrinks into a dot at its value, then a line threads through the dots — and back.", "每根柱子收缩成数值处的圆点，再由一条折线把圆点串起——也可反向还原。"),
        prompt: L(
            "An eight-month revenue card switches between a bar chart and a line chart in two beats. Bars → line: each 22 pt bar collapses from the baseline up into a 10 pt dot at its exact value on a spring (response 0.5 s, damping 0.75), 40 ms apart left to right; once the last dot lands, a 2.5 pt indigo line draws through them left to right over 600 ms (ease-in-out), and a soft gradient area fades in beneath it. Line → bars reverses the choreography: the line and area retract in 400 ms, then each dot drops a bar back down to the baseline with the same stagger. The values never leave their positions, so the eye follows every data point across the change. Legible, continuous, editorial.",
            "一张八个月营收卡片以“两拍”在柱状图与折线图之间切换。柱 → 线：每根 22pt 宽的柱子从基线向上收拢，化作停在其精确数值处的 10pt 圆点，使用弹簧（响应 0.5 秒、阻尼 0.75），从左到右间隔 40ms；最后一个圆点落定后，一条 2.5pt 的靛蓝折线在 600ms 内（缓入缓出）从左到右穿过所有圆点绘出，下方柔和的渐变面积随之淡入。线 → 柱则反向编排：折线与面积在 400ms 内收回，随后每个圆点以相同错峰向下“放出”柱子直抵基线。数据点在切换中始终不离原位，视线可以追踪每一个数值。清晰、连贯、有编辑设计感。"
        ),
        implementation: L(
            "Bars are rounded rectangles whose frame and position interpolate between a full bar and a dot, each with .animation(spring.delay(...), value: toLine); the line is a Path revealed with trim(from:to:) animated after the dots settle, and the reverse flips the order with Task delays.",
            "柱子是圆角矩形，其尺寸与位置在“整根柱子”与“圆点”之间插值，各自带 .animation(spring.delay(...), value: toLine)；折线是用 trim(from:to:) 揭示的 Path，在圆点落定后再动画；反向切换通过 Task 延迟调换先后顺序。"
        ),
        apis: ["trim(from:to:)", "animation(_:value:)", "Animation.delay", "Path", "position(x:y:)"],
        tags: ["bar chart", "line chart", "morph", "chart type", "柱状图", "折线图", "形变", "图表切换"],
        params: [
            .slider("stagger", L("Stagger", "错峰间隔"), 0...0.1, default: 0.04, unit: "s"),
            .slider("draw", L("Line draw", "折线绘制时长"), 0.3...1.2, default: 0.6, unit: "s"),
        ]
    ) { ctx in
        BarsToLineDemo(ctx: ctx)
    }
}

private let barLineValues: [CGFloat] = [0.42, 0.55, 0.48, 0.7, 0.62, 0.84, 0.76, 0.92]
private let barLineMonthsEN = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug"]
private let barLineMonthsZH = ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月"]

private struct BarsToLineDemo: View {
    let ctx: DemoContext
    @State private var toLine = false
    @State private var drawn: CGFloat = 0
    @State private var busy = false

    private let plot = CGSize(width: 264, height: 170)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            ZStack(alignment: .topLeading) {
                gridLines
                areaFill
                linePath
                    .trim(from: 0, to: drawn)
                    .stroke(Palette.indigo, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                ForEach(barLineValues.indices, id: \.self) { index in
                    bar(index)
                }
            }
            .frame(width: plot.width, height: plot.height)
            monthRow
        }
        .padding(18)
        .demoCard()
        .contentShape(Rectangle())
        .onTapGesture { toggle(haptic: true) }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap to switch chart type", "点击切换图表类型"), ctx: ctx)
                .padding(.bottom, 6)
        }
        .autoplay(ctx.isPreview, every: 2.6, delay: 1.0) { toggle(haptic: false) }
    }

    private var header: some View {
        HStack {
            Text(ctx.language == .zh ? "月度营收" : "Monthly revenue")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: toLine ? "chart.xyaxis.line" : "chart.bar.fill")
                    .contentTransition(.symbolEffect(.replace))
                Text(toLine ? (ctx.language == .zh ? "折线" : "Line") : (ctx.language == .zh ? "柱状" : "Bars"))
                    .contentTransition(.opacity)
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(Palette.indigo)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Palette.indigo.opacity(0.12), in: Capsule())
        }
        .frame(width: plot.width)
    }

    private func point(_ index: Int) -> CGPoint {
        let step = plot.width / CGFloat(barLineValues.count)
        let x = step * (CGFloat(index) + 0.5)
        let y = plot.height * (1 - barLineValues[index])
        return CGPoint(x: x, y: y)
    }

    private func bar(_ index: Int) -> some View {
        let top = point(index)
        let barHeight = plot.height - top.y
        let width: CGFloat = toLine ? 10 : 22
        let height: CGFloat = toLine ? 10 : barHeight
        let centerY: CGFloat = toLine ? top.y : top.y + barHeight / 2
        let stagger = ctx["stagger"]
        let delay = toLine ? Double(index) * stagger : 0.4 + Double(index) * stagger
        return RoundedRectangle(cornerRadius: toLine ? 5 : 6, style: .continuous)
            .fill(LinearGradient(colors: [Palette.sky, Palette.indigo], startPoint: .top, endPoint: .bottom))
            .overlay {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(.white, lineWidth: toLine ? 2 : 0)
            }
            .frame(width: width, height: height)
            .position(x: top.x, y: centerY)
            .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(delay), value: toLine)
    }

    private var linePath: Path {
        var path = Path()
        for index in barLineValues.indices {
            let p = point(index)
            if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        return path
    }

    private var areaFill: some View {
        var area = linePath
        area.addLine(to: CGPoint(x: point(barLineValues.count - 1).x, y: plot.height))
        area.addLine(to: CGPoint(x: point(0).x, y: plot.height))
        area.closeSubpath()
        return area
            .fill(LinearGradient(colors: [Palette.indigo.opacity(0.22), Palette.indigo.opacity(0)], startPoint: .top, endPoint: .bottom))
            .opacity(Double(drawn))
    }

    private var gridLines: some View {
        VStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { _ in
                Rectangle()
                    .fill(Color.primary.opacity(0.07))
                    .frame(height: 1)
                Spacer(minLength: 0)
            }
            Rectangle()
                .fill(Color.primary.opacity(0.18))
                .frame(height: 1)
        }
        .frame(width: plot.width, height: plot.height)
    }

    private var monthRow: some View {
        let labels = ctx.language == .zh ? barLineMonthsZH : barLineMonthsEN
        return HStack(spacing: 0) {
            ForEach(labels.indices, id: \.self) { index in
                Text(labels[index])
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(width: plot.width)
    }

    private func toggle(haptic: Bool) {
        guard !busy else { return }
        busy = true
        if haptic && !ctx.isPreview { Haptics.tap(.light) }
        let stagger = ctx["stagger"]
        let settle = 0.35 + Double(barLineValues.count) * stagger
        if !toLine {
            withAnimation(.snappy) { toLine = true }
            withAnimation(.easeInOut(duration: ctx["draw"]).delay(settle)) { drawn = 1 }
        } else {
            withAnimation(.easeInOut(duration: 0.4)) { drawn = 0 }
            withAnimation(.snappy) { toLine = false }
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(settle + 0.2))
            busy = false
        }
    }
}
