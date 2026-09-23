import SwiftUI

extension Effect {
    static let navigationScrollingDots = Effect(
        id: "navigation.scrolling-dots",
        category: .navigation,
        interaction: .gesture,
        name: L("Scrolling Page Dots", "滚动窗口页码点"),
        summary: L(
            "Twelve pages, five visible dots: the dot strip scrolls with you and the edge dots shrink to hint at more.",
            "十二页只显示五个圆点：圆点条随翻页滚动，边缘圆点缩小，暗示还有更多。"
        ),
        prompt: L(
            "A paging carousel of twelve 220 pt photo cards with a dot indicator that never shows more than five dots. The dot window keeps the current dot away from the edges: as you page past the middle, the whole strip slides by one 14 pt step on a spring (response ≈0.45 s, damping 0.8). Dots at the window's edges shrink to 55% when more pages lie beyond them, dots outside fade to nothing at 30% scale, and the active dot grows to 125% in the accent colour. The cards follow the finger 1:1 and settle to the nearest page using the drag's predicted end, with a selection tick per page. The same pattern Instagram and Photos use for long carousels — compact yet honest about length.",
            "一个由十二张 220pt 照片卡片组成的分页轮播，页码指示器最多只显示五个圆点。圆点窗口会让当前圆点远离边缘：翻过中间后，整条圆点以弹簧（响应约 0.45 秒、阻尼 0.8）滑动一个 14pt 的步长。当窗口外仍有页面时，边缘圆点缩小到 55%；窗口外的圆点缩到 30% 并完全淡出；当前圆点放大到 125% 并使用强调色。卡片 1:1 跟手，松手后依据拖拽预测终点吸附到最近一页，每翻一页触发一次选择触觉。与 Instagram 和照片 App 的长轮播相同的模式——紧凑，又如实地告诉你内容有多长。"
        ),
        implementation: L(
            "The dot strip is an HStack offset by the window start inside a clipped frame the width of the visible dots; each dot's scale and opacity derive from its position relative to that window. The carousel is an HStack offset by page and live drag translation.",
            "圆点条是一个 HStack，放在宽度等于可见圆点数的裁切框内，按窗口起点偏移；每个圆点的缩放与透明度由它相对窗口的位置决定。轮播是一个按页码与实时拖拽位移偏移的 HStack。"
        ),
        apis: ["DragGesture", "predictedEndTranslation", "offset(x:)", "clipped()", "spring(response:dampingFraction:)"],
        tags: ["page dots", "carousel", "pagination", "overflow", "页码圆点", "轮播", "分页", "溢出"],
        params: [
            .slider("visible", L("Visible dots", "可见圆点"), 3...7, default: 5, step: 2, decimals: 0),
            .slider("response", L("Spring response", "弹簧响应"), 0.25...0.8, default: 0.45, unit: "s"),
            .toggle("shrink", L("Shrink edge dots", "边缘圆点缩小"), default: true),
        ]
    ) { ctx in
        ScrollingDotsDemo(ctx: ctx)
    }
}

private struct ScrollingDotsDemo: View {
    let ctx: DemoContext
    @State private var page = 0
    @State private var drag: CGFloat = 0
    @State private var autoForward = true

    private let count = 12
    private let cardWidth: CGFloat = 220
    private let gap: CGFloat = 14
    private let dotStep: CGFloat = 14

    private var visible: Int {
        let raw = min(max(ctx.int("visible"), 3), 7)
        return raw % 2 == 0 ? raw + 1 : raw
    }

    private var windowStart: Int {
        let half = visible / 2
        return min(max(page - half, 0), max(count - visible, 0))
    }

    private var spring: Animation {
        .spring(response: ctx["response"], dampingFraction: 0.8)
    }

    var body: some View {
        VStack(spacing: 22) {
            carousel
            dots
            DemoHint(text: L("Swipe the cards", "左右滑动卡片"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 0.9) {
            if page == count - 1 { autoForward = false }
            if page == 0 { autoForward = true }
            go(to: page + (autoForward ? 1 : -1))
        }
    }

    private var carousel: some View {
        let pitch: CGFloat = cardWidth + gap
        let offset: CGFloat = -CGFloat(page) * pitch + drag
        return HStack(spacing: gap) {
            ForEach(0..<count, id: \.self) { index in
                card(index)
            }
        }
        .offset(x: offset + (CGFloat(count - 1) * pitch) / 2)
        .frame(width: 300, height: 190)
        .clipped()
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 8)
                .onChanged { value in
                    let raw: CGFloat = value.translation.width
                    let atStart: Bool = page == 0 && raw > 0
                    let atEnd: Bool = page == count - 1 && raw < 0
                    drag = (atStart || atEnd) ? rubberBand(raw, limit: 60) : raw
                }
                .onEnded { value in
                    let predicted: CGFloat = value.predictedEndTranslation.width
                    let pages: Int = Int((-predicted / pitch).rounded())
                    let step: Int = min(max(pages, -2), 2)
                    go(to: page + step)
                }
        )
    }

    private func card(_ index: Int) -> some View {
        let color = Palette.spectrum[index % Palette.spectrum.count]
        return RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(LinearGradient(colors: [color, color.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(alignment: .bottomLeading) {
                Text(String(format: "%02d", index + 1))
                    .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                    .padding(18)
            }
            .frame(width: cardWidth, height: 170)
            .scaleEffect(index == page ? 1 : 0.92)
            .animation(spring, value: page)
    }

    private var dots: some View {
        let windowWidth: CGFloat = CGFloat(visible) * dotStep
        let stripOffset: CGFloat = -CGFloat(windowStart) * dotStep
        return HStack(spacing: 0) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index == page ? AnyShapeStyle(Palette.primary) : AnyShapeStyle(Color.primary.opacity(0.25)))
                    .frame(width: 7, height: 7)
                    .scaleEffect(dotScale(index))
                    .opacity(dotOpacity(index))
                    .frame(width: dotStep, height: 14)
            }
        }
        .offset(x: stripOffset)
        .frame(width: windowWidth, height: 14, alignment: .leading)
        .clipped()
        .animation(spring, value: page)
    }

    private func dotScale(_ index: Int) -> CGFloat {
        if index == page { return 1.25 }
        let first = windowStart
        let last = windowStart + visible - 1
        if index < first || index > last { return 0.3 }
        guard ctx.bool("shrink") else { return 1 }
        if index == first && first > 0 { return 0.55 }
        if index == last && last < count - 1 { return 0.55 }
        return 1
    }

    private func dotOpacity(_ index: Int) -> Double {
        let first = windowStart
        let last = windowStart + visible - 1
        return (index < first || index > last) ? 0 : 1
    }

    private func go(to target: Int) {
        let clamped = min(max(target, 0), count - 1)
        if clamped != page && !ctx.isPreview { Haptics.selection() }
        withAnimation(spring) {
            page = clamped
            drag = 0
        }
    }
}
