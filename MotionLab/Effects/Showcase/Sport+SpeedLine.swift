import SwiftUI

extension Effect {
    static let showcaseSpeedLine = Effect(
        id: "showcase.speed-line",
        category: .showcase,
        interaction: .gesture,
        name: L("Top Speed Line", "极速折线"),
        summary: L("The speed number rolls up while a glowing dot rides the line as it draws on; drag to scrub.", "数字滚动上涨，发光圆点沿绘制中的折线前进；拖动即可逐点查看。"),
        prompt: L(
            "A dark TOP SPEED widget with a large rounded \"50 km/h\" readout above a jagged speed line. On appear the line draws from left to right over ~1.6 s with a soft orange glow and a fading area gradient beneath it, while a white dot with an orange halo rides exactly on the leading tip; the number rolls up digit by digit (numeric content transition) to the running maximum as the dot passes each sample. Dragging across the chart snaps a hairline cursor to the nearest sample, glides the dot along the path to it, shows a white capsule tooltip with the value and fires a selection haptic per sample; releasing glides the dot back to the tip. Precise, live and data-rich.",
            "深色“极速”小组件：上方是圆体大号“50 km/h”，下方是一条起伏的速度折线。出现时折线在约 1.6 秒内从左向右绘出，带柔和橙色辉光与向下渐隐的面积渐变；一颗带橙色光晕的白色圆点精确骑在线头上前进，每经过一个采样点，数字就以逐位滚动（numericText）的方式刷新为当前最高值。手指横向拖动时，细竖线吸附到最近的采样点，圆点沿路径滑向该点，并弹出白色胶囊提示显示数值，每跨一个点触发一次选择触感；松手后圆点沿线滑回线头。精准、实时、数据感十足。"
        ),
        implementation: L(
            "Animatable Shapes rebuild the partial polyline, area and dot for an interpolated progress value, so the dot follows the path instead of cutting across; a DragGesture maps x to the nearest sample index.",
            "自定义可动画 Shape 按插值后的进度重建折线、面积与圆点，使圆点沿路径移动而非直线穿越；DragGesture 将横坐标映射到最近的采样点。"
        ),
        apis: ["Shape.animatableData", "contentTransition(.numericText(value:))", "DragGesture", "task(id:)", "shadow"],
        tags: ["line chart", "sparkline", "scrub", "speed", "折线图", "拖动查看", "数字滚动", "速度"],
        params: [
            .slider("duration", L("Draw duration", "绘制时长"), 0.6...3.0, default: 1.6, unit: "s"),
            .slider("glow", L("Dot glow", "圆点辉光"), 0...20, default: 10, decimals: 0, unit: "pt"),
            .toggle("area", L("Area gradient", "面积渐变"), default: true),
        ]
    ) { ctx in
        SportSpeedDemo(ctx: ctx)
    }
}

private enum SpeedData {
    static let values: [Double] = [18, 24, 21, 29, 26, 35, 31, 39, 36, 44, 40, 50, 43, 47]
    static let minValue: Double = 10
    static let maxValue: Double = 54
    static let chartSize = CGSize(width: 252, height: 104)

    static func point(_ index: Int, in size: CGSize) -> CGPoint {
        let x = size.width * CGFloat(index) / CGFloat(values.count - 1)
        let normalized = (values[index] - minValue) / (maxValue - minValue)
        return CGPoint(x: x, y: size.height * CGFloat(1 - normalized))
    }

    /// Point on the polyline at a horizontal progress in 0...1.
    static func point(at progress: CGFloat, in size: CGSize) -> CGPoint {
        let f = progress.clamped(to: 0...1) * CGFloat(values.count - 1)
        let i = min(Int(f), values.count - 2)
        let r = f - CGFloat(i)
        let a = point(i, in: size)
        let b = point(i + 1, in: size)
        return CGPoint(x: a.x + (b.x - a.x) * r, y: a.y + (b.y - a.y) * r)
    }

    static func line(upTo progress: CGFloat, in size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(0, in: size))
        let whole = Int(progress.clamped(to: 0...1) * CGFloat(values.count - 1))
        if whole >= 1 {
            for i in 1...whole {
                path.addLine(to: point(i, in: size))
            }
        }
        path.addLine(to: point(at: progress, in: size))
        return path
    }
}

private struct SpeedLineShape: Shape {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        SpeedData.line(upTo: progress, in: rect.size)
    }
}

private struct SpeedAreaShape: Shape {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = SpeedData.line(upTo: progress, in: rect.size)
        let end = SpeedData.point(at: progress, in: rect.size)
        path.addLine(to: CGPoint(x: end.x, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

private struct SpeedDotShape: Shape {
    var progress: CGFloat
    var radius: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let p = SpeedData.point(at: progress, in: rect.size)
        return Path(ellipseIn: CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2))
    }
}

private struct SportSpeedDemo: View {
    let ctx: DemoContext
    @State private var progress: CGFloat = 0
    @State private var shown = 0
    @State private var scrub: Int?
    @State private var runID = 0

