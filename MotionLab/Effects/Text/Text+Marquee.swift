import SwiftUI

extension Effect {
    static let textMarquee = Effect(
        id: "text.marquee",
        category: .text,
        interaction: .loop,
        name: L("Marquee Ticker", "跑马灯"),
        summary: L("Seamless, endlessly scrolling ticker rows with feathered edges.", "首尾无缝、无限滚动的行情条，边缘柔和羽化。"),
        prompt: L(
            "Two stacked ticker rows scroll horizontally forever without a visible seam: a compact stock tape with symbols, prices and green/red change chips, and below it an oversized kinetic headline of keywords separated by gradient stars, travelling the opposite way. Motion is perfectly linear at a constant speed (≈60 pt/s for the tape, 80% of that for the headline) so it reads like a physical belt; content is duplicated end-to-end and wrapped modulo its own width. Both edges are feathered by a gradient mask spanning the outer 12% of the width, so items glide in and out of view — editorial, confident, always on.",
            "上下两条行情带无缝地无限横向滚动：上方是紧凑的股票行情，包含代码、价格与红绿涨跌标签；下方是超大号的动态关键词标题，以渐变星形分隔，并朝相反方向移动。运动严格匀速线性（行情带约60pt/秒，标题行为其80%），像一条真实的传送带；内容首尾复制拼接，并按自身宽度取模循环。左右两端各以占宽度12%的渐变遮罩羽化，让内容柔和地滑入滑出——有编辑感、自信、始终在线。"
        ),
        implementation: L(
            "TimelineView(.animation) offsets a fixed-size HStack holding three copies of the strip by (time × speed) mod stripWidth; the width is measured with onGeometryChange and edges are faded with a gradient mask.",
            "TimelineView(.animation) 以（时间 × 速度）对条带宽度取模来偏移一个含三份内容副本的固定尺寸 HStack；宽度由 onGeometryChange 测得，边缘使用渐变遮罩淡出。"
        ),
        apis: ["TimelineView(.animation)", "onGeometryChange(for:of:action:)", "fixedSize()", "mask"],
        tags: ["marquee", "ticker", "scrolling text", "loop", "跑马灯", "滚动字幕", "行情", "无限滚动"],
        params: [
            .slider("speed", L("Speed", "速度"), 15...160, default: 60, decimals: 0, unit: " pt/s"),
            .toggle("opposite", L("Opposite directions", "反向滚动"), default: true),
        ]
    ) { ctx in
        MarqueeDemo(ctx: ctx)
    }
}

private struct TickerQuote: Identifiable {
    let symbol: String
    let price: String
    let change: Double
    var id: String { symbol }
}

private struct MarqueeDemo: View {
    let ctx: DemoContext

    private let quotes: [TickerQuote] = [
        TickerQuote(symbol: "AAPL", price: "232.18", change: 1.24),
        TickerQuote(symbol: "NVDA", price: "141.02", change: 3.87),
        TickerQuote(symbol: "TSLA", price: "248.50", change: -2.11),
        TickerQuote(symbol: "MSFT", price: "438.66", change: 0.58),
        TickerQuote(symbol: "AMZN", price: "201.73", change: -0.42),
        TickerQuote(symbol: "META", price: "589.34", change: 2.05),
    ]

    private var words: [String] {
        ctx.language == .zh
            ? ["动效", "质感", "节奏", "细节", "愉悦"]
            : ["Motion", "Craft", "Rhythm", "Detail", "Delight"]
    }

    var body: some View {
        VStack(spacing: 22) {
            MarqueeRow(speed: ctx["speed"], reversed: false, preview: ctx.isPreview) {
                ForEach(quotes) { QuoteChip(quote: $0) }
            }
            MarqueeRow(speed: ctx["speed"] * 0.8, reversed: ctx.bool("opposite"), preview: ctx.isPreview) {
                ForEach(words, id: \.self) { word in
                    HeadlineWord(word: word)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct MarqueeRow<Content: View>: View {
    let speed: Double
    let reversed: Bool
    /// Grid previews tick at the capped frame rate.
    let preview: Bool
    @ViewBuilder let content: () -> Content
    @State private var stripWidth: CGFloat = 0

    var body: some View {
        // A zero-width, hidden copy of the strip gives the row its height
        // without leaking the (very wide) ideal width of the moving content
        // into the parent layout — otherwise the whole detail page is pushed
        // off-screen. The moving strips live in an overlay, which never
        // affects layout.
        strip
            .fixedSize()
            .hidden()
            .frame(width: 0)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) {
                TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview))) { timeline in
                    HStack(spacing: 0) {
                        strip
                            .onGeometryChange(for: CGFloat.self) { proxy in
                                proxy.size.width
                            } action: { newValue in
                                stripWidth = newValue
                            }
                        strip
                        strip
                    }
                    .fixedSize()
                    .offset(x: offset(at: timeline.date))
                }
            }
            .clipped()
            .mask { edgeFade }
    }

    private var strip: some View {
        HStack(spacing: 0) { content() }
    }

    private func offset(at date: Date) -> CGFloat {
        let width = Double(max(stripWidth, 1))
        let travelled = (date.timeIntervalSinceReferenceDate * speed).truncatingRemainder(dividingBy: width)
        return reversed ? CGFloat(travelled - width) : CGFloat(-travelled)
    }

    private var edgeFade: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: .black, location: 0.12),
                .init(color: .black, location: 0.88),
                .init(color: .clear, location: 1),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

private struct QuoteChip: View {
    let quote: TickerQuote

    var body: some View {
        let up = quote.change >= 0
        HStack(spacing: 8) {
            Text(verbatim: quote.symbol)
                .font(.subheadline.weight(.bold))
            Text(verbatim: quote.price)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
            Text(verbatim: (up ? "▲ " : "▼ ") + String(format: "%.2f%%", abs(quote.change)))
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(up ? Palette.green : Palette.red)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background((up ? Palette.green : Palette.red).opacity(0.14), in: Capsule())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Palette.stroke))
        .padding(.horizontal, 5)
    }
}

private struct HeadlineWord: View {
    let word: String

    var body: some View {
        HStack(spacing: 16) {
            Text(verbatim: word)
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(.primary)
            Image(systemName: "sparkle")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Palette.sunset)
        }
        .padding(.trailing, 16)
    }
}
