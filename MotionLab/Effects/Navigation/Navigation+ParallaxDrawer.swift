import SwiftUI

extension Effect {
    static let navigationParallaxDrawer = Effect(
        id: "navigation.parallax-drawer",
        category: .navigation,
        interaction: .gesture,
        name: L("Parallax Under-Drawer", "视差底层抽屉"),
        summary: L(
            "The page slides away to uncover a menu underneath that drifts in at a slower speed and rises out of the dark, its rows cascading in.",
            "页面滑开，露出下层菜单：菜单以更慢的速度漂入、从暗处浮起，各行依次滑入。"
        ),
        prompt: L(
            "A phone-sized frame shows a feed page resting on top of a dark navigation layer. Dragging right (or tapping the menu button) slides the page 170 pt to the right, 1:1 with the finger, casting a growing shadow and rounding its corners to 22 pt. Beneath it, a dark teal menu layer doesn't just sit still: it starts 35% of the travel to the left and moves at 35% of the page's speed, while it dollies up from 90% scale (anchored at its leading edge) and brightens out of a 50% black dim, so it rises out of depth rather than turning in 3D. The five menu rows cascade in from −30 pt, each lagging ≈7% of the progress behind the one above, and the same mapping plays in reverse while closing. Release springs to open or closed (response ≈0.45 s) based on the projected end position.",
            "一个手机大小的画框里，信息流页面叠在深色的导航层上。向右拖动（或点击菜单按钮）时，页面随手指 1:1 右移 170pt，投影逐渐加深，圆角增加到 22pt。下层深青色菜单并非静止：它从左侧 35% 行程处出发，以页面 35% 的速度移动形成视差，同时以左缘为锚从 90% 放大到 100%，并从 50% 的暗色中逐渐提亮，像从纵深处浮上来，而不是三维转动。五个菜单行从 −30pt 依次滑入，每一行比上一行落后约 7% 的进度；关闭时按同样的映射反向播放。松手后依据预测终点以弹簧（响应约 0.45 秒）打开或关闭。"
        ),
        implementation: L(
            "One progress value (drag translation ÷ drawer width, rubber-banded beyond the ends) drives everything; the menu is an Animatable view that maps the interpolated progress to its parallax offset, depth scale, dimming and each row's staggered local progress, so the cascade also plays during springs, not only while dragging.",
            "所有效果由同一个进度值驱动（拖拽位移 ÷ 抽屉宽度，超出两端时加橡皮筋阻尼）；菜单是一个 Animatable 视图，把插值中的进度映射为视差位移、纵深缩放、暗度以及每行错峰的局部进度，因此弹簧动画期间同样会出现依次滑入，而不仅仅是拖动时。"
        ),
        apis: ["DragGesture", "Animatable", "predictedEndTranslation", "offset(x:)", "rubberBand"],
        tags: ["drawer", "parallax", "side menu", "stagger", "抽屉", "视差", "侧边菜单", "错峰"],
        params: [
            .slider("parallax", L("Menu parallax", "菜单视差"), 0.0...1.0, default: 0.35),
            .slider("depth", L("Menu start scale", "菜单起始缩放"), 0.8...1.0, default: 0.9),
            .slider("stagger", L("Row stagger", "行错峰"), 0.0...0.15, default: 0.07),
            .slider("response", L("Spring response", "弹簧响应"), 0.25...0.8, default: 0.45, unit: "s"),
        ]
    ) { ctx in
        ParallaxDrawerDemo(ctx: ctx)
    }
}

private let parallaxMenu: [(String, LocalizedText)] = [
    ("house.fill", L("Home", "首页")),
    ("tray.full.fill", L("Inbox", "收件箱")),
    ("star.fill", L("Starred", "星标")),
    ("folder.fill", L("Projects", "项目")),
    ("gearshape.fill", L("Settings", "设置")),
]

private struct ParallaxDrawerDemo: View {
    let ctx: DemoContext
    @State private var progress: CGFloat = 0
    @State private var dragStart: CGFloat?

    private let travel: CGFloat = 170

