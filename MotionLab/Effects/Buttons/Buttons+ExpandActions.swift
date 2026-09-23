import SwiftUI

extension Effect {
    static let buttonsExpandActions = Effect(
        id: "buttons.expand-actions",
        category: .buttons,
        interaction: .tap,
        name: L("Expanding Action Button", "展开式操作按钮"),
        summary: L("A floating plus rotates into a close and fans out quick actions.", "悬浮加号旋转成关闭按钮，并扇形展开快捷操作。"),
        prompt: L(
            "A 64 pt circular floating action button with an indigo-violet gradient and a plus glyph. On tap the plus rotates 135° into a close mark while the button dips to 92% and rebounds, and three smaller 50 pt action circles (camera, photo, document), each tinted differently, burst out of its center along a 100 pt arc above it. Each action scales from 30% to 100%, fades in and travels outward on a spring (response 0.4 s, damping 0.7) with a 40 ms stagger, so they unfurl like a fan. Closing reverses the stagger order and tucks them back behind the button. A light haptic accompanies each toggle. Playful yet orderly — contextual actions without leaving the screen.",
            "直径 64pt 的圆形悬浮操作按钮，靛紫渐变，中间是加号。点击后加号旋转 135° 变成关闭符号，按钮同时下沉到 92% 再回弹；三个 50pt 的小圆形操作（相机、照片、文档，各有不同色调）从按钮中心迸出，沿其上方半径 100pt 的弧线排开。每个操作从 30% 缩放到 100%、同时淡入，以弹簧（响应 0.4 秒、阻尼 0.7）向外移动，彼此错开 40 毫秒，如扇面般依次展开。收起时按相反顺序错峰缩回按钮后方。每次切换都有轻触觉反馈。俏皮又有秩序——无需离开当前页面即可调出情境操作。"
        ),
        implementation: L(
            "Each action reads a single open flag and applies its own delayed spring via animation(_:value:), with the delay reversed on close; positions come from polar coordinates on an arc or a vertical stack.",
            "每个操作读取同一个展开状态，并通过 animation(_:value:) 应用各自带延迟的弹簧，收起时延迟顺序反转；位置由弧线上的极坐标或纵向堆叠计算得出。"
        ),
        apis: ["animation(_:value:)", "spring(response:dampingFraction:)", "rotationEffect", "delay"],
        tags: ["fab", "speed dial", "expand", "menu", "悬浮按钮", "展开", "快捷操作", "扇形"],
        params: [
            .slider("radius", L("Spread radius", "展开半径"), 70...130, default: 100, decimals: 0, unit: "pt"),
            .slider("stagger", L("Stagger", "错峰间隔"), 0...0.15, default: 0.04, unit: "s"),
            .choice("layout", L("Layout", "布局"), [L("Arc", "弧形"), L("Vertical", "纵向")], default: 0),
        ]
    ) { ctx in
        ButtonExpandActionsDemo(ctx: ctx)
    }
}

private struct ButtonActionItem {
    let symbol: String
    let color: Color
}

private struct ButtonExpandActionsDemo: View {
    let ctx: DemoContext
    @State private var open = false
    @State private var presses = 0

    private let items: [ButtonActionItem] = [
        ButtonActionItem(symbol: "camera.fill", color: Palette.coral),
        ButtonActionItem(symbol: "photo.fill", color: Palette.mint),
        ButtonActionItem(symbol: "doc.fill", color: Palette.sky),
    ]

    var body: some View {
        ZStack {
            ForEach(items.indices, id: \.self) { index in
                actionButton(index)
            }
            mainButton
        }
        .offset(y: 70)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.5, delay: 0.4) { toggle() }
    }

    private var mainButton: some View {
        Button(action: toggle) {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(open ? 135 : 0))
                .frame(width: 64, height: 64)
                .background(Palette.primary, in: Circle())
                .shadow(color: Palette.indigo.opacity(0.4), radius: 16, y: 8)
                .keyframeAnimator(initialValue: 1.0, trigger: presses) { content, scale in
                    content.scaleEffect(scale)
                } keyframes: { _ in
                    KeyframeTrack(\.self) {
                        CubicKeyframe(0.92, duration: 0.08)
                        SpringKeyframe(1, duration: 0.4, spring: .bouncy)
                    }
                }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.4, dampingFraction: 0.65), value: open)
    }

    private func actionButton(_ index: Int) -> some View {
        let item = items[index]
        let target = position(for: index)
        let stagger = ctx["stagger"]
        let delay = open ? Double(index) * stagger : Double(items.count - 1 - index) * stagger
        return Button {
            if !ctx.isPreview { Haptics.tap() }
            toggle()
        } label: {
            Image(systemName: item.symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(item.color.gradient, in: Circle())
                .shadow(color: item.color.opacity(0.35), radius: 10, y: 6)
        }
        .buttonStyle(.plain)
        .scaleEffect(open ? 1 : 0.3)
        .opacity(open ? 1 : 0)
        .offset(x: open ? target.x : 0, y: open ? target.y : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(delay), value: open)
        .allowsHitTesting(open)
    }

    private func position(for index: Int) -> CGPoint {
        let radius = ctx.cg("radius")
        if ctx.int("layout") == 1 {
            return CGPoint(x: 0, y: -CGFloat(index + 1) * (radius * 0.66))
        }
        let degrees = -150 + Double(index) * 60
        let radians = degrees * .pi / 180
        return CGPoint(x: CGFloat(cos(radians)) * radius, y: CGFloat(sin(radians)) * radius)
    }

    private func toggle() {
        open.toggle()
        presses += 1
        if !ctx.isPreview { Haptics.tap() }
    }
}
