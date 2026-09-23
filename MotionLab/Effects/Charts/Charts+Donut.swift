import SwiftUI

extension Effect {
    static let chartsDonut = Effect(
        id: "charts.donut-explode",
        category: .charts,
        interaction: .tap,
        name: L("Donut Sweep & Explode", "环形图展开与弹出"),
        summary: L("Rounded donut segments sweep in one by one; tap a slice to pop it out.", "圆角环形分段依次扫入，点击某段即可弹出高亮。"),
        prompt: L(
            "A 190 pt donut of five round-capped arc segments (26 pt stroke, small angular gaps; indigo, pink, amber, mint, sky). On appear the ring rotates from −150° to −90° while each segment sweeps to its full length on a spring (response 0.7 s, damping 0.8), 100 ms apart, so the colors unfurl clockwise like a fan. Tapping a segment explodes it: it slides 12 pt outward along its bisector and thickens to 34 pt with a soft colored shadow, the others dim to 35%, and the center label switches from the total to that category’s name and share with a numeric roll. A three-column legend below mirrors the selection and can select slices too; tapping the slice again or the hole restores everything on a snappy spring. A selection haptic marks each change. Tactile, legible, joyful.",
            "一个 190pt 的环形图，由五段圆角端点弧线组成（描边 26pt，段间留细小间隙，配色靛蓝、粉、琥珀、薄荷绿、天蓝）。出现时整环从 −150° 转到 −90°，各段以弹簧（响应 0.7 秒、阻尼 0.8）扫到完整长度，逐段错开 100ms，如折扇顺时针展开。点击某段即“弹出”：沿角平分线外移 12pt，描边加粗到 34pt 并带同色柔影，其余分段降至 35% 透明度；中心标签切换为该类别与占比，数字滚动过渡。下方三列图例同步高亮，也可直接点选。再点该段或中空处即以利落弹簧复原，并伴随选择触感。"
        ),
        implementation: L(
            "Each slice is a trimmed Circle stroked with round caps; a per-slice grow value animates with a staggered spring, and taps are mapped to slices by converting the touch location to an angle with onTapGesture’s location.",
            "每段为经 trim 裁切、圆角端点描边的 Circle；每段的生长值以错峰弹簧动画驱动，点击时通过 onTapGesture 提供的位置换算角度来定位分段。"
        ),
        apis: ["Circle.trim(from:to:)", "StrokeStyle(lineCap: .round)", "onTapGesture { location in }", "contentTransition(.numericText)", "spring"],
        tags: ["donut", "pie chart", "explode", "segment", "环形图", "饼图", "分段", "弹出"],
        params: [
            .slider("thickness", L("Thickness", "环宽"), 14...40, default: 26, step: 1, decimals: 0, unit: "pt"),
            .slider("explode", L("Explode distance", "弹出距离"), 0...24, default: 12, step: 1, decimals: 0, unit: "pt"),
            .slider("stagger", L("Stagger", "错峰间隔"), 0...0.3, default: 0.1, unit: "s"),
            .slider("response", L("Sweep response", "扫入弹簧响应"), 0.3...1.2, default: 0.7, unit: "s"),
        ]
    ) { ctx in
        DonutDemo(ctx: ctx)
    }
}

private struct DonutSlice {
    let name: LocalizedText
    let value: Double
    let color: Color
}

private let donutSlices: [DonutSlice] = [
    DonutSlice(name: L("Design", "设计"), value: 34, color: Palette.indigo),
    DonutSlice(name: L("Engineering", "研发"), value: 24, color: Palette.pink),
    DonutSlice(name: L("Marketing", "市场"), value: 18, color: Palette.amber),
    DonutSlice(name: L("Support", "支持"), value: 14, color: Palette.mint),
    DonutSlice(name: L("Other", "其他"), value: 10, color: Palette.sky),
]

private struct DonutDemo: View {
    let ctx: DemoContext
    /// Seeded fully swept so still snapshots show the ring; `onAppear` folds it and sweeps it in.
    @State private var grow: [Double] = Array(repeating: 1, count: donutSlices.count)
    @State private var intro: Double = 1
    @State private var selected: Int?
    @State private var autoStep = 0

    private let diameter: CGFloat = 190
    private var total: Double { donutSlices.reduce(0) { $0 + $1.value } }

