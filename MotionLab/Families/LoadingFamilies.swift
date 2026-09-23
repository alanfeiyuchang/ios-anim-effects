import Foundation

/// Families (variation groups) of `EffectCategory.loading`.
///
/// To add a variation: append the effect to `LoadingEffects.all`, then add one
/// `"<effect id>": "<family id>",` line to `membership` below. Each effect id may appear only once
/// (a duplicate dictionary key traps at launch). See docs/FAMILIES.md.
enum LoadingFamilies {
    static let all: [EffectFamily] = [
        EffectFamily(
            id: "loading.spinner",
            category: .loading,
            name: L("Spinner", "旋转加载"),
            summary: L("Indeterminate spinners: arcs, orbits and petals turning with easing.", "不确定进度的旋转指示器：弧线、轨道与花瓣。"),
            symbol: "progress.indicator"
        ),
        EffectFamily(
            id: "loading.pulse",
            category: .loading,
            name: L("Dots & Pulses", "跳动与脉冲"),
            summary: L("Bouncing dots, waveforms, radar rings and morphing grids that say 'working'.", "跳动圆点、波形、雷达环与形变方格，表达“处理中”。"),
            symbol: "waveform"
        ),
        EffectFamily(
            id: "loading.progress-bar",
            category: .loading,
            name: L("Progress Bar", "进度条"),
            summary: L("Linear progress: glowing fills, racing segments and story bars.", "线性进度：辉光填充、追逐线段与快拍进度条。"),
            symbol: "slider.horizontal.below.rectangle"
        ),
        EffectFamily(
            id: "loading.progress-ring",
            category: .loading,
            name: L("Progress Ring", "进度环"),
            summary: L("Circular progress: gradient rings and liquid levels with a rolling value.", "环形进度：渐变圆环与液面，数值同步滚动。"),
            symbol: "circle.dashed"
        ),
        EffectFamily(
            id: "loading.button",
            category: .loading,
            name: L("Loading Button", "加载按钮"),
            summary: L("Buttons that turn into their own progress indicator, then into a result.", "按钮自身变为进度指示，再变为结果状态。"),
            symbol: "arrow.down.circle.fill"
        ),
        EffectFamily(
            id: "loading.placeholder",
            category: .loading,
            name: L("Placeholders", "占位加载"),
            summary: L("Skeletons, blur-ups and generating cards that stand in for content.", "骨架屏、模糊渐显与生成中卡片等内容占位。"),
            symbol: "rectangle.dashed"
        ),
    ]

    static let membership: [String: String] = [
        // Spinner
        "loading.arc-spinner": "loading.spinner",
        "loading.orbit-dots": "loading.spinner",
        "loading.activity-petals": "loading.spinner",
        "loading.gooey-orbit": "loading.spinner",
        "loading.gyroscope": "loading.spinner",
        "loading.flip-tile": "loading.spinner",
        "loading.infinity-comet": "loading.spinner",
        // Dots & pulses
        "loading.dot-bounce": "loading.pulse",
        "loading.audio-wave": "loading.pulse",
        "loading.pulse-rings": "loading.pulse",
        "loading.square-grid": "loading.pulse",
        "loading.heartbeat": "loading.pulse",
        // Progress bar
        "loading.glow-bar": "loading.progress-bar",
        "loading.story-bars": "loading.progress-bar",
        "loading.indeterminate-bar": "loading.progress-bar",
        "loading.segment-bar": "loading.progress-bar",
        "loading.liquid-bar": "loading.progress-bar",
        "loading.tooltip-bar": "loading.progress-bar",
        "loading.candy-stripes": "loading.progress-bar",
        // Progress ring
        "loading.progress-ring": "loading.progress-ring",
        "loading.liquid-fill": "loading.progress-ring",
        "loading.tick-ring": "loading.progress-ring",
        "loading.install-pie": "loading.progress-ring",
        "loading.elastic-ring": "loading.progress-ring",
        "loading.ring-to-check": "loading.progress-ring",
        "loading.dash-flow-ring": "loading.progress-ring",
        // Loading button
        "loading.load-button": "loading.button",
        "loading.download-button": "loading.button",
        "loading.fill-button": "loading.button",
        "loading.dots-button": "loading.button",
        "loading.trace-button": "loading.button",
        // Placeholders
        "loading.skeleton-shimmer": "loading.placeholder",
        "loading.blur-up": "loading.placeholder",
        "loading.ai-generating": "loading.placeholder",
        "loading.breathing-skeleton": "loading.placeholder",
        "loading.mosaic-resolve": "loading.placeholder",
    ]
}
