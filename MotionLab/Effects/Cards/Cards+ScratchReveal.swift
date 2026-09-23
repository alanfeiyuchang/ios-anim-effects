import SwiftUI

extension Effect {
    static let cardsScratchReveal = Effect(
        id: "cards.scratch-reveal",
        category: .cards,
        interaction: .gesture,
        name: L("Scratch Card", "刮刮卡"),
        summary: L("Scratch a metallic foil off a reward card; past a threshold it clears itself.", "用手指刮开奖励卡上的金属涂层，超过阈值后自动揭晓。"),
        prompt: L(
            "A 280×170 pt reward card hides its prize under a brushed-metal foil with a fine diagonal pinstripe and an embossed “Scratch here” label. The finger erases the foil along its path with a round brush (~30 pt), leaving soft-edged strokes and a light selection tick every few new cells. Coverage is sampled on a coarse grid; once ~55% is gone, the remaining foil dissolves in 350 ms while scaling up 4%, and the prize beneath — a bold gradient amount with sparkles — springs from 92% to 100% (response 0.45 s, damping 0.6) with a success haptic. Tactile, suspenseful and rewarding.",
            "一张 280×170 pt 的奖励卡，奖品藏在带细斜纹拉丝质感、压印「刮开此处」字样的金属涂层下。手指沿轨迹以约 30 pt 的圆形笔刷擦除涂层，边缘柔和，每刮开若干新区域便有一次轻微的选择触感。系统在粗网格上统计刮开比例；超过约 55% 后，剩余涂层在 350 毫秒内放大 4% 并消散，下方的奖品——渐变大字金额与闪光——以弹簧（响应 0.45 秒、阻尼 0.6）从 92% 弹到 100%，伴随成功触感。有手感、有悬念、有回报。"
        ),
        implementation: L(
            "The foil is masked by a Canvas that fills its rect and then strokes the recorded drag paths with blendMode .destinationOut; a Set of touched grid cells estimates coverage and triggers the reveal animation.",
            "涂层以 Canvas 作为遮罩：先填满矩形，再以 .destinationOut 混合模式描绘记录下的拖动路径；用被触及网格单元的 Set 估算刮开比例并触发揭晓动画。"
        ),
        apis: ["Canvas", "GraphicsContext.blendMode", "mask(alignment:_:)", "DragGesture", "sensoryFeedback"],
        tags: ["scratch", "reveal", "reward", "lottery", "mask", "刮刮卡", "刮开", "奖励", "遮罩"],
        params: [
            .slider("brush", L("Brush size", "笔刷大小"), 14...56, default: 30, step: 1, decimals: 0, unit: "pt"),
            .slider("threshold", L("Auto-reveal at", "自动揭晓阈值"), 0.3...0.9, default: 0.55),
            .choice("foil", L("Foil", "涂层"), [L("Silver", "银色"), L("Gold", "金色")], default: 0),
        ]
    ) { ctx in
        CardsScratchDemo(ctx: ctx)
    }
}

private enum CardsScratchMetrics {
    static let size = CGSize(width: 280, height: 170)
    static let cell: CGFloat = 14
    static let columns = Int((size.width / cell).rounded(.up))
    static let rows = Int((size.height / cell).rounded(.up))
    static var total: Int { columns * rows }
}

private struct CardsScratchDemo: View {
    let ctx: DemoContext
    @State private var strokes: [[CGPoint]] = []
    @State private var cells: Set<Int> = []
    @State private var revealed = false
    @State private var round = 0
    @State private var ticks = 0
    @State private var autoStep = 0
    @State private var dragging = false
    @State private var startedRevealed = false

