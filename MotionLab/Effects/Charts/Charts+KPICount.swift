import SwiftUI

extension Effect {
    static let chartsKPICount = Effect(
        id: "charts.kpi-count-up",
        category: .charts,
        interaction: .tap,
        name: L("KPI Cards Count-Up", "KPI 卡片数字滚动"),
        summary: L("Four stat cards whose numbers count up with an expo ease, staggered like a dashboard waking up.", "四张数据卡片以指数缓动错峰计数，像仪表盘苏醒。"),
        prompt: L(
            "A 2 × 2 grid of KPI cards (143 × 124 pt, 20 pt continuous corners, elevated surface, hairline stroke): each shows a tinted glyph badge, a caption, a large rounded bold value (revenue, active users, conversion, latency) and a delta pill, plus a thin progress bar at the bottom. On appear the numbers count up from zero through every intermediate value on an expo-out curve (0.16, 1, 0.3, 1) over 1.6 s, card by card with 120 ms stagger, while the progress bars grow on the same curve and the delta pills fade and slide up 6 pt. Tapping refreshes the data and counts from the current values to the new ones, turning each pill green ▲ or red ▼. Tabular digits keep widths stable so nothing jitters. Confident, alive, executive-dashboard polish.",
            "一个 2 × 2 的 KPI 卡片网格（每张 143 × 124pt，20pt 连续圆角，浮起表面与细描边）：每张包含彩色图标徽章、说明文字、大号圆体粗数值（营收、活跃用户、转化率、延迟）与涨跌胶囊，底部还有一条细进度条。出现时数字从 0 开始，以指数缓出曲线（0.16, 1, 0.3, 1）在 1.6 秒内逐一经过每个中间值递增，卡片间错开 120ms；进度条以同一曲线生长，涨跌胶囊淡入并上移 6pt。点击刷新数据时，数字从当前值滚动到新值，胶囊按涨跌变为绿色 ▲ 或红色 ▼。等宽数字确保宽度稳定、毫无抖动。自信、鲜活，有高管仪表盘般的精致感。"
        ),
        implementation: L(
            "An Animatable text view interpolates the numeric value and formats it every frame, so the count passes through all intermediate numbers; each card gets its own withAnimation(.timingCurve(...).delay(i × stagger)).",
            "Animatable 文本视图逐帧插值并格式化数值，使计数经过所有中间值；每张卡片使用独立的 withAnimation(.timingCurve(...).delay(i × 间隔))。"
        ),
        apis: ["Animatable", "timingCurve", "Animation.delay", "monospacedDigit", "Grid"],
        tags: ["kpi", "stat card", "count up", "dashboard", "数据卡片", "计数", "数字滚动", "仪表盘"],
        params: [
            .slider("duration", L("Count duration", "计数时长"), 0.6...3.0, default: 1.6, unit: "s"),
            .slider("stagger", L("Stagger", "错峰间隔"), 0...0.3, default: 0.12, unit: "s"),
        ]
    ) { ctx in
        KPICountDemo(ctx: ctx)
    }
}

private enum KPIKind: Int, CaseIterable {
    case revenue, users, conversion, latency

    var title: LocalizedText {
        switch self {
        case .revenue: return L("Revenue", "营收")
        case .users: return L("Active users", "活跃用户")
        case .conversion: return L("Conversion", "转化率")
        case .latency: return L("Latency", "延迟")
        }
    }

    var symbol: String {
        switch self {
        case .revenue: return "dollarsign"
        case .users: return "person.2.fill"
        case .conversion: return "arrow.triangle.branch"
        case .latency: return "bolt.fill"
        }
    }

    var tint: Color {
        switch self {
        case .revenue: return Palette.indigo
        case .users: return Palette.mint
        case .conversion: return Palette.coral
        case .latency: return Palette.sky
        }
    }

    var range: ClosedRange<Double> {
        switch self {
        case .revenue: return 48_000...96_000
        case .users: return 8_000...24_000
        case .conversion: return 2.4...7.8
        case .latency: return 38...140
        }
    }

    /// Lower latency is better, so its "goal" fraction is inverted.
    func fraction(_ value: Double) -> Double {
        let f = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        let clamped = min(max(f, 0), 1)
        return self == .latency ? 1 - clamped * 0.7 : 0.3 + clamped * 0.7
    }

