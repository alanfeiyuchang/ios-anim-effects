import SwiftUI

extension Effect {
    static let chartsOdometerKPI = Effect(
        id: "charts.odometer-kpi",
        category: .charts,
        interaction: .tap,
        name: L("Odometer KPI Tile", "里程表 KPI 卡片"),
        summary: L("A revenue tile whose digits roll on independent mechanical wheels while the sparkline redraws.", "营收卡片：每位数字在独立的机械滚轮上滚动，迷你折线同步重绘。"),
        prompt: L(
            "A 300 pt KPI tile: caption, a 44 pt rounded-bold figure such as $48,209 built from five digit wheels (0–9 strips clipped to one digit and feathered top and bottom), a delta badge and a 70 pt sparkline with a gradient wash. On refresh the old sparkline retracts in 150 ms; then each digit wheel spins to its new digit on its own spring (response 0.7 s, damping 0.72), starting with the units and moving left 60 ms apart, so the number resolves right to left like a mechanical counter, passing through every digit in between. At the same moment the sparkline redraws left to right over 900 ms (ease-out) and the badge flips its arrow with a bounce and turns green or red. Mechanical, precise, satisfying.",
            "一张 300pt 宽的 KPI 卡片：说明文字、由五个数字滚轮组成的 44pt 圆体粗数值（如 $48,209，每个滚轮是裁切到一位、上下羽化的 0–9 数字条）、涨跌徽章，以及一条 70pt 高、带渐变铺底的迷你折线。刷新时，旧折线先在 150ms 内收回；随后每个数字滚轮以各自的弹簧（响应 0.7 秒、阻尼 0.72）转到新数字，从个位开始向左逐位延迟 60ms，数字像机械计数器一样从右往左依次定格，并滚过中间的每一个数字。与此同时，折线在 900ms 内（缓出）从左到右重新绘出，徽章的箭头弹跳翻转，并变为绿色或红色。机械、精准、令人满足。"
        ),
        implementation: L(
            "Each digit is a VStack of 0–9 offset by −digit × height inside a clipped, gradient-masked frame, with .animation(spring.delay(position × stagger), value: digit). The sparkline is a Path revealed by trim(from:to:), reset and redrawn around the data swap.",
            "每位数字是一个 0–9 的 VStack，按 −数字 × 行高偏移，并放在裁切且带渐变遮罩的框内，使用 .animation(spring.delay(位序 × 间隔), value: digit)。迷你折线是用 trim(from:to:) 揭示的 Path，在数据替换前后收回并重绘。"
        ),
        apis: ["offset(y:)", "clipped()", "mask", "animation(_:value:)", "trim(from:to:)", "symbolEffect(.bounce)"],
        tags: ["odometer", "kpi", "rolling digits", "sparkline", "里程表", "数字滚轮", "指标卡", "迷你折线"],
        params: [
            .slider("stagger", L("Digit stagger", "逐位延迟"), 0...0.15, default: 0.06, unit: "s"),
            .slider("damping", L("Wheel damping", "滚轮阻尼"), 0.4...1.0, default: 0.72),
        ]
    ) { ctx in
        OdometerKPIDemo(ctx: ctx)
    }
}

private let wheelHeight: CGFloat = 52

private struct OdometerKPIDemo: View {
    let ctx: DemoContext
    /// Seeded with a settled reading so still snapshots show a figure and sparkline; `onAppear` replays.
    @State private var value = 48_209
    @State private var previous = 45_830
    @State private var points: [CGFloat] = [0.32, 0.38, 0.35, 0.44, 0.41, 0.5, 0.47, 0.55, 0.52, 0.6, 0.57, 0.66, 0.63, 0.7, 0.74, 0.8]
    @State private var drawn: CGFloat = 1

