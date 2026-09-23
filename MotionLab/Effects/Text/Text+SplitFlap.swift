import SwiftUI

extension Effect {
    static let textSplitFlap = Effect(
        id: "text.split-flap",
        category: .text,
        interaction: .state,
        name: L("Split-Flap Board", "翻页信息牌"),
        summary: L("Airport-style flaps riffle through the alphabet to each new letter.", "机场式翻牌逐格翻过字母表，停在新字符上。"),
        prompt: L(
            "A departures board built from dark split-flap cells, each showing one character with a hairline hinge across its middle. When the board updates, every cell starts from the glyph it is showing and riffles forward through the character wheel (space, 0–9, colon and punctuation first, then A–Z) to its target, taking at most 10 flips — a long jump only shows the last few letters before the target. For each flip the upper flap carrying the old glyph folds down around the hinge to 90°, then the lower flap with the new glyph swings from −90° into place, ~60 ms per flip with a perspective tilt and a darkening shadow on the moving flap. Cells start with a ~35 ms left-to-right stagger and each row trails the one above by 120 ms, so the whole board clatters to rest in about a second — nostalgic, mechanical, full of anticipation.",
            "由深色翻页单元组成的出发信息牌，每个单元显示一个字符，中间有一道细细的铰链缝。信息更新时，每个单元从当前显示的字符出发，沿字符轮（空格、0–9、冒号与标点在前，A–Z 在后）向前翻到目标字符，最多翻 10 次——跨度较大时只翻过目标前的最后几个字符。每次翻动中，承载旧字符的上半翼先绕铰链向下翻折到 90°，携带新字符的下半翼再从 −90° 翻落到位，每次约 60 毫秒，带透视倾斜，运动中的翼片逐渐变暗。各单元从左到右错开约 35 毫秒启动，每行比上一行晚 120 毫秒，整块牌子约一秒内哗啦作响地依次停稳——怀旧、机械、充满期待感。"
        ),
        implementation: L(
            "On each update the board plans a short character path per cell (≤ 10 flips) and records a start date; a single TimelineView(.animation) clock derives every cell's current flip and its progress from elapsed time, which drives the rotation3DEffect of masked upper and lower glyph halves.",
            "每次更新时，信息牌为每个单元规划一条不超过 10 次翻动的字符路径并记录起始时间；由单一的 TimelineView(.animation) 时钟根据经过的时间推算每个单元当前的翻动序号与进度，驱动新旧字符上下半遮罩的 rotation3DEffect。"
        ),
        apis: ["TimelineView(.animation)", "rotation3DEffect", "mask(alignment:_:)", "Date"],
        tags: ["split flap", "flip", "board", "airport", "solari", "翻页", "翻牌", "机场", "信息牌"],
        params: [
            .slider("step", L("Flip duration", "单次翻动"), 0.03...0.15, default: 0.06, unit: "s"),
            .slider("stagger", L("Cell stagger", "单元错开"), 0...0.12, default: 0.035, unit: "s"),
        ]
    ) { ctx in
        SplitFlapDemo(ctx: ctx)
    }
}

private enum FlapWheel {
    /// Digits and the colon come first so time changes resolve in a few flips.
    static let characters: [Character] = Array(" 0123456789:.-ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    static let maxFlips = 10

    /// The characters a cell shows on its way from `from` to `to`, including both ends.
    /// Long jumps are shortened to the last `maxFlips` characters before the target.
    static func path(from: Character, to: Character) -> [Character] {
        let n = characters.count
        let a = characters.firstIndex(of: from) ?? 0
        let b = characters.firstIndex(of: to) ?? 0
        let distance = (b - a + n) % n
        guard distance > 0 else { return [from] }
        var result: [Character] = [from]
        if distance <= maxFlips {
            for step in 1...distance {
                let index: Int = (a + step) % n
                result.append(characters[index])
            }
            return result
        }
        let first: Int = b - maxFlips + 1 + n
        for step in 0..<maxFlips {
            let index: Int = (first + step) % n
            result.append(characters[index])
        }
        return result
    }
}

/// The in-flight update: one character path per cell, all timed from `start`.
private struct FlapPlan {
    var paths: [[[Character]]]
    var start: Date

    static func still(_ rows: [String]) -> FlapPlan {
        FlapPlan(paths: rows.map { row in row.map { [$0] } }, start: .distantPast)
    }
}

/// What one cell shows at a moment: the outgoing glyph, the incoming glyph and the flip progress (1 = at rest).
private struct FlapFrame {
    let previous: Character
    let current: Character
    let progress: Double
}

private let flapRowDelay = 0.12

private struct SplitFlapDemo: View {
    let ctx: DemoContext
    @State private var boardIndex = 0
    @State private var plan = FlapPlan.still(SplitFlapDemo.boards[0])
    @State private var running = false

    static let boards: [[String]] = [
        ["NRT 09:40", "SFO 11:15", "CDG 13:05"],
        ["PVG 10:20", "JFK 12:55", "LHR 16:30"],
        ["HND 07:50", "SIN 14:10", "DXB 22:35"],
    ]

