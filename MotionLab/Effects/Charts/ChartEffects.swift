import SwiftUI

enum ChartEffects {
    static let all: [Effect] = [
        .chartsBarGrow,
        .chartsLineDraw,
        .chartsDonut,
        .chartsGauge,
        .chartsActivityRings,
        .chartsScrub,
        .chartsHeatmap,
        .chartsKPICount,
        .chartsSparklineStream,
        .chartsBarRace,
        .chartsRadarMorph,
        .chartsRangeMorph,
        .chartsCandlestickLive,
        .chartsDonutToBars,
        .chartsStackedBars,
        // Bar variations
        .chartsLiquidBars,
        .chartsBrickBars,
        // Rings & gauges
        .chartsSegmentedGauge,
        .chartsRoseBloom,
        // Chart morph
        .chartsBarsToLine,
        .chartsScatterHistogram,
        .chartsGroupedStacked,
        // KPIs
        .chartsOdometerKPI,
        .chartsBulletKPI,
        .chartsWaffleKPI,
    ]
}

/// Chart demos seed their `@State` with settled data, so a still snapshot (which never runs `onAppear`)
/// shows a finished chart. On appear they snap back to empty without animation and replay their
/// entrance a few frames later, so the reset and the animated fill never coalesce into one no-op update.
enum ChartEntrance {
    @MainActor
    static func replay(reset: () -> Void, then play: @escaping @MainActor () -> Void) {
        var instant = Transaction()
        instant.disablesAnimations = true
        withTransaction(instant, reset)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.05))
            play()
        }
    }
}
