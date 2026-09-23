import Foundation

/// Families (variation groups) of `EffectCategory.charts`.
///
/// To add a variation: append the effect to `ChartEffects.all`, then add one
/// `"<effect id>": "<family id>",` line to `membership` below. Each effect id may appear only once
/// (a duplicate dictionary key traps at launch). See docs/FAMILIES.md.
enum ChartsFamilies {
    static let all: [EffectFamily] = [
        EffectFamily(
            id: "charts.bar",
            category: .charts,
            name: L("Bar Charts", "柱状图"),
            summary: L("Bars that grow, race and re-stack on springs.", "以弹簧生长、竞速与重新堆叠的柱状图。"),
            symbol: "chart.bar.fill"
        ),
        EffectFamily(
            id: "charts.line",
            category: .charts,
            name: L("Line Charts", "折线图"),
            summary: L("Lines that draw on, stream, morph between ranges and follow a scrub.", "折线绘制、实时流动、区间形变与跟随拖动。"),
            symbol: "chart.xyaxis.line"
        ),
        EffectFamily(
            id: "charts.ring",
            category: .charts,
            name: L("Rings & Gauges", "圆环与仪表"),
            summary: L("Donuts, activity rings and needles that sweep and settle.", "环形图、健身圆环与指针的扫动与回稳。"),
            symbol: "chart.pie.fill"
        ),
        EffectFamily(
            id: "charts.morph",
            category: .charts,
            name: L("Chart Morph", "图表形变"),
            summary: L("One chart shape turning into another dataset or chart type.", "图表在数据集或图表类型之间形变。"),
            symbol: "arrow.triangle.2.circlepath"
        ),
        EffectFamily(
            id: "charts.kpi",
            category: .charts,
            name: L("KPIs & Heatmaps", "指标与热力图"),
            summary: L("Stat tiles and grids that count up or ripple into view.", "数字滚动或涟漪入场的指标卡与热力格。"),
            symbol: "square.grid.3x3.fill"
        ),
    ]

    static let membership: [String: String] = [
        // Bar charts
        "charts.bar-grow": "charts.bar",
        "charts.bar-race": "charts.bar",
        "charts.stacked-bars": "charts.bar",
        // Line charts
        "charts.line-draw": "charts.line",
        "charts.scrub-tooltip": "charts.line",
        "charts.sparkline-stream": "charts.line",
        "charts.range-morph": "charts.line",
        "charts.candlestick-live": "charts.line",
        // Rings & gauges
        "charts.donut-explode": "charts.ring",
        "charts.gauge-needle": "charts.ring",
        "charts.activity-rings": "charts.ring",
        // Chart morph
        "charts.radar-morph": "charts.morph",
        "charts.donut-to-bars": "charts.morph",
        // KPIs & heatmaps
        "charts.heatmap-cascade": "charts.kpi",
        "charts.kpi-count-up": "charts.kpi",
    ]
}
