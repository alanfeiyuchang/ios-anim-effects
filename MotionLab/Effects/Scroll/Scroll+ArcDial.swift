import SwiftUI

extension Effect {
    static let scrollArcDial = Effect(
        id: "scroll.arc-dial",
        category: .scroll,
        interaction: .scroll,
        name: L("Arc Dial Picker", "弧形转盘选择器"),
        summary: L("A camera-style filter dial whose items ride a curved arc and snap into a fixed ring.", "相机滤镜式转盘：选项沿弧线滚动，吸附进固定的选择环。"),
        prompt: L(
            "A horizontal row of 64 pt circular filter swatches is bent onto a large invisible wheel below the stage: as they scroll, each item is placed on the arc by its distance from centre — rotated ~15° per step, dropping and tilting away, scaling down ~10% per step and fading out linearly between two and three steps from centre. A fixed hairline ring marks the centre; the item under it grows to 112% and snaps in with a firm deceleration, a selection tick and a crisp label cross-fade. The preview panel above cross-fades its gradient to the selected filter on a soft spring. Tactile and dial-like, as if turning a physical lens ring.",
            "一排 64 pt 的圆形滤镜色块被“弯”到舞台下方一个看不见的大转轮上：滚动时，每个选项依据与中心的距离被放置到弧线上——每隔一格旋转约 15°、向下沉并向外倾斜、缩小约 10%，并在距中心两格到三格之间线性淡出。中心有一道固定的细线选择环；落入环中的选项放大到 112%，以干脆的减速吸附到位，并伴随一次选择触感与标签的清晰淡入淡出。上方预览面板的渐变以柔和弹簧过渡到所选滤镜。像拧动真实镜头环一样富有手感。"
        ),
        implementation: L(
            "Spacer-padded LazyHStack with a custom ScrollTargetBehavior that snaps to whole items; each item's visualEffect converts its offset from centre into an angle on a circle and applies the matching offset, rotation and scale; onScrollGeometryChange derives the selection.",
            "LazyHStack 两侧用留白居中，自定义 ScrollTargetBehavior 按整格吸附；每个选项的 visualEffect 把到中心的距离换算为圆周上的角度，施加对应的位移、旋转与缩放；onScrollGeometryChange 推算当前选中项。"
        ),
        apis: ["visualEffect", "ScrollTargetBehavior", "onScrollGeometryChange", "ScrollPosition", "sensoryFeedback"],
        tags: ["dial", "arc", "picker", "carousel", "camera filter", "转盘", "弧形", "选择器", "滤镜"],
        params: [
            .slider("curve", L("Arc per step", "每格弧度"), 0...24, default: 15, step: 1, decimals: 0, unit: "°"),
            .slider("focus", L("Centre scale", "中心放大"), 1...1.3, default: 1.12),
            .toggle("tilt", L("Tilt along arc", "沿弧线倾斜"), default: true),
        ]
    ) { ctx in
        ScrollArcDialDemo(ctx: ctx)
    }
}

private struct ScrollArcFilter {
    let name: LocalizedText
    let symbol: String
    let colors: [Color]
}

private let scrollArcFilters: [ScrollArcFilter] = [
    ScrollArcFilter(name: L("Vivid", "鲜明"), symbol: "sun.max.fill", colors: [Palette.amber, Palette.coral]),
    ScrollArcFilter(name: L("Warm", "暖调"), symbol: "flame.fill", colors: [Palette.coral, Palette.pink]),
    ScrollArcFilter(name: L("Dream", "梦境"), symbol: "cloud.fill", colors: [Palette.pink, Palette.violet]),
    ScrollArcFilter(name: L("Dusk", "暮色"), symbol: "moon.stars.fill", colors: [Palette.violet, Palette.indigo]),
    ScrollArcFilter(name: L("Cool", "冷调"), symbol: "snowflake", colors: [Palette.sky, Palette.blue]),
    ScrollArcFilter(name: L("Fresh", "清新"), symbol: "leaf.fill", colors: [Palette.mint, Palette.sky]),
    ScrollArcFilter(name: L("Mono", "黑白"), symbol: "circle.lefthalf.filled", colors: [Color(hex: 0x8E93A6), Color(hex: 0x2B2F45)]),
    ScrollArcFilter(name: L("Neon", "霓虹"), symbol: "bolt.fill", colors: [Palette.mint, Palette.violet]),
    ScrollArcFilter(name: L("Film", "胶片"), symbol: "film.fill", colors: [Color(hex: 0xE9C98A), Color(hex: 0x6E4B2A)]),
]

private struct ScrollArcSnap: ScrollTargetBehavior {
    let pitch: CGFloat

    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        target.rect.origin.x = (target.rect.minX / pitch).rounded() * pitch
    }
}

private let scrollArcInitialIndex = 3

private struct ScrollArcDialDemo: View {
    let ctx: DemoContext
    @State private var current = scrollArcInitialIndex
    @State private var position = ScrollPosition(edge: .leading)
    @State private var width: CGFloat = 340
    @State private var direction = 1