    private let side: CGFloat = 250

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                ForEach(donutSlices.indices, id: \.self) { index in
                    slice(index)
                }
                centerLabel
            }
            .frame(width: side, height: side)
            .contentShape(Rectangle())
            .onTapGesture { location in
                handleTap(location)
            }
            legend
            DemoHint(text: L("Tap a segment", "点击某一分段"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            ChartEntrance.replay(reset: {
                grow = Array(repeating: 0, count: donutSlices.count)
                intro = 0
            }, then: {
                sweepIn()
            })
        }
        // The sweep already runs in onAppear, so the detail stage's one-shot intro is turned off.
        .autoplay(ctx.isPreview, every: 1.5, delay: 1.6, intro: false) { cycle() }
    }

    private func bounds(_ index: Int) -> (start: Double, end: Double) {
        var start = 0.0
        for i in 0..<index { start += donutSlices[i].value / total }
        return (start, start + donutSlices[index].value / total)
    }

    private func slice(_ index: Int) -> some View {
        let lineWidth = ctx.cg("thickness")
        let range = bounds(index)
        let gap = Double((lineWidth / 2 + 3) / (.pi * diameter))
        let from = range.start + gap
        let full = max(range.end - gap - from, 0.001)
        let isSelected = selected == index
        let mid = (range.start + range.end) / 2 * 2 * Double.pi - Double.pi / 2
        let distance = isSelected ? ctx.cg("explode") : 0
        let dimmed = selected != nil && !isSelected

        return Circle()
            .trim(from: from, to: from + full * grow[index])
            .stroke(donutSlices[index].color.gradient, style: StrokeStyle(lineWidth: isSelected ? lineWidth + 8 : lineWidth, lineCap: .round))
            .frame(width: diameter, height: diameter)
            .rotationEffect(.degrees(-90 - 60 * (1 - intro)))
            .offset(x: CGFloat(cos(mid)) * distance, y: CGFloat(sin(mid)) * distance)
            .opacity(grow[index] > 0.001 ? (dimmed ? 0.35 : 1) : 0)
            .shadow(color: donutSlices[index].color.opacity(isSelected ? 0.45 : 0), radius: 12, y: 6)
    }

    private var legend: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6, alignment: .leading), count: 3), alignment: .leading, spacing: 6) {
            ForEach(donutSlices.indices, id: \.self) { index in
                Button {
                    select(selected == index ? nil : index)
                } label: {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(donutSlices[index].color)
                            .frame(width: 8, height: 8)
                        Text(donutSlices[index].name, ctx.language)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text(verbatim: "\(Int((donutSlices[index].value / total * 100).rounded()))%")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .font(.caption2.weight(.semibold))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .opacity(selected == nil || selected == index ? 1 : 0.4)
            }
        }
        .frame(width: 300)
    }

    private var centerLabel: some View {
        let name = selected.map { donutSlices[$0].name(ctx.language) } ?? (ctx.language == .zh ? "总预算" : "Total budget")
        let number = selected.map { donutSlices[$0].value / total * 100 } ?? total
        let suffix = selected == nil ? "k" : "%"
        return VStack(spacing: 2) {
            Text(verbatim: "\(Int(number.rounded()))\(suffix)")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(value: number))
            Text(name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .contentTransition(.opacity)
        }
        .allowsHitTesting(false)
    }

    private func handleTap(_ location: CGPoint) {
        let dx = location.x - side / 2
        let dy = location.y - side / 2
        let radius = (dx * dx + dy * dy).squareRoot()
        let lineWidth = ctx.cg("thickness")
        guard radius > diameter / 2 - lineWidth, radius < diameter / 2 + lineWidth + 16 else {
            select(nil)
            return
        }
        var fraction = (Double(atan2(dy, dx)) + Double.pi / 2) / (2 * Double.pi)
        if fraction < 0 { fraction += 1 }
        let hit = donutSlices.indices.first { index in
            let range = bounds(index)
            return fraction >= range.start && fraction < range.end
        }
        select(hit == selected ? nil : hit)
    }

    private func select(_ index: Int?) {
        // Haptics.* (not .sensoryFeedback) so the detail page's arrival quiet window applies.
        if index != selected && !ctx.isPreview { Haptics.selection() }
        withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) { selected = index }
    }

    private func sweepIn() {
        withAnimation(.spring(response: 0.9, dampingFraction: 0.85)) { intro = 1 }
        for index in donutSlices.indices {
            withAnimation(.spring(response: ctx["response"], dampingFraction: 0.8).delay(Double(index) * ctx["stagger"])) {
                grow[index] = 1
            }
        }
    }

    private func cycle() {
        autoStep += 1
        let step = autoStep % (donutSlices.count + 1)
        select(step < donutSlices.count ? step : nil)
    }
}
