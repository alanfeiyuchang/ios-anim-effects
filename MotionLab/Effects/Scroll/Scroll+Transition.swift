import SwiftUI

extension Effect {
    static let scrollTransitionList = Effect(
        id: "scroll.transition-list",
        category: .scroll,
        interaction: .scroll,
        name: L("Edge-aware List", "边缘渐隐列表"),
        summary: L("Rows fade, shrink, blur or fold as they enter and leave the viewport.", "列表行进入或离开可视区域时渐隐、缩小、模糊或折叠。"),
        prompt: L(
            "A vertical list of rounded content rows scrolls inside a card. Each row is fully crisp while wholly visible, but as it crosses the top or bottom edge its appearance is interpolated continuously with the scroll position: in the default style it fades to ~20% opacity and shrinks to ~85% scale; alternatives blur it up to 10 pt or fold it back up to 60° around its horizontal axis like a page turning into depth. Because the effect is scrubbed by the finger rather than timed, it tracks flings and rubber-banding exactly. The result frames the content softly and gives the list a focused, cinematic depth.",
            "卡片内有一列圆角内容行可垂直滚动。每一行完全处于可视区域时保持清晰；一旦越过顶部或底部边缘，其外观随滚动位置连续插值：默认样式下淡出到约 20% 透明度并缩小到约 85%；另可选模糊最多 10 pt，或绕水平轴向后折叠最多 60°，像书页翻入纵深。由于效果由手指滚动实时驱动而非定时播放，它能精确跟随快速甩动与橡皮筋回弹。整体让内容边缘柔和收束，列表更具聚焦感与电影般的层次。"
        ),
        implementation: L(
            "Each row uses .scrollTransition(.interactive), mapping |phase.value| to opacity, scaleEffect, blur or rotation3DEffect depending on the chosen style.",
            "每一行使用 .scrollTransition(.interactive)，根据所选样式将 |phase.value| 映射到 opacity、scaleEffect、blur 或 rotation3DEffect。"
        ),
        apis: ["scrollTransition", "ScrollTransitionPhase", "ScrollPosition", "LazyVStack"],
        tags: ["scroll transition", "fade", "blur", "list", "滚动过渡", "渐隐", "模糊", "列表"],
        params: [
            .choice("style", L("Style", "样式"), [L("Fade & scale", "渐隐缩放"), L("Blur", "模糊"), L("Fold", "折叠")]),
            .slider("strength", L("Strength", "强度"), 0.2...1, default: 0.8),
        ]
    ) { ctx in
        ScrollTransitionDemo(ctx: ctx)
    }
}

private struct ScrollTransitionDemo: View {
    let ctx: DemoContext
    @State private var position = ScrollPosition(edge: .top)
    @State private var down = false

    var body: some View {
        let style = ctx.int("style")
        let strength = ctx["strength"]
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(0..<24, id: \.self) { i in
                    ScrollKitRow(index: i, language: ctx.language)
                        .scrollTransition(.interactive, axis: .vertical) { content, phase in
                            let v: Double = abs(phase.value) * strength
                            let scale: CGFloat = style == 0 ? 1 - CGFloat(v) * 0.15 : 1
                            let blur: CGFloat = style == 1 ? CGFloat(v) * 10 : 0
                            let fold: Double = style == 2 ? phase.value * 60 * strength : 0
                            return content
                                .opacity(1 - v * 0.8)
                                .scaleEffect(scale)
                                .blur(radius: blur)
                                .rotation3DEffect(.degrees(fold), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .scrollIndicators(.hidden)
        .scrollPosition($position)
        .autoplay(ctx.isPreview, every: 2.8) {
            down.toggle()
            withAnimation(.smooth(duration: 2.2)) {
                position.scrollTo(y: down ? 620 : 0)
            }
        }
    }
}