    private let side: CGFloat = 64
    private let spacing: CGFloat = 18
    private var pitch: CGFloat { side + spacing }

    var body: some View {
        let filter = scrollArcFilters[current]
        VStack(spacing: 14) {
            ScrollArcPreview(filter: filter, language: ctx.language)
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: current)
            ZStack {
                Circle()
                    .strokeBorder(Color.primary.opacity(0.35), lineWidth: 1.5)
                    .frame(width: side * ctx.cg("focus") + 12, height: side * ctx.cg("focus") + 12)
                    .offset(y: -12)
                dial
            }
            Text(filter.name, ctx.language)
                .font(.subheadline.weight(.semibold))
                .contentTransition(.interpolate)
                .animation(.snappy, value: current)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sensoryFeedback(.selection, trigger: current) { _, _ in !ctx.isPreview }
        .autoplay(ctx.isPreview, every: 1.2) { advance() }
    }

    private var dial: some View {
        let pitch = self.pitch
        let viewport = max(width, 1)
        let step = ctx["curve"] * .pi / 180
        // Radius chosen so neighbouring items keep their spacing along the arc.
        let radius: CGFloat = step > 0.001 ? pitch / CGFloat(sin(step)) : 0
        let focus = ctx.cg("focus")
        let tilt = ctx.bool("tilt")
        let count = scrollArcFilters.count
        return ScrollView(.horizontal) {
            LazyHStack(spacing: spacing) {
                ForEach(0..<count, id: \.self) { i in
                    ScrollArcSwatch(filter: scrollArcFilters[i], side: side)
                        .visualEffect { content, proxy in
                            let t = (proxy.frame(in: .scrollView).midX - viewport / 2) / pitch
                            let angle = Double(t) * step
                            let arcX = radius > 0 ? radius * CGFloat(sin(angle)) - t * pitch : 0
                            let arcY = radius > 0 ? radius * CGFloat(1 - cos(angle)) : 0
                            let near = max(1 - abs(t), 0)
                            return content
                                .scaleEffect((1 - min(abs(t), 3) * 0.1) + (focus - 1) * near)
                                .rotationEffect(.radians(tilt ? angle : 0))
                                .offset(x: arcX, y: arcY - 12)
                                .opacity(1 - Double(max(abs(t) - 2, 0)).clamped(to: 0...1))
                        }
                        .onTapGesture { select(i) }
                }
            }
            .padding(.horizontal, max((width - side) / 2, 0))
            .frame(height: 132)
        }
        .scrollTargetBehavior(ScrollArcSnap(pitch: pitch))
        .scrollPosition($position)
        .onScrollGeometryChange(for: Int.self, of: { geometry in
            let offset = geometry.contentOffset.x + geometry.contentInsets.leading
            return Int((offset / pitch).rounded()).clamped(to: 0...(count - 1))
        }, action: { _, newValue in
            current = newValue
        })
        .onAppear { position.scrollTo(x: CGFloat(scrollArcInitialIndex) * pitch) }
        .scrollIndicators(.hidden)
        .frame(height: 132)
        .onGeometryChange(for: CGFloat.self, of: { proxy in proxy.size.width }, action: { newWidth in
            width = newWidth
        })
    }

    private func select(_ i: Int) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
            position.scrollTo(x: CGFloat(i) * pitch)
        }
    }

    private func advance() {
        let count = scrollArcFilters.count
        if current + direction >= count || current + direction < 0 { direction = -direction }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
            position.scrollTo(x: CGFloat(current + direction) * pitch)
        }
    }
}

private struct ScrollArcSwatch: View {
    let filter: ScrollArcFilter
    let side: CGFloat

    var body: some View {
        Image(systemName: filter.symbol)
            .font(.system(size: side * 0.36, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: side, height: side)
            .background(
                LinearGradient(colors: filter.colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                in: Circle()
            )
            .overlay(Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 1))
            .shadow(color: .black.opacity(0.14), radius: 8, y: 4)
    }
}

/// The "viewfinder" above the dial, tinted by the selected filter.
private struct ScrollArcPreview: View {
    let filter: ScrollArcFilter
    let language: AppLanguage

    var body: some View {
        LinearGradient(colors: filter.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay(alignment: .bottomLeading) {
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white.opacity(0.3))
                    .offset(x: 16, y: 10)
            }
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(.white.opacity(0.5))
                    .frame(width: 26, height: 26)
                    .blur(radius: 2)
                    .padding(18)
            }
            .overlay(alignment: .topLeading) {
                Label {
                    Text(filter.name, language)
                } icon: {
                    Image(systemName: "camera.filters")
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.black.opacity(0.18), in: Capsule())
                .padding(12)
            }
            .frame(width: 280, height: 118)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: filter.colors[0].opacity(0.3), radius: 16, y: 8)
    }
}
