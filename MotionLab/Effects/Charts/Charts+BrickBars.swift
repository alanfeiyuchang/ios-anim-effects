import SwiftUI

extension Effect {
    static let chartsBrickBars = Effect(
        id: "charts.brick-bars",
        category: .charts,
        interaction: .tap,
        name: L("Falling Brick Bars", "积木堆叠柱状图"),
        summary: L("Bars built from bricks that rain in and bounce into stacks, bottom row first.", "柱子由一块块积木组成，从上方落下弹跳堆叠，自底向上。"),
        prompt: L(
            "A “Tasks shipped” card with seven columns of 30 × 16 pt bricks (5 pt continuous corners, up to ten bricks per column, 5 pt gaps), coloured by height from mint at the base to indigo at the top; empty slots show as faint 6% ghosts. On appear and on every tap the current bricks drop out in 180 ms, then the new ones rain in from 220 pt above: each brick falls on a bouncy spring (response 0.5 s, damping 0.62) delayed by 50 ms per column plus 35 ms per row, so every column fills bottom-up and the chart builds like a game of Tetris. The weekly total rolls to its new number. Tangible, countable, game-like.",
            "一张“本周完成任务”卡片，包含七列 30 × 16pt 的积木块（5pt 连续圆角，每列最多十块，间距 5pt），颜色随高度从底部的薄荷绿过渡到顶部的靛蓝；空位显示为 6% 透明度的淡影。出现时以及每次点击时，现有积木先在 180ms 内掉出，随后新积木从上方 220pt 处落下：每块以弹性弹簧（响应 0.5 秒、阻尼 0.62）下落，延迟为每列 50ms 加每行 35ms，于是每一列自底向上填满，整张图像俄罗斯方块一样被搭起来。本周总数滚动到新数值。具体、可数，带有游戏感。"
        ),
        implementation: L(
            "Each brick is a view with its own .animation(value:) whose delay depends on column and row, and whose curve depends on direction (ease-in to drop out, spring to land); play() hides, swaps the data after 220 ms, then shows again.",
            "每块积木是独立视图，带有自己的 .animation(value:)：延迟由列与行决定，曲线由方向决定（掉出用缓入，落下用弹簧）；play() 先隐藏，220ms 后替换数据，再重新显示。"
        ),
        apis: ["animation(_:value:)", "Animation.delay", "offset(y:)", "Color.mix(with:by:)", "contentTransition(.numericText)"],
        tags: ["unit chart", "bar chart", "bricks", "stack", "积木", "柱状图", "堆叠", "掉落"],
        params: [
            .slider("columnDelay", L("Column stagger", "列错峰"), 0...0.12, default: 0.05, unit: "s"),
            .slider("rowDelay", L("Row stagger", "行错峰"), 0...0.08, default: 0.035, unit: "s"),
            .slider("damping", L("Bounce damping", "弹跳阻尼"), 0.35...1.0, default: 0.62),
        ]
    ) { ctx in
        BrickBarsDemo(ctx: ctx)
    }
}

private let brickRows = 10
private let brickColumns = 7

private struct BrickBarsDemo: View {
    let ctx: DemoContext
    /// Seeded with a settled week so still snapshots show stacks; `onAppear` rewinds and plays.
    @State private var counts: [Int] = [5, 8, 6, 10, 7, 4, 9]
    @State private var shown = true
    @State private var dropping = false
    /// Bumped by every replay; an older pending drop bails out so rapid taps never change counts while shown.
    @State private var generation = 0

    var body: some View {
        let total = counts.reduce(0, +)
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(ctx.language == .zh ? "本周完成任务" : "Tasks shipped")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(verbatim: "\(shown ? total : 0)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(shown ? total : 0)))
            }
            HStack(alignment: .bottom, spacing: 5) {
                ForEach(0..<brickColumns, id: \.self) { column in
                    VStack(spacing: 5) {
                        ForEach((0..<brickRows).reversed(), id: \.self) { row in
                            Brick(
                                row: row,
                                column: column,
                                filled: row < counts[column],
                                shown: shown,
                                dropping: dropping,
                                columnDelay: ctx["columnDelay"],
                                rowDelay: ctx["rowDelay"],
                                damping: ctx["damping"]
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(18)
        .frame(width: 300)
        .demoCard()
        .contentShape(Rectangle())
        .onTapGesture { play(haptic: true) }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap to rebuild", "点击重新搭建"), ctx: ctx)
                .padding(.bottom, 6)
        }
        .onAppear {
            ChartEntrance.replay(isStill: ctx.isStill, reset: {
                shown = false
            }, then: {
                play(haptic: false)
            })
        }
        // The entrance already runs in onAppear, so the detail stage's one-shot intro is turned off.
        .autoplay(ctx.isPreview, every: 3.4, delay: 3.4, intro: false) { play(haptic: false) }
    }

    private func play(haptic: Bool) {
        withAnimation(.easeIn(duration: 0.18)) {
            shown = false
            dropping = true
        }
        if haptic && !ctx.isPreview { Haptics.tap(.light) }
        generation += 1
        let current = generation
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.22))
            guard current == generation else { return }
            // Park the (invisible) bricks above the chart in a separate, unanimated update…
            counts = (0..<brickColumns).map { _ in Int.random(in: 3...brickRows) }
            dropping = false
            try? await Task.sleep(for: .seconds(0.03))
            guard current == generation else { return }
            // …so they rain in from there.
            withAnimation(.snappy) { shown = true }
        }
    }
}

private struct Brick: View {
    let row: Int
    let column: Int
    let filled: Bool
    let shown: Bool
    let dropping: Bool
    let columnDelay: Double
    let rowDelay: Double
    let damping: Double

    var body: some View {
        let visible = filled && shown
        let t = Double(row) / Double(brickRows - 1)
        let delay = Double(column) * columnDelay + Double(row) * rowDelay
        let motion: Animation = shown
            ? .spring(response: 0.5, dampingFraction: damping).delay(delay)
            : .easeIn(duration: 0.18)
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color.primary.opacity(0.06))
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(brickColor(t))
                .offset(y: visible ? 0 : (dropping ? 14 : -220))
                .opacity(visible ? 1 : 0)
                .animation(motion, value: visible)
        }
        .frame(width: 30, height: 16)
    }

    private func brickColor(_ t: Double) -> Color {
        if t < 0.5 {
            return Palette.mint.mix(with: Palette.sky, by: t * 2)
        }
        return Palette.sky.mix(with: Palette.indigo, by: (t - 0.5) * 2)
    }
}