    private var step: Double { max(ctx["step"], 0.01) }
    private var stagger: Double { ctx["stagger"] }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "airplane.departure")
                Text(L("Departures", "出发航班"), ctx.language)
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(Palette.amber)
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview), paused: !running)) { timeline in
                board(at: timeline.date)
            }
            DemoHint(text: L("Tap to update the board", "点击更新信息牌"), ctx: ctx)
                .padding(.top, 4)
        }
        .padding(16)
        .background(Color(white: 0.07), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .environment(\.colorScheme, .dark)
        .shadow(color: .black.opacity(0.25), radius: 20, y: 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { update() }
        .task(id: boardIndex) {
            // Pause the clock once the slowest cell has landed.
            try? await Task.sleep(for: .seconds(totalDuration + 0.1))
            guard !Task.isCancelled else { return }
            running = false
        }
        .autoplay(ctx.isPreview, every: 3.0, delay: 1.0) { update() }
    }

    private func board(at date: Date) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(0..<plan.paths.count, id: \.self) { row in
                HStack(spacing: 3) {
                    ForEach(0..<plan.paths[row].count, id: \.self) { column in
                        let state = cellState(row: row, column: column, at: date)
                        FlapFace(current: state.current, previous: state.previous, progress: state.progress)
                            .frame(width: FlapMetrics.width, height: FlapMetrics.height)
                    }
                }
            }
        }
    }

    private func delay(row: Int, column: Int) -> Double {
        Double(row) * flapRowDelay + Double(column) * stagger
    }

    private var totalDuration: Double {
        let columns = plan.paths.map(\.count).max() ?? 0
        return delay(row: max(plan.paths.count - 1, 0), column: max(columns - 1, 0)) + Double(FlapWheel.maxFlips) * step
    }

    private func cellState(row: Int, column: Int, at date: Date) -> FlapFrame {
        let path = plan.paths[row][column]
        guard let first = path.first, let last = path.last else {
            return FlapFrame(previous: " ", current: " ", progress: 1)
        }
        let elapsed = date.timeIntervalSince(plan.start) - delay(row: row, column: column)
        guard elapsed > 0 else { return FlapFrame(previous: first, current: first, progress: 1) }
        let flip = Int(elapsed / step)
        guard flip < path.count - 1 else { return FlapFrame(previous: last, current: last, progress: 1) }
        let progress = elapsed / step - Double(flip)
        return FlapFrame(previous: path[flip], current: path[flip + 1], progress: progress)
    }

    /// The glyph a cell visibly shows right now (the old one until its flap passes the hinge).
    private func visibleCharacter(row: Int, column: Int, at date: Date) -> Character {
        guard row < plan.paths.count, column < plan.paths[row].count else { return " " }
        let state = cellState(row: row, column: column, at: date)
        return state.progress < 0.5 ? state.previous : state.current
    }

    private func update() {
        let now = Date()
        let next = Self.boards[(boardIndex + 1) % Self.boards.count]
        let paths: [[[Character]]] = next.enumerated().map { row, text in
            text.enumerated().map { column, target in
                FlapWheel.path(from: visibleCharacter(row: row, column: column, at: now), to: target)
            }
        }
        plan = FlapPlan(paths: paths, start: now)
        running = true
        boardIndex += 1
    }
}

private enum FlapMetrics {
    static let width: CGFloat = 28
    static let height: CGFloat = 42
}

/// Renders one flap cell at a given flip progress (0 → 1).
private struct FlapFace: View {
    let current: Character
    let previous: Character
    let progress: Double

    var body: some View {
        let p = min(max(progress, 0), 1)
        // Shade the moving flap only lightly: the tile is already ~0.2 white,
        // so heavier (additive) brightness crushed it to solid black bars.
        ZStack {
            FlapHalf(character: current, top: true)
            FlapHalf(character: previous, top: false)
            if p < 0.5 {
                FlapHalf(character: previous, top: true)
                    .brightness(-p * 0.25)
                    .rotation3DEffect(.degrees(-p * 180), axis: (x: 1, y: 0, z: 0), anchor: .center, perspective: 0.5)
            } else {
                FlapHalf(character: current, top: false)
                    .brightness(-(1 - p) * 0.25)
                    .rotation3DEffect(.degrees((1 - p) * 180), axis: (x: 1, y: 0, z: 0), anchor: .center, perspective: 0.5)
            }
            Rectangle()
                .fill(Color.black.opacity(0.6))
                .frame(height: 1)
        }
    }
}

private struct FlapHalf: View {
    let character: Character
    let top: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(LinearGradient(colors: [Color(white: 0.2), Color(white: 0.13)], startPoint: .top, endPoint: .bottom))
            Text(verbatim: String(character))
                .font(.system(size: 26, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(white: 0.96))
        }
        .frame(width: FlapMetrics.width, height: FlapMetrics.height)
        .mask(alignment: top ? .top : .bottom) {
            Rectangle().frame(height: FlapMetrics.height / 2)
        }
    }
}
