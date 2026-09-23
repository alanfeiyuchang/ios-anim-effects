import SwiftUI

extension Effect {
    static let navigationNumberPager = Effect(
        id: "navigation.number-pager",
        category: .navigation,
        interaction: .gesture,
        name: L("Rolling Page Counter", "滚动页码计数"),
        summary: L(
            "An editorial \"03 / 08\" counter whose digits roll in the swipe direction above a segmented progress track.",
            "杂志风的「03 / 08」页码：数字沿滑动方向滚动，下方是分段进度轨道。"
        ),
        prompt: L(
            "A gallery card with a large tinted image area and, beneath it, an editorial page counter — a big \"03\" beside a small \"/ 08\" — and an eight-segment progress track. Swiping or tapping the arrows pushes the next card in from the direction of travel while the old one recedes to 92% and fades; at the same time the current number rolls like an odometer (digits scroll up when moving forward, down when moving back) and the track's filled capsule grows or shrinks to the new segment on a spring (response ≈0.45 s, damping 0.8). A selection haptic ticks per page. Understated, typographic and precise — navigation told through numbers rather than dots.",
            "一张画廊卡片，上方是大面积的着色图片区，下方是杂志风页码：大号「03」配小号「/ 08」，以及八段式进度轨道。左右滑动或点击箭头时，下一张卡片从运动方向推入，旧卡片缩小到 92% 并淡出；同时当前页码像里程表一样滚动（前进时数字向上滚，后退时向下滚），轨道上的填充胶囊以弹簧（响应约 0.45 秒、阻尼 0.8）伸长或缩短到新的分段。每翻一页触发一次选择触觉。克制、重排版、精确——用数字而不是圆点讲述导航位置。"
        ),
        implementation: L(
            "The counter is a Text with contentTransition(.numericText(countsDown:)) so the roll direction follows the swipe; the card swaps with transition(.push(from:)) and the track fill is a capsule whose width follows the page on a spring.",
            "页码使用 contentTransition(.numericText(countsDown:)) 的 Text，滚动方向随滑动方向变化；卡片用 transition(.push(from:)) 切换，轨道填充是一个宽度随页码弹簧变化的胶囊。"
        ),
        apis: ["contentTransition(.numericText(countsDown:))", "transition(.push(from:))", "DragGesture", "monospacedDigit()"],
        tags: ["page indicator", "counter", "pagination", "odometer", "页码", "计数器", "分页", "滚动数字"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.25...0.8, default: 0.45, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.8),
            .toggle("track", L("Segmented track", "分段轨道"), default: true),
        ]
    ) { ctx in
        NumberPagerDemo(ctx: ctx)
    }
}

private let pagerSymbols: [String] = [
    "mountain.2.fill", "sun.haze.fill", "leaf.fill", "snowflake",
    "water.waves", "tent.fill", "binoculars.fill", "moon.stars.fill",
]
private let pagerColors: [Color] = [
    Palette.indigo, Palette.amber, Palette.green, Palette.sky,
    Palette.blue, Palette.coral, Palette.mint, Palette.violet,
]

private struct NumberPagerDemo: View {
    let ctx: DemoContext
    @State private var page = 0
    @State private var forward = true

    private let count = 8

    var body: some View {
        VStack(spacing: 18) {
            card
            footer
            DemoHint(text: L("Swipe the card or tap the arrows", "左右滑动卡片或点击箭头"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.2) { go(page == count - 1 ? -(count - 1) : 1) }
    }

    private var spring: Animation {
        .spring(response: ctx["response"], dampingFraction: ctx["damping"])
    }

    private var card: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(pagerColors[page].gradient)
                .overlay {
                    Image(systemName: pagerSymbols[page])
                        .font(.system(size: 64, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .id(page)
                // Removal can't follow a direction flipped in the same update, so the old card recedes instead.
                .transition(.asymmetric(
                    insertion: .push(from: forward ? .trailing : .leading),
                    removal: .opacity.combined(with: .scale(scale: 0.92))
                ))
        }
        .frame(width: 270, height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: pagerColors[page].opacity(0.3), radius: 16, y: 8)
        .contentShape(Rectangle())
        .pageSafeHorizontalDrag(minimumDistance: 12, onChanged: { _ in }, onEnded: { value in
            // The card never follows the finger, so a cancelled swipe (`nil`) has nothing to undo.
            guard let value else { return }
            if value.translation.width < -30 { go(1) }
            if value.translation.width > 30 { go(-1) }
        })
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(String(format: "%02d", page + 1))
                    .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                    .contentTransition(.numericText(countsDown: !forward))
                Text(String(format: "/ %02d", count))
                    .font(.system(size: 15, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                arrow("chevron.left", step: -1)
                arrow("chevron.right", step: 1)
            }
            if ctx.bool("track") {
                track
            }
        }
        .frame(width: 270)
    }

    private var track: some View {
        let segment: CGFloat = (270 + 4) / CGFloat(count)
        return ZStack(alignment: .leading) {
            HStack(spacing: 4) {
                ForEach(0..<count, id: \.self) { _ in
                    Capsule().fill(Color.primary.opacity(0.1))
                }
            }
            Capsule()
                .fill(Palette.primary)
                .frame(width: segment * CGFloat(page + 1) - 4)
        }
        .frame(width: 270, height: 4)
    }

    private func arrow(_ symbol: String, step: Int) -> some View {
        let target = page + step
        let enabled = target >= 0 && target < count
        return Button { go(step) } label: {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .frame(width: 38, height: 38)
                .background(Palette.surface, in: Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(enabled ? Color.primary : Color.secondary.opacity(0.5))
        .disabled(!enabled)
    }

    private func go(_ step: Int) {
        let target = page + step
        guard target >= 0, target < count, step != 0 else { return }
        if !ctx.isPreview { Haptics.selection() }
        forward = step > 0
        withAnimation(spring) { page = target }
    }
}
