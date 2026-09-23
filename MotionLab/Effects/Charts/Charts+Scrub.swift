import SwiftUI
import Charts

extension Effect {
    static let chartsScrub = Effect(
        id: "charts.scrub-tooltip",
        category: .charts,
        interaction: .gesture,
        name: L("Scrub with Tooltip", "滑动查看数据提示"),
        summary: L("Drag across a line chart; a rule, point and tooltip glide along with haptic ticks.", "在折线图上滑动，参考线、数据点与提示框随之滑行并伴随触感。"),
        prompt: L(
            "A 24-hour line chart (Swift Charts, Catmull-Rom line 2.5 pt in blue over a blue-to-clear gradient area, hidden y-axis, hour labels every 6 h) inside a card whose header shows the current value in large rounded digits. Touching and dragging horizontally selects the nearest hour: a dashed 1 pt vertical rule appears, an 11 pt point with a 2.5 pt white ring sits on the curve, and a compact material tooltip (time + value) floats above the chart, clamped so it never leaves the plot. The header number rolls to the selected value with a numeric content transition, every hour boundary crossed produces a selection haptic tick, and all marks glide with a snappy 250 ms animation rather than jumping. Lifting the finger clears the selection. Precise and tactile, like the Stocks and Health apps.",
            "一张 24 小时折线图（Swift Charts，2.5pt 蓝色 Catmull-Rom 曲线，下方为蓝色到透明的渐变面积，隐藏 y 轴，每 6 小时一个时间标签），置于卡片中，卡片标题以大号圆体数字显示当前数值。手指按下并水平拖动时选中最近的整点：出现一条 1pt 虚线竖向参考线，一个带 2.5pt 白色描边的 11pt 数据点贴在曲线上，上方悬浮一个紧凑的材质提示框（时间 + 数值），并自动约束在绘图区内。标题数字以数字内容转场滚动到所选数值，每跨过一个整点触发一次选择触感，所有标记以 250ms 的利落动画滑行而非跳变。抬手即取消选择，精准可触，如“股市”“健康”App。"
        ),
        implementation: L(
            "chartXSelection(value:) binds the selected hour, while chartGesture swaps in a horizontal-first DragGesture that calls proxy.selectXValue(at:), so vertical swipes still scroll the page; a RuleMark annotation with overflowResolution(.fit(to: .chart)) renders the tooltip and a selection haptic ticks on each hour.",
            "chartXSelection(value:) 绑定所选小时，chartGesture 换成横向优先的 DragGesture 并调用 proxy.selectXValue(at:)，竖向滑动仍可滚动页面；RuleMark 的 annotation 以 overflowResolution 的 .fit(to: .chart) 渲染提示框，每跨一个整点触发选择触感。"
        ),
        apis: ["chartXSelection(value:)", "chartGesture", "RuleMark", "annotation(position:overflowResolution:)", "AreaMark"],
        tags: ["scrub", "tooltip", "selection", "line chart", "滑动", "提示框", "数据点", "交互图表"],
        params: [
            .choice("curve", L("Interpolation", "插值方式"), [L("Smooth", "平滑"), L("Linear", "折线"), L("Step", "阶梯")]),
            .toggle("area", L("Area fill", "面积填充"), default: true),
        ]
    ) { ctx in
        ScrubDemo(ctx: ctx)
    }
}

private struct HourPoint: Identifiable {
    let id: Int
    let value: Double
}

private let scrubData: [HourPoint] = (0..<24).map { hour in
    let h = Double(hour)
    let base = 42 + 26 * sin((h - 7) / 24 * 2 * Double.pi) + 9 * sin(h * 1.3) + 5 * cos(h * 2.7)
    return HourPoint(id: hour, value: max(base, 8))
}

private struct ScrubDemo: View {
    let ctx: DemoContext
    @State private var selected: Int?
    /// True once the current touch has moved mostly sideways; until then the page keeps scrolling.
    @State private var engaged = false
    /// Resets itself when the touch ends or the system cancels it, so a scrub never gets stuck.
    @GestureState private var touching = false
    @State private var sweep: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var interpolation: InterpolationMethod {
        switch ctx.int("curve") {
        case 1: return .linear
        case 2: return .stepCenter
        default: return .catmullRom
        }
    }

