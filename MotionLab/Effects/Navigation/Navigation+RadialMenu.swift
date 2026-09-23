import SwiftUI

extension Effect {
    static let navigationRadialMenu = Effect(
        id: "navigation.radial-menu",
        category: .navigation,
        interaction: .gesture,
        name: L("Radial Quick Menu", "径向快捷菜单"),
        summary: L(
            "Actions fan out on an arc; slide your finger to one and release to pick it.",
            "操作项沿弧线扇形展开，手指滑到目标上松开即可选中。"
        ),
        prompt: L(
            "A 60 pt gradient action button sits at the bottom centre. Tapping — or pressing and holding — fans five circular actions out along a 160° arc of ~110 pt radius: each flies from the button's centre, spinning in from –90° and scaling from 30% to 100% on a bouncy spring (response ≈0.42 s, damping ≈0.68), staggered 35 ms left to right, while the plus turns into a × and a scrim dims the page. Without lifting the finger, sliding toward an action magnetically highlights it — it grows to 125% with a coloured glow, its label pops above, and a selection tick fires; releasing on it confirms with a success haptic and the arc collapses back into the button in reverse order, faster.",
            "底部中央是一枚 60pt 的渐变操作按钮。点击或按住时，五个圆形操作项沿半径约 110pt、跨度 160° 的弧线扇形展开：每一项从按钮中心飞出，自 –90° 旋转进入并从 30% 放大到 100%，采用富有弹性的弹簧（响应约 0.42 秒、阻尼约 0.68），从左到右错开 35 毫秒；同时加号转为 ×，页面覆盖一层遮罩。手指不离开屏幕、向某一项滑动时，该项被「磁吸」高亮——放大到 125% 并带有彩色辉光，名称在上方弹出，并触发选择触觉；在其上松手即确认选择，伴随成功触觉，弧形菜单以更快的速度按相反顺序收回按钮。"
        ),
        implementation: L(
            "Items are positioned with trigonometric offsets from the button centre and animate with per-index delayed springs; one DragGesture(minimumDistance: 0) opens the menu, hit-tests the finger against item positions and commits on release.",
            "各项以按钮中心为原点、用三角函数计算偏移，并以逐项延迟的弹簧动画；一个 DragGesture(minimumDistance: 0) 负责展开菜单、将手指与各项位置做命中测试，并在松手时确认。"
        ),
        apis: ["DragGesture", "offset", "rotationEffect", "animation(_:value:)", "UISelectionFeedbackGenerator"],
        tags: ["radial menu", "fan menu", "arc", "quick actions", "径向菜单", "扇形菜单", "快捷操作", "弧形"],
        params: [
            .slider("radius", L("Arc radius", "弧线半径"), 80...140, default: 110, decimals: 0, unit: "pt"),
            .slider("spread", L("Arc spread", "弧线跨度"), 90...200, default: 160, decimals: 0, unit: "°"),
            .slider("stagger", L("Stagger", "错开间隔"), 0.0...0.1, default: 0.035, decimals: 3, unit: "s"),
        ]
    ) { ctx in
        RadialMenuDemo(ctx: ctx)
    }
}

private struct RadialItem {
    let symbol: String
    let color: Color
    let title: LocalizedText
}

private let radialItems: [RadialItem] = [
    RadialItem(symbol: "camera.fill", color: Palette.coral, title: L("Camera", "相机")),
    RadialItem(symbol: "photo.fill", color: Palette.amber, title: L("Photo", "照片")),
    RadialItem(symbol: "mic.fill", color: Palette.mint, title: L("Voice", "语音")),
    RadialItem(symbol: "location.fill", color: Palette.sky, title: L("Location", "位置")),
    RadialItem(symbol: "doc.fill", color: Palette.violet, title: L("File", "文件")),
]

private struct RadialMenuDemo: View {
    let ctx: DemoContext
    @State private var open = false
    @State private var highlighted: Int?
    @State private var chosen: Int?
    @State private var previewPhase = 0
    @State private var pressBeganOpen: Bool?

