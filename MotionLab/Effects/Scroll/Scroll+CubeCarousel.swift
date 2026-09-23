import SwiftUI

extension Effect {
    static let scrollCubeCarousel = Effect(
        id: "scroll.cube-carousel",
        category: .scroll,
        interaction: .scroll,
        name: L("Cube Carousel", "立方体轮播"),
        summary: L("Full-width pages sit on the faces of a cube and turn around its edge as you page.", "整页卡片贴在立方体的各个面上，翻页时绕着棱边转动。"),
        prompt: L(
            "A paging carousel of story pages, each a rounded gradient card filling its page, in a pager inset 20 pt from the stage edges. Instead of sliding flat, each page rotates like a face of a cube: the outgoing page hinges on its trailing edge and turns away up to 90°, while the incoming page hinges on its leading edge and turns in from −90°, both in perspective, so the pair shares one hinge and always reads as two sides of one rotating block. Faces darken by up to 40% as they turn away from the viewer. Paging snaps to whole pages with the system paging curve, and a capsule page indicator below springs to the active page (response 0.4 s, damping 0.7). Bold, spatial and playful, like Instagram Stories.",
            "故事页分页轮播，每页是一张铺满页面的圆角渐变卡片，整个分页器距舞台两侧各 20 pt。页面不是平移，而是像立方体的一个面那样旋转：离开的页面以右侧棱边为轴向后转动至多 90°，进入的页面以左侧棱边为轴从 −90° 转入，两者都带透视，因此看起来总是同一个旋转方块的两个面。转离观者的面最多变暗 40%。翻页以系统分页曲线吸附到整页，下方的胶囊页码指示器以弹簧（响应 0.4 秒、阻尼 0.7）移动到当前页。大胆、有空间感、俏皮，就像 Instagram 的快拍。"
        ),
        implementation: L(
            "Pages use containerRelativeFrame with scrollTargetBehavior(.paging); each page's visualEffect converts its minX into a page progress and applies rotation3DEffect anchored at the trailing edge when leaving and the leading edge when arriving.",
            "页面使用 containerRelativeFrame 与 scrollTargetBehavior(.paging)；每页的 visualEffect 将其 minX 换算为翻页进度，离开时以右侧棱边为锚点、进入时以左侧棱边为锚点施加 rotation3DEffect。"
        ),
        apis: ["containerRelativeFrame", "scrollTargetBehavior(.paging)", "visualEffect", "rotation3DEffect(_:axis:anchor:perspective:)", "scrollPosition(id:)"],
        tags: ["cube", "carousel", "3D", "stories", "立方体", "轮播", "三维", "快拍"],
        params: [
            .slider("angle", L("Face angle", "侧面角度"), 30...90, default: 90, step: 1, decimals: 0, unit: "°"),
            .slider("perspective", L("Perspective", "透视强度"), 0.2...1.0, default: 0.5),
            .slider("shade", L("Face shade", "侧面阴影"), 0...0.8, default: 0.4),
        ]
    ) { ctx in
        ScrollCubeDemo(ctx: ctx)
    }
}

private struct ScrollCubeDemo: View {
    let ctx: DemoContext
    @State private var page: Int? = 0
    @State private var direction = 1

    private let count = 6

    var body: some View {
        VStack(spacing: 16) {
            pager
            ScrollCubeDots(count: count, current: page ?? 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.6) { advance() }
    }

    private var pager: some View {
        let maxAngle = ctx["angle"]
        let perspective = ctx.cg("perspective")
        let shade = ctx["shade"]
        return ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(0..<count, id: \.self) { i in
                    // The face fills its page, so neighbouring faces share the page boundary as their hinge.
                    ScrollCubeFace(index: i, language: ctx.language, shade: shade)
                        .containerRelativeFrame(.horizontal)
                        .visualEffect { content, proxy in
                            let width: CGFloat = max(proxy.size.width, 1)
                            let t: CGFloat = (proxy.frame(in: .scrollView).minX / width).clamped(to: -1...1)
                            let angle: Double = Double(t) * maxAngle
                            let anchor: UnitPoint = t < 0 ? .trailing : .leading
                            return content
                                .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), anchor: anchor, perspective: perspective)
                        }
                        .id(i)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $page)
        .scrollIndicators(.hidden)
        .frame(height: 260)
        // The inset sits outside the pager, not inside each face, so the cube's edges meet.
        .padding(.horizontal, 20)
    }

    private func advance() {
        let now = page ?? 0
        if now + direction >= count || now + direction < 0 { direction = -direction }
        withAnimation(.smooth(duration: 0.8)) {
            page = now + direction
        }
    }
}

/// A story page; its shade overlay darkens with the page's distance from the center.
private struct ScrollCubeFace: View {
    let index: Int
    let language: AppLanguage
    let shade: Double

    var body: some View {
        ScrollKitArt(index: index + 3, language: language)
            .overlay {
                Color.black
                    .visualEffect { content, proxy in
                        let width: CGFloat = max(proxy.size.width, 1)
                        let t: Double = Double(abs(proxy.frame(in: .scrollView).minX) / width)
                        return content.opacity(min(t, 1) * shade)
                    }
                    .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

private struct ScrollCubeDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == current ? AnyShapeStyle(Palette.primary) : AnyShapeStyle(Color.primary.opacity(0.18)))
                    .frame(width: i == current ? 22 : 7, height: 7)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: current)
    }
}