    var body: some View {
        VStack(spacing: 22) {
            card
            DemoHint(text: revealed ? L("Tap the card for a new one", "点击卡片换一张") : L("Scratch the foil", "刮开涂层"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sensoryFeedback(.selection, trigger: ticks)
        .autoplay(ctx.isPreview, every: 0.05, delay: 0.3) { autoScratch() }
    }

    private var card: some View {
        ZStack {
            CardsScratchPrize(round: round, revealed: revealed, language: ctx.language)
            CardsScratchFoil(gold: ctx.int("foil") == 1, language: ctx.language)
                .mask {
                    Canvas { context, size in
                        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))
                        context.blendMode = .destinationOut
                        let style = StrokeStyle(lineWidth: ctx.cg("brush"), lineCap: .round, lineJoin: .round)
                        for stroke in strokes {
                            guard let first = stroke.first else { continue }
                            var path = Path()
                            path.move(to: first)
                            // A lone tap still erases a dot.
                            path.addLine(to: CGPoint(x: first.x + 0.1, y: first.y))
                            for point in stroke.dropFirst() { path.addLine(to: point) }
                            context.stroke(path, with: .color(.black), style: style)
                        }
                    }
                }
                .scaleEffect(revealed ? 1.04 : 1)
                .opacity(revealed ? 0 : 1)
                .allowsHitTesting(false)
        }
        .frame(width: CardsScratchMetrics.size.width, height: CardsScratchMetrics.size.height)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
        .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
        .contentShape(Rectangle())
        .gesture(scratch)
    }

    private var scratch: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !dragging {
                    dragging = true
                    startedRevealed = revealed
                    if !revealed { strokes.append([]) }
                }
                guard !startedRevealed, !revealed, !strokes.isEmpty else { return }
                strokes[strokes.count - 1].append(value.location)
                mark(value.location)
            }
            .onEnded { _ in
                dragging = false
                // A touch that begins on an already revealed card deals a fresh one.
                if startedRevealed { reset() }
            }
    }

    /// Records grid cells under the brush and fires the reveal once enough foil is gone.
    private func mark(_ point: CGPoint) {
        let metrics = CardsScratchMetrics.self
        let radius = ctx.cg("brush") / 2
        let before = cells.count
        let minCol = max(Int((point.x - radius) / metrics.cell), 0)
        let maxCol = min(Int((point.x + radius) / metrics.cell), metrics.columns - 1)
        let minRow = max(Int((point.y - radius) / metrics.cell), 0)
        let maxRow = min(Int((point.y + radius) / metrics.cell), metrics.rows - 1)
        if minCol <= maxCol && minRow <= maxRow {
            for row in minRow...maxRow {
                for col in minCol...maxCol {
                    let center = CGPoint(x: (CGFloat(col) + 0.5) * metrics.cell, y: (CGFloat(row) + 0.5) * metrics.cell)
                    if hypot(center.x - point.x, center.y - point.y) <= radius + metrics.cell * 0.35 {
                        cells.insert(row * metrics.columns + col)
                    }
                }
            }
        }
        if !ctx.isPreview && cells.count / 6 != before / 6 { ticks += 1 }
        if !revealed && Double(cells.count) / Double(metrics.total) >= ctx["threshold"] {
            withAnimation(.easeOut(duration: 0.35)) { revealed = true }
            if !ctx.isPreview { Haptics.success() }
        }
    }

    private func reset() {
        Haptics.tap(.soft)
        strokes = []
        cells = []
        round += 1
        withAnimation(.smooth(duration: 0.3)) { revealed = false }
    }

    /// Preview: sweep a zig-zag brush across the card, hold the prize, then deal a fresh card.
    private func autoScratch() {
        let size = CardsScratchMetrics.size
        let steps = 90
        if autoStep < steps {
            let t = Double(autoStep) / Double(steps - 1)
            let lanes = 5.0
            let lane = min(floor(t * lanes), lanes - 1)
            let local = t * lanes - lane
            let forward = Int(lane).isMultiple(of: 2)
            let x = 24 + (size.width - 48) * CGFloat(forward ? local : 1 - local)
            let y = 22 + (size.height - 44) * CGFloat((lane + local * 0.9) / lanes)
            if strokes.isEmpty { strokes.append([]) }
            if !revealed {
                strokes[strokes.count - 1].append(CGPoint(x: x, y: y))
                mark(CGPoint(x: x, y: y))
            }
        } else if autoStep == steps + 30 {
            strokes = []
            cells = []
            round += 1
            withAnimation(.smooth(duration: 0.3)) { revealed = false }
            autoStep = -1
        }
        autoStep += 1
    }
}

private struct CardsScratchPrize: View {
    let round: Int
    let revealed: Bool
    let language: AppLanguage

    private var amount: String {
        let amounts = language == .zh ? ["¥88", "¥520", "¥66", "¥128"] : ["$25", "$100", "$10", "$50"]
        return amounts[round % amounts.count]
    }

    private let sparkleOffsets: [CGSize] = [
        CGSize(width: -110, height: -52),
        CGSize(width: -84, height: 50),
        CGSize(width: 96, height: -58),
        CGSize(width: 116, height: 30),
        CGSize(width: 70, height: 62),
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xFFF4E0), Color(hex: 0xFFE1EC)], startPoint: .topLeading, endPoint: .bottomTrailing)
            sparkles
            VStack(spacing: 4) {
                Text(L("YOU WON", "恭喜获得"), language)
                    .font(.caption.weight(.heavy))
                    .tracking(2)
                    .foregroundStyle(Color(hex: 0xD9468F).opacity(0.8))
                Text(verbatim: amount)
                    .font(.system(size: 54, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Palette.sunset)
                Text(L("Cash reward · valid 7 days", "现金红包 · 7 天内有效"), language)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.black.opacity(0.45))
            }
            .scaleEffect(revealed ? 1 : 0.92)
            .animation(.spring(response: 0.45, dampingFraction: 0.6), value: revealed)
        }
    }

    private var sparkles: some View {
        ZStack {
            ForEach(sparkleOffsets.indices, id: \.self) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: CGFloat(10 + (i * 7) % 14)))
                    .foregroundStyle(Palette.amber)
                    .offset(sparkleOffsets[i])
                    .scaleEffect(revealed ? 1 : 0.4)
                    .opacity(revealed ? 1 : 0.5)
                    .animation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.1 + Double(i) * 0.05), value: revealed)
            }
        }
    }
}

private struct CardsScratchFoil: View {
    let gold: Bool
    let language: AppLanguage

    private var colors: [Color] {
        gold
            ? [Color(hex: 0xF3DDA0), Color(hex: 0xC9A24B), Color(hex: 0xF7E7B8), Color(hex: 0xB08A3E)]
            : [Color(hex: 0xE4E7EE), Color(hex: 0xA9B0BE), Color(hex: 0xEEF0F5), Color(hex: 0x959DAD)]
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            // Brushed pinstripe.
            Canvas { context, size in
                var x: CGFloat = -size.height
                while x < size.width {
                    var line = Path()
                    line.move(to: CGPoint(x: x, y: size.height))
                    line.addLine(to: CGPoint(x: x + size.height, y: 0))
                    context.stroke(line, with: .color(.white.opacity(0.18)), lineWidth: 1)
                    x += 6
                }
            }
            VStack(spacing: 6) {
                Image(systemName: "hand.draw.fill")
                    .font(.system(size: 26, weight: .semibold))
                Text(L("SCRATCH HERE", "刮开此处"), language)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .tracking(2)
            }
            .foregroundStyle(Color.black.opacity(0.28))
            .shadow(color: .white.opacity(0.6), radius: 0, x: 0.5, y: 1)
        }
    }
}