    private let buttonSize: CGFloat = 60

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black
                .opacity(open ? 0.14 : 0)
                .animation(.easeOut(duration: 0.25), value: open)
                .allowsHitTesting(false)
            ZStack {
                ForEach(0..<radialItems.count, id: \.self) { index in
                    itemView(index)
                }
                mainButton
            }
            .frame(width: buttonSize, height: buttonSize)
            .padding(.bottom, 36)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .top) { chosenBadge }
        .overlay {
            DemoHint(text: L("Press + and slide to an item", "按住 + 并滑向选项"), ctx: ctx)
                .offset(y: -40)
                .opacity(open || chosen != nil ? 0 : 1)
                .animation(.easeOut(duration: 0.2), value: open)
                .allowsHitTesting(false)
        }
        .autoplay(ctx.isPreview, every: 0.9) { advancePreview() }
    }

    // MARK: Geometry

    private func angle(for index: Int) -> Double {
        let spread = ctx["spread"] * Double.pi / 180
        let start = 1.5 * Double.pi - spread / 2
        let step = radialItems.count > 1 ? spread / Double(radialItems.count - 1) : 0
        return start + Double(index) * step
    }

    private func position(for index: Int) -> CGPoint {
        let a = angle(for: index)
        let r = ctx["radius"]
        return CGPoint(x: cos(a) * r, y: sin(a) * r)
    }

    // MARK: Views

    private func itemView(_ index: Int) -> some View {
        let item = radialItems[index]
        let point = position(for: index)
        let isHot = highlighted == index
        let delay = open ? Double(index) * ctx["stagger"] : Double(radialItems.count - 1 - index) * ctx["stagger"] * 0.5
        return Image(systemName: item.symbol)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 48, height: 48)
            .background(item.color.gradient, in: Circle())
            .shadow(color: item.color.opacity(isHot ? 0.6 : 0.25), radius: isHot ? 14 : 6, y: 4)
            .overlay(alignment: .top) {
                Text(item.title, ctx.language)
                    .font(.caption.weight(.semibold))
                    .fixedSize()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.regularMaterial, in: Capsule())
                    .offset(y: -32)
                    .opacity(isHot ? 1 : 0)
                    .scaleEffect(isHot ? 1 : 0.6, anchor: .bottom)
            }
            .scaleEffect(open ? (isHot ? 1.25 : 1) : 0.3)
            .rotationEffect(.degrees(open ? 0 : -90))
            .offset(x: open ? point.x : 0, y: open ? point.y : 0)
            .opacity(open ? 1 : 0)
            .animation(.spring(response: 0.42, dampingFraction: 0.68).delay(delay), value: open)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isHot)
            .onTapGesture { commit(index) }
            .allowsHitTesting(open)
    }

    private var mainButton: some View {
        Image(systemName: "plus")
            .font(.title2.weight(.bold))
            .foregroundStyle(.white)
            .rotationEffect(.degrees(open ? 135 : 0))
            .frame(width: buttonSize, height: buttonSize)
            .background(Palette.primary, in: Circle())
            .shadow(color: Palette.indigo.opacity(0.4), radius: 14, y: 8)
            .scaleEffect(highlighted == nil ? 1 : 0.9)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: open)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: highlighted)
            .gesture(pressDrag)
    }

    @ViewBuilder private var chosenBadge: some View {
        if let chosen {
            Label(radialItems[chosen].title(ctx.language), systemImage: radialItems[chosen].symbol)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: Capsule())
                .padding(.top, 22)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: Interaction

    private var pressDrag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if pressBeganOpen == nil {
                    pressBeganOpen = open
                    if !open { setOpen(true) }
                }
                let center = CGPoint(x: buttonSize / 2, y: buttonSize / 2)
                let finger = CGPoint(x: value.location.x - center.x, y: value.location.y - center.y)
                var nearest: Int?
                var best: CGFloat = 40
                for index in 0..<radialItems.count {
                    let p = position(for: index)
                    let d = hypot(p.x - finger.x, p.y - finger.y)
                    if d < best {
                        best = d
                        nearest = index
                    }
                }
                if nearest != highlighted {
                    highlighted = nearest
                    if nearest != nil && !ctx.isPreview { Haptics.selection() }
                }
            }
            .onEnded { value in
                let wasOpen = pressBeganOpen ?? false
                pressBeganOpen = nil
                let moved = hypot(value.translation.width, value.translation.height) > 20
                if let highlighted {
                    commit(highlighted)
                } else if moved || wasOpen {
                    setOpen(false)
                }
            }
    }

    private func setOpen(_ value: Bool) {
        if value && !ctx.isPreview { Haptics.tap(.medium) }
        open = value
        if !value { highlighted = nil }
    }

    private func commit(_ index: Int) {
        if !ctx.isPreview { Haptics.success() }
        highlighted = nil
        open = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { chosen = index }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.1))
            if chosen == index {
                withAnimation(.easeOut(duration: 0.25)) { chosen = nil }
            }
        }
    }

    private func advancePreview() {
        switch previewPhase % 4 {
        case 0: setOpen(true)
        case 1: highlighted = 1
        case 2: highlighted = 3
        default: commit(3)
        }
        previewPhase += 1
    }
}
