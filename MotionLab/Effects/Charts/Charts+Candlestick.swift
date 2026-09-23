import SwiftUI

extension Effect {
    static let chartsCandlestickLive = Effect(
        id: "charts.candlestick-live",
        category: .charts,
        interaction: .tap,
        name: L("Live Candlesticks", "实时 K 线"),
        summary: L("A trading chart whose live candle breathes with every tick while history glides left and the scale re-fits smoothly.", "实时 K 线随每次报价伸缩，历史蜡烛平滑左移，纵轴刻度柔和自适应。"),
        prompt: L(
            "A trading card: pair name and last price on top, tinted green or red by the live candle’s direction, over 18 candlesticks plus one live candle. Every 140 ms the live close gets a new random-walk target and follows it exponentially (≈ 70 ms), so body and wick stretch organically instead of jumping; a dashed price line and a colored price tag track it in a right-hand axis column that also labels three horizontal guides. The live candle always keeps a full slot at the right edge and a soft glow. When its period ends it is committed and the whole series glides one slot left continuously, with no step, while the vertical scale eases (≈ 200 ms) to fit the visible high/low with 12% headroom. Tap to inject a volatility spike. Precise, alive, professional.",
            "一张交易卡片：顶部是交易对名称与最新价，按实时蜡烛涨跌染成绿色或红色；下方是 18 根历史 K 线加 1 根实时 K 线。实时收盘价每 140ms 获得一个新的随机游走目标，并以约 70ms 的指数跟随趋近，实体与影线因此自然伸缩而非跳变；虚线价格线与彩色价格标签在右侧价格轴一栏同步跟随，该栏同时标注三条水平参考线。实时蜡烛始终在最右侧占满一格，并带柔和辉光。周期结束时蜡烛被固定，整组序列连续平滑地左移一格，毫无阶跃；纵轴刻度在约 200ms 内缓动，以 12% 余量适配可见区间的高低点。点击可注入一次剧烈波动。精准、鲜活、专业。"
        ),
        implementation: L(
            "A reference-type model advanced by TimelineView eases the live close, commits candles on a timer and smooths the y-range; the fractional progress of the current period offsets every x, and a Canvas draws wicks, bodies, the price line and tag.",
            "由 TimelineView 推进的引用类型模型缓动实时收盘价、按周期固定蜡烛并平滑纵轴区间；当前周期的小数进度为所有 x 坐标提供偏移，Canvas 绘制影线、实体、价格线与标签。"
        ),
        apis: ["TimelineView(.animation)", "Canvas", "GraphicsContext.draw(_:at:)", "monospacedDigit", "onTapGesture"],
        tags: ["candlestick", "stock", "live", "ohlc", "K 线", "蜡烛图", "行情", "实时"],
        params: [
            .slider("interval", L("Candle period", "蜡烛周期"), 0.6...3.0, default: 1.4, unit: "s"),
            .slider("volatility", L("Volatility", "波动率"), 0.3...2.0, default: 1.0, unit: "×"),
            .choice("style", L("Style", "样式"), [L("Filled", "实心"), L("Hollow up", "空心阳线")]),
        ]
    ) { ctx in
        CandlestickDemo(ctx: ctx)
    }
}

private struct Candle {
    var open: Double
    var high: Double
    var low: Double
    var close: Double
}

private final class CandleModel {
    static let visible = 18

    private(set) var candles: [Candle] = []
    private(set) var live: Candle
    private(set) var low: Double
    private(set) var high: Double
    private(set) var phase: Double = 0
    var impulse: Double = 0
    private var target: Double
    private var lastTick: Date?
    private var lastCommit: Date?
    private var lastDate: Date?

    init() {
        var price = 182.0
        var list: [Candle] = []
        for _ in 0..<CandleModel.visible {
            let open = price
            let close = open + Double.random(in: -1.1...1.25)
            list.append(Candle(
                open: open,
                high: max(open, close) + Double.random(in: 0.1...0.7),
                low: min(open, close) - Double.random(in: 0.1...0.7),
                close: close
            ))
            price = close
        }
        candles = list
        live = Candle(open: price, high: price, low: price, close: price)
        target = price
        low = (list.map(\.low).min() ?? price) - 1
        high = (list.map(\.high).max() ?? price) + 1
    }