    var body: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .topLeading) {
                ParallaxMenuLayer(
                    progress: progress,
                    parallax: ctx.cg("parallax"),
                    depth: ctx.cg("depth"),
                    stagger: ctx["stagger"],
                    travel: travel,
                    language: ctx.language
                )
                page
            }
            .frame(width: 250, height: 320)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
            .contentShape(Rectangle())
            .pageSafeHorizontalDrag(onChanged: dragChanged, onEnded: dragEnded)
            DemoHint(text: L("Drag the page right", "向右拖动页面"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.7) { settle(open: progress < 0.5) }
    }

    private var page: some View {
        let p: CGFloat = min(max(progress, 0), 1)
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Button { settle(open: progress < 0.5) } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 36, height: 36)
                        .background(Palette.surface, in: Circle())
                }
                .buttonStyle(.plain)
                Spacer()
                Text(L("Feed", "动态"), ctx.language)
                    .font(.headline)
                Spacer()
                Color.clear.frame(width: 36, height: 36)
            }
            ForEach(0..<3, id: \.self) { index in
                HStack(spacing: 10) {
                    Circle()
                        .fill(Palette.spectrum[index + 2].gradient)
                        .frame(width: 34, height: 34)
                    PlaceholderLines(count: 2)
                }
                .padding(12)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(width: 250, height: 320)
        .background(Palette.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 22 * p + 2, style: .continuous))
        .shadow(color: .black.opacity(0.35 * Double(p)), radius: 20, x: -4, y: 0)
        .offset(x: travel * progress)
    }

    private func dragChanged(_ value: DragGesture.Value) {
        let start = dragStart ?? progress
        if dragStart == nil { dragStart = progress }
        let raw: CGFloat = start + value.translation.width / travel
        if raw > 1 {
            progress = 1 + rubberBand((raw - 1) * travel, limit: 30) / travel
        } else if raw < 0 {
            progress = rubberBand(raw * travel, limit: 16) / travel
        } else {
            progress = raw
        }
    }

    /// Release projects the flick; a system cancellation (`nil`) settles from where the page is.
    private func dragEnded(_ value: DragGesture.Value?) {
        let start = dragStart ?? progress
        dragStart = nil
        let projected: CGFloat = value.map { start + $0.predictedEndTranslation.width / travel } ?? progress
        settle(open: projected > 0.5)
    }

    private func settle(open: Bool) {
        if !ctx.isPreview { Haptics.tap(open ? .medium : .light) }
        withAnimation(.spring(response: ctx["response"], dampingFraction: 0.84)) {
            progress = open ? 1 : 0
        }
    }
}

/// The under-layer. Animatable so the staggered row mapping is evaluated on every spring frame.
private struct ParallaxMenuLayer: View, Animatable {
    var progress: CGFloat
    let parallax: CGFloat
    /// Menu scale when closed; it dollies up to 1 as the page slides away.
    let depth: CGFloat
    let stagger: Double
    let travel: CGFloat
    let language: AppLanguage

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        let p: CGFloat = min(max(progress, 0), 1)
        let layerOffset: CGFloat = -travel * parallax * (1 - p)
        let scale: CGFloat = depth + (1 - depth) * p
        return ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(hex: 0x0F3A3C), Color(hex: 0x071B20)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(Palette.sunset)
                        .frame(width: 38, height: 38)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: "Mia Chen")
                            .font(.subheadline.weight(.bold))
                        Text(L("Designer", "设计师"), language)
                            .font(.caption)
                            .opacity(0.6)
                    }
                }
                .padding(.bottom, 14)
                .opacity(Double(rowProgress(0)))
                ForEach(0..<parallaxMenu.count, id: \.self) { index in
                    row(index)
                }
            }
            .foregroundStyle(.white)
            .padding(.top, 28)
            .padding(.leading, 20)
            .scaleEffect(scale, anchor: .leading)
            .offset(x: layerOffset)
            // Brightens out of the dark as it rises toward the viewer.
            Color.black
                .opacity(0.5 * Double(1 - p))
                .allowsHitTesting(false)
        }
    }

    private func rowProgress(_ index: Int) -> CGFloat {
        let s: Double = min(stagger, 0.15)
        let span: Double = max(1 - s * Double(parallaxMenu.count), 0.2)
        let local: Double = (Double(min(max(progress, 0), 1)) - s * Double(index)) / span
        return CGFloat(min(max(local, 0), 1))
    }

    private func row(_ index: Int) -> some View {
        let local: CGFloat = rowProgress(index + 1)
        return HStack(spacing: 12) {
            Image(systemName: parallaxMenu[index].0)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 22)
            Text(parallaxMenu[index].1, language)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.vertical, 9)
        .opacity(Double(local))
        .offset(x: -30 * (1 - local))
    }
}
