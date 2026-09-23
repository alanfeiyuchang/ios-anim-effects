import SwiftUI

extension Effect {
    static let chartsGauge = Effect(
        id: "charts.gauge-needle",
        category: .charts,
        interaction: .tap,
        name: L("Spring Gauge Needle", "弹簧仪表指针"),
        summary: L("A speed-test dial whose needle swings, overshoots and settles, with a readout that follows it.", "测速仪表盘，指针摆动、过冲、回稳，读数与之同步。"),
        prompt: L(
            "A 180° gauge 220 pt wide: an 18 pt round-capped track in 8% primary, an active arc painted with an angular mint → amber → red gradient, eleven tick marks (every fifth one longer) and a slim 4 pt needle pivoting on a 16 pt hub with a small surface-colored core. Setting a new value swings the needle on an under-damped spring (response ≈ 0.7 s, damping ≈ 0.45): it overshoots by about 20% of the distance traveled, swings back and settles in about a second. The active arc and the large rounded readout (“742 Mbps”, tabular digits) are driven by the very same interpolated value, so the number visibly overshoots and counts back with the needle. Tap anywhere on the dial to aim the needle at that angle. Mechanical, energetic, precise.",
            "一个宽 220pt 的 180° 仪表盘：18pt 圆角端点的轨道为 8% 主色，激活弧线使用薄荷绿 → 琥珀 → 红的角向渐变，配 11 根刻度（每第五根更长），以及一根 4pt 细指针，绕 16pt 轴心旋转，轴心中央嵌一枚底色小圆点。设定新值时，指针以欠阻尼弹簧（响应约 0.7 秒、阻尼约 0.45）摆动：越过目标约为行程的 20%，回摆后约一秒内稳定。激活弧与大号圆体读数（“742 Mbps”，等宽数字）由同一个插值数值驱动，因此数字也会随指针过冲再回落。点击表盘任意位置即可让指针指向该角度。机械感、力量感与精准兼具。"
        ),
        implementation: L(
            "The whole face is an Animatable view keyed on value, so needle rotation, trimmed active arc and numeric readout are all computed from the same per-frame interpolated number; taps are converted to an angle with atan2.",
            "整个表盘是以 value 为动画数据的 Animatable 视图，指针旋转、trim 激活弧和数字读数都由同一帧插值数值计算；点击位置通过 atan2 换算为角度。"
        ),
        apis: ["Animatable", "rotationEffect", "trim(from:to:)", "AngularGradient", "spring(response:dampingFraction:)"],
        tags: ["gauge", "speedometer", "needle", "dial", "meter", "仪表盘", "指针", "测速", "表盘"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.2...1.4, default: 0.7, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.2...1.0, default: 0.45),
            .toggle("ticks", L("Tick marks", "刻度"), default: true),
        ]
    ) { ctx in
        GaugeDemo(ctx: ctx)
    }
}

private enum GaugeMetrics {
    static let size = CGSize(width: 280, height: 210)
    static let center = CGPoint(x: 140, y: 140)
    static let radius: CGFloat = 110
}

private struct GaugeDemo: View {
    let ctx: DemoContext
    @State private var value: Double = 0

    var body: some View {
        VStack(spacing: 16) {
            GaugeFace(value: value, showTicks: ctx.bool("ticks"), language: ctx.language)
                .frame(width: GaugeMetrics.size.width, height: GaugeMetrics.size.height)
                .contentShape(Rectangle())
                .onTapGesture { location in aim(at: location) }
            DemoHint(text: L("Tap anywhere on the dial", "点击表盘任意位置"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { set(0.74) }
        .autoplay(ctx.isPreview, every: 2.0, delay: 1.8) { set(Double.random(in: 0.15...0.95)) }
    }

    private func set(_ newValue: Double) {
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            value = newValue
        }
        if !ctx.isPreview { Haptics.tap(.rigid) }
    }

    private func aim(at location: CGPoint) {
        let dx = Double(location.x - GaugeMetrics.center.x)
        let dy = Double(min(location.y - GaugeMetrics.center.y, 0))
        // Angle from the left end (180°) across the top to the right end (360°).
        var degrees = atan2(dy, dx) * 180 / Double.pi
        if degrees > 0 { degrees = dx < 0 ? -180 : 0 }
        set(((degrees + 180) / 180).clamped(to: 0...1))
    }
}

private struct GaugeFace: View, Animatable {
    var value: Double
    let showTicks: Bool
    let language: AppLanguage

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        let clamped = min(max(value, 0), 1)
        let needleDegrees = min(max(-90 + 180 * value, -100), 100)
        ZStack(alignment: .topLeading) {
            arcs(clamped)
            if showTicks { ticks }
            needle(needleDegrees)
            readout
        }
    }

    private func arcs(_ clamped: Double) -> some View {
        let diameter = GaugeMetrics.radius * 2
        let gradient = AngularGradient(
            colors: [Palette.mint, Palette.amber, Palette.red],
            center: .center,
            startAngle: .degrees(180),
            endAngle: .degrees(360)
        )
        return ZStack {
            Circle()
                .trim(from: 0.5, to: 1)
                .stroke(Color.primary.opacity(0.08), style: StrokeStyle(lineWidth: 18, lineCap: .round))
            Circle()
                .trim(from: 0.5, to: 0.5 + 0.5 * max(clamped, 0.002))
                .stroke(gradient, style: StrokeStyle(lineWidth: 18, lineCap: .round))
        }
        .frame(width: diameter, height: diameter)
        .position(GaugeMetrics.center)
    }

    private var ticks: some View {
        ForEach(0...10, id: \.self) { index in
            Capsule()
                .fill(Color.primary.opacity(index % 5 == 0 ? 0.45 : 0.2))
                .frame(width: 2, height: index % 5 == 0 ? 10 : 6)
                .offset(y: -(GaugeMetrics.radius - 24))
                .rotationEffect(.degrees(-90 + Double(index) * 18))
                .position(GaugeMetrics.center)
        }
    }

    private func needle(_ degrees: Double) -> some View {
        ZStack {
            Capsule()
                .fill(Color.primary)
                .frame(width: 4, height: GaugeMetrics.radius - 20)
                .offset(y: -(GaugeMetrics.radius - 20) / 2)
                .rotationEffect(.degrees(degrees))
                .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
            Circle()
                .fill(Color.primary)
                .frame(width: 16, height: 16)
                .overlay(Circle().fill(Palette.surface).frame(width: 6, height: 6))
        }
        .position(GaugeMetrics.center)
    }

    private var readout: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("\(Int((max(value, 0) * 1000).rounded()))")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text("Mbps")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .position(x: GaugeMetrics.center.x, y: GaugeMetrics.center.y + 46)
    }
}
