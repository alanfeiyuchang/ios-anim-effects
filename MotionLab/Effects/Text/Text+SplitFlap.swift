import SwiftUI

extension Effect {
    static let textSplitFlap = Effect(
        id: "text.split-flap",
        category: .text,
        interaction: .state,
        name: L("Split-Flap Board", "翻页信息牌"),
        summary: L("Airport-style flaps riffle through the alphabet to each new letter.", "机场式翻牌逐格翻过字母表，停在新字符上。"),
        prompt: L(
            "A departures board built from dark split-flap cells, each showing one character with a hairline hinge across its middle. When the board updates, every cell riffles through the character wheel (space, A–Z, 0–9, punctuation) until it reaches its target: for each step the upper flap carrying the old glyph folds down around the hinge to 90° while the lower flap with the new glyph swings from −90° into place, about 50 ms per flip with a perspective tilt and a darkening shadow on the moving flap. Cells start with a ~35 ms left-to-right stagger, so the update clatters across the board — nostalgic, mechanical, full of anticipation.",
            "由深色翻页单元组成的出发信息牌，每个单元显示一个字符，中间有一道细细的铰链缝。信息更新时，每个单元沿字符轮（空格、A–Z、0–9、标点）逐格翻动直到目标字符：每一步中，承载旧字符的上半翼绕铰链向下翻折到 90°，携带新字符的下半翼再从 −90° 翻落到位，每次约 50 毫秒，带透视倾斜，运动中的翼片逐渐变暗。各单元从左到右错开约 35 毫秒启动，更新时整块牌子哗啦作响般依次翻动——怀旧、机械、充满期待感。"
        ),
        implementation: L(
            "Each cell runs an async step loop; an Animatable view maps the animated step value to the rotation3DEffect of an upper and lower half-mask of the old and new glyphs.",
            "每个单元运行一个异步步进循环；一个遵循 Animatable 的视图把动画中的步进值映射为新旧字符上下半遮罩的 rotation3DEffect。"
        ),
        apis: ["rotation3DEffect", "Animatable", "mask(alignment:_:)", ".task(id:)"],
        tags: ["split flap", "flip", "board", "airport", "solari", "翻页", "翻牌", "机场", "信息牌"],
        params: [
            .slider("step", L("Flip duration", "单次翻动"), 0.02...0.12, default: 0.05, unit: "s"),
            .slider("stagger", L("Cell stagger", "单元错开"), 0...0.12, default: 0.035, unit: "s"),
        ]
    ) { ctx in
        SplitFlapDemo(ctx: ctx)
    }
}

private enum FlapWheel {
    static let characters: [Character] = Array(" ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789:.-")

    static func next(after character: Character) -> Character {
        guard let index = characters.firstIndex(of: character) else { return characters[0] }
        return characters[(index + 1) % characters.count]
    }
}

private struct SplitFlapDemo: View {
    let ctx: DemoContext
    @State private var boardIndex = 0

    private let boards: [[String]] = [
        ["NRT 09:40", "SFO 11:15", "CDG 13:05"],
        ["PVG 10:20", "JFK 12:55", "LHR 16:30"],
        ["HND 07:50", "SIN 14:10", "DXB 22:35"],
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "airplane.departure")
                Text(L("Departures", "出发航班"), ctx.language)
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(Palette.amber)
            ForEach(0..<3, id: \.self) { row in
                FlapRow(
                    text: boards[boardIndex % boards.count][row],
                    baseDelay: Double(row) * 0.12,
                    step: ctx["step"],
                    stagger: ctx["stagger"]
                )
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
        .onTapGesture { boardIndex += 1 }
        .autoplay(ctx.isPreview, every: 4.2, delay: 3) { boardIndex += 1 }
    }
}

private struct FlapRow: View {
    let text: String
    let baseDelay: Double
    let step: Double
    let stagger: Double

    var body: some View {
        let characters = Array(text)
        HStack(spacing: 3) {
            ForEach(0..<characters.count, id: \.self) { i in
                FlapCell(
                    target: characters[i],
                    delay: baseDelay + Double(i) * stagger,
                    step: step
                )
            }
        }
    }
}

private struct FlapCell: View {
    let target: Character
    let delay: Double
    let step: Double
    @State private var current: Character = " "
    @State private var previous: Character = " "
    @State private var flips = 0
    @State private var animatedFlips: Double = 0

    var body: some View {
        FlapFace(current: current, previous: previous, target: flips, value: animatedFlips)
            .frame(width: FlapMetrics.width, height: FlapMetrics.height)
            .task(id: target) { await roll() }
    }

    private func roll() async {
        try? await Task.sleep(for: .seconds(delay))
        var guardCount = 0
        let duration = max(step, 0.01)
        while current != target && !Task.isCancelled && guardCount < 64 {
            previous = current
            current = FlapWheel.next(after: current)
            flips += 1
            withAnimation(.linear(duration: duration)) {
                animatedFlips = Double(flips)
            }
            try? await Task.sleep(for: .seconds(duration))
            guardCount += 1
        }
    }
}

private enum FlapMetrics {
    static let width: CGFloat = 28
    static let height: CGFloat = 42
}

/// Renders one flap cell. `value` animates towards `target`; the fractional remainder is the flip progress.
private struct FlapFace: View, Animatable {
    let current: Character
    let previous: Character
    let target: Int
    var value: Double

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    private var progress: Double {
        min(max(1 - (Double(target) - value), 0), 1)
    }

    var body: some View {
        let p = progress
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