    func step(to date: Date, interval: Double, volatility: Double) {
        let dt = min(max(lastDate.map { date.timeIntervalSince($0) } ?? 0, 0), 1.0 / 20.0)
        lastDate = date
        if lastCommit == nil { lastCommit = date }

        let sinceTick = lastTick.map { date.timeIntervalSince($0) } ?? .infinity
        if sinceTick > 0.14 {
            lastTick = date
            target = live.close + Double.random(in: -0.75...0.8) * volatility + impulse
            impulse *= 0.45
        }
        live.close += (target - live.close) * (1 - exp(-dt * 14))
        live.high = max(live.high, live.close)
        live.low = min(live.low, live.close)

        var elapsed = lastCommit.map { date.timeIntervalSince($0) } ?? 0
        if elapsed >= interval {
            candles.append(live)
            if candles.count > CandleModel.visible { candles.removeFirst(candles.count - CandleModel.visible) }
            live = Candle(open: live.close, high: live.close, low: live.close, close: live.close)
            lastCommit = date
            elapsed = 0
        }
        phase = min(max(elapsed / max(interval, 0.1), 0), 1)

        var lo = live.low
        var hi = live.high
        for candle in candles {
            lo = min(lo, candle.low)
            hi = max(hi, candle.high)
        }
        let pad = (hi - lo) * 0.12 + 0.3
        let k = 1 - exp(-dt * 5)
        low += (lo - pad - low) * k
        high += (hi + pad - high) * k
    }
}

private struct CandlestickDemo: View {
    let ctx: DemoContext
    @State private var model = CandleModel()

    var body: some View {
        let interval = ctx["interval"]
        let volatility = ctx["volatility"]
        let hollow = ctx.int("style") == 1
        VStack(alignment: .leading, spacing: 10) {
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let _ = model.step(to: timeline.date, interval: interval, volatility: volatility)
                VStack(alignment: .leading, spacing: 10) {
                    CandleHeader(live: model.live, language: ctx.language)
                    CandleCanvas(
                        candles: model.candles,
                        live: model.live,
                        phase: model.phase,
                        low: model.low,
                        high: model.high,
                        hollow: hollow
                    )
                    .frame(height: 176)
                }
            }
        }
        .padding(18)
        .frame(width: 304)
        .demoCard()
        .contentShape(Rectangle())
        .onTapGesture { spike() }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap to inject volatility", "点击注入一次波动"), ctx: ctx)
                .padding(.bottom, 8)
        }
    }

    private func spike() {
        model.impulse = (Bool.random() ? 1 : -1) * Double.random(in: 2.5...4.5) * ctx["volatility"]
        if !ctx.isPreview { Haptics.tap(.rigid) }
    }
}

private struct CandleHeader: View {
    let live: Candle
    let language: AppLanguage

    var body: some View {
        let up = live.close >= live.open
        let change = live.close - live.open
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(language == .zh ? "MLX / USD · 实时" : "MLX / USD · Live")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(String(format: "%.2f", live.close))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(up ? Palette.green : Palette.red)
            }
            Spacer()
            Text(String(format: "%+.2f", change))
                .font(.system(size: 13, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(up ? Palette.green : Palette.red)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background((up ? Palette.green : Palette.red).opacity(0.14), in: Capsule())
        }
    }
}

private struct CandleCanvas: View {
    let candles: [Candle]
    let live: Candle
    let phase: Double
    let low: Double
    let high: Double
    let hollow: Bool

    private static let tagWidth: CGFloat = 50