    private var displayed: Int {
        if let scrub { return Int(SpeedData.values[scrub]) }
        return shown
    }

    private var dotProgress: CGFloat {
        if let scrub { return CGFloat(scrub) / CGFloat(SpeedData.values.count - 1) }
        return progress
    }

    var body: some View {
        SignatureStage {
            VStack(spacing: 0) {
                Spacer()
                card
                Spacer()
                DemoHint(text: L("Drag across the chart", "在图表上横向拖动"), ctx: ctx)
                    .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task(id: runID) { await play() }
        .autoplay(ctx.isPreview, every: 4.4, delay: 4.4) { runID += 1 }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SportEyebrowRow(title: L("Top speed", "最高速度")(ctx.language), symbol: "speedometer")
                Button { runID += 1 } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Signature.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.white.opacity(0.07)))
                }
                .buttonStyle(SportPressStyle(scale: 0.88))
            }
            SpeedReadout(value: displayed, language: ctx.language)
            chart
        }
        .padding(20)
        .frame(width: 292)
        .signatureCard()
    }

    private var chart: some View {
        let size = SpeedData.chartSize
        return ZStack(alignment: .topLeading) {
            SpeedGridLines()
            if ctx.bool("area") {
                SpeedAreaShape(progress: progress)
                    .fill(LinearGradient(colors: [Signature.accent.opacity(0.32), Signature.accent.opacity(0)], startPoint: .top, endPoint: .bottom))
            }
            SpeedLineShape(progress: progress)
                .stroke(Signature.accentGradient, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .shadow(color: Signature.accent.opacity(0.6), radius: 6)
            SpeedDotShape(progress: dotProgress, radius: 10)
                .fill(Signature.accent.opacity(0.28))
            SpeedDotShape(progress: dotProgress, radius: 4.5)
                .fill(Color.white)
                .shadow(color: Signature.accent, radius: ctx.cg("glow"))
            if let scrub {
                SpeedTooltip(index: scrub, size: size)
            }
        }
        .frame(width: size.width, height: size.height)
        .contentShape(Rectangle())
        .gesture(scrubGesture)
    }

    private var scrubGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let count = SpeedData.values.count
                let f = (value.location.x / SpeedData.chartSize.width).clamped(to: 0...1)
                let index = Int((f * CGFloat(count - 1)).rounded())
                if progress < 1 {
                    progress = 1
                    shown = Int(SpeedData.values.max() ?? 0)
                }
                if index != scrub {
                    withAnimation(.snappy(duration: 0.22)) { scrub = index }
                    if !ctx.isPreview { Haptics.selection() }
                }
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { scrub = nil }
            }
    }

    private func play() async {
        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) {
            progress = 0
            shown = 0
            scrub = nil
        }
        try? await Task.sleep(for: .milliseconds(250))
        guard !Task.isCancelled else { return }
        let duration = ctx["duration"]
        withAnimation(.linear(duration: duration)) { progress = 1 }
        let step = duration / Double(SpeedData.values.count - 1)
        for value in SpeedData.values {
            guard !Task.isCancelled else { return }
            let v = Int(value)
            if v > shown {
                withAnimation(.snappy(duration: 0.3)) { shown = v }
            }
            try? await Task.sleep(for: .seconds(step))
        }
    }
}

private struct SpeedReadout: View {
    let value: Int
    let language: AppLanguage

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text("\(value)")
                .font(Signature.number(48))
                .foregroundStyle(Color.white)
                .contentTransition(.numericText(value: Double(value)))
            Text(verbatim: "km/h")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Signature.textSecondary)
            Spacer(minLength: 0)
            Text(L("Nordkette · today", "Nordkette · 今日"), language)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Signature.textSecondary)
        }
    }
}

private struct SpeedGridLines: View {
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { index in
                if index > 0 { Spacer(minLength: 0) }
                Rectangle()
                    .fill(Color.white.opacity(0.07))
                    .frame(height: 1)
            }
        }
    }
}

private struct SpeedTooltip: View {
    let index: Int
    let size: CGSize

    var body: some View {
        let p = SpeedData.point(index, in: size)
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color.white.opacity(0.28))
                .frame(width: 1, height: size.height)
                .position(x: p.x, y: size.height / 2)
            Text("\(Int(SpeedData.values[index])) km/h")
                .font(.system(size: 11, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(Color.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.white))
                .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
                .position(x: p.x.clamped(to: 32...(size.width - 32)), y: max(p.y - 24, 10))
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
    }
}
