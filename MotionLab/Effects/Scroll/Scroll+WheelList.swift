import SwiftUI

extension Effect {
    static let scrollWheelList = Effect(
        id: "scroll.wheel-list",
        category: .scroll,
        interaction: .scroll,
        name: L("Wheel Picker List", "滚轮列表"),
        summary: L("A drum-style list: rows curve away in 3D around a snapping center selection.", "滚筒式列表：各行绕着吸附的中心选中项向后弯曲成三维滚轮。"),
        prompt: L(
            "A vertical list of city names (44 pt rows, 22 pt rounded type) is shaped into a rotating drum. The row at the center sits flat, bold and fully opaque inside a subtle rounded selection band; rows further from the center tilt back around the horizontal axis up to ~60° in perspective, shrink by up to 12% and fade toward 25% opacity, so the list reads like the surface of a cylinder. Scrolling snaps one row precisely into the band, each change of selection ticks a selection haptic, and the label above updates to the chosen city. Tapping a row scrolls it into the band. Precise, mechanical and tactile, like the iOS time picker.",
            "一列城市名称（行高 44 pt，22 pt 圆体字）被塑造成可转动的滚筒。位于中心的一行平正、加粗、完全不透明，落在一条含蓄的圆角选中带内；越远离中心的行绕水平轴以透视向后倾斜，最多约 60°，同时最多缩小 12% 并淡出到约 25% 透明度，整列看起来就像圆柱表面。滚动时总有一行精确吸附到选中带中，每次切换选中项都伴随选择触感，上方标签随之更新为所选城市。点击某行会将其滚入选中带。精准、机械、富有触感，就像 iOS 的时间选择器。"
        ),
        implementation: L(
            "Each row's visualEffect maps its distance from the fixed viewport center to rotation3DEffect, scale and opacity; spacer padding centers the first and last rows, a custom ScrollTargetBehavior snaps the offset to whole rows, onScrollGeometryChange derives the selection and ScrollPosition drives programmatic scrolls, with sensoryFeedback(.selection).",
            "每行的 visualEffect 将其到固定视口中心的距离映射为 rotation3DEffect、缩放与透明度；上下留白让首尾行也能居中，自定义 ScrollTargetBehavior 将偏移吸附到整行，onScrollGeometryChange 推算选中项，ScrollPosition 负责程序化滚动，并通过 sensoryFeedback(.selection) 提供触感。"
        ),
        apis: ["visualEffect", "rotation3DEffect", "ScrollTargetBehavior", "onScrollGeometryChange", "ScrollPosition", "sensoryFeedback"],
        tags: ["wheel", "picker", "drum", "3D list", "滚轮", "选择器", "滚筒", "三维列表"],
        params: [
            .slider("curve", L("Curvature", "弯曲度"), 0...80, default: 60, step: 1, decimals: 0, unit: "°"),
            .slider("fade", L("Edge fade", "边缘淡出"), 0...1, default: 0.75),
        ]
    ) { ctx in
        ScrollWheelDemo(ctx: ctx)
    }
}

private let scrollWheelCities: [LocalizedText] = [
    L("Tokyo", "东京"), L("Paris", "巴黎"), L("New York", "纽约"), L("London", "伦敦"),
    L("Shanghai", "上海"), L("Sydney", "悉尼"), L("Berlin", "柏林"), L("Seoul", "首尔"),
    L("Reykjavík", "雷克雅未克"), L("Lisbon", "里斯本"), L("Cairo", "开罗"), L("Toronto", "多伦多"),
    L("Dubai", "迪拜"), L("Rome", "罗马"),
]

/// Snaps the resting offset to a whole row, so one row always lands in the band.
private struct ScrollWheelSnap: ScrollTargetBehavior {
    let rowHeight: CGFloat

    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        target.rect.origin.y = (target.rect.minY / rowHeight).rounded() * rowHeight
    }
}

private let scrollWheelInitialIndex = 4

private struct ScrollWheelDemo: View {
    let ctx: DemoContext
    @State private var current = scrollWheelInitialIndex
    @State private var position = ScrollPosition(edge: .top)
    @State private var direction = 1

    private let rowHeight: CGFloat = 44
    private let viewport: CGFloat = 264

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "airplane.departure")
                    .foregroundStyle(Palette.primary)
                Text(scrollWheelCities[current], ctx.language)
                    .contentTransition(.interpolate)
                    .animation(.snappy, value: current)
            }
            .font(.subheadline.weight(.semibold))
            wheel
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sensoryFeedback(.selection, trigger: current) { _, _ in !ctx.isPreview }
        .autoplay(ctx.isPreview, every: 1.3) { advance() }
    }

    // Plain spacer padding (instead of contentMargins) keeps the scroll offset,
    // the `.scrollView` coordinate space and the snapping all in one frame of
    // reference: at offset `i * rowHeight`, row `i` sits exactly in the band.
    private var wheel: some View {
        let curve = ctx["curve"]
        let fade = ctx["fade"]
        let height = viewport
        let pad = (viewport - rowHeight) / 2
        let count = scrollWheelCities.count
        let row = rowHeight
        return ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(scrollWheelCities.indices, id: \.self) { i in
                    let weight: Font.Weight = current == i ? .semibold : .regular
                    Text(scrollWheelCities[i], ctx.language)
                        .font(.system(size: 22, weight: weight, design: .rounded))
                        .foregroundStyle(current == i ? Color.primary : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: rowHeight)
                        .contentShape(Rectangle())
                        .visualEffect { content, proxy in
                            let mid = proxy.frame(in: .scrollView).midY
                            let t = ((mid - height / 2) / (height / 2)).clamped(to: -1...1)
                            return content
                                .rotation3DEffect(.degrees(-Double(t) * curve), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
                                .scaleEffect(1 - abs(t) * 0.12)
                                .opacity(1 - Double(abs(t)) * fade)
                        }
                        .onTapGesture { select(i) }
                }
            }
            .padding(.vertical, pad)
        }
        .scrollTargetBehavior(ScrollWheelSnap(rowHeight: rowHeight))
        .scrollPosition($position)
        .onScrollGeometryChange(for: Int.self, of: { geometry in
            let offset = geometry.contentOffset.y + geometry.contentInsets.top
            return Int((offset / row).rounded()).clamped(to: 0...(count - 1))
        }, action: { _, newValue in
            current = newValue
        })
        .onAppear { position.scrollTo(y: CGFloat(scrollWheelInitialIndex) * rowHeight) }
        .scrollIndicators(.hidden)
        .frame(height: viewport)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Palette.stroke))
                .frame(height: rowHeight)
                .padding(.horizontal, 28)
        }
    }

    private func select(_ i: Int) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            position.scrollTo(y: CGFloat(i) * rowHeight)
        }
    }

    private func advance() {
        let count = scrollWheelCities.count
        let stepSize = 2
        if current + direction * stepSize >= count || current + direction * stepSize < 0 { direction = -direction }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.86)) {
            position.scrollTo(y: CGFloat(current + direction * stepSize) * rowHeight)
        }
    }
}