    private var selectedPoint: HourPoint? {
        guard let selected else { return nil }
        return scrubData.first { $0.id == selected }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            chart
                .frame(height: 170)
        }
        .padding(16)
        .frame(width: 310)
        .demoCard()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Drag across the chart", "在图表上左右滑动"), ctx: ctx)
                .padding(.bottom, 8)
        }
        .onChange(of: selected) { _, newValue in
            // Only a real finger ticks: the arrival sweep and previews stay silent.
            if newValue != nil && engaged { Haptics.selection() }
        }
        .onChange(of: touching) { _, isTouching in
            if !isTouching { endScrub() }
        }
        .onAppear { startSweep() }
        .onDisappear { sweep?.cancel() }
        .autoplay(ctx.isPreview, every: 0.32, delay: 0.5, intro: false) { advance() }
    }

    private var header: some View {
        let value = selectedPoint?.value ?? scrubData[scrubData.count - 1].value
        let label = selectedPoint.map { String(format: "%02d:00", $0.id) } ?? (ctx.language == .zh ? "当前" : "Now")
        return VStack(alignment: .leading, spacing: 2) {
            Text(ctx.language == .zh ? "心率 · \(label)" : "Heart rate · \(label)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(verbatim: "\(Int(value.rounded()) + 40)")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: value))
                Text(verbatim: "BPM")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Palette.pink)
            }
        }
        .animation(.snappy(duration: 0.25), value: selected)
    }

    private var chart: some View {
        Chart {
            ForEach(scrubData) { point in
                if ctx.bool("area") {
                    AreaMark(x: .value("Hour", point.id), y: .value("Value", point.value))
                        .interpolationMethod(interpolation)
                        .foregroundStyle(LinearGradient(colors: [Palette.blue.opacity(0.32), Palette.blue.opacity(0)], startPoint: .top, endPoint: .bottom))
                }
                LineMark(x: .value("Hour", point.id), y: .value("Value", point.value))
                    .interpolationMethod(interpolation)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .foregroundStyle(Palette.blue)
            }
            if let point = selectedPoint {
                RuleMark(x: .value("Hour", point.id))
                    .foregroundStyle(Color.primary.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .annotation(position: .top, spacing: 4, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                        ScrubTooltip(hour: point.id, value: point.value + 40)
                    }
                PointMark(x: .value("Hour", point.id), y: .value("Value", point.value))
                    .foregroundStyle(Palette.blue)
                    .symbol {
                        Circle()
                            .fill(Palette.blue)
                            .frame(width: 11, height: 11)
                            .overlay(Circle().strokeBorder(.white, lineWidth: 2.5))
                            .shadow(color: Palette.blue.opacity(0.5), radius: 4)
                    }
            }
        }
        .chartXSelection(value: $selected)
        .chartGesture { proxy in
            DragGesture(minimumDistance: 8)
                .updating($touching) { _, state, _ in state = true }
                .onChanged { value in scrub(value, proxy: proxy) }
        }
        .chartYScale(domain: 0...95)
        .chartYAxis(.hidden)
        .chartXScale(domain: 0...23)
        .chartXAxis {
            AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                AxisValueLabel {
                    Text(verbatim: String(format: "%02d:00", value.as(Int.self) ?? 0))
                }
            }
        }
        .animation(.snappy(duration: 0.25), value: selected)
    }

    private func advance() {
        let next = (selected ?? -1) + 1
        selected = next < scrubData.count ? next : nil
    }

    /// Horizontal-first: a mostly vertical swipe is left to the page's scroll view.
    private func scrub(_ value: DragGesture.Value, proxy: ChartProxy) {
        if !engaged {
            guard abs(value.translation.width) > abs(value.translation.height) else { return }
            engaged = true
            sweep?.cancel()
        }
        proxy.selectXValue(at: value.location.x)
    }

    private func endScrub() {
        guard engaged else { return }
        engaged = false
        withAnimation(.snappy(duration: 0.25)) { selected = nil }
    }

    /// Detail arrival: glide the cursor once across the day, then clear it.
    private func startSweep() {
        guard !ctx.isPreview, !ctx.isStill, !reduceMotion else { return }
        sweep?.cancel()
        sweep = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.7))
            for hour in 0..<scrubData.count {
                guard !Task.isCancelled else { return }
                withAnimation(.snappy(duration: 0.25)) { selected = hour }
                try? await Task.sleep(for: .milliseconds(40))
            }
            guard !Task.isCancelled else { return }
            try? await Task.sleep(for: .seconds(0.35))
            guard !Task.isCancelled else { return }
            withAnimation(.snappy(duration: 0.25)) { selected = nil }
        }
    }
}

private struct ScrubTooltip: View {
    let hour: Int
    let value: Double

    var body: some View {
        VStack(spacing: 1) {
            Text(String(format: "%02d:00", hour))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(verbatim: "\(Int(value.rounded()))")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Palette.stroke, lineWidth: 1))
        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
    }
}
