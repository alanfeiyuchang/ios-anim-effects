import SwiftUI

extension Effect {
    static let chartsHeatmap = Effect(
        id: "charts.heatmap-cascade",
        category: .charts,
        interaction: .tap,
        name: L("Heatmap Ripple Reveal", "热力图涟漪揭示"),
        summary: L("A contribution grid that pops in as a ripple radiating from the cell you tap.", "贡献热力图以你点击的格子为圆心，涟漪般逐格弹出。"),
        prompt: L(
            "A 14 × 7 contribution heatmap of 16 pt rounded cells (4 pt corners, 4 pt gaps) in five intensity levels — 7% primary for empty, then mint at 30/55/80/100% — under a header with the yearly total. On appear the grid reveals from the top-left corner; tapping any cell makes the current cells shrink away in 180 ms, loads new data and then reveals it as a circular ripple centered on the tapped cell: each cell’s delay is its Euclidean distance × 35 ms, and it springs from 30% scale and 0 opacity to full size (response 0.45 s, damping 0.6, slight overshoot). The origin cell keeps a soft mint glow and the total rolls with a numeric transition. The wave makes a static grid feel alive and spatially connected to your touch.",
            "一张 14 × 7 的贡献热力图，格子为 16pt 圆角方块（圆角 4pt、间距 4pt），分五档强度——空值为 7% 主色，其余为 30/55/80/100% 的薄荷绿——上方标题显示年度总数。出现时从左上角开始揭示；点击任意格子，现有格子先在 180ms 内缩小消失，载入新数据后以被点格子为圆心呈圆形涟漪逐格出现：每格延迟 = 与圆心的欧氏距离 × 35ms，从 30% 缩放、0 透明度以弹簧（响应 0.45 秒、阻尼 0.6，轻微过冲）弹到完整尺寸。圆心格保留柔和的薄荷绿辉光，总数以数字转场滚动。涟漪让静态网格充满生命力，并与指尖建立空间关联。"
        ),
        implementation: L(
            "Every cell applies .animation(revealed ? spring.delay(distance × stagger) : easeOut, value: revealed); a tap stores the origin, hides the grid, swaps the data after a short Task sleep and flips revealed back on.",
            "每个格子使用 .animation(revealed ? spring.delay(距离 × 间隔) : easeOut, value: revealed)；点击时记录圆心、隐藏网格，经短暂 Task.sleep 后替换数据并重新揭示。"
        ),
        apis: ["animation(_:value:)", "Animation.delay", "Grid", "contentTransition(.numericText)", "Task.sleep"],
        tags: ["heatmap", "contribution", "ripple", "cascade", "热力图", "贡献图", "涟漪", "网格"],
        params: [
            .slider("stagger", L("Ripple speed", "涟漪间隔"), 0.01...0.08, default: 0.035, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.4...1.0, default: 0.6),
            .slider("response", L("Spring response", "弹簧响应"), 0.25...0.9, default: 0.45, unit: "s"),
            .choice("shape", L("Cell shape", "格子形状"), [L("Square", "方形"), L("Circle", "圆形")]),
        ]
    ) { ctx in
        HeatmapDemo(ctx: ctx)
    }
}

private let heatColumns = 14
private let heatRows = 7

private func randomLevels() -> [Int] {
    (0..<(heatColumns * heatRows)).map { _ in
        let r = Double.random(in: 0...1)
        if r < 0.28 { return 0 }
        if r < 0.55 { return 1 }
        if r < 0.75 { return 2 }
        if r < 0.9 { return 3 }
        return 4
    }
}

private let heatSeed = randomLevels()

private func heatTotal(_ levels: [Int]) -> Int {
    levels.reduce(0) { $0 + $1 * 7 } + 120
}

private struct HeatmapDemo: View {
    let ctx: DemoContext
    /// Seeded revealed so still snapshots show the grid; `onAppear` hides it and ripples it in.
    @State private var levels: [Int] = heatSeed
    @State private var revealed = true
    @State private var origin = (column: 0, row: 0)
    @State private var total = heatTotal(heatSeed)
    /// Bumped by every ripple; a pending swap from an older tap bails out instead of hard-cutting the grid.
    @State private var generation = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Grid(horizontalSpacing: 4, verticalSpacing: 4) {
                ForEach(0..<heatRows, id: \.self) { row in
                    GridRow {
                        ForEach(0..<heatColumns, id: \.self) { column in
                            cell(column: column, row: row)
                        }
                    }
                }
            }
        }
        .padding(16)
        .demoCard()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap any cell", "点击任意格子"), ctx: ctx)
                .padding(.bottom, 8)
        }
        .onAppear {
            ChartEntrance.replay(reset: {
                revealed = false
            }, then: {
                ripple(column: 0, row: 0, refresh: false)
            })
        }
        // The entrance already runs in onAppear, so the detail stage's one-shot intro is turned off.
        .autoplay(ctx.isPreview, every: 3.0, delay: 2.6, intro: false) {
            ripple(column: Int.random(in: 0..<heatColumns), row: Int.random(in: 0..<heatRows), refresh: true)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(verbatim: "\(total)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(total)))
            Text(ctx.language == .zh ? "次提交" : "contributions")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private func color(for level: Int) -> Color {
        switch level {
        case 0: return Color.primary.opacity(0.07)
        case 1: return Palette.mint.opacity(0.3)
        case 2: return Palette.mint.opacity(0.55)
        case 3: return Palette.mint.opacity(0.8)
        default: return Palette.mint
        }
    }

    private func cell(column: Int, row: Int) -> some View {
        let level = levels[row * heatColumns + column]
        let dx = Double(column - origin.column)
        let dy = Double(row - origin.row)
        let delay = (dx * dx + dy * dy).squareRoot() * ctx["stagger"]
        let isOrigin = column == origin.column && row == origin.row
        let radius: CGFloat = ctx.int("shape") == 1 ? 8 : 4
        let animation: Animation = revealed
            ? .spring(response: ctx["response"], dampingFraction: ctx["damping"]).delay(delay)
            : .easeOut(duration: 0.18)

        return RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(color(for: level))
            .frame(width: 16, height: 16)
            .shadow(color: Palette.mint.opacity(isOrigin && revealed ? 0.8 : 0), radius: 6)
            .scaleEffect(revealed ? 1 : 0.3)
            .opacity(revealed ? 1 : 0)
            .animation(animation, value: revealed)
            .onTapGesture { ripple(column: column, row: row, refresh: true) }
    }

    private func ripple(column: Int, row: Int, refresh: Bool) {
        origin = (column, row)
        revealed = false
        generation += 1
        let current = generation
        if !ctx.isPreview && refresh { Haptics.tap(.light) }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.22))
            guard current == generation else { return }
            if refresh { levels = randomLevels() }
            revealed = true
            withAnimation(.snappy) { total = heatTotal(levels) }
        }
    }
}