    var body: some View {
        let digits = String(value).compactMap { $0.wholeNumberValue }
        let delta = Double(value - previous) / Double(max(previous, 1)) * 100
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(ctx.language == .zh ? "今日营收" : "Revenue today")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                OdometerBadge(delta: delta)
            }
            HStack(spacing: 0) {
                Text(verbatim: "$")
                ForEach(digits.indices, id: \.self) { index in
                    if index == digits.count - 3 {
                        Text(verbatim: ",")
                    }
                    DigitWheel(
                        digit: digits[index],
                        delay: Double(digits.count - 1 - index) * ctx["stagger"],
                        damping: ctx["damping"]
                    )
                }
            }
            .font(.system(size: 44, weight: .bold, design: .rounded))
            .monospacedDigit()
            sparkline
                .frame(height: 70)
            Text(ctx.language == .zh ? "较昨日" : "vs. yesterday")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(18)
        .frame(width: 300)
        .demoCard()
        .contentShape(Rectangle())
        .onTapGesture { refresh(haptic: true) }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap to refresh", "点击刷新"), ctx: ctx)
                .padding(.bottom, 8)
        }
        .onAppear {
            ChartEntrance.replay(reset: {
                drawn = 0
            }, then: {
                refresh(haptic: false)
            })
        }
        // The entrance already runs in onAppear, so the detail stage's one-shot intro is skipped.
        .autoplay(ctx.isPreview, every: 2.8, delay: 2.8) { if ctx.isPreview { refresh(haptic: false) } }
    }

    private var sparkline: some View {
        let line = SparkPath(points: points)
        return ZStack {
            SparkArea(points: points)
                .fill(LinearGradient(colors: [Palette.indigo.opacity(0.25), Palette.indigo.opacity(0)], startPoint: .top, endPoint: .bottom))
                .opacity(Double(drawn))
            line
                .trim(from: 0, to: drawn)
                .stroke(Palette.primary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        }
    }

    private func refresh(haptic: Bool) {
        withAnimation(.easeIn(duration: 0.15)) { drawn = 0 }
        if haptic && !ctx.isPreview { Haptics.tap(.light) }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.18))
            let factor = Double.random(in: 0.8...1.25)
            let next = Int((Double(value) * factor).rounded()).clamped(to: 21_000...98_000)
            var walk: [CGFloat] = []
            var level = CGFloat.random(in: 0.3...0.6)
            let trend: CGFloat = next >= value ? 0.03 : -0.03
            for _ in 0..<16 {
                let noise: CGFloat = CGFloat.random(in: -0.09...0.09)
                let stepped: CGFloat = level + trend + noise
                level = min(max(stepped, 0.08), 0.95)
                walk.append(level)
            }
            previous = value
            points = walk
            value = next
            withAnimation(.easeOut(duration: 0.9)) { drawn = 1 }
        }
    }
}

private struct DigitWheel: View {
    let digit: Int
    let delay: Double
    let damping: Double

    var body: some View {
        // 9 · 0…9 · 0: the padding rows keep a spring overshoot past 0 or 9 from showing a blank cell.
        VStack(spacing: 0) {
            ForEach(0..<12, id: \.self) { row in
                Text(verbatim: "\((row + 9) % 10)")
                    .frame(height: wheelHeight)
            }
        }
        .offset(y: -CGFloat(digit + 1) * wheelHeight)
        .animation(.spring(response: 0.7, dampingFraction: damping).delay(delay), value: digit)
        .frame(width: 27, height: wheelHeight, alignment: .top)
        .clipped()
        .mask {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.18),
                    .init(color: .black, location: 0.82),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

private struct OdometerBadge: View {
    let delta: Double

    var body: some View {
        let up = delta >= 0
        let color = up ? Palette.green : Palette.red
        HStack(spacing: 3) {
            Image(systemName: up ? "arrow.up.right" : "arrow.down.right")
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce, value: up)
            Text(String(format: "%.1f%%", abs(delta)))
                .monospacedDigit()
                .contentTransition(.numericText(value: delta))
        }
        .font(.system(size: 12, weight: .bold, design: .rounded))
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.14), in: Capsule())
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: delta)
    }
}

private func sparkPoint(_ index: Int, count: Int, value: CGFloat, in rect: CGRect) -> CGPoint {
    let x: CGFloat = rect.minX + rect.width * CGFloat(index) / CGFloat(max(count - 1, 1))
    let y: CGFloat = rect.maxY - rect.height * value
    return CGPoint(x: x, y: y)
}

private struct SparkPath: Shape {
    let points: [CGFloat]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for (index, value) in points.enumerated() {
            let p = sparkPoint(index, count: points.count, value: value, in: rect)
            if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        return path
    }
}

private struct SparkArea: Shape {
    let points: [CGFloat]

    func path(in rect: CGRect) -> Path {
        var path = SparkPath(points: points).path(in: rect)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
