import SwiftUI

extension Effect {
    static let scrollStretchyHeader = Effect(
        id: "scroll.stretchy-header",
        category: .scroll,
        interaction: .scroll,
        name: L("Stretchy Parallax Header", "弹性视差头图"),
        summary: L("A hero header that zooms when pulled down and drifts behind the content when scrolled.", "下拉时放大拉伸、上滑时在内容后方视差漂移的头图。"),
        prompt: L(
            "A scrolling detail page opens with a 190 pt hero header — a softly animated mesh gradient in indigo, violet, coral and mint with a white title — and a content sheet with 24 pt rounded top corners overlapping it from below. Pulling down past the top anchors the header to the top edge and scales it up from its bottom edge, so it stretches to fill the overscroll gap and snaps back with the scroll view's native rubber-band. Scrolling up moves the header at only ~50% of the scroll speed so the sheet glides over it, while the header progressively blurs up to 8 pt. Everything is driven frame-by-frame by scroll geometry, so it feels glued to the finger — rich, immersive and premium.",
            "滚动详情页顶部是一张 190 pt 的头图——靛蓝、紫、珊瑚与薄荷色的柔和网格渐变，配白色标题——下方内容面板以 24 pt 圆角顶边压在头图之上。越过顶部继续下拉时，头图固定在顶边并以底边为锚点放大，拉伸填满回弹空隙，松手后随滚动视图原生的橡皮筋效果回弹。向上滚动时头图仅以约 50% 的速度移动，内容面板从其上方滑过，同时头图逐渐模糊到 8 pt。全部效果由滚动几何逐帧驱动，仿佛黏在手指上——饱满、沉浸且高级。"
        ),
        implementation: L(
            "The header's visualEffect reads its minY in the .scrollView space: positive values scale it from the bottom anchor, negative values offset it by a parallax factor and blur it; the sheet sits above with a higher zIndex.",
            "头图的 visualEffect 读取其在 .scrollView 坐标空间中的 minY：为正时以底部为锚点放大，为负时按视差系数偏移并模糊；内容面板以更高 zIndex 盖在其上。"
        ),
        apis: ["visualEffect", "MeshGradient", "UnevenRoundedRectangle", "ScrollPosition", "zIndex"],
        tags: ["stretchy header", "parallax", "hero", "overscroll", "弹性头图", "视差", "下拉放大", "吸顶"],
        params: [
            .slider("parallax", L("Parallax factor", "视差系数"), 0...0.9, default: 0.5),
            .toggle("blur", L("Blur on scroll", "滚动模糊"), default: true),
        ]
    ) { ctx in
        ScrollStretchyDemo(ctx: ctx)
    }
}

private struct ScrollStretchyDemo: View {
    let ctx: DemoContext
    @State private var position = ScrollPosition(edge: .top)
    /// Simulated overscroll used only by the auto-playing preview.
    @State private var pull: CGFloat = 0
    @State private var step = 0

    private let headerHeight: CGFloat = 190

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .zIndex(0)
                sheet
                    .zIndex(1)
            }
            .padding(.top, pull)
        }
        .scrollIndicators(.hidden)
        .scrollPosition($position)
        .autoplay(ctx.isPreview, every: 1.5) { advance() }
    }

    private var header: some View {
        let height = headerHeight
        let parallax = ctx.cg("parallax")
        let blurs = ctx.bool("blur")
        return ScrollStretchyArtwork(language: ctx.language)
            .frame(height: height)
            .visualEffect { content, proxy in
                let minY = proxy.frame(in: .scrollView).minY
                let stretch = max(minY, 0)
                let scrolled = max(-minY, 0)
                return content
                    .scaleEffect(1 + stretch / height, anchor: .bottom)
                    .offset(y: scrolled * parallax)
                    .blur(radius: blurs ? min(scrolled / 14, 8) : 0)
            }
    }

    private var sheet: some View {
        VStack(spacing: 10) {
            Capsule()
                .fill(Color.primary.opacity(0.15))
                .frame(width: 36, height: 5)
                .padding(.bottom, 4)
            ForEach(0..<10, id: \.self) { i in
                ScrollKitRow(index: i + 3, language: ctx.language)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 24)
        .background(
            Palette.surface,
            in: UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24, style: .continuous)
        )
        .padding(.top, -24)
    }

    private func advance() {
        switch step % 4 {
        case 0:
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) { pull = 80 }
        case 1:
            withAnimation(.spring(response: 0.55, dampingFraction: 0.62)) { pull = 0 }
        case 2:
            withAnimation(.smooth(duration: 1.2)) { position.scrollTo(y: 170) }
        default:
            withAnimation(.smooth(duration: 1.2)) { position.scrollTo(y: 0) }
        }
        step += 1
    }
}

private struct ScrollStretchyArtwork: View {
    let language: AppLanguage

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let cx = Float(0.5 + 0.12 * sin(t * 0.7))
            let cy = Float(0.45 + 0.1 * cos(t * 0.9))
            let points: [SIMD2<Float>] = [
                SIMD2(0, 0), SIMD2(0.5, 0), SIMD2(1, 0),
                SIMD2(0, 0.5), SIMD2(cx, cy), SIMD2(1, 0.5),
                SIMD2(0, 1), SIMD2(0.5, 1), SIMD2(1, 1),
            ]
            MeshGradient(
                width: 3,
                height: 3,
                points: points,
                colors: [
                    Palette.indigo, Palette.violet, Palette.pink,
                    Palette.sky, Palette.violet, Palette.coral,
                    Palette.mint, Palette.blue, Palette.amber,
                ]
            )
        }
        .overlay(alignment: .topTrailing) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.18))
                .rotationEffect(.degrees(-18))
                .padding(24)
        }
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L("Kyoto in Autumn", "秋日京都"), language)
                    .font(.title2.weight(.bold))
                Text(L("12 places · 4 days", "12 个地点 · 4 天"), language)
                    .font(.footnote.weight(.semibold))
                    .opacity(0.85)
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.2), radius: 8, y: 3)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .clipped()
    }
}
