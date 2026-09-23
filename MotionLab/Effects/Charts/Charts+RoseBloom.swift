import SwiftUI

extension Effect {
    static let chartsRoseBloom = Effect(
        id: "charts.rose-bloom",
        category: .charts,
        interaction: .tap,
        name: L("Nightingale Rose Bloom", "南丁格尔玫瑰图绽放"),
        summary: L("Twelve equal-angle petals grow outward from the centre, each to its own radius, like a flower opening.", "十二片等角花瓣从中心向外生长到各自半径，像花朵绽放。"),
        prompt: L(
            "A polar-area (Nightingale rose) chart of monthly rainfall: twelve 30° wedges with 2.5° gaps around a 22 pt hole, each wedge's radius proportional to its value (max 118 pt), coloured along a sky → indigo → violet ramp, with month initials on an outer ring. On appear the petals grow radially from the hole on a spring (response 0.7 s, damping 0.62), clockwise from January, 55 ms apart, while the whole flower turns from −20° to 0° on the same spring, so it blooms rather than sweeps. Tapping loads another year: every petal springs from its current radius to the new one with the same stagger, overshooting a little, and the year label rolls. Organic, seasonal, surprisingly readable.",
            "一张月降雨量的极坐标面积图（南丁格尔玫瑰图）：十二片 30° 扇瓣围绕 22pt 的中心孔，瓣间留 2.5° 间隙，每片的半径与数值成正比（最大 118pt），颜色沿天蓝 → 靛蓝 → 紫色渐变，外圈标注月份缩写。出现时花瓣以弹簧（响应 0.7 秒、阻尼 0.62）从中心孔沿径向生长，从一月起顺时针依次错开 55ms，同时整朵花以同一弹簧从 −20° 转到 0°——是“绽放”而非“扫过”。点击载入另一年份：每片花瓣以相同的错峰从当前半径弹到新半径，略带过冲，年份标签滚动切换。自然、有季节感，而且出乎意料地易读。"
        ),
        implementation: L(
            "Each petal is an annular-sector Shape whose animatableData is its outer radius; a per-petal .animation(spring.delay(i × stagger), value: radius) turns one state change into a radial cascade, and rotationEffect adds the opening twist.",
            "每片花瓣是一个环形扇区 Shape，其 animatableData 为外半径；每片使用 .animation(spring.delay(序号 × 间隔), value: 半径)，一次状态变化即可形成径向级联，rotationEffect 负责绽放时的扭转。"
        ),
        apis: ["Shape", "animatableData", "Path.addArc", "animation(_:value:)", "rotationEffect", "contentTransition(.numericText)"],
        tags: ["rose chart", "polar area", "nightingale", "bloom", "玫瑰图", "极坐标", "南丁格尔", "绽放"],
        params: [
            .slider("stagger", L("Stagger", "错峰间隔"), 0...0.12, default: 0.055, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.4...1.0, default: 0.62),
            .toggle("twist", L("Opening twist", "绽放扭转"), default: true),
        ]
    ) { ctx in
        RoseBloomDemo(ctx: ctx)
    }
}

private let roseHole: CGFloat = 22
private let roseMax: CGFloat = 118

private struct RosePetal: Shape {
    var radius: CGFloat
    let index: Int

    var animatableData: CGFloat {
        get { radius }
        set { radius = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let gap: Double = 1.25
        let start = Angle.degrees(-90 + Double(index) * 30 + gap)
        let end = Angle.degrees(-90 + Double(index + 1) * 30 - gap)
        let outer = max(radius, roseHole + 0.5)
        var path = Path()
        path.addArc(center: center, radius: outer, startAngle: start, endAngle: end, clockwise: false)
        path.addArc(center: center, radius: roseHole, startAngle: end, endAngle: start, clockwise: true)
        path.closeSubpath()
        return path
    }
}

private let roseMonthsEN = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]
private let roseMonthsZH = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"]

private struct RoseBloomDemo: View {
    let ctx: DemoContext
    /// Seeded in bloom so still snapshots show petals; `onAppear` folds them away and blooms them in.
    @State private var values: [CGFloat] = [0.86, 0.78, 0.7, 0.55, 0.42, 0.3, 0.26, 0.34, 0.48, 0.6, 0.74, 0.9]
    @State private var year = 2021
    @State private var turned = true

    var body: some View {
        let stagger = ctx["stagger"]
        let spring = Animation.spring(response: 0.7, dampingFraction: ctx["damping"])
        VStack(spacing: 10) {
            HStack {
                Text(ctx.language == .zh ? "月降雨量" : "Monthly rainfall")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(year))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(year)))
            }
            .frame(width: 280)
            ZStack {
                ForEach(0..<12, id: \.self) { index in
                    let t = Double(index) / 11
                    RosePetal(radius: roseHole + (roseMax - roseHole) * values[index], index: index)
                        .fill(petalColor(t).gradient)
                        .animation(spring.delay(Double(index) * stagger), value: values[index])
                }
                monthLabels
            }
            .frame(width: 280, height: 280)
            .rotationEffect(.degrees(ctx.bool("twist") && !turned ? -20 : 0))
        }
        .contentShape(Rectangle())
        .onTapGesture { load(haptic: true) }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap for another year", "点击切换年份"), ctx: ctx)
                .padding(.bottom, 2)
        }
        .onAppear {
            ChartEntrance.replay(reset: {
                values = Array(repeating: 0, count: 12)
                turned = false
            }, then: {
                load(haptic: false)
            })
        }
        // The entrance already runs in onAppear, so the detail stage's one-shot intro is turned off.
        .autoplay(ctx.isPreview, every: 2.8, delay: 2.8, intro: false) { load(haptic: false) }
    }

    private var monthLabels: some View {
        let labels = ctx.language == .zh ? roseMonthsZH : roseMonthsEN
        return ForEach(0..<12, id: \.self) { index in
            let degrees: Double = -90 + (Double(index) + 0.5) * 30
            let radians: Double = degrees * Double.pi / 180
            let dx: CGFloat = 132 * CGFloat(cos(radians))
            let dy: CGFloat = 132 * CGFloat(sin(radians))
            Text(labels[index])
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .offset(x: dx, y: dy)
        }
    }

    private func petalColor(_ t: Double) -> Color {
        if t < 0.5 {
            return Palette.sky.mix(with: Palette.indigo, by: t * 2)
        }
        return Palette.indigo.mix(with: Palette.violet, by: (t - 0.5) * 2)
    }

    private func load(haptic: Bool) {
        // Wetter winters, drier summers, plus noise.
        let next: [CGFloat] = (0..<12).map { index in
            let seasonal = 0.55 + 0.3 * cos(Double(index) / 12 * 2 * .pi)
            let noise = Double.random(in: -0.22...0.22)
            return CGFloat(min(max(seasonal + noise, 0.12), 1))
        }
        let first = values.allSatisfy { $0 == 0 }
        if first {
            turned = false
        }
        withAnimation(.spring(response: 0.7, dampingFraction: ctx["damping"])) {
            values = next
            year = first ? year : (year >= 2025 ? 2021 : year + 1)
            turned = true
        }
        if haptic && !ctx.isPreview { Haptics.tap(.light) }
    }
}
