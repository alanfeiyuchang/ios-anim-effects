import SwiftUI

extension Effect {
    static let scrollParallaxCards = Effect(
        id: "scroll.parallax-cards",
        category: .scroll,
        interaction: .scroll,
        name: L("Parallax Windows", "视差窗口卡片"),
        summary: L("Feed cards act as windows: the artwork inside drifts slower than the scroll.", "信息流卡片像一扇扇窗：内部画面比滚动更慢地漂移。"),
        prompt: L(
            "A vertical feed of wide cards (150 pt tall, 22 pt corners) scrolls in a card-sized viewport. Each card is a window onto oversized artwork — a gradient with a large glyph and soft light blobs — that is taller than the card by twice the parallax amount. As a card travels from the bottom of the viewport to the top, its artwork translates in the opposite direction by up to ±36 pt relative to the frame, linearly with the card's distance from the viewport center, so the image appears to sit deeper than the glass. Cards near the edges also ease down to 92% scale. The motion is scrubbed directly by scroll position — subtle, dimensional and editorial.",
            "一列宽幅卡片（高 150 pt，22 pt 圆角）在卡片大小的视口中纵向滚动。每张卡片都是一扇窗，窗内是比卡片高出两倍视差量的超大画面——渐变、大号图标与柔和光斑。卡片从视口底部移动到顶部的过程中，画面相对卡片框朝反方向平移，最多 ±36 pt，与卡片到视口中心的距离成线性关系，使画面看起来位于玻璃之后更深处。靠近边缘的卡片还会缓缓缩小到 92%。运动完全由滚动位置实时驱动——含蓄、立体，富有杂志编排感。"
        ),
        implementation: L(
            "The artwork is framed taller than its clipped container and a visualEffect offsets it by its normalised distance from the viewport center (measured via onGeometryChange); a scrollTransition adds the edge scale.",
            "画面的高度大于被裁剪的容器，visualEffect 按其到视口中心的归一化距离（视口高度由 onGeometryChange 测得）进行偏移；scrollTransition 负责边缘缩放。"
        ),
        apis: ["visualEffect", "onGeometryChange", "scrollTransition", "clipShape", "ScrollPosition"],
        tags: ["parallax", "feed", "depth", "window", "视差", "信息流", "纵深", "卡片"],
        params: [
            .slider("amount", L("Parallax amount", "视差幅度"), 0...60, default: 36, step: 1, decimals: 0, unit: "pt"),
            .toggle("zoom", L("Edge zoom", "边缘缩放"), default: true),
        ]
    ) { ctx in
        ScrollParallaxDemo(ctx: ctx)
    }
}

private struct ScrollParallaxDemo: View {
    let ctx: DemoContext
    @State private var position = ScrollPosition(edge: .top)
    @State private var viewport: CGFloat = 340
    @State private var down = false

    var body: some View {
        let zoom = ctx.bool("zoom")
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(0..<9, id: \.self) { i in
                    ScrollParallaxWindow(index: i, language: ctx.language, amount: ctx.cg("amount"), viewport: viewport)
                        .scrollTransition(.interactive, axis: .vertical) { content, phase in
                            let scale: CGFloat = zoom ? 1 - CGFloat(abs(phase.value)) * 0.08 : 1
                            return content.scaleEffect(scale)
                        }
                }
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .scrollPosition($position)
        .onGeometryChange(for: CGFloat.self, of: { proxy in proxy.size.height }, action: { newHeight in
            viewport = newHeight
        })
        .autoplay(ctx.isPreview, every: 3.0) {
            down.toggle()
            withAnimation(.smooth(duration: 2.6)) {
                position.scrollTo(y: down ? 560 : 0)
            }
        }
    }
}

private struct ScrollParallaxWindow: View {
    let index: Int
    let language: AppLanguage
    let amount: CGFloat
    let viewport: CGFloat

    var body: some View {
        let amount = self.amount
        let viewport = self.viewport
        return ScrollKitArt(index: index * 2 + 1, language: language, showsTitle: false)
            .frame(height: 150 + amount * 2)
            .visualEffect { content, proxy in
                let mid = proxy.frame(in: .scrollView).midY
                let t = ((mid - viewport / 2) / max(viewport, 1)).clamped(to: -1...1)
                return content.offset(y: -t * amount * 2)
            }
            .frame(height: 150)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(alignment: .bottomLeading) { caption }
            .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(ScrollKit.title(index * 2 + 1), language)
                .font(.headline.weight(.bold))
            Text(ScrollKit.subtitle(index * 2 + 1), language)
                .font(.caption.weight(.medium))
                .opacity(0.85)
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
        .padding(14)
    }
}
