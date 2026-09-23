import SwiftUI

extension Effect {
    static let scrollCoverFlow = Effect(
        id: "scroll.cover-flow",
        category: .scroll,
        interaction: .scroll,
        name: L("Cover Flow", "封面流"),
        summary: L("A 3D album carousel: side covers swing away in perspective, with glossy reflections.", "3D 专辑轮播：两侧封面以透视向后旋开，并带光泽倒影。"),
        prompt: L(
            "A horizontal carousel of square album covers (150 pt, 14 pt corners) with a glossy floor reflection beneath each — a mirrored copy that starts at ~60% strength and fades out within 56 pt. The cover at the center faces the viewer flat and full-size; as covers move away from the center they rotate around their vertical axis up to ~55° in strong perspective, shrink by up to 15% and dim slightly, turning their faces toward the middle like a record crate. The rotation is a continuous function of each cover's distance from the viewport center, so it scrubs perfectly with the finger. The scroll snaps so that one cover always settles dead center, and the title beneath cross-fades to match. Nostalgic, tactile and luxurious.",
            "一排方形专辑封面（150 pt，14 pt 圆角）横向排列，每张下方都有光泽地面倒影——镜像副本从约 60% 强度开始，在 56 pt 内渐隐。位于中心的封面正对观者、保持原始尺寸；越远离中心的封面绕竖直轴以强透视旋转，最多约 55°，同时最多缩小 15% 并略微变暗，封面朝向中间，就像翻看唱片架。旋转是封面到视口中心距离的连续函数，因此完全跟随手指滑动。滚动会吸附，使总有一张封面稳稳停在正中央，下方标题随之淡入切换。怀旧、可触、充满质感。"
        ),
        implementation: L(
            "Each cover's visualEffect reads its frame in the .scrollView coordinate space and maps its normalised distance from the center to rotation3DEffect and scale; a custom ScrollTargetBehavior snaps the offset to whole covers, and onScrollGeometryChange derives the centered cover.",
            "每张封面的 visualEffect 读取自身在 .scrollView 坐标空间中的位置，将其到中心的归一化距离映射为 rotation3DEffect 与缩放；自定义 ScrollTargetBehavior 将偏移吸附到整张封面，onScrollGeometryChange 推算居中项。"
        ),
        apis: ["visualEffect", "rotation3DEffect", "ScrollTargetBehavior", "ScrollPosition", "onScrollGeometryChange"],
        tags: ["cover flow", "carousel", "3D", "album", "封面流", "轮播", "三维", "专辑"],
        params: [
            .slider("angle", L("Side angle", "侧边角度"), 20...75, default: 55, step: 1, decimals: 0, unit: "°"),
            .slider("spacing", L("Spacing", "间距"), -40...20, default: -10, step: 1, decimals: 0, unit: "pt"),
            .toggle("reflection", L("Reflection", "倒影"), default: true),
            .slider("perspective", L("Perspective", "透视强度"), 0.1...1.0, default: 0.5),
        ]
    ) { ctx in
        ScrollCoverFlowDemo(ctx: ctx)
    }
}

/// Snaps the resting offset to a whole cover, so one cover always rests in the center.
private struct ScrollCoverSnap: ScrollTargetBehavior {
    let stride: CGFloat

    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        target.rect.origin.x = (target.rect.minX / stride).rounded() * stride
    }
}

private let scrollCoverInitialIndex = 3

private struct ScrollCoverFlowDemo: View {
    let ctx: DemoContext
    @State private var current = scrollCoverInitialIndex
    @State private var position = ScrollPosition(edge: .leading)
    @State private var width: CGFloat = 340
    @State private var direction = 1

    private let count = 10
    private let side: CGFloat = 150

    /// Distance between neighbouring cover centers.
    private var stride: CGFloat { max(side + ctx.cg("spacing"), 1) }

    var body: some View {
        VStack(spacing: 10) {
            carousel
            Text(ScrollKit.title(current), ctx.language)
                .font(.headline)
                .contentTransition(.interpolate)
                .animation(.snappy, value: current)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.4) { advance() }
    }

    // Plain spacer padding (instead of contentMargins) keeps the scroll offset,
    // the `.scrollView` coordinate space and the snapping in one frame of
    // reference: at offset `i * stride`, cover `i` is exactly centered.
    private var carousel: some View {
        let angle = ctx["angle"]
        let perspective = CGFloat(ctx["perspective"])
        let viewport = max(width, 1)
        let reflection = ctx.bool("reflection")
        let stride = self.stride
        let count = self.count
        return ScrollView(.horizontal) {
            LazyHStack(spacing: ctx.cg("spacing")) {
                ForEach(0..<count, id: \.self) { i in
                    ScrollCoverItem(index: i, language: ctx.language, side: side, reflection: reflection)
                        .visualEffect { content, proxy in
                            let mid = proxy.frame(in: .scrollView).midX
                            let t = ((mid - viewport / 2) / (viewport / 2)).clamped(to: -1...1)
                            return content
                                .rotation3DEffect(.degrees(-Double(t) * angle), axis: (x: 0, y: 1, z: 0), perspective: perspective)
                                .scaleEffect(1 - abs(t) * 0.15)
                                .opacity(1 - Double(abs(t)) * 0.25)
                        }
                        .onTapGesture { select(i) }
                }
            }
            .padding(.horizontal, max((width - side) / 2, 0))
        }
        .scrollTargetBehavior(ScrollCoverSnap(stride: stride))
        .scrollPosition($position)
        .onScrollGeometryChange(for: Int.self, of: { geometry in
            let offset = geometry.contentOffset.x + geometry.contentInsets.leading
            return Int((offset / stride).rounded()).clamped(to: 0...(count - 1))
        }, action: { _, newValue in
            current = newValue
        })
        .onAppear { position.scrollTo(x: CGFloat(scrollCoverInitialIndex) * stride) }
        .scrollIndicators(.hidden)
        .frame(height: side + 72)
        .onGeometryChange(for: CGFloat.self, of: { proxy in proxy.size.width }, action: { newWidth in
            width = newWidth
        })
    }

    private func select(_ i: Int) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
            position.scrollTo(x: CGFloat(i) * stride)
        }
    }

    private func advance() {
        if current + direction >= count || current + direction < 0 { direction = -direction }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.86)) {
            position.scrollTo(x: CGFloat(current + direction) * stride)
        }
    }
}

private struct ScrollCoverItem: View {
    let index: Int
    let language: AppLanguage
    let side: CGFloat
    let reflection: Bool

    var body: some View {
        VStack(spacing: 6) {
            cover
            if reflection {
                // Mirrored cover, cropped to its top 56 pt and faded out towards the floor.
                cover
                    .scaleEffect(x: 1, y: -1)
                    .frame(height: 56, alignment: .top)
                    .clipped()
                    .mask {
                        LinearGradient(
                            stops: [
                                .init(color: .black.opacity(0.6), location: 0),
                                .init(color: .black.opacity(0.22), location: 0.55),
                                .init(color: .clear, location: 1),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
            } else {
                Color.clear.frame(height: 56)
            }
        }
    }

    private var cover: some View {
        ScrollKitArt(index: index, language: language, showsTitle: false)
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.white.opacity(0.2), lineWidth: 1))
    }
}