    func format(_ value: Double, locale: Locale) -> String {
        switch self {
        case .revenue: return "$" + Int(value.rounded()).formatted(.number.locale(locale))
        case .users: return Int(value.rounded()).formatted(.number.locale(locale))
        case .conversion: return String(format: "%.1f%%", value)
        case .latency: return "\(Int(value.rounded())) ms"
        }
    }
}

private struct KPICountDemo: View {
    let ctx: DemoContext
    /// Seeded with settled numbers so still snapshots show data; `onAppear` rewinds and counts up.
    @State private var values: [Double] = [72_480, 15_320, 4.6, 64]
    @State private var deltas: [Double] = [8.4, 3.1, -2.2, -6.5]
    @State private var shown = true

    var body: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                card(.revenue)
                card(.users)
            }
            GridRow {
                card(.conversion)
                card(.latency)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { refresh(fromZero: false) }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap to refresh", "点击刷新"), ctx: ctx)
                .padding(.bottom, 10)
        }
        .onAppear {
            ChartEntrance.replay(reset: {
                values = [0, 0, 0, 0]
                shown = false
            }, then: {
                refresh(fromZero: true)
            })
        }
        // The entrance already runs in onAppear, so the detail stage's one-shot intro is turned off.
        .autoplay(ctx.isPreview, every: ctx["duration"] + 2.0, delay: ctx["duration"] + 1.6, intro: false) {
            replay()
        }
    }

    private func card(_ kind: KPIKind) -> some View {
        KPICard(
            kind: kind,
            value: values[kind.rawValue],
            delta: deltas[kind.rawValue],
            shown: shown,
            language: ctx.language
        )
    }

    private func refresh(fromZero: Bool) {
        let duration = ctx["duration"]
        let stagger = ctx["stagger"]
        let old = values
        let targets = KPIKind.allCases.map { Double.random(in: $0.range) }
        if !ctx.isPreview && !fromZero { Haptics.tap(.light) }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
            shown = true
            for kind in KPIKind.allCases {
                let i = kind.rawValue
                // From zero there is no real previous value, so invent a varied baseline per card
                // (otherwise every pill reads the identical +17.6%).
                let previous = old[i] == 0 ? targets[i] * Double.random(in: 0.78...1.12) : old[i]
                deltas[i] = (targets[i] - previous) / previous * 100
            }
        }
        for kind in KPIKind.allCases {
            let i = kind.rawValue
            withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: duration).delay(Double(i) * stagger)) {
                values[i] = targets[i]
            }
        }
    }

    private func replay() {
        withAnimation(.easeOut(duration: 0.3)) {
            values = [0, 0, 0, 0]
            shown = false
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.35))
            refresh(fromZero: true)
        }
    }
}

private struct KPICard: View {
    let kind: KPIKind
    let value: Double
    let delta: Double
    let shown: Bool
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: kind.symbol)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(kind.tint.gradient, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                Spacer()
                DeltaPill(delta: delta, invert: kind == .latency)
                    .opacity(shown ? 1 : 0)
                    .offset(y: shown ? 0 : 6)
            }
            Text(kind.title, language)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            CountingValue(value: value, kind: kind, locale: language.locale)
            ProgressLine(fraction: value == 0 ? 0 : kind.fraction(value), tint: kind.tint)
        }
        .padding(12)
        .frame(width: 143, height: 124)
        .demoCard(cornerRadius: 20)
    }
}

private struct CountingValue: View, Animatable {
    var value: Double
    let kind: KPIKind
    let locale: Locale

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text(kind.format(max(value, 0), locale: locale))
            .font(.system(size: 21, weight: .bold, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

private struct ProgressLine: View {
    let fraction: Double
    let tint: Color

    var body: some View {
        Capsule()
            .fill(Color.primary.opacity(0.08))
            .frame(height: 4)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(tint.gradient)
                    .frame(width: 119 * fraction, height: 4)
            }
    }
}

private struct DeltaPill: View {
    let delta: Double
    let invert: Bool

    var body: some View {
        let good = invert ? delta <= 0 : delta >= 0
        let color = good ? Palette.green : Palette.red
        let arrow = delta >= 0 ? "▲" : "▼"
        Text(arrow + " " + String(format: "%.1f", abs(delta)) + "%")
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.14), in: Capsule())
            .contentTransition(.numericText(value: delta))
    }
}
