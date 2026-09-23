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
            "A 60 pt gradient attach button sits at the bottom center of a chat screen. Tapping, or pressing and holding, fans five circular actions along a 160° arc of ~110 pt radius: each flies out of the button's center, spinning in from –90° and scaling 30% → 100% on a bouncy spring (response 0.42 s, damping 0.68), staggered 35 ms left to right, as the plus turns into a × and a scrim dims the page. Sliding toward an action without lifting magnetically highlights it (125% with a colored glow, its label popping above, a selection tick); releasing on it confirms with a success haptic and the arc collapses back into the button in reverse, faster. Playful, direct, one-thumb.",
            "聊天界面底部正中是一枚 60 pt 的渐变“附件”按钮。点一下或按住，五个圆形操作沿半径约 110 pt、跨度 160° 的弧线扇形展开：每个都从按钮中心飞出，自 –90° 旋入，从 30% 放大到 100%，乘富有弹性的弹簧（响应 0.42 秒、阻尼 0.68），自左向右相隔 35 毫秒；加号同时转成 ×，页面压上遮罩。手指不松、滑向某项，它便被“磁吸”点亮：放大到 125%、泛起彩色辉光，名称在上方弹出，并有选择触感；在其上松手即确认，伴随成功触感，弧形菜单按相反顺序更快地收回按钮。俏皮、直接，单手即可。"
        ),
        implementation: L(
            "Items are positioned with trigonometric offsets from the button center and animate with per-index delayed springs; one DragGesture(minimumDistance: 0) opens the menu, hit-tests the finger against item positions and commits on release.",
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
    @State private var token = 0
    /// Resets on system cancellation too (scroll takeover, Control Center pull), which skips `onEnded`.
    @GestureState private var pressing = false

    private let buttonSize: CGFloat = 60

    var body: some View {
        ZStack(alignment: .bottom) {
            RadialChatBackdrop(language: ctx.language)
                .blur(radius: open ? 2 : 0)
                .animation(.easeOut(duration: 0.25), value: open)
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
            .onChange(of: pressing) { _, active in
                if !active { cancelPress() }
            }
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
            .updating($pressing) { _, state, _ in state = true }
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

    /// Cancelled press: forget the press so the next touch on + starts fresh, and drop the highlight without
    /// committing. The menu stays open, so its items can still be tapped. No-op after a normal release.
    private func cancelPress() {
        guard pressBeganOpen != nil else { return }
        pressBeganOpen = nil
        highlighted = nil
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
        token += 1
        let current = token
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.1))
            if token == current && chosen == index {
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

/// A short chat so the attach menu fans out over a real conversation instead of an empty stage.
private struct RadialChatBackdrop: View {
    let language: AppLanguage

    private var zh: Bool { language == .zh }

    var body: some View {
        VStack(spacing: 10) {
            bubble(zh ? "今晚在哪儿碰头？" : "Where should we meet tonight?", outgoing: false)
            bubble(zh ? "我把位置发给你 📍" : "Sending you the spot 📍", outgoing: true)
            bubble(zh ? "好，七点见！" : "Perfect — see you at 7!", outgoing: false)
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(false)
    }

    private func bubble(_ text: String, outgoing: Bool) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(outgoing ? Color.white : Color.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                outgoing ? AnyShapeStyle(Palette.primary) : AnyShapeStyle(Palette.surface),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .frame(maxWidth: .infinity, alignment: outgoing ? .trailing : .leading)
    }
}
