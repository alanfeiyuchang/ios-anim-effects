import SwiftUI

extension Effect {
    static let cardsStackingScroll = Effect(
        id: "cards.stacking-scroll",
        category: .cards,
        interaction: .scroll,
        name: L("Stacking Cards", "堆叠吸顶卡片"),
        summary: L("Cards pin to the top as you scroll and pile into a receding stack.", "滚动时卡片依次吸顶，层层堆叠并向后退去。"),
        prompt: L(
            "A vertical feed of 300×150 pt pass cards, each a rich gradient with a large faded glyph. As a card reaches the top it pins there instead of scrolling away, 10 pt lower than the card pinned before it, so the stack keeps a neat staircase of peeking edges. The next card slides over it, and every pinned card recedes continuously with the scroll — scaling from its top edge toward ~88% and softening with up to 2 pt of blur — so the pile reads as depth rather than clutter. Everything is scrubbed by the finger, including flings and bounces. Tactile, orderly and editorial.",
            "一列 300×150 pt 的卡券卡片纵向排列，每张都是浓郁渐变并配有大号淡化图标。卡片滚动到顶部时不会移出，而是吸附在那里，且每张比前一张低 10 pt，形成整齐的阶梯状露边。下一张卡片随即盖上来；已吸顶的卡片随滚动连续后退——以顶边为锚点缩小至约 88%，并带最多 2 pt 的轻微模糊——让堆叠呈现纵深而不显杂乱。全程由手指滚动实时驱动，甩动与回弹都精确跟随。有手感、有秩序、有杂志感。"
        ),
        implementation: L(
            "Each card's visualEffect reads its minY in the .scrollView space; once it passes its pin line the card is offset back by the overshoot and scaled/blurred by how far it has been buried. Later siblings draw on top, so no zIndex is needed.",
            "每张卡片的 visualEffect 读取其在 .scrollView 坐标空间中的 minY；越过吸顶线后，按超出距离反向偏移，并依被覆盖的深度缩放、模糊。后面的兄弟视图天然绘制在上层，无需 zIndex。"
        ),
        apis: ["visualEffect", "GeometryProxy.frame(in: .scrollView)", "ScrollPosition", "scaleEffect(_:anchor:)"],
        tags: ["sticky", "stack", "pinned", "scroll", "cards", "吸顶", "堆叠", "滚动", "卡片"],
        params: [
            .slider("peek", L("Peek step", "露边间距"), 0...20, default: 10, step: 1, decimals: 0, unit: "pt"),
            .slider("depth", L("Recede scale", "后退缩放"), 0...0.3, default: 0.12),
            .slider("blur", L("Depth blur", "纵深模糊"), 0...6, default: 2, decimals: 1, unit: "pt"),
        ]
    ) { ctx in
        CardsStackingDemo(ctx: ctx)
    }
}

private struct CardsStackingPass {
    let title: LocalizedText
    let detail: LocalizedText
    let symbol: String
    let theme: Int
}

private let cardsStackingPasses: [CardsStackingPass] = [
    CardsStackingPass(title: L("Flight", "航班"), detail: L("SFO → NRT · Gate 42", "SFO → NRT · 42 号登机口"), symbol: "airplane", theme: 0),
    CardsStackingPass(title: L("Concert", "演唱会"), detail: L("Row 12 · Seat 8", "12 排 · 8 座"), symbol: "music.note", theme: 1),
    CardsStackingPass(title: L("Coffee Club", "咖啡会员"), detail: L("7 of 10 stamps", "已集 7 / 10 枚印章"), symbol: "cup.and.saucer.fill", theme: 2),
    CardsStackingPass(title: L("Gym", "健身房"), detail: L("Member since 2021", "2021 年起会员"), symbol: "figure.run", theme: 3),
    CardsStackingPass(title: L("Museum", "美术馆"), detail: L("Tue · 14:00 entry", "周二 · 14:00 入场"), symbol: "building.columns.fill", theme: 4),
    CardsStackingPass(title: L("Hotel", "酒店"), detail: L("Room 1208 · 3 nights", "1208 房 · 3 晚"), symbol: "bed.double.fill", theme: 5),
]

private struct CardsStackingDemo: View {
    let ctx: DemoContext
    @State private var position = ScrollPosition(edge: .top)
    @State private var down = false

    private let cardHeight: CGFloat = 150
    private let spacing: CGFloat = 14
    private let pinTop: CGFloat = 16

    var body: some View {
        let peek = ctx.cg("peek")
        let depth = ctx.cg("depth")
        let blur = ctx.cg("blur")
        let buryDistance = (cardHeight + spacing) * 3
        ScrollView {
            VStack(spacing: spacing) {
                ForEach(cardsStackingPasses.indices, id: \.self) { i in
                    let pinLine = pinTop + CGFloat(i) * peek
                    CardsStackingTile(pass: cardsStackingPasses[i], language: ctx.language)
                        .frame(width: 300, height: cardHeight)
                        .visualEffect { content, proxy in
                            let minY = proxy.frame(in: .scrollView).minY
                            let overshoot = max(pinLine - minY, 0)
                            let buried = min(overshoot / buryDistance, 1)
                            return content
                                .scaleEffect(1 - depth * buried, anchor: .top)
                                .blur(radius: blur * buried)
                                .offset(y: overshoot)
                        }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, pinTop)
            // Enough runway for the last card to reach its pin line.
            .padding(.bottom, 200)
        }
        .scrollIndicators(.hidden)
        .scrollPosition($position)
        .autoplay(ctx.isPreview, every: 3.4) {
            down.toggle()
            withAnimation(.smooth(duration: 2.8)) {
                position.scrollTo(y: down ? 700 : 0)
            }
        }
    }
}

private struct CardsStackingTile: View {
    let pass: CardsStackingPass
    let language: AppLanguage

    var body: some View {
        LinearGradient(colors: CardsArt.colors(pass.theme), startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay(alignment: .trailing) {
                Image(systemName: pass.symbol)
                    .font(.system(size: 96, weight: .bold))
                    .foregroundStyle(.white.opacity(0.16))
                    .offset(x: 14, y: 10)
            }
            .overlay(alignment: .topLeading) { header }
            .overlay(alignment: .bottomLeading) { footer }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(LinearGradient(colors: [.white.opacity(0.45), .white.opacity(0.05)], startPoint: .top, endPoint: .bottom), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.16), radius: 14, y: -2)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: pass.symbol)
                .font(.system(size: 14, weight: .bold))
                .frame(width: 30, height: 30)
                .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            Text(pass.title, language)
                .font(.system(size: 17, weight: .bold, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(16)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(pass.detail, language)
                .font(.subheadline.weight(.semibold))
            Text(verbatim: "•••• \(1_024 + pass.theme * 1_311)")
                .font(.caption.monospaced())
                .opacity(0.75)
        }
        .foregroundStyle(.white)
        .padding(16)
    }
}