    var body: some View {
        Canvas { context, size in
            guard size.width > CandleCanvas.tagWidth + 20, size.height > 20 else { return }
            let plotWidth = size.width - CandleCanvas.tagWidth - 6
            // 1.2 extra slots leave room for the live candle's body and glow at phase 0, so it is never clipped.
            let step = plotWidth / (CGFloat(CandleModel.visible) + 1.2)
            let span = max(high - low, 0.0001)
            let y = { (value: Double) -> CGFloat in size.height * CGFloat(1 - (value - low) / span) }

            var grid = Path()
            for fraction: CGFloat in [0.25, 0.5, 0.75] {
                grid.move(to: CGPoint(x: 0, y: size.height * fraction))
                grid.addLine(to: CGPoint(x: plotWidth, y: size.height * fraction))
            }
            context.stroke(grid, with: .color(.primary.opacity(0.07)), lineWidth: 0.5)

            var plot = context
            plot.clip(to: Path(CGRect(x: 0, y: 0, width: plotWidth, height: size.height)))
            for (index, candle) in candles.enumerated() {
                let x = (CGFloat(index) - CGFloat(phase)) * step + step / 2
                CandleCanvas.draw(&plot, candle: candle, x: x, width: step * 0.62, y: y, hollow: hollow, glow: false)
            }
            let liveX = (CGFloat(candles.count) - CGFloat(phase)) * step + step / 2
            CandleCanvas.draw(&plot, candle: live, x: liveX, width: step * 0.62, y: y, hollow: hollow, glow: true)

            let up = live.close >= live.open
            let tint = up ? Palette.green : Palette.red
            let priceY = y(live.close).clamped(to: 9...max(size.height - 9, 9))
            var line = Path()
            line.move(to: CGPoint(x: 0, y: priceY))
            line.addLine(to: CGPoint(x: plotWidth + 6, y: priceY))
            context.stroke(line, with: .color(tint.opacity(0.7)), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

            // Price axis: the value at each guide, in the tag column, skipped where the live tag would cover it.
            for fraction: CGFloat in [0.25, 0.5, 0.75] {
                let guideY = size.height * fraction
                guard abs(guideY - priceY) > 14 else { continue }
                let value = low + Double(1 - fraction) * span
                context.draw(
                    Text(String(format: "%.2f", value))
                        .font(.system(size: 9, weight: .semibold, design: .rounded).monospacedDigit())
                        .foregroundStyle(Color.secondary),
                    at: CGPoint(x: size.width - CandleCanvas.tagWidth / 2, y: guideY)
                )
            }

            let tag = CGRect(x: size.width - CandleCanvas.tagWidth, y: priceY - 9, width: CandleCanvas.tagWidth, height: 18)
            context.fill(Path(roundedRect: tag, cornerRadius: 5, style: .continuous), with: .color(tint))
            context.draw(
                Text(String(format: "%.2f", live.close))
                    .font(.system(size: 10, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color.white),
                at: CGPoint(x: tag.midX, y: tag.midY)
            )
        }
    }

    private static func draw(
        _ context: inout GraphicsContext,
        candle: Candle,
        x: CGFloat,
        width: CGFloat,
        y: (Double) -> CGFloat,
        hollow: Bool,
        glow: Bool
    ) {
        let up = candle.close >= candle.open
        let color = up ? Palette.green : Palette.red
        let top = y(max(candle.open, candle.close))
        let bottom = max(y(min(candle.open, candle.close)), top + 1.5)
        let body = CGRect(x: x - width / 2, y: top, width: width, height: bottom - top)

        if glow {
            context.fill(
                Path(roundedRect: body.insetBy(dx: -3, dy: -3), cornerRadius: 4, style: .continuous),
                with: .color(color.opacity(0.18))
            )
        }
        var wick = Path()
        wick.move(to: CGPoint(x: x, y: y(candle.high)))
        wick.addLine(to: CGPoint(x: x, y: y(candle.low)))
        context.stroke(wick, with: .color(color), lineWidth: 1.2)

        let shape = Path(roundedRect: body, cornerRadius: 1.5, style: .continuous)
        if hollow && up {
            context.fill(shape, with: .color(Palette.elevated))
            context.stroke(shape, with: .color(color), lineWidth: 1.2)
        } else {
            context.fill(shape, with: .color(color))
        }
    }
}
