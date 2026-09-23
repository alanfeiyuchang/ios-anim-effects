import SwiftUI

extension Effect {
    static let scrollWheelList = Effect(
        id: "scroll.wheel-list",
        category: .scroll,
        interaction: .scroll,
        name: L("Wheel Picker List", "滚轮列表"),
        summary: L("A drum-style list: rows curve away in 3D around a snapping center selection.", "滚筒式列表：各行绕着吸附的中心选中项向后弯曲成三维滚轮。"),
        prompt: L(
            "A vertical list of city names in 22 pt rounded type on 44 pt rows is shaped into a rotating drum. The centre row sits flat, bold and opaque inside a subtle rounded selection band, while rows further out tilt back up to 60° in perspective, shrink by up to 12% and fade toward 25% opacity, and the top and bottom 22% dissolve through a gradient mask. Scrolling snaps a whole row into the band with a selection tick per change, and tapping a row springs it there (response 0.45 s, damping 0.85). A time-zone chip above rolls its digits to the city's UTC offset and its local time at noon UTC. Precise and mechanical, like the iOS time picker.",
            "一列城市名（22 pt圆体，行高44 pt）被塑造成可转动的滚筒。正中一行平正、加粗、完全不透明，落在一条含蓄的圆角选中带里；越往外的行绕水平轴以透视向后倾斜，最多60°，同时最多缩小12%、淡到25%不透明度，上下各22%经渐变遮罩融化。滚动总会把一整行吸进选中带，每换一行轻轻一震；点某行则以弹簧（响应0.45秒、阻尼0.85）把它转进来。上方时区胶囊以数字滚动显示该城市的UTC偏移，以及UTC正午时的当地时间。精准而富有机械感，像iOS的时间选择器。"
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

/// Standard-time UTC offsets (hours) for `scrollWheelCities`, shown in the time-zone chip.
private let scrollWheelOffsets: [Int] = [9, 1, -5, 0, 8, 10, 1, 9, 0, 0, 2, -5, 4, 1]

private let scrollWheelInitialIndex = 4

private struct ScrollWheelDemo: View {
    let ctx: DemoContext
    @State private var current = scrollWheelInitialIndex
    @State private var position = ScrollPosition(edge: .top)
    @State private var direction = 1
    /// True while autoplay (or the detail intro) scrolls the wheel, so scripted ticks stay silent.
    @State private var scripted = false

    private let rowHeight: CGFloat = 44
    private let viewport: CGFloat = 264

    var body: some View {
        VStack(spacing: 14) {
            ScrollWheelZoneChip(offset: scrollWheelOffsets[current])
            wheel
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sensoryFeedback(.selection, trigger: current) { _, _ in !ctx.isPreview && !scripted }
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
        .scrollTargetBehavior(ScrollStrideSnap(pitch: rowHeight, axis: .vertical))
        .scrollPosition($position)
        .onScrollGeometryChange(for: Int.self, of: { geometry in
            let offset = geometry.contentOffset.y + geometry.contentInsets.top
            return Int((offset / row).rounded()).clamped(to: 0...(count - 1))
        }, action: { _, newValue in
            current = newValue
        })
        .onScrollPhaseChange { _, newPhase in
            if newPhase == .interacting { scripted = false }
        }
        .onAppear { position.scrollTo(y: CGFloat(scrollWheelInitialIndex) * rowHeight) }
        .scrollIndicators(.hidden)
        .frame(height: viewport)
        .mask {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.22),
                    .init(color: .black, location: 0.78),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Palette.stroke))
                .frame(height: rowHeight)
                .padding(.horizontal, 28)
        }
    }

    private func select(_ i: Int) {
        scripted = false
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            position.scrollTo(y: CGFloat(i) * rowHeight)
        }
    }

    private func advance() {
        let count = scrollWheelCities.count
        let stepSize = 2
        scripted = true
        if current + direction * stepSize >= count || current + direction * stepSize < 0 { direction = -direction }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.86)) {
            position.scrollTo(y: CGFloat(current + direction * stepSize) * rowHeight)
        }
    }
}

/// "UTC+9 · 21:00": the selected city's offset and its local time at 12:00 UTC, rolling with a numeric transition.
private struct ScrollWheelZoneChip: View {
    let offset: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "globe")
                .foregroundStyle(Palette.primary)
            Text(verbatim: offset == 0 ? "UTC±0" : (offset > 0 ? "UTC+\(offset)" : "UTC−\(-offset)"))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(offset)))
            Text(verbatim: "·")
                .foregroundStyle(.tertiary)
            // Local time when it is 12:00 UTC.
            Text(verbatim: String(format: "%02d:00", (12 + offset + 24) % 24))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .contentTransition(.numericText(value: Double(offset)))
        }
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.primary.opacity(0.06), in: Capsule())
        .animation(.snappy, value: offset)
    }
}
